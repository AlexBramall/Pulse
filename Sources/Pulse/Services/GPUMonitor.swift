import Foundation
import IOKit

final class GPUMonitor {
    // Returns the busiest accelerator's utilization (0.0–1.0) and total GPU memory in use (GB).
    func sample() -> (usage: Double, memoryUsed: Double) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator
        ) == KERN_SUCCESS else { return (0, 0) }
        defer { IOObjectRelease(iterator) }

        var usage = 0.0
        var memoryBytes = 0.0

        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }

            guard let stats = IORegistryEntryCreateCFProperty(
                service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? [String: Any] else { continue }

            let device = (stats["Device Utilization %"] as? NSNumber)?.doubleValue ?? 0
            usage = max(usage, device / 100)
            memoryBytes += (stats["In use system memory"] as? NSNumber)?.doubleValue ?? 0
        }

        return (min(usage, 1), memoryBytes / 1_073_741_824)
    }
}
