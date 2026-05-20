import Foundation

final class DiskMonitor {
    func sample() -> DiskMetrics {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
              let totalBytes = attrs[.systemSize] as? Double,
              let freeBytes  = attrs[.systemFreeSize] as? Double else {
            return DiskMetrics(used: 0, total: 0)
        }

        let total = totalBytes / 1_073_741_824
        let free  = freeBytes  / 1_073_741_824
        return DiskMetrics(used: max(0, total - free), total: total)
    }
}
