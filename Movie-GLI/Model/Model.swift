//
//  Model.swift
//  Movie-GLI
//
//  Created by Muhammad Faruuq Qayyum on 14/01/21.
//

import Foundation

struct Root: Decodable, Hashable {
    let results: [Results]
}

struct Results: Decodable, Hashable {
    let id: Int?
    let title: String?
    let image: String?
    let overview: String?
    let youtube: String?
    let imageLandscape: String?
    let content: String?
    var identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    enum CodingKeys: String, CodingKey {
        case image = "poster_path"
        case youtube = "key"
        case imageLandscape = "backdrop_path"
        case id, overview, title, content
    }
}

struct Review: Decodable {
    let results: [Results]
    
    struct Results: Decodable {
        let author: String?
        let content: String?
        let key: String?
    }
}


