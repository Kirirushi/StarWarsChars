//
//  RealmModels.swift
//  StarWars
//
//  Created by Master on 15/07/2019.
//  Copyright © 2019 Kirirushi. All rights reserved.
//

import UIKit
import RealmSwift

class RealmCharacter: Object {
  @objc dynamic var id = ""
  @objc dynamic var name = ""
  @objc dynamic var birthYear = ""
  @objc dynamic var eyeColor = ""
  @objc dynamic var hairColor = ""
  @objc dynamic var skinColor = ""
  @objc dynamic var gender = ""
  @objc dynamic var height = ""
  @objc dynamic var mass = ""
  @objc dynamic var url = ""
  @objc dynamic var homeworld: RealmPlanet?
  var films = List<RealmFilm>()
  override static func primaryKey() -> String? {
    return "id"
  }
}
extension RealmCharacter {
  convenience init(with character: Character) {
    self.init()
    id = character.id
    name = character.name
    birthYear = character.birthYear
    eyeColor = character.eyeColor
    hairColor = character.hairColor
    skinColor = character.skinColor
    gender = character.gender
    height = character.height
    mass = character.mass
    url = character.url

    homeworld = nil
    films = List<RealmFilm>()
  }
  func addFilm(_ film: Film) {
    films.append(RealmFilm(with: film))
  }
  func addNomeworld(_ planet: Planet) {
    homeworld = RealmPlanet(with: planet)
  }
}
extension Character {
  init(with realmCharacter: RealmCharacter) {
    self.init(birthYear: realmCharacter.birthYear,
              eyeColor: realmCharacter.eyeColor,
              gender: realmCharacter.gender,
              hairColor: realmCharacter.hairColor,
              height: realmCharacter.height,
              homeworld: "",
              mass: realmCharacter.mass,
              skinColor: realmCharacter.skinColor,
              name: realmCharacter.name,
              url: realmCharacter.url,
              films: [], species: [], starships: [], vehicles: [])
  }
}
extension Film {
  init(with realmFilm: RealmFilm) {
    self.init(title: realmFilm.title,
              episodeID: realmFilm.episodeID,
              openingCrawl: realmFilm.openingCrawl,
              director: realmFilm.director,
              producer: realmFilm.producer,
              releaseDate: realmFilm.releaseDate)
  }
}
extension Planet {
  init(with realmPlanet: RealmPlanet) {
    self.init(name: realmPlanet.name,
              rotationPeriod: realmPlanet.rotationPeriod,
              orbitalPeriod: realmPlanet.orbitalPeriod,
              diameter: realmPlanet.diameter,
              climate: realmPlanet.climate,
              gravity: realmPlanet.gravity,
              terrain: realmPlanet.terrain,
              surfaceWater: realmPlanet.surfaceWater,
              population: realmPlanet.population)
  }
}
class RealmFilm: Object {
  @objc dynamic var title = ""
  @objc dynamic var director = ""
  @objc dynamic var openingCrawl = ""
  @objc dynamic var producer = ""
  @objc dynamic var releaseDate = ""
  @objc dynamic var episodeID = 0
}
extension RealmFilm {
  convenience init(with film: Film) {
    self.init()
    title = film.title
    director = film.director
    openingCrawl = film.openingCrawl
    producer = film.producer
    releaseDate = film.releaseDate
    episodeID = film.episodeID
  }
}
class RealmPlanet: Object {
  @objc dynamic var name = ""
  @objc dynamic var rotationPeriod = ""
  @objc dynamic var orbitalPeriod = ""
  @objc dynamic var diameter = ""
  @objc dynamic var climate = ""
  @objc dynamic var gravity = ""
  @objc dynamic var terrain = ""
  @objc dynamic var surfaceWater = ""
  @objc dynamic var population = ""
}
extension RealmPlanet {

  convenience init(with planet: Planet) {
    self.init()
    name = planet.name
    rotationPeriod = planet.rotationPeriod
    orbitalPeriod = planet.orbitalPeriod
    diameter = planet.diameter
    climate = planet.climate
    gravity = planet.gravity
    terrain = planet.terrain
    surfaceWater = planet.surfaceWater
    population = planet.population
  }
}
