import Foundation
import SwiftUI
import TootSniffer
@testable import WhiffFeatures

struct TootViewPreview: PreviewProvider {

    static var previews: some View {
        VStack {
            TootView(toot: .example.toot, attributedContent: Toot.example.attributedString, images: [:], settings: .init())
        }
    }

}

extension Toot {

    static var example = example(from: """
    eyJhY2NvdW50Ijp7ImF2YXRhciI6Imh0dHBzOlwvXC9tZWRpYS5tc3Rkbi5zb2NpYWxcL2FjY291bnRzXC9hdmF0YXJzXC8xMDlcLzM1NFwvOTQzXC81NjNcLzY0OFwvNzU2XC9vcmlnaW5hbFwvOTA3ZTRkMWMwMjI5ZTEyYi5wbmciLCJ1c2VybmFtZSI6IkBsb2xlbm51aUBtc3Rkbi5zb2NpYWwiLCJkaXNwbGF5TmFtZSI6IkFteSJ9LCJjb250ZW50IjoiPHA+SSBmZWVsIGxpa2UgdHdpdHRlciB3YXMgYSBiYXIgd2hlcmUgZm9yIHNvbWUgcmVhc29uIGV2ZXJ5b25lIGhhZCBhIGtuaWZlIGFuZCBub3cgSeKAmW0gaGVyZSBsb29raW5nIGFyb3VuZCBsaWtlIOKAnG5vbmUgb2YgeW91IGhhdmUgS05JVkVTLCByaWdodD8/4oCdIGFuZCB5b3XigJlyZSBhbGwgbGlrZSDigJx3aHkgd291bGQgSSBoYXZlIGEga25pZmUsIGFyZSB5b3Ugb2vigJ08XC9wPiIsIm1lZGlhQXR0YWNobWVudHMiOltdLCJ1cmwiOiJodHRwczpcL1wvbXN0ZG4uc29jaWFsXC9AbG9sZW5udWlcLzEwOTU0Nzg0MjQ4MDQ5NjA5NCIsImNyZWF0ZWRBdCI6NjkzMjYwMjIwLjY4MzAwMDA5fQ==
    """, attributedStringData: "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwTFx8lKVUkbnVsbNMNDg8QERJYTlNTdHJpbmdWJGNsYXNzXE5TQXR0cmlidXRlc4ACgAaABNIOFBUWWU5TLnN0cmluZ4ADbxDMAEkAIABmAGUAZQBsACAAbABpAGsAZQAgAHQAdwBpAHQAdABlAHIAIAB3AGEAcwAgAGEAIABiAGEAcgAgAHcAaABlAHIAZQAgAGYAbwByACAAcwBvAG0AZQAgAHIAZQBhAHMAbwBuACAAZQB2AGUAcgB5AG8AbgBlACAAaABhAGQAIABhACAAawBuAGkAZgBlACAAYQBuAGQAIABuAG8AdwAgAEkgGQBtACAAaABlAHIAZQAgAGwAbwBvAGsAaQBuAGcAIABhAHIAbwB1AG4AZAAgAGwAaQBrAGUAICAcAG4AbwBuAGUAIABvAGYAIAB5AG8AdQAgAGgAYQB2AGUAIABLAE4ASQBWAEUAUwAsACAAcgBpAGcAaAB0AD8APyAdACAAYQBuAGQAIAB5AG8AdSAZAHIAZQAgAGEAbABsACAAbABpAGsAZQAgIBwAdwBoAHkAIAB3AG8AdQBsAGQAIABJACAAaABhAHYAZQAgAGEAIABrAG4AaQBmAGUALAAgAGEAcgBlACAAeQBvAHUAIABvAGsgHQAK0hgZGhtaJGNsYXNzbmFtZVgkY2xhc3Nlc18QD05TTXV0YWJsZVN0cmluZ6McHR5fEA9OU011dGFibGVTdHJpbmdYTlNTdHJpbmdYTlNPYmplY3TTICEOIiMkV05TLmtleXNaTlMub2JqZWN0c6CggAXSGBkmJ1xOU0RpY3Rpb25hcnmiKB5cTlNEaWN0aW9uYXJ50hgZKitfEBlOU011dGFibGVBdHRyaWJ1dGVkU3RyaW5noywtHl8QGU5TTXV0YWJsZUF0dHJpYnV0ZWRTdHJpbmdfEBJOU0F0dHJpYnV0ZWRTdHJpbmcACAARABoAJAApADIANwBJAEwAUQBTAFsAYQBoAHEAeACFAIcAiQCLAJAAmgCcAjcCPAJHAlACYgJmAngCgQKKApECmQKkAqUCpgKoAq0CugK9AsoCzwLrAu8DCwAAAAAAAAIBAAAAAAAAAC4AAAAAAAAAAAAAAAAAAAMg")

    private static func example(from tootData: String, attributedStringData: String? = nil) -> (toot: Toot, attributedString: AttributedString?) {
        let toot = try! JSONDecoder()
            .decode(Toot.self, from: Data(base64Encoded: tootData)!)
        let attributedString: AttributedString?
        if let attributedStringData {
            let ns = try! NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: Data(base64Encoded: attributedStringData)!)!
            attributedString = AttributedString(ns)
        } else {
            attributedString = nil
        }
        return (toot, attributedString)
    }
}
