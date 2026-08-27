import XCTest

@testable import Mihrab

/// Guards for the tasbih strand.
///
/// The strand is a physical simulation, and the parts of it that can go wrong
/// silently are all arithmetic: which piece is under the thumb, how many beads
/// a flick actually counted, and whether the thing ever comes to rest. All of
/// that lives in `TasbihStrandLayout` and `TasbihPhysics`, which are plain
/// value types precisely so it can be checked here rather than by hand on a
/// device.
final class TasbihLayoutTests: XCTestCase {

    private let layout = TasbihStrandLayout()

    func testStrandCarriesThirtyThreeCountsInThirtySixPieces() {
        XCTAssertEqual(layout.countableCount, 33)
        XCTAssertEqual(layout.slotCount, 36)
        XCTAssertEqual(layout.pieces.filter { $0 == .bead }.count, 33)
        XCTAssertEqual(layout.pieces.filter { $0 == .durak }.count, 2)
        XCTAssertEqual(layout.pieces.filter { $0 == .imame }.count, 1)
    }

    func testImameOpensTheLoopAndDuraksSplitItIntoRunsOfEleven() {
        XCTAssertEqual(layout.piece(atSlot: 0), .imame)
        XCTAssertEqual(layout.piece(atSlot: 12), .durak)
        XCTAssertEqual(layout.piece(atSlot: 24), .durak)
        // Everything between them counts.
        for slot in 1...11 { XCTAssertEqual(layout.piece(atSlot: slot), .bead) }
        for slot in 13...23 { XCTAssertEqual(layout.piece(atSlot: slot), .bead) }
        for slot in 25...35 { XCTAssertEqual(layout.piece(atSlot: slot), .bead) }
    }

    func testSlotLookupWrapsInBothDirections() {
        XCTAssertEqual(layout.piece(atSlot: 36), layout.piece(atSlot: 0))
        XCTAssertEqual(layout.piece(atSlot: -1), layout.piece(atSlot: 35))
        XCTAssertEqual(layout.piece(atSlot: -36), .imame)
    }

    /// The whole strand has to agree with itself: walking the loop one boundary
    /// at a time must land on exactly the position the count lookup names.
    /// A drift here would show up as beads that sit between the marks.
    func testSlotPositionAndCrossingsAgreeOverThreeFullTurns() {
        var counted = 0
        for boundary in 1...(layout.slotCount * 3) {
            let crossing = layout.crossings(from: Double(boundary - 1), to: Double(boundary))
            counted += crossing.beads
            guard crossing.beads > 0 else { continue }
            XCTAssertEqual(
                layout.slotPosition(forCount: counted),
                Double(boundary),
                "position lookup drifted from the walk at boundary \(boundary)"
            )
        }
        XCTAssertEqual(counted, 99)
    }

    func testSlotPositionLandsOnTheBoundaryAfterTheNthBead() {
        XCTAssertEqual(layout.slotPosition(forCount: 0), 0)
        // Slot 0 is the imame, so the first bead has passed at boundary 2.
        XCTAssertEqual(layout.slotPosition(forCount: 1), 2)
        XCTAssertEqual(layout.slotPosition(forCount: 11), 12)
        // A durak sits at slot 12, so the twelfth bead clears at boundary 14.
        XCTAssertEqual(layout.slotPosition(forCount: 12), 14)
        XCTAssertEqual(layout.slotPosition(forCount: 33), 36)
        XCTAssertEqual(layout.slotPosition(forCount: 66), 72)
    }

    func testOneFlickAcrossAWholeRunReportsEveryBeadAndBothLandmarks() {
        let crossing = layout.crossings(from: 0, to: 36)
        XCTAssertEqual(crossing.beads, 33)
        XCTAssertTrue(crossing.passedDurak)
        XCTAssertTrue(crossing.passedImame)
    }

    func testBackwardsAndStationaryMovementCountNothing() {
        XCTAssertTrue(layout.crossings(from: 10, to: 4).isEmpty)
        XCTAssertTrue(layout.crossings(from: 10, to: 10).isEmpty)
        XCTAssertTrue(layout.crossings(from: 10.1, to: 10.9).isEmpty)
    }
}

final class TasbihPhysicsTests: XCTestCase {

    private let pitch: Double = 26

    private func makePhysics(stepwise: Bool = false) -> TasbihPhysics {
        var physics = TasbihPhysics()
        physics.stepwise = stepwise
        physics.pitch = pitch
        return physics
    }

    // MARK: Dragging

    func testDraggingOnePitchRollsOneSlotPast() {
        var physics = makePhysics()
        physics.beginDrag()
        // Slot 0 is the imame, so the first pitch of travel counts nothing —
        // exactly as on a real strand, where the terminal bead is not a count.
        let first = physics.drag(travel: pitch, at: 0.016)
        XCTAssertEqual(first.beads, 0)
        XCTAssertTrue(first.passedImame)

        let second = physics.drag(travel: pitch * 2, at: 0.032)
        XCTAssertEqual(second.beads, 1)
    }

    func testDraggingAWholeLoopCountsThirtyThree() {
        var physics = makePhysics()
        physics.beginDrag()
        var total = 0
        for step in 1...36 {
            total += physics.drag(travel: pitch * Double(step), at: Double(step) * 0.016).beads
        }
        XCTAssertEqual(total, 33)
    }

    /// The count must not depend on how many times the gesture reported itself.
    func testCountIsIndependentOfSampleRate() {
        func run(samples: Int) -> Int {
            var physics = makePhysics()
            physics.beginDrag()
            var total = 0
            for step in 1...samples {
                let travel = pitch * 20 * Double(step) / Double(samples)
                total += physics.drag(travel: travel, at: Double(step) * 0.008).beads
            }
            return total
        }
        XCTAssertEqual(run(samples: 4), run(samples: 200))
    }

    func testStrandCannotBePulledBackBehindABeadAlreadyCounted() {
        var physics = makePhysics()
        physics.beginDrag()
        _ = physics.drag(travel: pitch * 6, at: 0.016)
        let settled = physics.position

        // Drag the thumb all the way back past the start.
        let back = physics.drag(travel: -pitch * 20, at: 0.032)
        XCTAssertTrue(back.isEmpty, "reversing must never count")
        XCTAssertLessThanOrEqual(physics.position, settled)
        XCTAssertGreaterThanOrEqual(physics.position, 6)

        // And going forward again must not re-count what it already counted.
        let forward = physics.drag(travel: pitch * 6, at: 0.048)
        XCTAssertTrue(forward.isEmpty)
    }

    // MARK: Inertia

    func testAFlickKeepsCountingAfterTheFingerLifts() {
        var physics = makePhysics()
        physics.beginDrag()
        // Six pitches in 100 ms — a brisk flick.
        for step in 1...6 {
            _ = physics.drag(travel: pitch * Double(step), at: Double(step) * 0.016)
        }
        physics.endDrag(at: 6 * 0.016)
        XCTAssertTrue(physics.isMoving, "the strand should still be running")

        var coasted = 0
        for _ in 0..<600 where physics.isMoving {
            coasted += physics.advance(by: 1.0 / 60.0).beads
        }
        XCTAssertGreaterThan(coasted, 0, "a flick must run more beads by itself")
    }

    func testAFlickAlwaysComesToRestOnAWholePiece() {
        var physics = makePhysics()
        physics.beginDrag()
        for step in 1...10 {
            _ = physics.drag(travel: pitch * Double(step) * 1.5, at: Double(step) * 0.012)
        }
        physics.endDrag(at: 10 * 0.012)

        var frames = 0
        while physics.isMoving, frames < 1_200 {
            _ = physics.advance(by: 1.0 / 60.0)
            frames += 1
        }
        XCTAssertFalse(physics.isMoving, "the strand never settled")
        XCTAssertEqual(physics.position, physics.position.rounded(), accuracy: 0.001)
    }

    func testAPausedFingerDoesNotFling() {
        var physics = makePhysics()
        physics.beginDrag()
        for step in 1...5 {
            _ = physics.drag(travel: pitch * Double(step), at: Double(step) * 0.016)
        }
        // The finger rested for a fifth of a second before lifting.
        physics.endDrag(at: 5 * 0.016 + 0.2)
        var coasted = 0
        for _ in 0..<600 where physics.isMoving {
            coasted += physics.advance(by: 1.0 / 60.0).beads
        }
        XCTAssertEqual(coasted, 0, "lifting from a standstill must not throw the strand")
    }

    /// A stray gesture sample must not be able to spin the loop. Both guards
    /// are checked: the velocity ceiling, and the clamp inside `crossings`.
    func testSpeedIsCappedSoOneFrameCannotSwallowTheLoop() {
        var physics = makePhysics()
        physics.beginDrag()
        // Two samples one millisecond apart, an absurd distance apart — the
        // velocity this implies is thousands of slots a second.
        _ = physics.drag(travel: pitch, at: 0.001)
        _ = physics.drag(travel: pitch * 4_000, at: 0.002)
        physics.endDrag(at: 0.002)

        // Per frame the cap must hold: at 24 slots/s a 1/60 s frame moves 0.4
        // of a slot, so a single frame legitimately crosses nothing. What must
        // never happen is one frame swallowing a whole turn.
        var total = 0
        for _ in 0..<15 {
            let crossed = physics.advance(by: 1.0 / 60.0).beads
            XCTAssertLessThanOrEqual(
                crossed,
                layout.countableCount,
                "one frame ran more than a whole turn of the strand"
            )
            total += crossed
        }
        XCTAssertGreaterThan(total, 0, "a capped flick must still coast")
    }

    private let layout = TasbihStrandLayout()

    // MARK: Reduce Motion

    func testReduceMotionStepsPieceByPieceAndNeverCoasts() {
        var physics = makePhysics(stepwise: true)
        physics.beginDrag()
        // Nine tenths of a pitch is not a bead yet.
        _ = physics.drag(travel: pitch * 0.9, at: 0.016)
        XCTAssertEqual(physics.position, 0)
        _ = physics.drag(travel: pitch * 1.0, at: 0.032)
        XCTAssertEqual(physics.position, 1)

        for step in 2...8 {
            _ = physics.drag(travel: pitch * Double(step), at: Double(step) * 0.016)
            XCTAssertEqual(physics.position, Double(step), "the strand must land on whole pieces")
        }

        physics.endDrag(at: 8 * 0.016)
        XCTAssertFalse(physics.isMoving, "Reduce Motion must not leave the strand coasting")
    }

    func testReduceMotionStillCountsTheSameTotal() {
        func total(stepwise: Bool) -> Int {
            var physics = makePhysics(stepwise: stepwise)
            physics.beginDrag()
            var counted = 0
            for step in 1...36 {
                counted += physics.drag(travel: pitch * Double(step), at: Double(step) * 0.02).beads
            }
            physics.endDrag(at: 36 * 0.02)
            return counted
        }
        XCTAssertEqual(total(stepwise: true), total(stepwise: false))
    }

    // MARK: Reconciling with the outside world

    func testSyncRealignsToTheNearestTurnRatherThanUnwindingEveryOne() {
        var physics = makePhysics()
        _ = physics.step(beads: 99)
        let spun = physics.position
        XCTAssertGreaterThan(spun, 100)

        // Reset to zero: the beads should move less than a whole loop, not
        // three of them.
        physics.sync(toCount: 0)
        XCTAssertLessThanOrEqual(abs(physics.position - spun), Double(TasbihStrandLayout().slotCount))
    }

    func testSyncLeavesTheStrandStillAndOnAWholePiece() {
        var physics = makePhysics()
        physics.beginDrag()
        _ = physics.drag(travel: pitch * 9.4, at: 0.016)
        physics.sync(toCount: 4)
        XCTAssertFalse(physics.isMoving)
        XCTAssertEqual(physics.position, physics.position.rounded(), accuracy: 0.0001)
    }

    func testSteppingByBeadsSkipsTheFurnitureAndCountsOnlyBeads() {
        var physics = makePhysics()
        var counted = 0
        for _ in 0..<33 {
            counted += physics.step(beads: 1).beads
        }
        XCTAssertEqual(counted, 33)
        // 33 beads is one whole turn of a 36-piece loop.
        XCTAssertEqual(physics.position, 36, accuracy: 0.0001)
    }
}

final class TasbihMaterialTests: XCTestCase {

    /// `L10n.language` reads the device, so a unit test can only exercise the
    /// language the test host is running in — but that is enough to catch the
    /// failure that actually happens: a material added to the enum and not to
    /// the copy, which falls through to its raw identifier on screen.
    func testEveryMaterialIsNamedRatherThanFallingThroughToItsIdentifier() {
        var names: Set<String> = []
        for material in TasbihMaterial.allCases {
            let name = material.localizedName
            XCTAssertFalse(name.isEmpty)
            XCTAssertNotEqual(name, material.rawValue, "\(material.rawValue) has no copy")
            names.insert(name)
        }
        XCTAssertEqual(names.count, TasbihMaterial.allCases.count, "two materials share a name")
        // And an id that is not a material still returns something printable.
        XCTAssertEqual(Mihrab.L10n.dhkMaterialName("granite"), "granite")
    }

    func testCyclingVisitsEveryMaterialAndReturns() {
        var seen: [TasbihMaterial] = []
        var current = TasbihMaterial.amber
        for _ in 0..<TasbihMaterial.allCases.count {
            seen.append(current)
            current = current.next
        }
        XCTAssertEqual(Set(seen), Set(TasbihMaterial.allCases))
        XCTAssertEqual(current, .amber)
    }

    /// The click is meant to sound like the material, so the three must not be
    /// interchangeable: harder, denser stock rings higher and longer than wood.
    func testHarderMaterialsRingHigherAndLongerThanWood() {
        XCTAssertGreaterThan(TasbihMaterial.amber.clickFrequency, TasbihMaterial.olive.clickFrequency)
        XCTAssertGreaterThan(TasbihMaterial.olive.clickFrequency, TasbihMaterial.ebony.clickFrequency)
        XCTAssertGreaterThan(TasbihMaterial.amber.clickDecay, TasbihMaterial.ebony.clickDecay)
        for material in TasbihMaterial.allCases {
            XCTAssertGreaterThan(material.clickFrequency, 20)
            XCTAssertLessThan(material.clickFrequency, 20_000, "above the audible band")
            XCTAssertGreaterThan(material.clickDecay, 0)
            XCTAssertLessThan(material.clickDecay, 0.09, "a click, not a chime")
        }
    }
}
