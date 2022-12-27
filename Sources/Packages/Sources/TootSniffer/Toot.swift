import SwiftUI


public struct Toot: Equatable, Sendable, Codable {

    public var createdAt: Date
    public var content: String
    public var account: Tooter

}

public struct Tooter: Equatable, Sendable, Codable {

    public var username: String
    public var displayName: String
    public var avatar: URL

}

