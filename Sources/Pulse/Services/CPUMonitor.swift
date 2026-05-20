import Darwin.Mach
import Foundation

final class CPUMonitor {
    private var previousTicks: [[UInt32]] = []

    // Returns overall CPU usage 0.0–1.0, computed as delta since last call.
    // First call returns 0 (no previous baseline).
    func sample() -> Double {
        var numCPUs: natural_t = 0
        var cpuInfoPtr: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
            &numCPUs, &cpuInfoPtr, &numCPUInfo
        )
        guard result == KERN_SUCCESS, let cpuInfoPtr else { return 0 }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfoPtr),
                vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        let stride = Int(CPU_STATE_MAX)
        let current: [[UInt32]] = (0..<Int(numCPUs)).map { i in
            let base = i * stride
            return [
                UInt32(bitPattern: cpuInfoPtr[base + Int(CPU_STATE_USER)]),
                UInt32(bitPattern: cpuInfoPtr[base + Int(CPU_STATE_SYSTEM)]),
                UInt32(bitPattern: cpuInfoPtr[base + Int(CPU_STATE_NICE)]),
                UInt32(bitPattern: cpuInfoPtr[base + Int(CPU_STATE_IDLE)])
            ]
        }

        var totalUsage = 0.0

        if previousTicks.count == current.count {
            for i in 0..<current.count {
                let p = previousTicks[i]
                let c = current[i]
                let userD   = Double(c[0] &- p[0])
                let sysD    = Double(c[1] &- p[1])
                let niceD   = Double(c[2] &- p[2])
                let idleD   = Double(c[3] &- p[3])
                let total   = userD + sysD + niceD + idleD
                let active  = userD + sysD + niceD
                totalUsage += total > 0 ? active / total : 0
            }
            totalUsage /= Double(current.count)
        }

        previousTicks = current
        return totalUsage
    }
}
