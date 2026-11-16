import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var metrics: MetricsService

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            memorySection
            Divider().padding(.horizontal, 14)
            cpuSection
            Divider().padding(.horizontal, 14)
            gpuSection
            Divider().padding(.horizontal, 14)
            diskSection
            Divider()
            footer
        }
        .frame(width: 300)
        .background(.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.system(size: 12))
            Text("Pulse")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("System Health")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Full Detail") { }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue)
            Spacer()
            Button("Settings") { }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Memory

    private var memorySection: some View {
        MetricSectionView(title: "Memory", icon: "memorychip") {
            let m = metrics.current.memory
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: m.usageRatio, tint: pressureColor(m.pressure))
                    Text(String(format: "%.1f / %.0f GB", m.used, m.total))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(pressureColor(m.pressure))
                        .frame(width: 5, height: 5)
                    Text("Pressure: \(m.pressure.rawValue)")
                        .font(.system(size: 11))
                    if m.swapUsed > 0.01 {
                        Spacer()
                        Text(String(format: "Swap %.1f GB", m.swapUsed))
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                }
                processLine(processes: m.topProcesses, formatValue: { formatMemory($0) })
            }
        }
    }

    // MARK: - CPU

    private var cpuSection: some View {
        MetricSectionView(title: "CPU", icon: "cpu") {
            let c = metrics.current.cpu
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: c.usage, tint: cpuColor(c.usage))
                    Text("\(Int(c.usage * 100))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                if c.sustained {
                    Label("Sustained high load", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - GPU

    private var gpuSection: some View {
        MetricSectionView(title: "GPU", icon: "square.stack.3d.up") {
            let g = metrics.current.gpu
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: g.usage, tint: cpuColor(g.usage))
                    Text("\(Int(g.usage * 100))%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(gpuStatusColor(g.status))
                        .frame(width: 5, height: 5)
                    Text("Status: \(g.status.rawValue)")
                        .font(.system(size: 11))
                    Spacer()
                    Text(String(format: "%.1f GB in use", g.memoryUsed))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                if g.isThrottling {
                    Label("Thermal throttling", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                } else if g.sustained {
                    Label("Sustained high load", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Disk

    private var diskSection: some View {
        MetricSectionView(title: "Storage", icon: "internaldrive") {
            let d = metrics.current.disk
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ProgressBarView(value: d.usageRatio, tint: diskColor(d.free))
                    Text(String(format: "%.0f / %.0f GB", d.used, d.total))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                if d.free < 20 {
                    Label(
                        String(format: "%.1f GB free — running low", d.free),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(d.free < 5 ? .red : .orange)
                }
            }
        }
    }

    // MARK: - Shared helpers

    @ViewBuilder
    private func processLine(processes: [ProcessStat], formatValue: @escaping (Double) -> String) -> some View {
        let top = Array(processes.prefix(3))
        if !top.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(top.enumerated()), id: \.offset) { index, proc in
                    Text(proc.name)
                        .font(.system(size: 10, weight: .medium))
                    Text(" \(formatValue(proc.value))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    if index < top.count - 1 {
                        Text("  ·  ")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func formatMemory(_ mb: Double) -> String {
        mb >= 1024
            ? String(format: "%.1fGB", mb / 1024)
            : String(format: "%.0fMB", mb)
    }

    // MARK: - Color logic

    private func pressureColor(_ p: MemoryPressure) -> Color {
        switch p {
        case .normal:   return .blue
        case .elevated: return .orange
        case .critical: return .red
        }
    }

    private func cpuColor(_ usage: Double) -> Color {
        if usage > 0.85 { return .red }
        if usage > 0.60 { return .orange }
        return .blue
    }

    private func gpuStatusColor(_ s: GPUStatus) -> Color {
        switch s {
        case .normal:     return .blue
        case .busy:       return .orange
        case .overworked: return .red
        }
    }

    private func diskColor(_ freeGB: Double) -> Color {
        if freeGB < 5  { return .red }
        if freeGB < 20 { return .orange }
        return .blue
    }
}
