import ComposableArchitecture
import Foundation
import RegexBuilder
import SwiftUI

public protocol TootSnifferProtocol: Sendable {
    func sniff(url: URL) async throws -> Toot
}

public final class TootSniffer: TootSnifferProtocol {

    public init() {
    }

    public func sniff(url: URL) async throws -> Toot {
        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"
        let (_, rawResponse) = try await URLSession.shared.data(for: headRequest)
        let response = rawResponse as! HTTPURLResponse
        guard response.allHeaderFields["Server"] as? String == "Mastodon" else { throw NotAMastadonPost() }
        let parser = try await TootParser(url: url)
//        print(String(data: try JSONEncoder().encode(try parser.toot), encoding: .utf8)!)
        return try parser.toot
    }

}

private final class TootParser: NSObject, XMLParserDelegate {

    var parsingToot: Toot = .init(
        source: URL(string: "https://example.com")!,
        date: .distantPast,
        tooter: Tooter(
            image: URL(string: "https://example.com")!,
            name: "",
            username: ""
        ),
        body: "",
        images: []
    )

    var error: (any Error)?

    init(url: URL) async throws {
        super.init()
        parsingToot.source = url
        let (data, _) = try await URLSession.shared.data(from: url)
        // Is it ideal to use an XMLParser for this?
        // No, but it's not worth pulling in a dep for it, and we know mastodon pages will be
        // reasonably well-formed. ¯\_(ツ)_/¯
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        do {
            guard elementName == "meta" else { return }
            guard let content = attributeDict["content"] else { return }
            switch attributeDict["property"] {
            case "og:title":
                let regex = Regex {
                    Capture {
                        OneOrMore {
                            .any
                        }
                    }
                    " "
                    "("
                    Capture {
                        OneOrMore {
                            .any
                        }
                    }
                    ")"
                }
                guard let matches = try regex.firstMatch(in: content) else { throw UnableToParseAuthorName() }
                parsingToot.tooter.name = String(matches.output.1)
                parsingToot.tooter.username = String(matches.output.2)
            case "og:published_time":
                guard let date = ISO8601DateFormatter().date(from: content) else { throw UnableToParseDate() }
                parsingToot.date = date
            case "og:description":
                parsingToot.body = content
            case "og:image":
                guard let url = URL(string: content) else { throw UnableToParseAuthorImage() }
                parsingToot.tooter.image = url
            default:
                return
            }
        } catch {
            self.error = error
            parser.abortParsing()
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "head" {
            parser.abortParsing()
        }
    }

    var toot: Toot {
        get throws {
            if let error {
                throw error
            }
            return parsingToot
        }
    }

}

public final class UnimplementedTootSniffer: TootSnifferProtocol {

    public init() {
    }

    public func sniff(url: URL) async throws -> Toot {
        fatalError("Unimplemented")
    }

}

struct NotAMastadonPost: Error {
}

struct UnableToParseAuthorName: Error {
}

struct UnableToParseAuthorImage: Error {
}

struct UnableToParseDate: Error {
}
