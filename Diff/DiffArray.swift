// swiftlint:disable line_length
// swiftlint:disable file_length
// swiftlint:disable cyclomatic_complexity
//
//  DiffArray.swift
//  DBDB
//
//  Created by Deecke,Roddi on 11.12.14.
//  Copyright (c) 2014 Deecke,Roddi. All rights reserved.
//

import Foundation
import FURRExtensions

public enum DiffOperation {
    case delete
    case insert
    case equal

    func debugDescription() -> String {
        switch self {
        case .delete:
            return "delete"
        case .equal:
            return "equal"
        case .insert:
            return "insert"
        }
    }
}

public class Diff<T: Equatable>: Equatable, CustomDebugStringConvertible {
    public let operation: DiffOperation
    public var array: [T]

    init(operation: DiffOperation, array: [T]) {
        assert(array.count != 0, "array may not be empty")
        self.operation = operation
        self.array = array
    }

    public var debugDescription: String {
        var result: String = self.operation.debugDescription()
        result += " " + self.array.debugDescription

        return result
    }
}

public func == <T> (lhs: Diff<T>, rhs: Diff<T>) -> Bool {
    if lhs.operation != rhs.operation {
        return false
    }

    return lhs.array == rhs.array
}

func diff_commonPrefix<T: Equatable>(arrayA: [T], arrayB: [T]) -> [T] {
    let smallerCount = (arrayA.count < arrayB.count) ? arrayA.count : arrayB.count

    var common: [T] = []

    for idx in 0 ..< smallerCount {
        if arrayA[idx] != arrayB[idx] {
            break
        } else {
            common.append(arrayA[idx])
        }
    }

    return common
}

func diff_commonSuffix<T: Equatable>(arrayA: [T], arrayB: [T]) -> [T] {
    let smallerCount = (arrayA.count < arrayB.count) ? arrayA.count : arrayB.count

    var commonReversed: [T] = []

    for idx in 0 ..< smallerCount {
        if arrayA[arrayA.count - 1 - idx] != arrayB[arrayB.count - 1 - idx] {
            break
        } else {
            commonReversed.append(arrayA[arrayA.count - 1 - idx])
        }
    }

    let common = commonReversed.reversed()

    return common
}

private func diff_subArrayToIndex<T>(array inArray: [T], index inIndex: Int) -> [T] {
    let result = Array(inArray[0..<inIndex])
    return result
}

private func diff_subArrayFromIndex<T>(array inArray: [T], index inIndex: Int) -> [T] {
    let result = Array(inArray[inIndex..<inArray.endIndex])
    return result
}

private func diff_appendDiffsAndCompact<T>(array inArray: [Diff<T>], diffs: [Diff<T>]) -> [Diff<T>] {
    var result = inArray
    for diff in diffs {
        result = diff_appendDiffAndCompact(array: result, diff: diff)
    }
    return result
}

private func diff_appendDiffAndCompact<T>(array inArray: [Diff<T>], diff: Diff<T>) -> [Diff<T>] {
    guard let lastDiff = inArray.last else {
        return [diff]
    }

    if diff.operation == lastDiff.operation {
        lastDiff.array.append(contentsOf: diff.array)
        return inArray
    }

    var newArray = inArray
    newArray.append(diff)
    return newArray
}

internal struct DiffCommonAndRemaining<T: Equatable> {
    let common: [T]
    let remainingA: [T]
    let remainingB: [T]
}

func diff_removeCommonPrefix<T: Equatable>(arrayA inArrayA: [T], arrayB inArrayB: [T]) -> DiffCommonAndRemaining<T> {
    let commonPrefix = diff_commonPrefix(arrayA: inArrayA, arrayB: inArrayB)
    let remainingArrayA = diff_subArrayFromIndex(array: inArrayA, index: commonPrefix.count)
    let remainingArrayB = diff_subArrayFromIndex(array: inArrayB, index: commonPrefix.count)
    return DiffCommonAndRemaining(common: commonPrefix, remainingA: remainingArrayA, remainingB: remainingArrayB)
}

func diff_removeCommonSuffix<T: Equatable>(arrayA inArrayA: [T], arrayB inArrayB: [T]) -> DiffCommonAndRemaining<T> {
    let commonSuffix = diff_commonSuffix(arrayA: inArrayA, arrayB: inArrayB)
    let restOfArrayA = diff_subArrayToIndex(array: inArrayA, index: inArrayA.count - commonSuffix.count)
    let restOfArrayB = diff_subArrayToIndex(array: inArrayB, index: inArrayB.count - commonSuffix.count)
    return DiffCommonAndRemaining(common: commonSuffix, remainingA: restOfArrayA, remainingB: restOfArrayB)
}

public func diffBetweenArrays<T: Equatable>(arrayA inArrayA: [T], arrayB inArrayB: [T]) -> [Diff<T>] {

    // Check for equality (speedup).
    if inArrayA == inArrayB {
        if inArrayA.count != 0 {
            return [Diff(operation: .equal, array: inArrayA)]
        }
        return []
    }

    var resultDiffs: [Diff<T>] = []

    // e.g.
    // A: [111222333]
    // B: [111444333]

    // Trim off common prefix (speedup).
    let commonPrefixAndRemaining = diff_removeCommonPrefix(arrayA: inArrayA, arrayB: inArrayB)

    // commonPrefix: [111]
    // remainingA:       [222333]
    // remainingB:       [444333]

    // Trim off common suffix (speedup).
    let commonSuffixAndRemaining = diff_removeCommonSuffix(arrayA: commonPrefixAndRemaining.remainingA, arrayB: commonPrefixAndRemaining.remainingB)

    // commonPrefix:     [333]
    // remainingA:   [222]
    // remainingB:   [444]

    // add common prefix as equal
    if commonPrefixAndRemaining.common.count != 0 {
        resultDiffs = diff_appendDiffAndCompact(array: resultDiffs, diff: Diff(operation: .equal, array: commonPrefixAndRemaining.common))
    }

    // [eq: 111]

    // diff the remaining part
    let middlePart = diff_computeDiffsBetweenArrays(arrayA: commonSuffixAndRemaining.remainingA, arrayB: commonSuffixAndRemaining.remainingB)
    resultDiffs = diff_appendDiffsAndCompact(array: resultDiffs, diffs: middlePart)

    // [eq: 111][..: ...][..: ...]

    // add the common suffix as equal
    if commonSuffixAndRemaining.common.count != 0 {
        resultDiffs = diff_appendDiffAndCompact(array: resultDiffs, diff: Diff(operation: .equal, array: commonSuffixAndRemaining.common))
    }

    // [eq: 111][..: ...][..: ...][eq: 333]

    return resultDiffs
}

private func diff_computeDiffsBetweenArrays<T: Equatable>(arrayA: [T], arrayB: [T]) -> [Diff<T>] {
    if arrayA.count == 0 && arrayB.count == 0 {
        // this case is not covered by the tests so I put a assert here.
        // please file a bug if it is hit!
        assertionFailure("Please file a bug!")
        return []
    }

    if arrayA.count == 0 {
        // Just add some text (speedup).
        return [Diff(operation: .insert, array: arrayB)]
    }

    if arrayB.count == 0 {
        // Just delete some text (speedup).
        return [Diff(operation: .delete, array: arrayA)]
    }

    var longArray = arrayA.count > arrayB.count ? arrayA : arrayB
    var shortArray = arrayA.count > arrayB.count ? arrayB : arrayA

    if shortArray.count == 1 && longArray.count == 1 {
        // Single character strings.
        if shortArray[0] == longArray[0] {
            // this case is not covered by the tests so I put a assert here.
            // please file a bug if it is hit!
            assertionFailure("Please file a bug!")
            return [Diff(operation: .equal, array: shortArray)]
        }

        let delete = Diff<T>(operation: .delete, array: arrayA)
        let insert = Diff<T>(operation: .insert, array: arrayB)
        return [delete, insert]
    }

    return diff_bisectOfArrays(arrayA: arrayA, arrayB: arrayB)
}

// yes this method is way too long. Pull requests welcome!

// swiftlint:disable function_body_length
// swiftlint:disable identifier_name
func diff_bisectOfArrays<T: Equatable>(arrayA inArrayA: [T], arrayB inArrayB: [T]) -> [Diff<T>] {
    let arrayALength = inArrayA.count
    let arrayBLength = inArrayB.count
    var haveFoundDiffs = false
    var diffs: [Diff<T>]  = []

    let maxD = (arrayALength + arrayBLength + 1) / 2
    let vOffset = maxD
    var vLength = 2 * maxD

    if vLength <= vOffset + 2 {
        vLength = vOffset + 2
    }

    var v1: [Int] = []
    var v2: [Int] = []

    for _ in 0..<vLength {
        v1.append(-1)
        v2.append(-1)
    }

    v1[vOffset + 1] = 0
    v2[vOffset + 1] = 0

    let delta = arrayALength - arrayBLength

    // If the total number of characters is odd, then the front path will collide with the reverse path.
    let front = delta % 2 != 0
    // BOOL front = (delta % 2 != 0);

    // Offsets for start and end of k loop. Prevents mapping of space beyond the grid.
    var k1start = 0
    var k1end = 0
    var k2start = 0
    var k2end = 0

    //
    for d in 0..<maxD {

        // Walk the front path one step.
        var k1 = -d + k1start
        while k1 <= d - k1end {
            defer {
                k1 += 2
            }
            let k1_offset = vOffset + k1
            var x1 = 0

            if k1 == -d || (k1 != d && v1[k1_offset - 1] < v1[k1_offset + 1]) {
                x1 = v1[k1_offset + 1]
            } else {
                x1 = v1[k1_offset - 1] + 1
            }

            var y1 = x1 - k1

            // follow the snake!
            while x1 < arrayALength && y1 < arrayBLength && inArrayA[x1] == inArrayB[y1] {
                x1 += 1
                y1 += 1
            }

            v1[k1_offset] = x1

            if x1 > arrayALength {
                // Ran off the right of the graph.
                k1end += 2
            } else if y1 > arrayBLength {
                // Ran off the bottom of the graph.
                k1start += 2
            } else if front {
                let k2_offset = vOffset + delta - k1

                if k2_offset >= 0 && k2_offset < vLength && v2[k2_offset] != -1 {
                    // Mirror x2 onto top-left coordinate system.
                    let x2 = arrayALength - v2[k2_offset]
                    if x1 >= x2 {
                        // diffs = diff_bisectSplitOfStrings(text1, text2, x1, y1, properties);
                        diffs = diff_bisectSplitOfArrays(arrayA: inArrayA, arrayB: inArrayB, x: x1, y: y1)
                        haveFoundDiffs = true
                        break
                    }
                }
            }
        }

        if haveFoundDiffs {
            break
        }

        // Walk the reverse path one step.
        var k2 = -d + k2start
        while  k2 <= d - k2end {

            defer {
                k2 += 2
            }
            let k2_offset = vOffset + k2
            var x2 = 0

            if k2 == -d || (k2 != d && v2[k2_offset - 1] < v2[k2_offset + 1]) {
                x2 = v2[k2_offset + 1]
            } else {
                x2 = v2[k2_offset - 1] + 1
            }

            var y2 = x2 - k2

            while x2 < arrayALength && y2 < arrayBLength && (inArrayA[arrayALength - x2 - 1] == inArrayB[arrayBLength - y2 - 1]) {
                x2 += 1
                y2 += 1
            }

            v2[k2_offset] = x2

            if x2 > arrayALength {
                // Ran off the left of the graph.
                k2end += 2
            } else if y2 > arrayBLength {
                // Ran off the top of the graph.
                k2start += 2
            } else if !front {
                let k1_offset = vOffset + delta - k2

                if k1_offset >= 0 && k1_offset < vLength && v1[k1_offset] != -1 {
                    let x1 = v1[k1_offset]
                    let y1 = vOffset + x1 - k1_offset
                    // Mirror x2 onto top-left coordinate system.
                    x2 = arrayALength - x2

                    if x1 >= x2 {
                        // Overlap detected.
                        diffs = diff_bisectSplitOfArrays(arrayA: inArrayA, arrayB: inArrayB, x: x1, y: y1)
                        haveFoundDiffs = true
                        break
                    }
                }
            }
        }

        if haveFoundDiffs {
            break
        }
    }

    if !haveFoundDiffs {
        // we haven't found a snake at all so we couldn't cut the problem in half.
        // This means we have no common element. Just add the diffs straight away.
        diffs = [Diff(operation: .delete, array: inArrayA), Diff(operation: .insert, array: inArrayB)]
    }

    return diffs
}
// swiftlint:enable function_body_length
// swiftlint:enable identifier_name

private func diff_bisectSplitOfArrays<T: Equatable>(arrayA inArrayA: [T], arrayB inArrayB: [T], x inX: Int, y inY: Int) -> [Diff<T>] {
    let arrayAa = diff_subArrayToIndex(array: inArrayA, index: inX)
    let arrayBa = diff_subArrayToIndex(array: inArrayB, index: inY)
    let arrayAb = diff_subArrayFromIndex(array: inArrayA, index: inX)
    let arrayBb = diff_subArrayFromIndex(array: inArrayB, index: inY)

    let diffsA = diffBetweenArrays(arrayA: arrayAa, arrayB: arrayBa)
    let diffsB = diffBetweenArrays(arrayA: arrayAb, arrayB: arrayBb)

    let diffs = diff_appendDiffsAndCompact(array: diffsA, diffs: diffsB)

    return diffs
}
