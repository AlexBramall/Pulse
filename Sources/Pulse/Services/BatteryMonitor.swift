import Foundation
import IOKit.ps

final class BatteryMonitor {
    func sample() -> BatteryMetrics {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources  = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)
                    .takeUnretainedValue() as? [String: Any] else { continue }

            guard let type = info[kIOPSTypeKey] as? String,
                  type == kIOPSInternalBatteryType else { continue }

            let percentage  = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let isCharging  = (info[kIOPSIsChargingKey] as? Bool) ?? false
            let isOnAC      = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue

            // Health: design capacity vs max capacity
            let maxCap      = info[kIOPSMaxCapacityKey] as? Int ?? 100
            let designCap   = info["DesignCapacity"] as? Int ?? maxCap
            let health      = designCap > 0 ? Int(Double(maxCap) / Double(designCap) * 100) : 100

            let cycleCount  = info["CycleCount"] as? Int ?? 0

            return BatteryMetrics(
                percentage:  percentage,
                isCharging:  isCharging,
                health:      min(health, 100),
                cycleCount:  cycleCount,
                cpuTemp:     nil,   // M3: add SMC temperature reads
                gpuTemp:     nil,
                fanRPM:      nil,
                isOnACPower: isOnAC
            )
        }

        // No battery found (desktop Mac)
        return BatteryMetrics(
            percentage: 100, isCharging: false, health: 100,
            cycleCount: 0, cpuTemp: nil, gpuTemp: nil, fanRPM: nil, isOnACPower: true
        )
    }
}
