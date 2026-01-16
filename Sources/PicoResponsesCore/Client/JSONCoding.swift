import Foundation

public enum ResponsesJSONCoding {
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970))
        }
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let intSeconds = try? container.decode(Int64.self) {
                return Date(timeIntervalSince1970: TimeInterval(intSeconds))
            }
            let doubleSeconds = try container.decode(Double.self)
            return Date(timeIntervalSince1970: doubleSeconds)
        }
        return decoder
    }
}
