//
//  EyeHeavenTests.swift
//  EyeHeavenTests
//
//  Created by Nikolai Nikolaev on 26.04.26.
//

import XCTest
@testable import EyeHeaven

@MainActor
final class EyeHeavenTests: XCTestCase {
    func testLongPostponeAdds180Seconds() {
        let engine = TimerEngine(settings: TestSettings(), autoStart: false)

        engine.advanceTimeForTesting(by: 3)
        assertStateIsBreak(engine.state, type: .short)
        engine.skipBreak(.short)

        let enteredLongPreBreak = advanceUntil(maxTicks: 8, using: engine) {
            if case .inPreBreak(.long, _) = $0.state { return true }
            return false
        }
        XCTAssertTrue(enteredLongPreBreak)
        let beforePostpone = rounded(engine.nextLongBreakIn)

        engine.postponeLongBreak()
        XCTAssertEqual(rounded(engine.nextLongBreakIn) - beforePostpone, 180)
        assertStateIsRunning(engine.state)
    }

    func testSkipCountsAsCompletedBreak() {
        let engine = TimerEngine(settings: TestSettings(), autoStart: false)

        engine.advanceTimeForTesting(by: 3)
        assertStateIsBreak(engine.state, type: .short)
        engine.skipBreak(.short)

        // Short skip counts as completed, so long countdown continues.
        XCTAssertEqual(rounded(engine.nextLongBreakIn), 3)
        XCTAssertEqual(rounded(engine.nextShortBreakIn), 3)

        engine.advanceTimeForTesting(by: 3)
        assertStateIsBreak(engine.state, type: .long)

        engine.skipBreak(.long)

        assertStateIsRunning(engine.state)
        XCTAssertEqual(rounded(engine.nextShortBreakIn), 3)
        XCTAssertEqual(rounded(engine.nextLongBreakIn), 6)
    }

    private func rounded(_ value: TimeInterval) -> Int {
        Int(value.rounded())
    }

    private func assertStateIsBreak(_ state: TimerState, type: BreakType, file: StaticString = #filePath, line: UInt = #line) {
        guard case let .inBreak(foundType) = state else {
            XCTFail("Expected .inBreak", file: file, line: line)
            return
        }
        XCTAssertEqual(foundType, type, file: file, line: line)
    }

    private func assertStateIsPreBreak(_ state: TimerState, type: BreakType, file: StaticString = #filePath, line: UInt = #line) {
        guard case let .inPreBreak(foundType, _) = state else {
            XCTFail("Expected .inPreBreak", file: file, line: line)
            return
        }
        XCTAssertEqual(foundType, type, file: file, line: line)
    }

    private func assertStateIsRunning(_ state: TimerState, file: StaticString = #filePath, line: UInt = #line) {
        guard case .running = state else {
            XCTFail("Expected .running", file: file, line: line)
            return
        }
    }

    private func advanceUntil(
        maxTicks: Int,
        using engine: TimerEngine,
        predicate: (TimerEngine) -> Bool
    ) -> Bool {
        for _ in 0 ..< maxTicks {
            if predicate(engine) { return true }
            engine.advanceTimeForTesting(by: 1)
        }
        return predicate(engine)
    }
}

private final class TestSettings: TimerSettingsProviding {
    var shortBreakInterval: TimeInterval = 3
    var shortBreakDuration: TimeInterval = 20
    var shortBreakWarning: TimeInterval = 1
    var longBreakDuration: TimeInterval = 60
    var longBreakWarning: TimeInterval = 2
    var longBreakMaxPostpones: Int = 2
    var longBreakAllowSkip: Bool = true

    var longBreakInterval: TimeInterval {
        shortBreakInterval * 2
    }

}
