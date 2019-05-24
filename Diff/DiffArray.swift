// swiftlint:disable line_length
// swiftlint:disable file_length
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

private class Kay {
    var start: Int = 0
    var end: Int = 0
    var index: Int = 0
}

private struct CommonPathParameters<T: Equatable> {
    let vOffset: Int
    let inArrayA: [T]
    let inArrayB: [T]
    let front: Bool
    let delta: Int
    let vLength: Int
}

// swiftlint:disable identifier_name
private func walkFrontPath<T: Equatable>(
    commonParameters: CommonPathParameters<T>,
    currentD: Int,
    kay1: Kay,
    vectors1: inout [Int],
    vectors2: inout [Int]) -> [Diff<T>] {

    while kay1.index <= currentD - kay1.end {
        defer {
            kay1.index += 2
        }
        let k1Offset = commonParameters.vOffset + kay1.index
        var x1 = 0

        if kay1.index == -currentD || (kay1.index != currentD && vectors1[k1Offset - 1] < vectors1[k1Offset + 1]) {
            x1 = vectors1[k1Offset + 1]
        } else {
            x1 = vectors1[k1Offset - 1] + 1
        }

        var y1 = x1 - kay1.index

        // follow the snake!
        while x1 < commonParameters.inArrayA.count && y1 < commonParameters.inArrayB.count && commonParameters.inArrayA[x1] == commonParameters.inArrayB[y1] {
            x1 += 1
            y1 += 1
        }

        vectors1[k1Offset] = x1

        if x1 > commonParameters.inArrayA.count {
            // Ran off the right of the graph.
            kay1.end += 2
        } else if y1 > commonParameters.inArrayB.count {
            // Ran off the bottom of the graph.
            kay1.start += 2
        } else if commonParameters.front {
            let k2Offset = commonParameters.vOffset + commonParameters.delta - kay1.index

            if k2Offset >= 0 && k2Offset < commonParameters.vLength && vectors2[k2Offset] != -1 {
                // Mirror x2 onto top-left coordinate system.
                let x2 = commonParameters.inArrayA.count - vectors2[k2Offset]
                if x1 >= x2 {
                    // diffs = diff_bisectSplitOfStrings(text1, text2, x1, y1, properties);
                    return diff_bisectSplitOfArrays(arrayA: commonParameters.inArrayA, arrayB: commonParameters.inArrayB, x: x1, y: y1)
                }
            }
        }
    }
    return []
}

private func walkReversePath<T: Equatable>(
    commonParameters: CommonPathParameters<T>,
    currentD: Int,
    kay2: Kay,
    vectors1: inout [Int],
    vectors2: inout [Int]) -> [Diff<T>] {

    while kay2.index <= currentD - kay2.end {

        defer {
            kay2.index += 2
        }
        let k2Offset = commonParameters.vOffset + kay2.index
        var x2 = 0

        if kay2.index == -currentD || (kay2.index != currentD && vectors2[k2Offset - 1] < vectors2[k2Offset + 1]) {
            x2 = vectors2[k2Offset + 1]
        } else {
            x2 = vectors2[k2Offset - 1] + 1
        }

        var y2 = x2 - kay2.index

        while x2 < commonParameters.inArrayA.count && y2 < commonParameters.inArrayB.count && (commonParameters.inArrayA[commonParameters.inArrayA.count - x2 - 1] == commonParameters.inArrayB[commonParameters.inArrayB.count - y2 - 1]) {
            x2 += 1
            y2 += 1
        }

        vectors2[k2Offset] = x2

        if x2 > commonParameters.inArrayA.count {
            // Ran off the left of the graph.
            kay2.end += 2
        } else if y2 > commonParameters.inArrayB.count {
            // Ran off the top of the graph.
            kay2.start += 2
        } else if !commonParameters.front {
            let k1Offset = commonParameters.vOffset + commonParameters.delta - kay2.index

            if k1Offset >= 0 && k1Offset < commonParameters.vLength && vectors1[k1Offset] != -1 {
                let x1 = vectors1[k1Offset]
                let y1 = commonParameters.vOffset + x1 - k1Offset
                // Mirror x2 onto top-left coordinate system.
                x2 = commonParameters.inArrayA.count - x2

                if x1 >= x2 {
                    // Overlap detected.
                    return diff_bisectSplitOfArrays(arrayA: commonParameters.inArrayA, arrayB: commonParameters.inArrayB, x: x1, y: y1)
                }
            }
        }
    }
    return []
}
// swiftlint:enable identifier_name

// yes this method is way too long. Pull requests welcome!
func diff_bisectOfArrays<T: Equatable>(arrayA inArrayA: [T], arrayB inArrayB: [T]) -> [Diff<T>] {
    let maxD = (inArrayA.count + inArrayB.count + 1) / 2
    let vOffset = maxD
    var vLength = 2 * maxD

    if vLength <= vOffset + 2 {
        vLength = vOffset + 2
    }

    var vectors1: [Int] = []
    var vectors2: [Int] = []

    for _ in 0..<vLength {
        vectors1.append(-1)
        vectors2.append(-1)
    }
    vectors1[vOffset + 1] = 0
    vectors2[vOffset + 1] = 0

    let delta = inArrayA.count - inArrayB.count

    // If the total number of characters is odd, then the front path will collide with the reverse path.
    let front = delta % 2 != 0

    // Offsets for start and end of k loop. Prevents mapping of space beyond the grid.
    let kay1 = Kay()
    let kay2 = Kay()

    let commonParameters = CommonPathParameters(vOffset: vOffset, inArrayA: inArrayA, inArrayB: inArrayB, front: front, delta: delta, vLength: vLength)

    for currentD in 0..<maxD {

        // Walk the front path one step.
        kay1.index = -currentD + kay1.start
        let frontDiffs = walkFrontPath(
            commonParameters: commonParameters,
            currentD: currentD,
            kay1: kay1,
            vectors1: &vectors1,
            vectors2: &vectors2)

        if !frontDiffs.isEmpty {
            return frontDiffs
        }

        // Walk the reverse path one step.
        kay2.index = -currentD + kay2.start
        let reverseDiffs = walkReversePath(
            commonParameters: commonParameters,
            currentD: currentD,
            kay2: kay2,
            vectors1: &vectors1,
            vectors2: &vectors2)

        if !reverseDiffs.isEmpty {
            return reverseDiffs
        }
    }

    // we haven't found a snake at all so we couldn't cut the problem in half.
    // This means we have no common element. Just add the diffs straight away.
    return [Diff(operation: .delete, array: inArrayA), Diff(operation: .insert, array: inArrayB)]
}
// swiftlint:enable function_body_length

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
