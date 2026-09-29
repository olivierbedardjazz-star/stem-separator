import Foundation

enum AppLegalDocumentID: String, CaseIterable, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }
}

struct AppLegalDocument: Identifiable {
    let id: AppLegalDocumentID
    let label: String
    let title: String
    let body: String
}

enum AppLegalDocumentCatalog {
    #if APP_STORE
    private static let termsResource = "APP_STORE_TERMS"
    private static let privacyResource = "APP_STORE_PRIVACY"
    #else
    private static let termsResource = "TEMPLATE_APP_TERMS"
    private static let privacyResource = "TEMPLATE_APP_PRIVACY"
    #endif
    static let documents: [AppLegalDocument] = [
        AppLegalDocument(
            id: .terms,
            label: "Terms",
            title: "Terms of Use",
            body: loadMarkdown(named: termsResource)
        ),
        AppLegalDocument(
            id: .privacy,
            label: "Privacy",
            title: "Privacy Policy",
            body: loadMarkdown(named: privacyResource)
        )
    ]

    static func document(for id: AppLegalDocumentID) -> AppLegalDocument? {
        documents.first(where: { $0.id == id })
    }

    private static func loadMarkdown(named resourceName: String) -> String {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "md") else {
            return "This document is temporarily unavailable in the app bundle."
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            return "This document could not be loaded from the app bundle."
        }
    }
}
