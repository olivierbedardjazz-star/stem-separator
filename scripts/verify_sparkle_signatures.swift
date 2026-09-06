import Foundation
import CryptoKit

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw NSError(domain: "SparkleVerification", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
}
do {
    let args = CommandLine.arguments
    try require(args.count == 5, "Usage: verifier appcast.xml archive.zip Info.plist expectedURL")
    let feed = try Data(contentsOf: URL(fileURLWithPath: args[1]))
    let archive = try Data(contentsOf: URL(fileURLWithPath: args[2]), options: .mappedIfSafe)
    let infoData = try Data(contentsOf: URL(fileURLWithPath: args[3]))
    let info = try PropertyListSerialization.propertyList(from: infoData, format: nil) as! [String: Any]
    let key = try Curve25519.Signing.PublicKey(rawRepresentation: Data(base64Encoded: info["SUPublicEDKey"] as! String)!)
    let marker = Data("<!-- sparkle-signatures:\n".utf8)
    guard let range = feed.range(of: marker, options: .backwards), let block = String(data: feed[range.upperBound...], encoding: .utf8) else { throw NSError(domain: "MissingFeedSignature", code: 1) }
    var fields = [String: String]()
    for line in block.components(separatedBy: "\n") {
        let pair = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        if pair.count == 2 { fields[pair[0]] = pair[1] }
    }
    let signedData = feed[..<range.lowerBound]
    try require(Int(fields["length"] ?? "") == signedData.count, "Feed signed length mismatch")
    guard let signature = Data(base64Encoded: fields["edSignature"] ?? "") else { throw NSError(domain: "InvalidFeedSignature", code: 1) }
    try require(key.isValidSignature(signature, for: signedData), "Feed signature invalid")
    let xml = try XMLDocument(data: feed)
    let enclosures = try xml.nodes(forXPath: "//enclosure")
    try require(enclosures.count == 1, "Expected one enclosure")
    let enclosure = enclosures[0] as! XMLElement
    let attributes = Dictionary(uniqueKeysWithValues: (enclosure.attributes ?? []).map { ($0.name!, $0.stringValue!) })
    try require(attributes["url"] == args[4], "Unexpected archive URL")
    try require(Int(attributes["length"] ?? "") == archive.count, "Archive length mismatch")
    guard let archiveSignature = Data(base64Encoded: attributes["sparkle:edSignature"] ?? "") else { throw NSError(domain: "MissingArchiveSignature", code: 1) }
    try require(key.isValidSignature(archiveSignature, for: archive), "Archive signature invalid")
    let item = enclosure.parent as! XMLElement
    func value(_ name: String) -> String? { item.elements(forName: name).first?.stringValue }
    try require(value("sparkle:version") == info["CFBundleVersion"] as? String, "Build mismatch")
    try require(value("sparkle:shortVersionString") == info["CFBundleShortVersionString"] as? String, "Version mismatch")
    try require(value("sparkle:minimumSystemVersion") == info["LSMinimumSystemVersion"] as? String, "Minimum OS mismatch")
    print("PASS: feed and archive Ed25519 signatures, URL, length, version and minimum OS verified with bundled public key")
} catch {
    fputs("Verification failed: \(error)\n", stderr)
    exit(1)
}
