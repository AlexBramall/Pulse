import Foundation
import SwiftUI

@MainActor
final class MetricsService: ObservableObject {
    @Published private(set) var current: SystemMetrics = .placeholder

    private let cpu        = CPUMonitor()
    private let memory     = MemoryMonitor()
    private let processes  = ProcessMonitor()
    private let gpu        = GPUMonitor()
    private let disk       = DiskMonitor()

    private var pollingTask: Task<Void, Never>?
    private var cpuLoad = SustainedLoadTracker()
    private var gpuLoad = SustainedLoadTracker()
    let pollInterval: TimeInterval = 3.0

    init() {
        // Warm up the CPU delta baseline before the first real sample.
        _ = cpu.sample()
        startPolling()
    }

    func startPolling() {
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(self?.pollInterval ?? 3))
            }
        }
    }

    private func refresh() {
        let cpuUsage = cpu.sample()

        let sustained = cpuLoad.update(cpuUsage)

        let (memUsed, memTotal, pressure, swapUsed) = memory.sample()
        let topMemProcs = processes.topByMemory(limit: 3)
        let (gpuUsage, gpuMemory) = gpu.sample()
        let dsk = disk.sample()

        current = SystemMetrics(
            cpu: CPUMetrics(
                usage: cpuUsage,
                topProcesses: topMemProcs, // reuse memory top for now; CPU per-process in M4
                sustained: sustained
            ),
            memory: MemoryMetrics(
                used: memUsed,
                total: memTotal,
                pressure: pressure,
                topProcesses: topMemProcs,
                swapUsed: swapUsed
            ),
            gpu: GPUMetrics(
                usage: gpuUsage,
                memoryUsed: gpuMemory,
                thermalState: ProcessInfo.processInfo.thermalState,
                sustained: gpuLoad.update(gpuUsage)
            ),
            disk: dsk
        )
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Menu bar helpers

    var menuBarText: String {
        let ram = Int(current.memory.usageRatio * 100)
        let cpu = Int(current.cpu.usage * 100)
        let gpu = Int(current.gpu.usage * 100)
        return "RAM \(ram)%  CPU \(cpu)%  GPU \(gpu)%"
    }

    var healthTint: Color {
        if current.memory.pressure == .critical || current.gpu.status == .overworked { return .red }
        if current.memory.pressure == .elevated || current.cpu.usage > 0.85 || current.gpu.usage > 0.85 {
            return .orange
        }
        return .primary
    }
}
