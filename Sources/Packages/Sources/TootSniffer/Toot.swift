import SwiftUI

public struct Toot: Equatable, Sendable, Codable {

    public var url: URL
    public var createdAt: Date
    public var content: String
    public var account: Tooter
    public var mediaAttachments: [MediaAttachment]

    public var allImages: [URL] {
        [account.avatar] + mediaAttachments.map(\.url)
    }

}

public struct Tooter: Equatable, Sendable, Codable {

    public var username: String
    public var displayName: String
    public var avatar: URL

}

public struct MediaAttachment: Equatable, Sendable, Codable, Identifiable {

    public let id: String
    public let url: URL
    public let meta: MediaAttachmentMeta
    public let blurhash: String
    public var size: CGSize {
        CGSize(width: meta.original.width, height: meta.original.height)
    }

}

public struct MediaAttachmentMeta: Equatable, Sendable, Codable {

    public let original: MediaAttachmentSize

}

public struct MediaAttachmentSize: Equatable, Sendable, Codable {

    public let width: Int
    public let height: Int

}

public extension Toot {

    static let placeholder = Toot(url: URL(string: "https://example.com")!, createdAt: .distantPast, content: "Hello world. Hello world. Hello world. Hello world. Hello world.", account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com")!), mediaAttachments: [])

}
