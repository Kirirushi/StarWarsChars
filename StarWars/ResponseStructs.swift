//
//  ResponseStructs.swift
//  StarWars
//
//  Created by Master on 15/07/2019.
//  Copyright © 2019 Kirirushi. All rights reserved.
//

import Foundation

struct Planet: Codable {
  let name, rotationPeriod, orbitalPeriod, diameter: String
  let climate, gravity, terrain, surfaceWater: String
  let population: String

  enum CodingKeys: String, CodingKey {
    case name
    case rotationPeriod = "rotation_period"
    case orbitalPeriod = "orbital_period"
    case diameter, climate, gravity, terrain
    case surfaceWater = "surface_water"
    case population
  }
}
struct Character: Codable {
  var birthYear, eyeColor, gender,
  hairColor, height, homeworld,
  mass, skinColor, name, url: String
  var films, species,
  starships, vehicles: [String]
  enum CodingKeys: String, CodingKey {
    case gender, height, homeworld, mass, name, films, species, starships, vehicles, url
    case birthYear = "birth_year"
    case eyeColor = "eye_color"
    case hairColor = "hair_color"
    case skinColor = "skin_color"
  }
}
extension Character {
  var id: String {
    return url.components(separatedBy: "/").filter({ !$0.isEmpty }).last ?? url
  }
}
struct Film: Codable {
  let title: String
  let episodeID: Int
  let openingCrawl, director, producer, releaseDate: String

  enum CodingKeys: String, CodingKey {
    case title
    case episodeID = "episode_id"
    case openingCrawl = "opening_crawl"
    case director, producer
    case releaseDate = "release_date"
  }
}
struct SearchResponse: Codable {
  var countOfCharacters: Int
  var nextPage, previousPage: String?
  var characters: [Character]

  enum CodingKeys: String, CodingKey {
    case characters = "results"
    case countOfCharacters = "count"
    case nextPage = "next"
    case previousPage = "previous"
  }
}
