import Foundation
import SwiftData

enum StereogramPicker {
    /// Weighted random selection. Weight = daysSinceLastShown / (timesShown + 1).
    /// Updates the chosen record in SwiftData. Returns nil if no local images available.
    static func pick(
        from catalog: [CatalogImage],
        service: CatalogService,
        context: ModelContext
    ) -> (CatalogImage, URL)? {
        let available = catalog.compactMap { img -> (CatalogImage, URL)? in
            guard let url = service.localURL(for: img) else { return nil }
            return (img, url)
        }
        guard !available.isEmpty else { return nil }

        let records = (try? context.fetch(FetchDescriptor<StereogramRecord>())) ?? []
        let recordMap = Dictionary(uniqueKeysWithValues: records.map { ($0.imageId, $0) })

        let now = Date.now
        let weights: [Double] = available.map { img, _ in
            let record = recordMap[img.id]
            let days = record.map { now.timeIntervalSince($0.lastShownAt) / 86400 } ?? 9999
            let shown = Double(record?.timesShown ?? 0)
            return days / (shown + 1)
        }

        guard let chosen = weightedRandom(items: available, weights: weights) else { return nil }

        updateRecord(imageId: chosen.0.id, context: context, existing: recordMap[chosen.0.id])

        return chosen
    }

    // MARK: - Private

    private static func weightedRandom<T>(items: [T], weights: [Double]) -> T? {
        guard !items.isEmpty else { return nil }
        let total = weights.reduce(0, +)
        guard total > 0 else { return items.randomElement() }
        var roll = Double.random(in: 0 ..< total)
        for (item, weight) in zip(items, weights) {
            roll -= weight
            if roll <= 0 { return item }
        }
        return items.last
    }

    private static func updateRecord(
        imageId: String,
        context: ModelContext,
        existing: StereogramRecord?
    ) {
        if let record = existing {
            record.lastShownAt = .now
            record.timesShown += 1
        } else {
            let record = StereogramRecord(imageId: imageId)
            record.lastShownAt = .now
            record.timesShown = 1
            context.insert(record)
        }
        try? context.save()
    }
}
