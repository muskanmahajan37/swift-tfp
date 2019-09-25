@testable import LibShapeChecker
import SIL
import XCTest

@available(macOS 10.13, *)
final class TransformsTests: XCTestCase {
  let s0 = ListExpr.var(ListVar(0))
  let s1 = ListExpr.var(ListVar(1))
  let d0 = IntExpr.var(IntVar(0))
  let d1 = IntExpr.var(IntVar(1))
  let d2 = IntExpr.var(IntVar(2))
  let b0 = BoolExpr.var(BoolVar(0))
  let b1 = BoolExpr.var(BoolVar(1))
  let b2 = BoolExpr.var(BoolVar(2))
  let b3 = BoolExpr.var(BoolVar(3))

  func testSimplify() {
    XCTAssertEqual(simplify(.add(2, 4)), 6)
    XCTAssertEqual(simplify(.add(d1, 0)), d1)
    XCTAssertEqual(simplify(.add(0, d1)), d1)
    XCTAssertEqual(simplify(.sub(6, 2)), 4)
    XCTAssertEqual(simplify(.mul(6, 2)), 12)
    XCTAssertEqual(simplify(.div(5, 2)), 2)
    XCTAssertEqual(simplify(.element(0, of: .literal([d0]))), d0)
    XCTAssertEqual(simplify(.element(-2, of: .literal([d0, nil]))), d0)
    XCTAssertEqual(simplify(.broadcast(.literal([4, 5]), .literal([8, 4, 1]))),
                   .literal([8, 4, 5]))
    XCTAssertEqual(simplify(.broadcast(.literal([4, nil]), .literal([8, 4, 5]))),
                   .literal([8, 4, 5]))
    XCTAssertEqual(simplify(.broadcast(.literal([4, nil]), .literal([8, 4, nil]))),
                   .literal([8, 4, nil]))
  }

  func testDeduplicate() {
    XCTAssertEqual(deduplicate([
      .expr(.intEq(.element(1, of: s0), 2), assuming: .true, .asserted, .top),
      .expr(.intEq(.element(0, of: s0), 4), assuming: .true, .asserted, .top),
      .expr(.intEq(.element(1, of: s0), 2), assuming: .true, .asserted, .top),
      .expr(.listEq(s0, .literal([nil, 2])), assuming: .true, .asserted, .top),
      .expr(.intEq(.element(1, of: s0), 2), assuming: .true, .asserted, .top),
      .expr(.listEq(s0, .literal([nil, 2])), assuming: .true, .asserted, .top),
    ]), [
      .expr(.intEq(.element(1, of: s0), 2), assuming: .true, .asserted, .top),
      .expr(.intEq(.element(0, of: s0), 4), assuming: .true, .asserted, .top),
      .expr(.listEq(s0, .literal([nil, 2])), assuming: .true, .asserted, .top),
    ])
  }

  func testInline() {
    // If we read the expressions in order then we cannot remove the second one
    let nonInlinable: [Constraint] = [
      .expr(.intGt(d0, d1), assuming: .true, .asserted, .top),
      .expr(.intEq(d0, 2), assuming: .true, .asserted, .top),
    ]
    XCTAssertEqual(inline(nonInlinable), nonInlinable)

    XCTAssertEqual(inline([
      .expr(.intEq(d0, .add(d1, d2)), assuming: .true, .asserted, .top),
      .expr(.intEq(d0, 2), assuming: .true, .asserted, .top),
    ]), [
      .expr(.intEq(.add(d1, d2), 2), assuming: .true, .asserted, .top),
    ])

    XCTAssertEqual(inline([
      .expr(.intEq(d0, .add(d1, d2)), assuming: .true, .asserted, .top),
      .expr(.intEq(d1, .sub(d0, 2)), assuming: .true, .asserted, .top),
      .expr(.intEq(d0, 2), assuming: .true, .asserted, .top),
    ]), [
      .expr(.intEq(d1, .sub(.add(d1, d2), 2)), assuming: .true, .asserted, .top),
      .expr(.intEq(.add(d1, d2), 2), assuming: .true, .asserted, .top),
    ])

    XCTAssertEqual(inline([
      .expr(.intEq(d0, .add(2, 3)), assuming: .true, .asserted, .top),
      .expr(.intEq(d1, .mul(d0, d0)), assuming: .true, .asserted, .top),
      .expr(.intEq(d2, .sub(d1, 5)), assuming: .true, .asserted, .top),
      .expr(.intEq(.element(0, of: s0), d2), assuming: .true, .asserted, .top)
    ]), [
      .expr(.intEq(.element(0, of: s0), 20), assuming: .true, .asserted, .top),
    ])
  }

  static var allTests = [
    ("testSimplify", testSimplify),
    ("testDeduplicate", testDeduplicate),
    ("testInline", testInline),
  ]
}


