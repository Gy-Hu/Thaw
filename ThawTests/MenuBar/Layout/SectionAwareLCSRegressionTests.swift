import Testing
@testable import Thaw

@Suite("Section-aware LCS regression")
struct SectionAwareLCSRegressionTests {
    @Test("An unchanged flat order still moves a hidden item into visible")
    func revealWithoutReordering() {
        let moves = LayoutSolver.planLCSMoveSequence(
            currentNoControls: ["a", "b", "c"],
            desiredNoControls: ["a", "b", "c"],
            sectionMap: ["a": "visible", "b": "visible", "c": "hidden"],
            currentSectionMap: ["a": "visible", "b": "hidden", "c": "hidden"]
        )
        #expect(moves == [.init(uid: "b", destination: .rightOfUID("a"))])
    }

    @Test("Switching back hides the item without reordering its neighbours")
    func concealWithoutReordering() {
        let moves = LayoutSolver.planLCSMoveSequence(
            currentNoControls: ["a", "b", "c"],
            desiredNoControls: ["a", "b", "c"],
            sectionMap: ["a": "visible", "b": "hidden", "c": "hidden"],
            currentSectionMap: ["a": "visible", "b": "visible", "c": "hidden"]
        )
        #expect(moves == [.init(uid: "b", destination: .leftOfUID("c"))])
    }

    @Test("Wrong-section items cannot anchor each other before being moved")
    func wrongSectionAnchors() {
        let moves = LayoutSolver.planLCSMoveSequence(
            currentNoControls: ["a", "b", "c", "d"],
            desiredNoControls: ["a", "b", "c", "d"],
            sectionMap: ["a": "visible", "b": "visible", "c": "visible", "d": "hidden"],
            currentSectionMap: ["a": "visible", "b": "hidden", "c": "hidden", "d": "hidden"]
        )
        #expect(moves == [
            .init(uid: "b", destination: .rightOfUID("a")),
            .init(uid: "c", destination: .rightOfUID("b"))
        ])
    }

    @Test("A correct layout with section metadata remains a no-op")
    func correctLayout() {
        let sections = ["a": "visible", "b": "hidden", "c": "alwaysHidden"]
        #expect(LayoutSolver.planLCSMoveSequence(
            currentNoControls: ["a", "b", "c"], desiredNoControls: ["a", "b", "c"],
            sectionMap: sections, currentSectionMap: sections
        ).isEmpty)
    }

    @Test("A missing profile item is not manufactured as a move target")
    func missingItem() {
        #expect(LayoutSolver.planLCSMoveSequence(
            currentNoControls: ["a"], desiredNoControls: ["a", "b"],
            sectionMap: ["a": "visible", "b": "visible"],
            currentSectionMap: ["a": "visible", "b": "hidden"]
        ).isEmpty)
    }
}
