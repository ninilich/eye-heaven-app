import AppKit
import Foundation
import SwiftData

struct CatalogImage: Codable, Identifiable {
    let id: String
    let filename: String
    let url: String
    let source: String?
    let author: String?
}

private struct Catalog: Codable {
    let version: Int
    let images: [CatalogImage]
}

@Observable
@MainActor
final class CatalogService {
    static let shared = CatalogService()

    private(set) var images: [CatalogImage] = []
    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var downloadStatusText = ""
    private(set) var downloadError: String?

    var needsDownload: Bool {
        images.isEmpty || images.contains { localURL(for: $0) == nil }
    }

    private let catalogURL = URL(string: "https://github.com/ninilich/eye-heaven-app/releases/latest/download/catalog.json")!
    private let settings = AppSettings.shared

    private init() {}

    // MARK: - Public

    func start() {
        loadCachedCatalog()
        checkForUpdateIfNeeded()
        scheduleBackgroundUpdateTimer()
    }

    func fetchAndDownload() async {
        guard !isDownloading else { return }
        isDownloading = true
        downloadProgress = 0
        downloadError = nil

        do {
            let catalog = try await downloadCatalog()
            images = catalog.images
            saveCatalogToCache(catalog)
            try await downloadMissingImages(catalog.images)
            let ctx = ModelContext(DataStack.container)
            pruneIfNeeded(context: ctx)
            settings.stereogramsLastChecked = .now
        } catch {
            downloadError = error.localizedDescription
        }

        isDownloading = false
        downloadProgress = 1
        downloadStatusText = ""
    }

    func localURL(for image: CatalogImage) -> URL? {
        let url = cacheDir.appendingPathComponent(image.filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Private: cache directory

    private var cacheDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("EyeHeaven/stereograms", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var cachedCatalogURL: URL {
        cacheDir.appendingPathComponent("catalog.json")
    }

    // MARK: - Private: load

    private func loadCachedCatalog() {
        guard let data = try? Data(contentsOf: cachedCatalogURL),
              let catalog = try? JSONDecoder().decode(Catalog.self, from: data)
        else { return }
        images = catalog.images
    }

    private func saveCatalogToCache(_ catalog: Catalog) {
        guard let data = try? JSONEncoder().encode(catalog) else { return }
        try? data.write(to: cachedCatalogURL)
    }

    // MARK: - Private: download

    private func downloadCatalog() async throws -> Catalog {
        downloadStatusText = String(localized: "settings.stereograms_downloading")
        let (data, response) = try await URLSession.shared.data(from: catalogURL)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Catalog.self, from: data)
    }

    private func downloadMissingImages(_ images: [CatalogImage]) async throws {
        let missing = images.filter { localURL(for: $0) == nil }
        guard !missing.isEmpty else { return }

        let ctx = ModelContext(DataStack.container)
        for (index, image) in missing.enumerated() {
            guard let url = URL(string: image.url) else { continue }
            downloadStatusText = String(
                localized: "settings.stereograms_downloading_progress \(index + 1) \(missing.count)"
            )
            downloadProgress = Double(index) / Double(missing.count)

            let (data, _) = try await URLSession.shared.data(from: url)
            let dest = cacheDir.appendingPathComponent(image.filename)
            try data.write(to: dest)

            upsertRecord(imageId: image.id, context: ctx)
        }
        downloadProgress = 1
    }

    private func upsertRecord(imageId: String, context: ModelContext) {
        let existing = try? context.fetch(
            FetchDescriptor<StereogramRecord>(predicate: #Predicate { $0.imageId == imageId })
        ).first
        if existing == nil {
            let record = StereogramRecord(imageId: imageId)
            context.insert(record)
        }
        try? context.save()
    }

    // MARK: - Private: pruning

    private func pruneIfNeeded(context: ModelContext) {
        let max = settings.stereogramsMaxImages
        guard max > 0 else { return }

        let all = (try? context.fetch(
            FetchDescriptor<StereogramRecord>(sortBy: [SortDescriptor(\.downloadedAt, order: .reverse)])
        )) ?? []

        guard all.count > max else { return }

        let toDelete = all.dropFirst(max)
        for record in toDelete {
            if let img = images.first(where: { $0.id == record.imageId }) {
                let fileURL = cacheDir.appendingPathComponent(img.filename)
                try? FileManager.default.removeItem(at: fileURL)
            }
            context.delete(record)
        }
        try? context.save()

        images = images.filter { img in
            all.prefix(max).contains(where: { $0.imageId == img.id })
        }
    }

    // MARK: - Private: auto-update

    private func checkForUpdateIfNeeded() {
        guard settings.stereogramsEnabled, settings.stereogramsAutoUpdate else { return }
        let lastChecked = settings.stereogramsLastChecked ?? .distantPast
        let daysSince = Date.now.timeIntervalSince(lastChecked) / 86400
        guard daysSince >= 7 else { return }
        Task { await fetchAndDownload() }
    }

    private func scheduleBackgroundUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkForUpdateIfNeeded()
            }
        }
    }
}
