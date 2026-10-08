#if DEBUG
import Foundation
import WhoopStore

/// DEBUG only: `--forget-device <id>` forgets one registry entry and its recordings through the same
/// `DeviceRegistry.forget` the Devices screen uses, without releasing any Bluetooth link. Exists for a
/// mis-paired row (a WHOOP registered under the Garmin brand) whose Remove would drop the real strap's
/// connection. Refuses the active device and any id it cannot find.
@MainActor
enum DebugForgetDevice {
    static var requestedId: String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--forget-device"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func run(model: AppModel) async {
        guard let id = requestedId else { return }
        note("start \(id)")
        for _ in 0..<40 where model.deviceRegistry == nil {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        guard let registry = model.deviceRegistry, let store = await model.repo.storeHandle() else {
            note("registry not ready"); return
        }
        guard let device = registry.devices.first(where: { $0.id == id }) else {
            note("no device \(id) in \(registry.devices.map(\.id))"); return
        }
        guard device.status != .active else {
            note("refusing the active device \(id)"); return
        }
        await registry.forget(id, store: store)
        let still = registry.devices.contains { $0.id == id }
        note(still ? "forget ran but \(id) is still registered" : "forgot \(id)")
    }
}

extension DebugForgetDevice {
    /// Appends one line to Documents/forget-device.txt, so the outcome can be read off the device.
    static func note(_ line: String) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = dir.appendingPathComponent("forget-device.txt")
        let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        try? (text + "\(Date()) \(line)\n").write(to: url, atomically: true, encoding: .utf8)
    }
}
#endif
