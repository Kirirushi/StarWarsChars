//
//  SWAPI.swift
//  StarWars
//
//  Created by Master on 12/07/2019.
//  Copyright © 2019 Kirirushi. All rights reserved.
//

import UIKit
import Alamofire
import RxSwift
import RxCocoa

struct Constants {
  static let baseUrl = "https://swapi.co/api/"

  struct Parameters {
    static let id = "id"
    static let search = "search"
    static let page = "page"
  }
  enum HttpHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
  }

  enum ContentType: String {
    case json = "application/json"
  }
}
enum ApiRouter: URLRequestConvertible {
  case searchPeople(name: String, page: Int)
  case getPlanet(id: String)
  case getFilm(id: String)

  func asURLRequest() throws -> URLRequest {
    let url = try Constants.baseUrl.asURL()

    var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue(Constants.ContentType.json.rawValue, forHTTPHeaderField: Constants.HttpHeaderField.acceptType.rawValue)
        urlRequest.setValue(Constants.ContentType.json.rawValue, forHTTPHeaderField: Constants.HttpHeaderField.contentType.rawValue)

    let encoding: ParameterEncoding = {
      switch method {
      case .get:
        return URLEncoding.default
      default:
        return JSONEncoding.default
      }
    }()
    return try encoding.encode(urlRequest, with: parameters)
  }
  private var method: HTTPMethod {
    switch self {
    case .searchPeople, .getPlanet, .getFilm:
      return .get
    }
  }

  private var path: String {
    switch self {
    case .getFilm(let id):
      return "films/\(id)"
    case .getPlanet(let id):
      return "planets/\(id)"
    case .searchPeople:
      return "people"
    }
  }

  private var parameters: Parameters? {
    switch self {
    case .getPlanet, .getFilm:
      return nil
    case .searchPeople(let name, let page):
      return [Constants.Parameters.search: name,
              Constants.Parameters.page: page
      ]
    }
  }
  func request<T: Codable> (_ urlConvertible: URLRequestConvertible) -> Observable<T> {
    return Observable<T>.create { observer in
      let request = AF.request(urlConvertible).responseDecodable { (response: DataResponse<T>) in
        switch response.result {
        case .success(let value):
          observer.onNext(value)
          observer.onCompleted()
        case .failure(let error):
          switch response.response?.statusCode {
          case 404:
            observer.onError(ApiError.notFound)
          case 500:
            observer.onError(ApiError.internalServerError)
          default:
            if let err = error as? URLError, err.code == .notConnectedToInternet {
              observer.onError(ApiError.noInternet)
            } else {
              observer.onError(error)
            }
          }
        }
      }
      return Disposables.create {
        request.cancel()
      }
    }
  }
}

enum ApiError: Error {
  case notFound
  case internalServerError
  case noInternet
}
class ApiClient {
  static func searchPeople(name: String?, page: Int) -> Observable<SearchResponse> {
    return request(ApiRouter.searchPeople(name: name ?? "", page: page))
  }
  static func getPlanet(url: String) -> Observable<Planet> {
    return request(ApiRouter.getPlanet(id: url.components(separatedBy: "/").filter({ !$0.isEmpty }).last ?? "1"))
  }
  static func getFilm(url: String) -> Observable<Film> {
    return request(ApiRouter.getFilm(id: url.components(separatedBy: "/").filter({ !$0.isEmpty }).last ?? "1"))
  }
  private static func request<T: Codable> (_ urlConvertible: URLRequestConvertible) -> Observable<T> {
    return Observable<T>.create { observer in
      let request = AF.request(urlConvertible).responseDecodable { (response: DataResponse<T>) in
        switch response.result {
        case .success(let value):
          observer.onNext(value)
          observer.onCompleted()
        case .failure(let error):
          switch response.response?.statusCode {
          case 404:
            observer.onError(ApiError.notFound)
          case 500:
            observer.onError(ApiError.internalServerError)
          default:
            if let err = error as? URLError, err.code == .notConnectedToInternet {
              observer.onError(ApiError.noInternet)
            } else {
              observer.onError(error)
            }
          }
        }
      }
      return Disposables.create {
        request.cancel()
      }
    }
  }
}
