import Foundation
import Testing
@testable import PicoResponsesCore

@Test func fileObjectDecodesStatusDetails() throws {
    let payload: [String: Any] = [
        "id": "file_123",
        "object": "file",
        "bytes": 512,
        "created_at": 1_700_000_000,
        "filename": "notes.txt",
        "purpose": "responses",
        "status": "uploaded",
        "status_details": [
            "error": [
                "code": "quota_exceeded",
                "message": "You exceeded storage quota"
            ]
        ]
    ]

    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let file = try decoder.decode(FileObject.self, from: data)

    #expect(file.status == "uploaded")
    let errorDetails = file.statusDetails? ["error"]?.dictionaryValue
    #expect(errorDetails? ["code"]?.stringValue == "quota_exceeded")

    let encoder = ResponsesJSONCoding.makeEncoder()
    let encoded = try encoder.encode(file)
    let roundTrip = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let statusDetails = roundTrip? ["status_details"] as? [String: Any]
    let error = statusDetails? ["error"] as? [String: Any]
    #expect(error? ["message"] as? String == "You exceeded storage quota")
}
