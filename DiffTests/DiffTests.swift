// swiftlint:disable line_length
//
//  DiffTests.swift
//  DBDB
//
//  Created by Ruotger Deecke on 17.12.14.
//  Copyright (c) 2014-2016 Deecke,Roddi. All rights reserved.
//
//
// TL/DR; BSD 2-clause license
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
// following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
//    disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
//    following disclaimer in the documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// relax some rules for the test code

import Foundation
import XCTest
@testable import FURRDiff

// long test class is long (which is a good thing in this case, right?)

class DiffTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func assertPrefix<T: Equatable>(arrayA: [T], arrayB: [T], expCommon: [T], expRemainA: [T], expRemainB: [T]) {
        assertCommonPrefix(arrayA: arrayA, arrayB: arrayB, expCommon: expCommon, expRemainA: expRemainA, expRemainB: expRemainB)
        assertCommonPrefix(arrayA: arrayB, arrayB: arrayA, expCommon: expCommon, expRemainA: expRemainB, expRemainB: expRemainA)
    }

    func assertCommonPrefix<T: Equatable>(arrayA: [T], arrayB: [T], expCommon: [T], expRemainA: [T], expRemainB: [T]) {
        let prefix = diff_commonPrefix(arrayA: arrayA, arrayB: arrayB)
        XCTAssert(prefix.count == expCommon.count)

        let commonPrefixAndRemains = diff_removeCommonPrefix(arrayA: arrayA, arrayB: arrayB)
        XCTAssert(commonPrefixAndRemains.common == expCommon)
        XCTAssert(commonPrefixAndRemains.remainingA == expRemainA)
        XCTAssert(commonPrefixAndRemains.remainingB == expRemainB)
    }

    func assertSuffix<T: Equatable>(arrayA: [T], arrayB: [T], expCommon: [T], expRemainA: [T], expRemainB: [T]) {
        assertCommonSuffix(arrayA: arrayA, arrayB: arrayB, expCommon: expCommon, expRemainA: expRemainA, expRemainB: expRemainB)
        assertCommonSuffix(arrayA: arrayB, arrayB: arrayA, expCommon: expCommon, expRemainA: expRemainB, expRemainB: expRemainA)
    }

    func assertCommonSuffix<T: Equatable>(arrayA: [T], arrayB: [T], expCommon: [T], expRemainA: [T], expRemainB: [T]) {
        let suffix = diff_commonSuffix(arrayA: arrayA, arrayB: arrayB)
        XCTAssert(suffix == expCommon)

        let commonSuffixAndRemains = diff_removeCommonSuffix(arrayA: arrayA, arrayB: arrayB)
        XCTAssert(commonSuffixAndRemains.common == expCommon)
        XCTAssert(commonSuffixAndRemains.remainingA == expRemainA)
        XCTAssert(commonSuffixAndRemains.remainingB == expRemainB)
    }

    func thenDiffsShouldNotContainRepeatedDiffTypes<T>(array: [Diff<T>]) {
        if array.count < 2 {
            return
        }

        guard let firstDiff = array.first else {
            XCTFail("there must be a diff!")
            return
        }

        var lastDiffOperation = firstDiff.operation == DiffOperation.delete ? DiffOperation.insert : DiffOperation.delete

        for diff in array {
            XCTAssertNotEqual(lastDiffOperation, diff.operation)
            lastDiffOperation = diff.operation
        }
    }

    func test000_commonPrefix() {
        // no common prefix
        assertPrefix(arrayA: ["a", "b", "c"], arrayB: ["x", "y", "z"], expCommon: [], expRemainA: ["a", "b", "c"], expRemainB: ["x", "y", "z"])
        assertPrefix(arrayA: [0, 1, 2], arrayB: [7, 8, 9], expCommon: [], expRemainA: [0, 1, 2], expRemainB: [7, 8, 9])
        assertPrefix(arrayA: ["aa", "bb", "cc"], arrayB: ["xx", "yy", "zz"], expCommon: [], expRemainA: ["aa", "bb", "cc"], expRemainB: ["xx", "yy", "zz"])

        // some common prefix
        assertPrefix(arrayA: ["1", "2", "3", "4", "a", "b", "c", "d", "e", "f"], arrayB: ["1", "2", "3", "4", "x", "y", "z"], expCommon: ["1", "2", "3", "4"], expRemainA: ["a", "b", "c", "d", "e", "f"], expRemainB: ["x", "y", "z"])
        assertPrefix(arrayA: [0, 1, 2, 3, 4], arrayB: [0, 1, 2, 10, 11], expCommon: [0, 1, 2], expRemainA: [3, 4], expRemainB: [10, 11])

        // complete string is prefix
        assertPrefix(arrayA: ["1", "2", "3", "4"], arrayB: ["1", "2", "3", "4", "x", "y", "z"], expCommon: ["1", "2", "3", "4"], expRemainA: [], expRemainB: ["x", "y", "z"])
        assertPrefix(arrayA: [1, 2, 3], arrayB: [1, 2], expCommon: [1, 2], expRemainA: [3], expRemainB: [])

        // empty string
        assertCommonPrefix(arrayA: [], arrayB: ["x", "y", "z"], expCommon: [], expRemainA: [], expRemainB: ["x", "y", "z"])
    }

    func test001_commonSuffix() {
        // no common suffix
        assertSuffix(arrayA: ["a", "b", "c"], arrayB: ["x", "y", "z"], expCommon: [], expRemainA: ["a", "b", "c"], expRemainB: ["x", "y", "z"])
        assertSuffix(arrayA: [0, 1, 2], arrayB: [7, 8, 9], expCommon: [], expRemainA: [0, 1, 2], expRemainB: [7, 8, 9])

        // common suffix
        assertSuffix(arrayA: ["a", "b", "c", "d", "e", "f", "1", "2", "3", "4"], arrayB: ["x", "y", "z", "1", "2", "3", "4"], expCommon: ["1", "2", "3", "4"], expRemainA: ["a", "b", "c", "d", "e", "f"], expRemainB: ["x", "y", "z"])
        assertSuffix(arrayA: [0, 1, 2], arrayB: [4, 1, 2], expCommon: [1, 2], expRemainA: [0], expRemainB: [4])

        // complete string is suffix
        assertSuffix(arrayA: ["1", "2", "3", "4"], arrayB: ["x", "y", "z", "1", "2", "3", "4"], expCommon: ["1", "2", "3", "4"], expRemainA: [], expRemainB: ["x", "y", "z"])

        // empty string
        assertSuffix(arrayA: ["1", "2", "3", "4"], arrayB: [], expCommon: [], expRemainA: ["1", "2", "3", "4"], expRemainB: [])
    }

    func test002_bisectTest() {
        let arrayA = ["c", "a", "t"]
        let arrayB = ["m", "a", "p"]

        let shouldBe = [
            Diff(operation: .delete, array: ["c"]),
            Diff(operation: .insert, array: ["m"]),
            Diff(operation: .equal, array: ["a"]),
            Diff(operation: .delete, array: ["t"]),
            Diff(operation: .insert, array: ["p"])
        ]

        let isActually = diff_bisectOfArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test_equalOperatorForDiffs() {
        XCTAssert(Diff(operation: .delete, array: ["bla"]) == Diff(operation: .delete, array: ["bla"]))
        XCTAssert(Diff(operation: .delete, array: ["bla"]) == Diff(operation: .delete, array: ["bla"]))
        XCTAssert(Diff(operation: .insert, array: ["bla"]) != Diff(operation: .delete, array: ["bla"]))
        XCTAssert(Diff(operation: .delete, array: ["bla"]) != Diff(operation: .delete, array: ["blubb"]))
    }

    func test003_trivialDiffEmpty() {
        var arrayA: [String] = []
        var arrayB: [String] = []

        var shouldBe: [Diff<String>] = []

        var isActually: [Diff<String>] = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)

        // ----

        arrayA = ["a"]
        arrayB = []
        shouldBe = [Diff(operation: .delete, array: ["a"])]
        isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)

        arrayA = []
        arrayB = ["b"]
        shouldBe = [Diff(operation: .insert, array: ["b"])]
        isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)

    }

    func test004_trivialDiffSame() {
        let arrayA: [String] = ["a", "b", "c"]
        let arrayB: [String] = ["a", "b", "c"]

        let shouldBe = [
            Diff(operation: .equal, array: ["a", "b", "c"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test005_simpleInsertion() {
        let arrayA: [String] = ["a", "b", "c"]
        let arrayB: [String] = ["a", "b", "1", "2", "3", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .equal, array: ["a", "b"]),
            Diff(operation: .insert, array: ["1", "2", "3"]),
            Diff(operation: .equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test006_simpleDeletion() {
        let arrayA: [String] = ["a", "b", "1", "2", "3", "c"]
        let arrayB: [String] = ["a", "b", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .equal, array: ["a", "b"]),
            Diff(operation: .delete, array: ["1", "2", "3"]),
            Diff(operation: .equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test007_twoInsertions() {
        let arrayA: [String] = ["a", "b", "c"]
        let arrayB: [String] = ["a", "1", "2", "3", "b", "4", "5", "6", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .equal, array: ["a"]),
            Diff(operation: .insert, array: ["1", "2", "3"]),
            Diff(operation: .equal, array: ["b"]),
            Diff(operation: .insert, array: ["4", "5", "6"]),
            Diff(operation: .equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test008_twoDeletions() {
        let arrayA: [String] = ["a", "1", "2", "3", "b", "4", "5", "6", "c"]
        let arrayB: [String] = ["a", "b", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .equal, array: ["a"]),
            Diff(operation: .delete, array: ["1", "2", "3"]),
            Diff(operation: .equal, array: ["b"]),
            Diff(operation: .delete, array: ["4", "5", "6"]),
            Diff(operation: .equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test009_simpleCase() {
        let arrayA: [String] = ["a"]
        let arrayB: [String] = ["b"]

        let shouldBe = [
            Diff(operation: .delete, array: ["a"]),
            Diff(operation: .insert, array: ["b"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test010_prettySimpleCase() {
        let arrayA: [String] = ["h", "e", "l", "g", "e"]
        let arrayB: [String] = ["a", "n", "n", "a"]

        let shouldBe = [
            Diff(operation: .delete, array: ["h", "e", "l", "g", "e"]),
            Diff(operation: .insert, array: ["a", "n", "n", "a"])
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test011_prettySimpleCaseWithCharacters() {
        let arrayA = Array(String("helge"))
        let arrayB = Array(String("anna"))

        let shouldBe = [
            Diff(operation: .delete, array: Array(String("helge"))),
            Diff(operation: .insert, array: Array(String("anna")))
        ]

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    func test012_longCase() {
        let aText = "dfhgvsrktzblzbasvfkugkbfgarzkulbdzsasrzlruoiunouizubsvtzkbnuhjmluinsbrtzstbusrxdzsdztkbnsrtztinlukdbzjrthsrtubulz"
        let bText = "dfhgvsrkblzbasvfkugkfzbjdbfgarzkulbdzsasrzlruoiunouizubruwsvtznuhjmluinsbrtzstbusrxdzbkzwksdztkbnsrtztinlukdbzjrthsrtubulz"

        let arrayA = Array(aText)
        let arrayB = Array(bText)

        let isActually = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        self.thenDiffsShouldNotContainRepeatedDiffTypes(array: isActually)
    }

    // this test is more a code coverage test. The debug description is not a vital part
    // so we only make sure it doesn't crash.
    func test013_debugDescription() {
        let arrayA: [String] = ["h", "e", "l", "l", "o"]
        let arrayB: [String] = ["w", "o", "r", "l", "d"]

        let diffs = diffBetweenArrays(arrayA: arrayA, arrayB: arrayB)

        print("debug description: \(diffs)")
    }
}

// swiftlint:enable type_body_length
