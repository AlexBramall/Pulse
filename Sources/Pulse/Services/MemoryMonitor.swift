import Darwin.Mach
import Foundation

final class MemoryMonitor {
    func sample() -> (used: Double, total: Double, pressure: MemoryPressure, swapUsed: Double) {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let total = Double(totalBytes) / 1_073_741_824

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, total, .normal, 0)
        }

        let pageSize = Double(vm_kernel_page_size)
        let wired      = Double(stats.wire_count)           * pageSize
        let active     = Double(stats.active_count)         * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        let used = min((wired + active + compressed) / 1_073_741_824, total)

        let free = Double(stats.free_count + stats.inactive_count) * pageSize / 1_073_741_824
        let freeRatio = total > 0 ? free / total : 1

        var swapInfo = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swapInfo, &swapSize, nil, 0)
        let swapUsed = Double(swapInfo.xsu_used) / 1_073_741_824

        let pressure: MemoryPressure
        if freeRatio < 0.08 || swapUsed > 4 {
            pressure = .critical
        } else if freeRatio < 0.20 || swapUsed > 0.5 {
            pressure = .elevated
        } else {
            pressure = .normal
        }

        return (used, total, pressure, swapUsed)
    }
}
