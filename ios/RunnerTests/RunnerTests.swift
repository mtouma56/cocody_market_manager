import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testBundleIdentifierMatchesExpectedValue() {
    let bundleIdentifier = Bundle.main.bundleIdentifier

    XCTAssertEqual(
      bundleIdentifier,
      "com.cocody_market_manager.app.testProject",
      "Runner bundle identifier should remain stable"
    )
  }

}
