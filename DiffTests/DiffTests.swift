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

import Foundation
import XCTest
@testable import FURRDiff

// long test class is long (which is a good thing in this case, right?)

// swiftlint:disable type_body_length
class DiffTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func assertPrefix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>, expCommon inCommon: Array<T>, expRemainA inRemainA: Array<T>, expRemainB inRemainB: Array<T>) {
        assertCommonPrefix(arrayA: inArrayA, arrayB: inArrayB, expCommon: inCommon, expRemainA: inRemainA, expRemainB: inRemainB)
        assertCommonPrefix(arrayA: inArrayB, arrayB: inArrayA, expCommon: inCommon, expRemainA: inRemainB, expRemainB: inRemainA)
    }

    func assertCommonPrefix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>, expCommon inCommon: Array<T>, expRemainA inRemainA: Array<T>, expRemainB inRemainB: Array<T>) {
        let prefix = diff_commonPrefix(arrayA: inArrayA, arrayB: inArrayB)
        XCTAssert(prefix.count == inCommon.count)

        let (commonPrefix, remainA, remainB) = diff_removeCommonPrefix(arrayA:inArrayA, arrayB:inArrayB)
        XCTAssert(commonPrefix == inCommon)
        XCTAssert(remainA == inRemainA)
        XCTAssert(remainB == inRemainB)
    }

    func assertSuffix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>, expCommon inCommon: Array<T>, expRemainA inRemainA: Array<T>, expRemainB inRemainB: Array<T>) {
        assertCommonSuffix(arrayA: inArrayA, arrayB: inArrayB, expCommon: inCommon, expRemainA: inRemainA, expRemainB: inRemainB)
        assertCommonSuffix(arrayA: inArrayB, arrayB: inArrayA, expCommon: inCommon, expRemainA: inRemainB, expRemainB: inRemainA)
    }

    func assertCommonSuffix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>, expCommon inCommon: Array<T>, expRemainA inRemainA: Array<T>, expRemainB inRemainB: Array<T>) {
        let suffix = diff_commonSuffix(arrayA: inArrayA, arrayB: inArrayB)
        XCTAssert(suffix == inCommon)

        let (common, remainA, remainB) = diff_removeCommonSuffix(arrayA: inArrayA, arrayB: inArrayB)
        XCTAssert(common == inCommon)
        XCTAssert(remainA == inRemainA)
        XCTAssert(remainB == inRemainB)
    }

    #if swift(>=3.0)
    func thenDiffsShouldNotContainRepeatedDiffTypes<T: Equatable>(_ array: Array<Diff<T>>) {
        thenDiffsShouldNotContainRepeatedDiffTypes(array: array)
    }
    #endif

    func thenDiffsShouldNotContainRepeatedDiffTypes<T: Equatable>(array: Array<Diff<T>>) {
        if array.count < 2 {
            return
        }

        guard let firstDiff = array.first else {
            XCTFail()
            return
        }

        var lastDiffOperation = firstDiff.operation == DiffOperation.Delete ? DiffOperation.Insert : DiffOperation.Delete

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
        let a = ["c", "a", "t"]
        let b = ["m", "a", "p"]

        let shouldBe = [
            Diff(operation: .Delete, array: ["c"]),
            Diff(operation: .Insert, array: ["m"]),
            Diff(operation: .Equal, array: ["a"]),
            Diff(operation: .Delete, array: ["t"]),
            Diff(operation: .Insert, array: ["p"])
        ]

        let isActually = diff_bisectOfArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test_equalOperatorForDiffs() {
        XCTAssert(Diff(operation: .Delete, array: ["bla"]) == Diff(operation: .Delete, array: ["bla"]))
        XCTAssert(Diff(operation: .Delete, array: ["bla"]) == Diff(operation: .Delete, array: ["bla"]))
        XCTAssert(Diff(operation: .Insert, array: ["bla"]) != Diff(operation: .Delete, array: ["bla"]))
        XCTAssert(Diff(operation: .Delete, array: ["bla"]) != Diff(operation: .Delete, array: ["blubb"]))
    }

    func test003_trivialDiffEmpty() {
        var a: [String] = []
        var b: [String] = []

        var shouldBe: Array<Diff<String> > = []

        var isActually: Array<Diff<String> > = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)

        // ----

        a = ["a"]
        b = []
        shouldBe = [Diff(operation: .Delete, array: ["a"])]
        isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)

        a = []
        b = ["b"]
        shouldBe = [Diff(operation: .Insert, array: ["b"])]
        isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)

    }

    func test004_trivialDiffSame() {
        let a: [String] = ["a", "b", "c"]
        let b: [String] = ["a", "b", "c"]

        let shouldBe = [
            Diff(operation: .Equal, array: ["a", "b", "c"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test005_simpleInsertion() {
        let a: [String] = ["a", "b", "c"]
        let b: [String] = ["a", "b", "1", "2", "3", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .Equal, array: ["a", "b"]),
            Diff(operation: .Insert, array: ["1", "2", "3"]),
            Diff(operation: .Equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }


    func test006_simpleDeletion() {
        let a: [String] = ["a", "b", "1", "2", "3", "c"]
        let b: [String] = ["a", "b", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .Equal, array: ["a", "b"]),
            Diff(operation: .Delete, array: ["1", "2", "3"]),
            Diff(operation: .Equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test007_twoInsertions() {
        let a: [String] = ["a", "b", "c"]
        let b: [String] = ["a", "1", "2", "3", "b", "4", "5", "6", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .Equal, array: ["a"]),
            Diff(operation: .Insert, array: ["1", "2", "3"]),
            Diff(operation: .Equal, array: ["b"]),
            Diff(operation: .Insert, array: ["4", "5", "6"]),
            Diff(operation: .Equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test008_twoDeletions() {
        let a: [String] = ["a", "1", "2", "3", "b", "4", "5", "6", "c"]
        let b: [String] = ["a", "b", "c"]

        let shouldBe: [Diff<String>] = [
            Diff(operation: .Equal, array: ["a"]),
            Diff(operation: .Delete, array: ["1", "2", "3"]),
            Diff(operation: .Equal, array: ["b"]),
            Diff(operation: .Delete, array: ["4", "5", "6"]),
            Diff(operation: .Equal, array: ["c"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test009_simpleCase() {
        let a: [String] = ["a"]
        let b: [String] = ["b"]

        let shouldBe = [
            Diff(operation: .Delete, array: ["a"]),
            Diff(operation: .Insert, array: ["b"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test010_prettySimpleCase() {
        let a: [String] = ["h", "e", "l", "g", "e"]
        let b: [String] = ["a", "n", "n", "a"]

        let shouldBe = [
            Diff(operation: .Delete, array: ["h", "e", "l", "g", "e"]),
            Diff(operation: .Insert, array: ["a", "n", "n", "a"])
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test011_prettySimpleCaseWithCharacters() {
        let a = Array(String("helge").characters)
        let b = Array(String("anna").characters)

        let shouldBe = [
            Diff(operation: .Delete, array: Array(String("helge").characters)),
            Diff(operation: .Insert, array: Array(String("anna").characters))
        ]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        XCTAssertEqual(shouldBe, isActually, "...")
        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    func test012_longCase() {
        let aText = "dfhgvsrktzblzbasvfkugkbfgarzkulbdzsasrzlruoiunouizubsvtzkbnuhjmluinsbrtzstbusrxdzsdztkbnsrtztinlukdbzjrthsrtubulz"
        let bText = "dfhgvsrkblzbasvfkugkfzbjdbfgarzkulbdzsasrzlruoiunouizubruwsvtznuhjmluinsbrtzstbusrxdzbkzwksdztkbnsrtztinlukdbzjrthsrtubulz"

        let a = Array(aText.characters)
        let b = Array(bText.characters)

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        self.thenDiffsShouldNotContainRepeatedDiffTypes(isActually)
    }

    // this test is more a code coverage test. The debug description is not a vital part
    // so we only make sure it doesn't crash.
    func test013_debugDescription() {
        let a: [String] = ["h", "e", "l", "g", "a"]
        let b: [String] = ["a", "n", "n", "a"]

        let isActually = diffBetweenArrays(arrayA: a, arrayB: b)

        print("debug description: \(isActually)")
    }
}


// swiftlint:enable type_body_length
