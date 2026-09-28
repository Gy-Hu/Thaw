from pathlib import Path
import subprocess,sys
base='--baseline' in sys.argv
root=Path(__file__).resolve().parents[1]
pkg=root/'build'/('regression-baseline' if base else 'regression-patched')
(pkg/'Sources/Core').mkdir(parents=True,exist_ok=True)
(pkg/'Tests/CoreTests').mkdir(parents=True,exist_ok=True)
# These are generated harness sources, never the repository source files.
for folder in [pkg/'Sources/Core', pkg/'Tests/CoreTests']:
 for generated in folder.glob('*.swift'):generated.unlink()
def read(path):
 return subprocess.check_output(['git','show','d5eab80b:'+path],cwd=root,text=True) if base else (root/path).read_text()
def block(s,needle):
 start=s.index(needle); left=s.index('{',start);depth=1;i=left+1
 while depth:
  depth+= (s[i]=='{')-(s[i]=='}');i+=1
 return s[start:i]
s=read('Thaw/MenuBar/MenuBarItems/LayoutSolver.swift')
parts=[block(s,n) for n in ['enum LCSPlannedDestination:', 'struct LCSPlannedMove:', 'static nonisolated func planLCSMoveSequence(', 'static nonisolated func longestCommonSubsequence(', 'static nonisolated func isOnScreen(', 'static nonisolated func isFullyOffScreen(']]
adapter='''
static func planLCSMoveSequence(currentNoControls: [String], desiredNoControls: [String], sectionMap: [String: String], currentSectionMap: [String: String]) -> [LCSPlannedMove] {
    planLCSMoveSequence(currentNoControls: currentNoControls, desiredNoControls: desiredNoControls, sectionMap: sectionMap)
}
''' if base else ''
(pkg/'Sources/Core/Extracted.swift').write_text('import Foundation\nimport CoreGraphics\nenum MenuBarSection { enum Name { case visible, hidden, alwaysHidden } }\nenum LayoutSolver {\n'+'\n'.join(parts)+adapter+'\n}\n')
(pkg/'Package.swift').write_text('''// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "ThawRegression", platforms: [.macOS("26.0")], targets: [.target(name: "Core"), .testTarget(name: "CoreTests", dependencies: ["Core"])])
''')
for f in ['ThawTests/MenuBar/Layout/PlanLCSMoveSequenceTests.swift','ThawTests/MenuBar/Layout/SectionAwareLCSRegressionTests.swift','ThawTests/MenuBar/Layout/CapturedDisplayTraceTests.swift']:
 (pkg/'Tests/CoreTests'/Path(f).name).write_text((root/f).read_text().replace('@testable import Thaw','@testable import Core'))
if not base:
 (pkg/'Sources/Core/DisplayConnectionProfilePolicy.swift').write_text((root/'Thaw/Settings/Models/DisplayConnectionProfilePolicy.swift').read_text())
 (pkg/'Sources/Core/CodeSigningInfo.swift').write_text((root/'Shared/Utilities/CodeSigningInfo.swift').read_text())
 f=root/'ThawTests/Shared/LocalPeerSigningTests.swift'
 (pkg/'Tests/CoreTests'/f.name).write_text(f.read_text().replace('@testable import Thaw','@testable import Core'))
 f=root/'ThawTests/Settings/Models/DisplayConnectionProfilePolicyTests.swift'
 (pkg/'Tests/CoreTests'/f.name).write_text(f.read_text().replace('@testable import Thaw','@testable import Core'))
(pkg/'Tests/CoreTests/GeometryTests.swift').write_text('''import Foundation
import Testing
@testable import Core
@Suite("Collapsed divider geometry") struct GeometryTests {
 @Test func expandedSpacerIsNotAStrandedDivider() {
  let screens = [CGRect(x: 0,y: 0,width: 1512,height: 982),CGRect(x: -408,y: -1152,width: 2048,height: 1152)]
  // Representative 5000pt collapsed geometry; -4023 is from the user's log.
  let divider = CGRect(x: -4023,y: -1152,width: 5000,height: 30)
  #expect(!LayoutSolver.isOnScreen(bounds: divider,screenFrames: screens))
  #expect(!LayoutSolver.isFullyOffScreen(bounds: divider,screenFrames: screens))
 }
}
''')
print('Extracted production functions from', 'd5eab80b (baseline)' if base else 'patched checkout',flush=True)
r=subprocess.run(['swift','test','--package-path',str(pkg)],text=True)
sys.exit(r.returncode)
