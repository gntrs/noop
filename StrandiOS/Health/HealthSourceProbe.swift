#if DEBUG
import Foundation
import HealthKit

/// DEBUG only, launched with --health-probe. Lists what each app writes into Apple Health over the last
/// 7 days (heart rate, sleep, workouts, steps, HRV) per source bundle id, and writes the result to
/// Documents/health-probe.json. Read only. Exists to learn what Garmin Connect actually writes before the
/// Garmin gap filler is built on it.
enum HealthSourceProbe {
    static let argument = "--health-probe"
    static var requested: Bool { CommandLine.arguments.contains(argument) }

    static func run() async {
        guard HKHealthStore.isHealthDataAvailable() else { return write(["error": "health unavailable"]) }
        let store = HKHealthStore()
        let quantityIds: [HKQuantityTypeIdentifier] = [.heartRate, .restingHeartRate, .heartRateVariabilitySDNN, .stepCount]
        var read = Set<HKObjectType>(quantityIds.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { read.insert(sleep) }
        read.insert(HKObjectType.workoutType())
        do { try await store.requestAuthorization(toShare: [], read: read) } catch {
            return write(["error": "authorization: \(error.localizedDescription)"])
        }

        let end = Date()
        let start = end.addingTimeInterval(-7 * 86_400)
        let window = HKQuery.predicateForSamples(withStart: start, end: end)
        var out: [String: Any] = ["generatedAt": iso(end), "windowDays": 7]

        for id in quantityIds {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { continue }
            let samples = await fetch(store, type, window)
            out[id.rawValue] = bySource(samples).mapValues { group -> [String: Any] in
                let dates = group.map(\.startDate).sorted()
                let gaps = zip(dates.dropFirst(), dates).map { $0.timeIntervalSince($1) }.sorted()
                return [
                    "count": group.count,
                    "first": dates.first.map(iso) ?? "",
                    "last": dates.last.map(iso) ?? "",
                    "medianGapS": gaps.isEmpty ? 0 : Int(gaps[gaps.count / 2]),
                ]
            }
        }

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let samples = await fetch(store, sleepType, window)
            out["sleepAnalysis"] = bySource(samples).mapValues { group -> [String: Any] in
                var values: [String: Int] = [:]
                for s in group { if let c = s as? HKCategorySample { values[sleepName(c.value), default: 0] += 1 } }
                let nights = Set(group.map { Calendar.current.startOfDay(for: $0.endDate) }).count
                return ["count": group.count, "nights": nights, "values": values]
            }
        }

        let workouts = await fetch(store, HKObjectType.workoutType(), window).compactMap { $0 as? HKWorkout }
        var rows: [[String: Any]] = []
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            for w in workouts {
                let attached = await fetch(store, hrType, HKQuery.predicateForObjects(from: w))
                let inWindow = await fetch(store, hrType, HKQuery.predicateForSamples(withStart: w.startDate, end: w.endDate))
                rows.append([
                    "source": w.sourceRevision.source.bundleIdentifier,
                    "activity": w.workoutActivityType.rawValue,
                    "start": iso(w.startDate),
                    "minutes": Int(w.duration / 60),
                    "hrAttached": attached.count,
                    "hrInWindowBySource": bySource(inWindow).mapValues(\.count),
                ])
            }
        }
        out["workouts"] = rows
        write(out)
    }

    private static func fetch(_ store: HKHealthStore, _ type: HKSampleType, _ predicate: NSPredicate) async -> [HKSample] {
        await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, _ in cont.resume(returning: samples ?? []) }
            store.execute(q)
        }
    }

    private static func bySource(_ samples: [HKSample]) -> [String: [HKSample]] {
        Dictionary(grouping: samples) { s in
            let src = s.sourceRevision.source
            return "\(src.bundleIdentifier) (\(src.name))"
        }
    }

    private static func sleepName(_ value: Int) -> String {
        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .inBed: return "inBed"
        case .asleepUnspecified: return "asleepUnspecified"
        case .awake: return "awake"
        case .asleepCore: return "core"
        case .asleepDeep: return "deep"
        case .asleepREM: return "rem"
        default: return "other\(value)"
        }
    }

    private static func iso(_ d: Date) -> String { ISO8601DateFormatter().string(from: d) }

    private static func write(_ obj: [String: Any]) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
        else { return }
        try? data.write(to: dir.appendingPathComponent("health-probe.json"))
    }
}
#endif
