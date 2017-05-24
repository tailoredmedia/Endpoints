import Foundation
import Endpoints

// MARK: -
// MARK: Client

public class BinClient: AnyClient {
    init() {
        super.init(baseURL: URL(string: "https://httpbin.org")!)
    }
    
    override public func validate(result: URLSessionTaskResult) throws {
        do {
            try result.httpResponse?.validateStatusCode()
        } catch StatusCodeError.unacceptable(let code, let reason) {
            let message = result.httpResponse?.allHeaderFields["X-Error-Message"] as? String

            throw StatusCodeError.unacceptable(code: code, reason: message ?? reason)
        }
    }
}

// MARK: 
// MARK: Requests

protocol BinCall: Call {}

public extension BinClient {
    public struct GetOutput: BinCall {
        public typealias ResponseType = OutputValue
        
        public var value: String
        
        public var request: URLRequestEncodable {
            return Request(.get, "get", query: [ "value": value ])
        }
    }
    
    static func getOutput(value: String) -> AnyCall<OutputValue> {
        return AnyCall<OutputValue>(Request(.get, "get", query: [ "value": value]))
    }
}

// MARK: -
// MARK: Responses

public struct OutputValue: ResponseDecodable {
    public var value: String
    
    public static func responseDecoder() -> Decoder {
        return decodeOutputValue
    }

    public static func decodeOutputValue(response: HTTPURLResponse, data: Data) throws -> OutputValue {
        let dict = try [String: Any].decodeJSONDictionary(response: response, data: data)
        guard let args = dict["args"] as? [String: String], let value = args["value"] else {
            throw DecodingError.invalidData(description: "value not found")
        }
        return OutputValue(value: value)
    }
}
