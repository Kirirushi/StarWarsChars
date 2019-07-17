//
//  ViewController.swift
//  StarWars
//
//  Created by Master on 12/07/2019.
//  Copyright © 2019 Kirirushi. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift
import RxSwift
import RxCocoa
import SafariServices

class CharactersViewController: UIViewController {
  @IBOutlet weak var charactersTableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!

  let disposeBag = DisposeBag()
  var selectedCharacter: Character?
  var currentPage = BehaviorRelay<Int>(value: 1)
  var isLoading = BehaviorRelay<Bool>(value: false)
  var characters = BehaviorRelay<[Character]>(value: [])
  var lastEvent: (text: String?,page: Int) = ("", 1)
  var isReachable: Bool {
    return NetworkReachabilityManager()?.isReachable ?? false
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let realm = try? Realm() else {
      print("Failed to load Realm Database")
      return
    }

    BehaviorRelay<Bool>(value: NetworkReachabilityManager()?.isReachable ?? false).asObservable()
      .flatMap { isReachable -> Observable<[Character]> in
        if isReachable {
          return self.characters.asObservable()
        } else {
          let realmCharacters = try? realm.objects(RealmCharacter.self).filter { character -> Bool in
            if character.id.isEmpty {
              throw NSError(domain: "Wrong ID", code: -1, userInfo: nil)
            }
            return true
          }
          let savedCharacters = (realmCharacters ?? []).compactMap({ Character(with: $0) })
          return Observable.just(savedCharacters)
        }
      }
      .bind(to: charactersTableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { row, element, cell in
        cell.textLabel?.text = element.name
      }
      .disposed(by: disposeBag)

    Observable.combineLatest(
      searchBar.rx.text.throttle(RxTimeInterval.milliseconds(700), scheduler: MainScheduler.instance),
      searchBar.rx.searchButtonClicked.asObservable()
    )
      .flatMapLatest({ (text, _) -> Observable<SearchResponse> in
        self.isLoading.accept(true)
        self.lastEvent.text = text
        self.lastEvent.page = 1
        return ApiClient.searchPeople(name: text, page: self.lastEvent.page)
      })
      .subscribe(
       onNext: { response in
        self.characters.accept(response.characters)
      },
       onError: { error in
        self.processError(error: error)
      },
       onCompleted: {
        self.isLoading.accept(false)
      })
      .disposed(by: disposeBag)

    charactersTableView.rx.modelSelected(Character.self)
      .subscribe(onNext: { character in
        self.selectedCharacter = character
        self.performSegue(withIdentifier: "characterInfo", sender: self)
      })
      .disposed(by: disposeBag)

    keyboardHeight()
      .observeOn(MainScheduler.instance)
      .subscribe({ keyboardHeight in
        self.charactersTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight.element ?? 0, right: 0)
      })
      .disposed(by: disposeBag)

    currentPage.asObservable()
      .flatMapLatest({ page -> Observable<SearchResponse> in
        self.lastEvent.page = page
        if !self.isLoading.value {
          self.isLoading.accept(true)
          return ApiClient.searchPeople(name: self.searchBar.text, page: page)
        }
        return Observable.just(SearchResponse(countOfCharacters: -1, nextPage: nil, previousPage: nil, characters: []))
      })
      .subscribe(
       onNext: { response in
        if response.countOfCharacters == -1 {
          print("Now something is loading")
          return
        }
        var oldCharacters = self.characters.value
        if self.lastEvent.page == 1 {
          oldCharacters.removeAll()
        }
        oldCharacters.append(contentsOf: response.characters)
        self.characters.accept(oldCharacters)
        self.isLoading.accept(false)
      },
       onError: { error in
        self.processError(error: error)
      })
      .disposed(by: disposeBag)

    charactersTableView.rx
      .contentOffset
      .subscribe(onNext: { offset in
        let currentOffset = offset.y
        let maximumOffset = self.charactersTableView.contentSize.height - self.charactersTableView.frame.height
        let deltaOffset = maximumOffset - currentOffset
        if deltaOffset <= 0, currentOffset > 0, !self.isLoading.value {
          self.currentPage.accept(self.currentPage.value + 1)
        }
      })
      .disposed(by: disposeBag)
    
    isLoading.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { isLoading in
        if isLoading {
          let footerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: 44)))
          let activityIndicator = UIActivityIndicatorView(style: .gray)
          footerView.addSubview(activityIndicator)
          activityIndicator.center = CGPoint(x: self.view.frame.width / 2, y: 22)
          activityIndicator.startAnimating()
          self.charactersTableView.tableFooterView = footerView
        } else {
          self.charactersTableView.tableFooterView = nil
        }
      })
      .disposed(by: disposeBag)
  }
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if let index = charactersTableView.indexPathForSelectedRow {
      selectedCharacter = nil
      charactersTableView.deselectRow(at: index, animated: true)
    }
  }
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "characterInfo", let selectedCharacter = selectedCharacter {
      (segue.destination as? CharacterInfoViewController)?.character = selectedCharacter
    }
  }
  func keyboardHeight() -> Observable<CGFloat> {
    return Observable
      .from([
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
          .map { notification -> CGFloat in
             return (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
          },
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
          .map { _ -> CGFloat in return 0 }
        ])
      .merge()
  }
  @objc func closeKeyboard() {
    view.endEditing(true)
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
}
