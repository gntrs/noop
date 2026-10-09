import XCTest
import StrandAnalytics
@testable import Strand

final class SwimFixStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "SwimFixStoreTests")
        defaults.removePersistentDomain(forName: "SwimFixStoreTests")
    }

    func testSaveLoadAndClear() {
        XCTAssertNil(SwimFixStore.load(startTs: 1, sport: "Swimming", from: defaults))
        SwimFixStore.save(.init(poolM: 25, lengths: 60), startTs: 1, sport: "Swimming", to: defaults)
        XCTAssertEqual(SwimFixStore.load(startTs: 1, sport: "Swimming", from: defaults)?.lengths, 60)
        SwimFixStore.save(nil, startTs: 1, sport: "Swimming", to: defaults)
        XCTAssertNil(SwimFixStore.load(startTs: 1, sport: "Swimming", from: defaults))
    }

    func testUnusableFixIsNotStored() {
        SwimFixStore.save(.init(poolM: 25), startTs: 2, sport: "Swimming", to: defaults)
        XCTAssertTrue(SwimFixStore.loadMap(from: defaults).isEmpty)
    }

    func testSessionsDoNotCollide() {
        SwimFixStore.save(.init(poolM: 25, lengths: 40), startTs: 3, sport: "Swimming", to: defaults)
        SwimFixStore.save(.init(poolM: 50, lengths: 30), startTs: 4, sport: "Swimming", to: defaults)
        SwimFixStore.save(.init(poolM: 50, distanceM: 900), startTs: 3, sport: "Open Water", to: defaults)
        XCTAssertEqual(SwimFixStore.load(startTs: 3, sport: "Swimming", from: defaults)?.lengths, 40)
        XCTAssertEqual(SwimFixStore.load(startTs: 4, sport: "Swimming", from: defaults)?.poolM, 50)
        XCTAssertEqual(SwimFixStore.load(startTs: 3, sport: "Open Water", from: defaults)?.distanceM, 900)
    }

    func testGarbageBlobReadsEmpty() {
        defaults.set(Data("nope".utf8), forKey: SwimFixStore.defaultsKey)
        XCTAssertTrue(SwimFixStore.loadMap(from: defaults).isEmpty)
    }
}
