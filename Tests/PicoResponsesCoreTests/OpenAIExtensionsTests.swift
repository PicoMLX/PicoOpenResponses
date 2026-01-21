import Foundation
import Testing
@testable import PicoResponsesCore

@Test func responseAudioOptionsEncoding() throws {
    let options = ResponseAudioOptions(voice: "alloy", format: "wav")
    let data = try ResponsesJSONCoding.makeEncoder().encode(options)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json? ["voice"] as? String == "alloy")
    #expect(json? ["format"] as? String == "wav")
}

@Test func responseModalityEncoding() throws {
    let modalities: [ResponseModality] = [.text, .audio]
    let data = try JSONEncoder().encode(modalities)
    let raw = try JSONSerialization.jsonObject(with: data) as? [String]
    #expect(raw == ["text", "audio"])
}
