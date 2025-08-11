import Foundation
import UIKit

struct MarkdownParser {
    static func parse(_ text: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attr.length)
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        attr.addAttribute(.font, value: bodyFont, range: fullRange)

        applyHeading(pattern: "^###\\s+(.+)$", font: UIFont.preferredFont(forTextStyle: .title3), attr: attr)
        applyHeading(pattern: "^##\\s+(.+)$", font: UIFont.preferredFont(forTextStyle: .title2), attr: attr)
        applyHeading(pattern: "^#\\s+(.+)$", font: UIFont.preferredFont(forTextStyle: .title1), attr: attr)

        applyList(pattern: "^(\\d+)\\.\\s+(.+)$", ordered: true, attr: attr)
        applyList(pattern: "^[-\\*]\\s+(.+)$", ordered: false, attr: attr)

        applyBlockquote(pattern: "^>\\s+(.+)$", attr: attr)

        applyRegex(pattern: "\\*\\*(.+?)\\*\\*", markerLength: 2, attributes: [.font: UIFont.boldSystemFont(ofSize: bodyFont.pointSize)], attr: attr)
        applyRegex(pattern: "\\*(.+?)\\*", markerLength: 1, attributes: [.font: UIFont.italicSystemFont(ofSize: bodyFont.pointSize)], attr: attr)
        applyRegex(pattern: "__([^_]+?)__", markerLength: 2, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue], attr: attr)
        applyRegex(pattern: "~~([^~]+?)~~", markerLength: 2, attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue], attr: attr)
        applyRegex(pattern: "`([^`]+?)`", markerLength: 1, attributes: [
            .font: UIFont.monospacedSystemFont(ofSize: bodyFont.pointSize, weight: .regular),
            .backgroundColor: UIColor.systemGray5
        ], attr: attr)

        applyHorizontalRule(pattern: "^---+$", attr: attr)

        return attr
    }

    private static func applyRegex(pattern: String, markerLength: Int, attributes: [NSAttributedString.Key: Any], attr: NSMutableAttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let matches = regex.matches(in: attr.string, options: [], range: NSRange(location: 0, length: attr.length)).reversed()
        for match in matches {
            attr.addAttributes(attributes, range: match.range(at: 1))
            attr.deleteCharacters(in: NSRange(location: match.range.location + match.range.length - markerLength, length: markerLength))
            attr.deleteCharacters(in: NSRange(location: match.range.location, length: markerLength))
        }
    }

    private static func applyHeading(pattern: String, font: UIFont, attr: NSMutableAttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let matches = regex.matches(in: attr.string, options: [], range: NSRange(location: 0, length: attr.length)).reversed()
        for match in matches {
            attr.addAttribute(.font, value: font, range: match.range(at: 1))
            attr.deleteCharacters(in: NSRange(location: match.range.location, length: match.range.length - match.range(at: 1).length))
        }
    }

    private static func applyList(pattern: String, ordered: Bool, attr: NSMutableAttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let matches = regex.matches(in: attr.string, options: [], range: NSRange(location: 0, length: attr.length)).reversed()
        for match in matches {
            let paragraph = NSMutableParagraphStyle()
            paragraph.headIndent = 20
            let range = match.range(at: 0)
            attr.addAttribute(.paragraphStyle, value: paragraph, range: range)
            if !ordered {
                attr.replaceCharacters(in: match.range(at: 0), with: "• " + (attr.string as NSString).substring(with: match.range(at: 1)))
            }
        }
    }

    private static func applyBlockquote(pattern: String, attr: NSMutableAttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let matches = regex.matches(in: attr.string, options: [], range: NSRange(location: 0, length: attr.length)).reversed()
        for match in matches {
            let range = match.range(at: 1)
            attr.addAttributes([
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
            ], range: range)
            attr.deleteCharacters(in: NSRange(location: match.range.location, length: 2))
        }
    }

    private static func applyHorizontalRule(pattern: String, attr: NSMutableAttributedString) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let matches = regex.matches(in: attr.string, options: [], range: NSRange(location: 0, length: attr.length)).reversed()
        for match in matches {
            let line = String(repeating: "\u{2015}", count: 20)
            attr.replaceCharacters(in: match.range, with: "\n" + line + "\n")
        }
    }
}
