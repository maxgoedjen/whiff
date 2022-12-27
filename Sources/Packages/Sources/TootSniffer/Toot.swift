import SwiftUI

public struct Toot: Equatable, Sendable, Codable {

    public var source: URL
    public var date: Date
    public var tooter: Tooter
    public var body: String
    public var images: [URL]

}

public struct Tooter: Equatable, Sendable, Codable {

    public var image: URL
    public var name: String
    public var username: String

}
