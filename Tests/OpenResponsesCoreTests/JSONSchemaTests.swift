import Foundation
import Testing
@testable import OpenResponses

@Test func jsonSchemaEncodingAndDecoding() throws {
    let schema = JSONSchema.object(
        properties: [
            "name": .string(minLength: 1, maxLength: 64, description: "Display name"),
            "age": .integer(minimum: 0, maximum: 150),
            "tags": .array(items: .string(), minItems: 1)
        ],
        patternProperties: ["^x-": .string()],
        required: ["name", "age"],
        additionalProperties: .schema(.string()),
        description: "Person record"
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(schema)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json? ["type"] as? String == "object")
    let required = json? ["required"] as? [String]
    #expect(required == ["age", "name"] || required == ["name", "age"])
    let additional = json? ["additionalProperties"] as? [String: Any]
    #expect(additional? ["type"] as? String == "string")
    let pattern = json? ["patternProperties"] as? [String: Any]
    let customHeader = pattern? ["^x-"] as? [String: Any]
    #expect(customHeader? ["type"] as? String == "string")

    let decoded = try JSONDecoder().decode(JSONSchema.self, from: data)
    #expect(decoded == schema)

    let document = JSONSchema.document(
        root: schema,
        definitions: [
            "Location": .object(
                properties: [
                    "lat": .number(),
                    "lon": .number()
                ],
                additionalProperties: .boolean(false)
            )
        ]
    )
    let documentData = try encoder.encode(document)
    let documentJSON = try JSONSerialization.jsonObject(with: documentData) as? [String: Any]
    let defs = documentJSON? ["$defs"] as? [String: Any]
    let locationSchema = defs? ["Location"] as? [String: Any]
    #expect(locationSchema? ["type"] as? String == "object")
    let decodedDocument = try JSONDecoder().decode(JSONSchema.self, from: documentData)
    if case .document(let root, let definitions) = decodedDocument {
        #expect(root == schema)
        #expect(definitions.keys.contains("Location"))
    } else {
        Issue.record("Expected document schema with $defs")
    }

    let notSchema = JSONSchema.not(.string(), description: "no strings")
    let notData = try encoder.encode(notSchema)
    let notJSON = try JSONSerialization.jsonObject(with: notData) as? [String: Any]
    #expect(notJSON? ["not"] as? [String: Any] != nil)
    let decodedNot = try JSONDecoder().decode(JSONSchema.self, from: notData)
    #expect(decodedNot == notSchema)

    let conditional = JSONSchema.conditional(
        if: .object(properties: ["kind": .constant(AnyCodable("cat"))]),
        then: .object(properties: ["purrs": .boolean()]),
        else: .object(properties: ["barks": .boolean()]),
        description: "Animal behaviour"
    )
    let conditionalData = try encoder.encode(conditional)
    let conditionalJSON = try JSONSerialization.jsonObject(with: conditionalData) as? [String: Any]
    #expect(conditionalJSON? ["if"] as? [String: Any] != nil)
    let decodedConditional = try JSONDecoder().decode(JSONSchema.self, from: conditionalData)
    #expect(decodedConditional == conditional)

    let tupleSchema = JSONSchema.tuple(
        prefixItems: [.string(), .number()],
        items: .string(),
        minItems: 2,
        maxItems: 4,
        description: "Tuple schema"
    )
    let tupleData = try encoder.encode(tupleSchema)
    let tupleJSON = try JSONSerialization.jsonObject(with: tupleData) as? [String: Any]
    let prefixSchemas = tupleJSON? ["prefixItems"] as? [[String: Any]]
    #expect(prefixSchemas?.count == 2)
    let decodedTuple = try JSONDecoder().decode(JSONSchema.self, from: tupleData)
    if case .raw(let rawValue) = decodedTuple {
        #expect(rawValue["prefixItems"] != nil)
    } else {
        Issue.record("Expected prefixItems schemas to decode as raw until tuple parsing is implemented")
    }

    let nullableData = try JSONSerialization.data(withJSONObject: [
        "type": ["string", "null"],
        "description": "Optional string"
    ])
    let nullable = try JSONDecoder().decode(JSONSchema.self, from: nullableData)
    #expect(nullable == .union([.string, .null], description: "Optional string"))

    let anyOfData = try JSONSerialization.data(withJSONObject: [
        "anyOf": [
            ["type": "string"],
            ["type": "number"]
        ],
        "description": "String or number"
    ])
    let anyOf = try JSONDecoder().decode(JSONSchema.self, from: anyOfData)
    #expect(anyOf == .anyOf([.string(), .number()], description: "String or number"))
}
