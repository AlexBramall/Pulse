import Darwin
import Foundation

final class ProcessMonitor {
    // Returns top processes sorted by resident memory (MB), capped at `limit`.
    func topByMemory(limit: Int = 5) -> [ProcessStat] {
        var pids = [Int32](repeating: 0, count: 1024)
        let byteCount = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size))
        let count = Int(byteCount) / MemoryLayout<Int32>.size

        var results: [(name: String, mb: Double)] = []

        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }

            var info = proc_taskinfo()
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info,
                                   Int32(MemoryLayout<proc_taskinfo>.size))
            guard ret > 0 else { continue }

            var nameBuf = [CChar](repeating: 0, count: Int(MAXCOMLEN) + 1)
            proc_name(pid, &nameBuf, UInt32(nameBuf.count))
            let name = String(cString: nameBuf)
            guard !name.isEmpty else { continue }

            let mb = Double(info.pti_resident_size) / 1_048_576
            results.append((name: name, mb: mb))
        }

        return results
            .sorted { $0.mb > $1.mb }
            .prefix(limit)
            .map { ProcessStat(name: $0.name, value: $0.mb) }
    }
}
