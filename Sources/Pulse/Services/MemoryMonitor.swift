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

        var swapInfo = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swapInfo, &swapSize, nil, 0)
        let swapUsed = Double(swapInfo.xsu_used) / 1_073_741_824

        return (used, total, kernelPressure(), swapUsed)
    }

    // The kernel's own level (what Activity Monitor graphs): 1 normal, 2 warning, 4 critical.
    // Swap size alone is a poor signal; macOS can hold several GB of swap at normal pressure.
    private func kernelPressure() -> MemoryPressure {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else {
            return .normal
        }
        switch level {
        case 4...: return .critical
        case 2...: return .elevated
        default:   return .normal
        }
    }
}
