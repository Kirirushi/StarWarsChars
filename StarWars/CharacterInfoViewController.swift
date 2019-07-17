//
//  CharacterInfoViewController.swift
//  StarWars
//
//  Created by Master on 14/07/2019.
//  Copyright © 2019 Kirirushi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RealmSwift
import Alamofire

class CharacterInfoViewController: UIViewController {
  @IBOutlet weak var characterTableView: UITableView!

  var character = Character(birthYear: "", eyeColor: "", gender: "",
                            hairColor: "", height: "", homeworld: "",
                            mass: "", skinColor: "", name: "", url: "",
                            films: [], species: [], starships: [], vehicles: [])

  let disposeBag = DisposeBag()
  var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, (String, String?)>>(
    configureCell: { (_, tableView, indexPath, element) in
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? CharacterParametrCell
      cell?.paramName.text = element.0
      cell?.paramValue.text = element.1
      return cell ?? UITableViewCell()
  },
    titleForHeaderInSection: { dataSource, sectionIndex in
      return dataSource[sectionIndex].model
  })

  var sections: BehaviorRelay<[SectionModel<String, (String, String?)>]>!
  var isLoading = BehaviorRelay<Bool>(value: false)

  var isOfflineMode = false

  var realm: Realm!
  var filmsCount: Int {
    return character.films.count
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let realm = try? Realm() else {
      print("Failed to load Realm Database")
      return
    }
    
    self.realm = realm
    title = character.name

    if let realmCharacter = realm.object(ofType: RealmCharacter.self, forPrimaryKey: character.id) {
      if realmCharacter.homeworld != nil, !realmCharacter.films.isEmpty {
        isOfflineMode = true
      }
    }

    if isOfflineMode {
      setOfflineMode()
      return
    }
    try? realm.write {
      realm.add(RealmCharacter(with: self.character), update: .modified)
    }
    sections = BehaviorRelay(value: [
      SectionModel<String, (String, String?)>(model: "Desription", items: [
        ("Birthyear", character.birthYear),
        ("Gender", character.gender),
        ("Hair color", character.hairColor),
        ("Eye color", character.eyeColor),
        ("Skin color", character.skinColor),
        ("Height", character.height),
        ("Weight", character.mass),
        ])
      ])

    startLoadHomeworld()
      .subscribe(
       onNext: { planet in
        var oldValue = self.sections.value
        let homeworldSection = SectionModel<String, (String, String?)>(model: "Homeworld", items: [
          ("Planet", planet.name),
          ("Rotation period", planet.rotationPeriod),
          ("Orbital period", planet.orbitalPeriod),
          ("Diameter", planet.diameter),
          ("Gravity", planet.gravity),
          ("Climate", planet.climate),
          ("Terrain", planet.terrain),
          ("Surface water", planet.surfaceWater),
          ("Population", planet.population),
          ])
        oldValue.append(homeworldSection)
        self.sections.accept(oldValue)
        let currentCharacter = realm.object(ofType: RealmCharacter.self, forPrimaryKey: self.character.id)
        try? realm.write {
          currentCharacter?.addNomeworld(planet)
        }
        Observable.merge(self.character.films.map({ ApiClient.getFilm(url: $0) }))
          .take(self.filmsCount)
          .subscribe(
            onNext: { film in
              if film.episodeID > 0 {
                var oldValue = self.sections.value
                var filmsSection = SectionModel<String, (String, String?)>(model: "Films", items: [])
                if let films = oldValue.first(where: { $0.model == "Films" }) {
                  filmsSection.items = films.items
                  filmsSection.items.append((film.title, ""))
                } else {
                  filmsSection.items = [(film.title, "")]
                }
                if let index = oldValue.firstIndex(where: { $0.model == "Films" }) {
                  oldValue.remove(at: index)
                  oldValue.insert(filmsSection, at: index)
                } else {
                  oldValue.insert(filmsSection, at: oldValue.endIndex)
                }
                let currentCharacter = realm.object(ofType: RealmCharacter.self, forPrimaryKey: self.character.id)
                try? realm.write {
                  currentCharacter?.addFilm(film)
                }
                self.sections.accept(oldValue)
              }
          },
            onError: { error in
              self.processError(error: error)
          },
            onCompleted: {
              self.isLoading.accept(false)
          })
          .disposed(by: self.disposeBag)
      },
       onError: { error in
        self.processError(error: error)
      })
      .disposed(by: disposeBag)

    sections.asObservable()
      .bind(to: characterTableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)

    characterTableView.rx
      .setDelegate(self)
      .disposed(by: disposeBag)

    isLoading.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(
       onNext: { isLoading in
        if isLoading {
          let footerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: 44)))
          let activityIndicator = UIActivityIndicatorView(style: .gray)
          footerView.addSubview(activityIndicator)
          activityIndicator.center = CGPoint(x: self.view.frame.width / 2, y: 22)
          activityIndicator.startAnimating()
          self.characterTableView.tableFooterView = footerView
        } else {
          self.characterTableView.tableFooterView = nil
        }
      })
      .disposed(by: disposeBag)
  }
  func startLoadHomeworld() -> Observable<Planet> {
    isLoading.accept(true)
    return ApiClient.getPlanet(url: character.homeworld)
  }
  func processError(error: Error) {
    isLoading.accept(false)
    switch error {
    case ApiError.notFound:
      present(UIAlertController.errorAlertController(title: "Error", message: "Not found"), animated: true)
    case ApiError.internalServerError:
      present(UIAlertController.errorAlertController(title: "Error", message: "Server error"), animated: true)
    case ApiError.noInternet:
      present(UIAlertController.errorAlertController(title: "Error", message: "No Internet"), animated: true)
    default:
      present(UIAlertController.errorAlertController(title: "Error", message: error.localizedDescription), animated: true)
    }
  }
  func setOfflineMode() {
    guard let realmCharacter = realm.object(ofType: RealmCharacter.self, forPrimaryKey: character.id) else {
      print("Character not found")
      return
    }
    let rxRealmCharacter = BehaviorRelay<RealmCharacter>(value: realmCharacter)

    rxRealmCharacter.asObservable()
      .map { realmCharacter -> [SectionModel<String, (String, String?)>] in
        var sections = [SectionModel<String, (String, String?)>(model: "Desription", items: [
          ("Birthyear", realmCharacter.birthYear),
          ("Gender", realmCharacter.gender),
          ("Hair color", realmCharacter.hairColor),
          ("Eye color", realmCharacter.eyeColor),
          ("Skin color", realmCharacter.skinColor),
          ("Height", realmCharacter.height),
          ("Weight", realmCharacter.mass),
          ])]
        if realmCharacter.homeworld != nil {
          let planet = realmCharacter.homeworld!
          sections.append(SectionModel<String, (String, String?)>(model: "Homeworld", items: [
            ("Planet", planet.name),
            ("Rotation period", planet.rotationPeriod),
            ("Orbital period", planet.orbitalPeriod),
            ("Diameter", planet.diameter),
            ("Gravity", planet.gravity),
            ("Climate", planet.climate),
            ("Terrain", planet.terrain),
            ("Surface water", planet.surfaceWater),
            ("Population", planet.population),
            ]))
        }
        if !realmCharacter.films.isEmpty {
          var filmsSection = SectionModel<String, (String, String?)>(model: "Films", items: [])
          filmsSection.items = realmCharacter.films.map({ ($0.title, "") })
          sections.append(filmsSection)
        }
        return sections
      }
      .bind(to: characterTableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)

  }
}
extension CharacterInfoViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let cell = tableView.cellForRow(at: indexPath) as? CharacterParametrCell {
      return cell.paramValue.frame.height + 6
    }
    return UITableView.automaticDimension
  }
  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .none
  }
}
class CharacterParametrCell: UITableViewCell {
  @IBOutlet weak var paramName: UILabel!
  @IBOutlet weak var paramValue: UILabel!
}
