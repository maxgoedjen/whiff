import SwiftUI

/// Model for a Mastodon post.
public struct Toot: Equatable, Sendable, Codable, Identifiable {

    /// ID for the post.
    public var id: String
    /// If the post is a reply to another post, the ID for that post.
    private var inReplyTo: String?
    /// The public URL for the post.
    public var url: URL
    /// The date the post was originally created at.
    public var createdAt: Date
    /// The raw content for the post.
    /// > Warning:  Usually contains HTML, so be cautious about displaying directly.
    public var content: String
    /// The account that made the post.
    public var account: Tooter
    /// Any media attached to the post.
    public var mediaAttachments: [MediaAttachment]

    /// All media attached to the post, including the avatar of the poster (wrapped in a MediaAttachment struct to simplify loading).
    public var allImages: [MediaAttachment] {
        mediaAttachments +
            [MediaAttachment(url: account.avatar)]
    }

    /// Convenience accessor for determining if the post is a reply.
    public var reply: Bool? {
        inReplyTo != nil
    }

}

/// Model for a Mastodon user.
public struct Tooter: Equatable, Sendable, Codable {

    /// The username for the poster.
    public var username: String
    /// The display name for the poster.
    /// > Warning: Often contains emoji such as `:wave:`, so be cautious about displaying this directly.
    public var displayName: String
    /// The URL for the user's icon.
    public var avatar: URL

}

/// Model for a piece of media (image, video, etc) attached to a post.
public struct MediaAttachment: Equatable, Sendable, Codable, Identifiable {

    /// The ID for the media.
    public let id: String
    /// The URL to load the media from.
    public let url: URL
    /// Metadata associated with the media (resolution, etc).
    public let meta: MediaAttachmentMeta
    /// A blurhash to use while the media is loading.
    public let blurhash: String?
    /// CGSize wrapper for the size attributes.
    public var size: CGSize {
        CGSize(width: meta.original.width, height: meta.original.height)
    }

    /// Initializes a MediaAttachment.
    /// - Parameters:
    ///   - id: A unique ID to use for the attachment. Falls back to using the URL if none is specified.
    ///   - url: The URL to load the media from.
    ///   - meta: Metadata associated with the media (resolution, etc).
    ///   - blurhash: A blurhash to use while the media is loading.
    fileprivate init(id: String? = nil, url: URL, meta: MediaAttachmentMeta = MediaAttachmentMeta(original: MediaAttachmentSize(width: 100, height: 100)),
                     blurhash: String? = nil)
    {
        self.id = id ?? url.absoluteString
        self.url = url
        self.meta = meta
        self.blurhash = blurhash
    }

}

/// Model for metadata associated with media.
public struct MediaAttachmentMeta: Equatable, Sendable, Codable {

    /// The original size of the media.
    public let original: MediaAttachmentSize

}

/// The size of the media.
public struct MediaAttachmentSize: Equatable, Sendable, Codable {

    /// The width, in pixels, of the media.
    public let width: Int
    /// The height, in pixels, of the media.
    public let height: Int

}

/// Model object for a post's "context" – any posts that the post is in reply to, and replies to it.
public struct TootContext: Equatable, Sendable, Codable {

    /// Posts that this post is replying to.
    public var ancestors: [Toot]
    /// Posts that are replies to this post.
    public var descendants: [Toot]

    /// Initializes a context object.
    /// - Parameters:
    ///   - ancestors: Posts that this post is replying to.
    ///   - descendants: Posts that are replies to this post.
    init(ancestors: [Toot] = [], descendants: [Toot] = []) {
        self.ancestors = ancestors
        self.descendants = descendants
    }

    /// All posts in the context object.
    public var all: [Toot] {
        ancestors + descendants
    }

    /// All of the images contained within all the posts in the context.
    public var allImages: [MediaAttachment] {
        all.flatMap(\.allImages)
    }

}

/// Wrapper for dictionary lookup of a given URL + type combination.
public struct URLKey: Hashable, Sendable {

    /// The type of resource.
    public enum Kind: Hashable, Sendable {
        case blurhash
        case remote
    }

    /// The URL of the media.
    let url: URL
    /// The kind of resource specified by the key.
    let kind: Kind

    /// Initializes a URLKey.
    /// - Parameters:
    ///   - url: The URL of the media.
    ///   - kind:  The kind of resource specified by the key.
    public init(_ url: URL, _ kind: Kind) {
        self.url = url
        self.kind = kind
    }

    /// Initializes a URLKey form a string.
    /// - Parameters:
    ///   - string: The string representation of the URL of the media.
    ///   - kind:  The kind of resource specified by the key.
    init(_ string: String, _ kind: Kind = .remote) {
        url = URL(string: string)!
        self.kind = kind
    }
}

public extension Toot {

    static let placeholder = Toot(
        id: "root",
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. Hello world. Hello world. Hello world. Hello world.",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments: []
    )

    static let placeholderWithHTML = Toot(
        id: "root",
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. <a href=\"https://example.com\">Test</a>",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments: []
    )

    static let placeholderWithAttachments = Toot(
        id: "root",
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. Hello world. Hello world. Hello world. Hello world.",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments:
        (0..<4).map {
            MediaAttachment(
                id: $0.formatted(),
                url: URL(string: "https://example.com/\($0)")!,
                meta: MediaAttachmentMeta(original: MediaAttachmentSize(width: 100, height: 100)),
                blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
            )
        }
    )

    static func placeholderWithAttachmentName(_ attachmentName: String) -> Toot {
        Toot(
            id: attachmentName,
            url: URL(string: "https://example.com")!,
            createdAt: .distantPast,
            content: "Hello world.",
            account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/\(attachmentName)_avatar")!),
            mediaAttachments: [
                MediaAttachment(
                    id: attachmentName,
                    url: URL(string: "https://example.com/attachments/\(attachmentName)")!,
                    meta: MediaAttachmentMeta(original: MediaAttachmentSize(width: 100, height: 100)),
                    blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
                ),
            ]
        )
    }

}
