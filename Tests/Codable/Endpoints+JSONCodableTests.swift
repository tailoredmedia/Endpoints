import XCTest
@testable import Endpoints

class EndpointsJSONCodableTests: XCTestCase {

    func testDecodingArray() throws {
        let decoded = try JSONParser<[City]>().parse(data: FileUtil.load(named: "CityArray"), encoding: .utf8)

        validateCityArray(decoded)
    }

    // this test case is relevant, as there is a difference between using [City].parse
    // and parse on the same type, but with the heavy generics use of Endpoints
    func testDecodingArrayViaResponse() throws {
        let client = AnyClient(baseURL: URL(string: "www.tailored-apps.com")!)
        let call = CitiesCall()
        let result = URLSessionTaskResult(response:
            FakeHTTPURLResponse(status: 200, header: nil),
            data: try FileUtil.load(named: "CityArray"),
            error: nil)

        let cities = try client.parse(sessionTaskResult: result, for: call)

        validateCityArray(cities)
    }

    func testEncoding() throws {
        let city = City(name: "test1234", postalCode: 1234)
        let jsonData: Data = try city.toJSON()

        let decoded = try City.jsonDecoder.decode(City.self, from: jsonData)

        XCTAssertEqual(city, decoded, "Encoding -> Decoding should result in the same values")
    }

    func testUsingCustomDecoder() throws {
        do {
            _ = try DateCrashParser<Person>().parse(data: FileUtil.load(named: "Person"), encoding: .utf8)
            XCTFail("parsing should not succeed")
        } catch ExpectedError.decoderWasReplaced {
            // expected
        }
    }

    func testUsingCustomDecoderAndAnyClient() throws {
        let client = AnyClient(baseURL: URL(string: "www.tailored-apps.com")!)
        let call = PersonCall()
        let result = URLSessionTaskResult(response:
            FakeHTTPURLResponse(status: 200, header: nil),
                                          data: try FileUtil.load(named: "Person"),
                                          error: nil
        )

        do {
            _ = try client.parse(sessionTaskResult: result, for: call)
            XCTFail("parsing should not succeed")
        } catch ExpectedError.decoderWasReplaced {
            // expected
        }
    }

    private func validateCityArray(_ cities: [City]) {
        XCTAssertEqual(cities.count, 7, "there should be exactly 7 elements in the array")
        XCTAssertEqual(cities.first, City(name: "Biehle", postalCode: 9753), "the first element should have the right name / postalCode")
    }

    fileprivate static func getDateCrashDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            throw ExpectedError.decoderWasReplaced
        })

        return decoder
    }

    private struct CitiesCall: Call {
        typealias Parser = JSONParser<[City]>

        var request: URLRequestEncodable {
            return Request(.get)
        }
    }

    private struct PersonsCall: Call {
        typealias Parser = DateCrashParser<[Person]>

        var request: URLRequestEncodable {
            return Request(.get)
        }
    }

    private struct PersonCall: Call {
        typealias Parser = DateCrashParser<Person>

        var request: URLRequestEncodable {
            return Request(.get)
        }
    }

    private struct City: Codable, Equatable {
        static var jsonDecoder: JSONDecoder {
            return JSONDecoder()
        }

        let name: String
        let postalCode: Int
    }

    fileprivate struct Person: Decodable {
        let name: String
        let birthday: Date
    }

    private enum ExpectedError: LocalizedError {
        case decoderWasReplaced
    }
}

extension EndpointsJSONCodableTests.Person {
    public static var jsonDecoder: JSONDecoder {
        return EndpointsJSONCodableTests.getDateCrashDecoder()
    }
}

class DateCrashParser<T: Decodable>: JSONParser<T> {
    override var jsonDecoder: JSONDecoder {
        return EndpointsJSONCodableTests.getDateCrashDecoder()
    }
}
