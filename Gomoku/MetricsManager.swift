//
//  MetricsManager.swift
//  Gomoku
//
//  Collects MetricKit diagnostic/metric payloads and persists them to disk so they can
//  be inspected or exported from Settings. Apple delivers these payloads about once a
//  day for the prior session; crashes / hangs / disk-write exceptions come through too.
//

import Foundation
import MetricKit

class MetricsManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsManager()

    private let folderName = "diagnostics"
    private let maxPayloads = 20

    private override init() { super.init() }

    func start() {
        MXMetricManager.shared.add(self)
    }

    // MARK: - MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            persist(data: payload.jsonRepresentation(), prefix: "metric")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            persist(data: payload.jsonRepresentation(), prefix: "diagnostic")
        }
    }

    // MARK: - Persistence

    var diagnosticsFolderURL: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = docs.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    var storedPayloadURLs: [URL] {
        guard let folder = diagnosticsFolderURL else { return [] }
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey])) ?? []
        return urls.sorted { lhs, rhs in
            let lhsDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lhsDate > rhsDate
        }
    }

    private func persist(data: Data, prefix: String) {
        guard let folder = diagnosticsFolderURL else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = folder.appendingPathComponent("\(prefix)-\(timestamp).json")
        do {
            try data.write(to: url)
            pruneOldPayloads(in: folder)
        } catch {
            print("MetricsManager: failed to persist payload — \(error.localizedDescription)")
        }
    }

    private func pruneOldPayloads(in folder: URL) {
        let urls = storedPayloadURLs
        guard urls.count > maxPayloads else { return }
        for url in urls.dropFirst(maxPayloads) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
