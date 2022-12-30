import SwiftUI

public struct Toot: Equatable, Sendable, Codable {

    public var url: URL
    public var createdAt: Date
    public var content: String
    public var account: Tooter
    public var mediaAttachments: [MediaAttachment]

    public var allImages: [MediaAttachment] {
        [MediaAttachment(id: "", url: account.avatar, meta: MediaAttachmentMeta(original: MediaAttachmentSize(width: 100, height: 100)), blurhash: nil)] + mediaAttachments
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
    public let blurhash: String?
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

public struct URLKey: Hashable, Sendable {

    public enum Kind: Hashable, Sendable {
        case blurhash
        case remote
    }

    let url: URL
    let kind: Kind

    public init(_ url: URL, _ kind: Kind) {
        self.url = url
        self.kind = kind
    }
}

public extension Toot {

    static let placeholder = Toot(
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. Hello world. Hello world. Hello world. Hello world.",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments: []
    )

    static let placeholderWithHTML = Toot(
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. <a href=\"https://example.com\">Test</a>",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments: []
    )

    static let placeholderWithAttachments = Toot(
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. Hello world. Hello world. Hello world. Hello world.",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments:
            (0..<4).map {
                MediaAttachment(
                    id: $0.formatted(),
                    url: URL(string: "https://example.com/\($0)")!,
                    meta: MediaAttachmentMeta(original: MediaAttachmentSize(width: 1, height: 1)),
                    blurhash: nil
                )
            }
    )

}
