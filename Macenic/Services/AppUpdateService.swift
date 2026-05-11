import Foundation
import AppKit
import SwiftUI

struct GitHubRelease: Decodable {
    let tagName: String
    let body: String?
    let htmlURL: String
    let draft: Bool
    let prerelease: Bool
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case htmlURL = "html_url"
        case draft
        case prerelease
        case assets
    }
}

struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

@MainActor
@Observable
final class AppUpdateService {
    var isChecking = false
    var isUpdateAvailable = false
    var latestVersion = ""
    var releaseNotes = ""
    var downloadURL = ""

    private let endpoint = "https://api.github.com/repos/0xRahad/Macenic/releases/latest"

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        guard let url = URL(string: endpoint) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Macenic", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            guard !release.draft, !release.prerelease else { return }
            let latest = release.tagName.replacingOccurrences(of: "v", with: "")
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

            guard latest.compare(current, options: .numeric) == .orderedDescending else { return }

            let dmgAsset = release.assets.first { asset in
                asset.name.lowercased().hasSuffix(".dmg")
            }
            let resolvedURL = dmgAsset?.browserDownloadURL ?? release.htmlURL

            latestVersion = latest
            releaseNotes = release.body?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            downloadURL = resolvedURL
            isUpdateAvailable = true
        } catch {}
    }

    func dismissUpdate() {
        isUpdateAvailable = false
    }

    func openDownload() {
        guard let url = URL(string: downloadURL) else { return }
        NSWorkspace.shared.open(url)
        isUpdateAvailable = false
    }
}
