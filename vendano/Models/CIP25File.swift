//
//  CIP25File.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Foundation

struct CIP25File: Decodable {
    let src: String // URI of the file
    let mediaType: String? // MIME type (e.g. "image/png")
}
