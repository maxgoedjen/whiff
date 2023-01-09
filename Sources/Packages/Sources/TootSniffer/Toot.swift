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
    /// Any card attached to the post.
    public var card: Card?

    /// All media attached to the post, including the avatar of the poster (wrapped in a MediaAttachment struct to simplify loading).
    public var allImages: [MediaAttachment] {
        var attachments = [MediaAttachment(url: account.avatar)] + mediaAttachments
        if let card, let image = card.image {
            attachments.append(MediaAttachment(
                id: card.url.absoluteString,
                type: .image,
                url: image,
                meta: MediaAttachment.Meta(original: .init(width: card.width, height: card.height)),
                blurhash: card.blurhash
            ))
        }
        return attachments
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
    /// The type of media.
    public let type: MediaType
    /// The URL to load the media from.
    /// > Warning: May be a video, gif, etc. Use displayURL to load an image.
    private let url: URL
    /// The URL for a thumbnail for the media.
    public let previewUrl: URL
    /// Metadata associated with the media (resolution, etc).
    public let meta: Meta
    /// A blurhash to use while the media is loading.
    public let blurhash: String?
    /// CGSize wrapper for the size attributes.
    public var size: CGSize {
        CGSize(width: meta.original.width, height: meta.original.height)
    }

    /// Image to display. URL for images, previewURL for videos and other media types.
    public var displayURL: URL {
        if case .image = type {
            return url
        }
        return previewUrl
    }

    /// Initializes a MediaAttachment.
    /// - Parameters:
    ///   - id: A unique ID to use for the attachment. Falls back to using the URL if none is specified.
    ///   - type: The type of media.
    ///   - url: The URL to load the media from.
    ///   - previewURL: The URL for a preview thumbnail for the media.
    ///   - meta: Metadata associated with the media (resolution, etc).
    ///   - blurhash: A blurhash to use while the media is loading.
    fileprivate init(id: String? = nil, type: MediaType = .image, url: URL, previewUrl: URL? = nil, meta: Meta = Meta(original: Meta.Size(width: 100, height: 100)),
                     blurhash: String? = nil)
    {
        self.id = id ?? url.absoluteString
        self.type = type
        self.url = url
        self.previewUrl = previewUrl ?? url
        self.meta = meta
        self.blurhash = blurhash
    }

}

public extension MediaAttachment {

    /// Enum desecribing what kind of media an attachment is.
    enum MediaType: String, Codable, Sendable {
        case image
        case gifv
        case video
        case audio
        case unknown
    }

}

public extension MediaAttachment {

    /// Model for metadata associated with media.
    struct Meta: Equatable, Sendable, Codable {

        /// The original size of the media.
        public let original: Size

    }

}

public extension MediaAttachment.Meta {

    /// The size of the media.
    struct Size: Equatable, Sendable, Codable {

        /// The width, in pixels, of the media.
        public let width: Int
        /// The height, in pixels, of the media.
        public let height: Int

    }

}

/// Model object for a "card" – usually a link to a website with a thumb/title.
public struct Card: Equatable, Sendable, Codable {

    /// Title for the card.
    public let title: String
    /// Description for the card.
    public let description: String?
    /// The URL the card links to.
    public let url: URL
    /// A URL for a preview image for the card, if one exists.
    public let image: URL?
    /// A blurhash for the image.
    public let blurhash: String?
    /// The width, in pixels, of the image.
    public let width: Int
    /// The height, in pixels, of the image.
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
    public let url: URL
    /// The kind of resource specified by the key.
    public let kind: Kind

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
                meta: MediaAttachment.Meta(original: MediaAttachment.Meta.Size(width: 100, height: 100)),
                blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
            )
        }
    )

    static let placeholderWithVideoAttachment = Toot(
        id: "root",
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. Hello world. Hello world. Hello world. Hello world.",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments: [
            MediaAttachment(
                id: "video",
                type: .video,
                url: URL(string: "https://example.com/video.mp4")!,
                previewUrl: URL(string: "https://example.com/video_thumb")!,
                meta: MediaAttachment.Meta(original: MediaAttachment.Meta.Size(width: 100, height: 100)),
                blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
            ),
        ]
    )

    static let placeholderWithCard = Toot(
        id: "root",
        url: URL(string: "https://example.com")!,
        createdAt: .distantPast,
        content: "Hello world. Hello world. Hello world. Hello world. Hello world.",
        account: Tooter(username: "@maxgoedjen", displayName: "Max Goedjen", avatar: URL(string: "https://example.com/avatar")!),
        mediaAttachments: [],
        card: Card(
            title: "Some Card",
            description: "Some Description",
            url: URL(string: "https://example.com")!,
            image: URL(string: "https://example.com/cardimage")!,
            blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj",
            width: 100,
            height: 100
        )
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
                    meta: MediaAttachment.Meta(original: MediaAttachment.Meta.Size(width: 100, height: 100)),
                    blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"
                ),
            ]
        )
    }

}
