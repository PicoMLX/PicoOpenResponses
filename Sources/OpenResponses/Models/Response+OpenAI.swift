//
//  Response+OpenAI.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 1/18/26.
//
// OpenAI-specific extensions not part of the Open Responses standard

import Foundation

public enum ResponseModality: String, Codable, Sendable {
    case text
    case audio
    case image
    case video
}

public struct ResponseAudioOptions: Codable, Sendable, Equatable {
    public let voice: String?
    public let format: String?

    public init(voice: String? = nil, format: String? = nil) {
        self.voice = voice
        self.format = format
    }
}
