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
    case Delete
    case Insert
    case Equal

    func debugDescription() -> String {
        switch self {
        case .Delete:
            return "delete"
        case .Equal:
            return "equal"
        case .Insert:
            return "insert"
        }
    }
}

public class Diff<T:Equatable>: Equatable, CustomDebugStringConvertible {
    public var operation: DiffOperation
    public var array: Array<T>

    init(operation inOperation: DiffOperation, array inArray: Array<T>) {
        assert(inArray.count != 0, "array may not be empty")
        self.operation = inOperation
        self.array = inArray
    }

    public var debugDescription: String {
        get {
            var result: String = self.operation.debugDescription()
            result = result + " " + self.array.debugDescription

            return result
        }

    }
}



public func == <T: Equatable> (lhs: Diff<T>, rhs: Diff<T>) -> Bool {
    if lhs.operation != rhs.operation {
        return false
    }

    return lhs.array == rhs.array
}


func diff_commonPrefix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> Array<T> {
    let smallerCount = (inArrayA.count < inArrayB.count) ? inArrayA.count : inArrayB.count

    var common: Array<T> = []

    for i in 0 ..< smallerCount {
        if inArrayA[i] != inArrayB[i] {
            break
        } else {
            common.append(inArrayA[i])
        }
    }

    return common
}

func diff_commonSuffix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> Array<T> {
    let smallerCount = (inArrayA.count < inArrayB.count) ? inArrayA.count : inArrayB.count

    var commonReversed: Array<T> = []

    for i in 0 ..< smallerCount {
        if inArrayA[inArrayA.count - 1 - i] != inArrayB[inArrayB.count - 1 - i] {
            break
        } else {
            commonReversed.append(inArrayA[inArrayA.count - 1 - i])
        }
    }

    let common = commonReversed.reversed()

    return common
}

private func diff_subArrayToIndex<T>(array inArray: Array<T>, index inIndex: Int) -> Array<T> {
    let result = Array(inArray[0..<inIndex])
    return result
}

private func diff_subArrayFromIndex<T>(array inArray: Array<T>, index inIndex: Int) -> Array<T> {
    let result = Array(inArray[inIndex..<inArray.endIndex])
    return result
}

private func diff_appendDiffsAndCompact<T>(array inArray: Array<Diff<T>>, diffs: Array<Diff<T>>) -> Array<Diff<T>> {
    var result = inArray
    for diff in diffs {
        result = diff_appendDiffAndCompact(array: result, diff: diff)
    }
    return result
}

private func diff_appendDiffAndCompact<T>(array inArray: Array<Diff<T>>, diff: Diff<T>) -> Array<Diff<T>> {
    guard let lastDiff = inArray.last else {
        return [diff]
    }

    if diff.operation == lastDiff.operation {
        #if swift(>=3.0)
            lastDiff.array.append(contentsOf:diff.array)
        #else
            lastDiff.array.appendContentsOf(diff.array)
        #endif
        return inArray
    }

    var newArray = inArray
    newArray.append(diff)
    return newArray
}

func diff_removeCommonPrefix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> (common: Array<T>, remainingA: Array<T>, remainingB: Array<T>) {
    let commonPrefix = diff_commonPrefix(arrayA: inArrayA, arrayB: inArrayB)
    let remainingArrayA = diff_subArrayFromIndex(array: inArrayA, index: commonPrefix.count)
    let remainingArrayB = diff_subArrayFromIndex(array: inArrayB, index: commonPrefix.count)
    return (commonPrefix, remainingArrayA, remainingArrayB)
}

func diff_removeCommonSuffix<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> (common: Array<T>, remainingA: Array<T>, remainingB: Array<T>) {
    let commonSuffix = diff_commonSuffix(arrayA: inArrayA, arrayB: inArrayB)
    let restOfArrayA = diff_subArrayToIndex(array: inArrayA, index: inArrayA.count - commonSuffix.count)
    let restOfArrayB = diff_subArrayToIndex(array: inArrayB, index: inArrayB.count - commonSuffix.count)
    return (commonSuffix, restOfArrayA, restOfArrayB)
}

public func diffBetweenArrays<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> Array<Diff<T>> {

    // Check for equality (speedup).
    if inArrayA == inArrayB {
        if inArrayA.count != 0 {
            return [Diff(operation:.Equal, array: inArrayA)]
        }
        return []
    }

    var resultDiffs: Array<Diff<T>> = Array()

    // Trim off common prefix (speedup).
    let (commonPrefix, remainingSuffixArrayA, remainingSuffixArrayB) = diff_removeCommonPrefix(arrayA: inArrayA, arrayB: inArrayB)

    // Trim off common suffix (speedup).
    let (commonSuffix, remainingArrayA, remainingArrayB) = diff_removeCommonSuffix(arrayA: remainingSuffixArrayA, arrayB: remainingSuffixArrayB)

    // add common suffix as equal
    if commonPrefix.count != 0 {
        resultDiffs = diff_appendDiffAndCompact(array: resultDiffs, diff: Diff(operation:.Equal, array: commonPrefix))
    }

    // diff the remaining part
    let middlePart = diff_computeDiffsBetweenArrays(arrayA: remainingArrayA, arrayB: remainingArrayB)
    resultDiffs = diff_appendDiffsAndCompact(array: resultDiffs, diffs: middlePart)

    // add the common suffix as equal
    if commonSuffix.count != 0 {
        resultDiffs = diff_appendDiffAndCompact(array: resultDiffs, diff: Diff(operation:.Equal, array: commonSuffix))
    }

    return resultDiffs
}


private func diff_computeDiffsBetweenArrays<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> Array<Diff<T>> {
    if inArrayA.count == 0 && inArrayB.count == 0 {
        // this case is not covered by the tests so I put a assert here.
        // please file a bug if it is hit!
        assertionFailure("Please file a bug!")
        return []
    }

    if inArrayA.count == 0 {
        // Just add some text (speedup).
        return [Diff(operation:.Insert, array:inArrayB)]
    }

    if inArrayB.count == 0 {
        // Just delete some text (speedup).
        return [Diff(operation:.Delete, array:inArrayA)]
    }

    var longArray = inArrayA.count > inArrayB.count ? inArrayA : inArrayB
    var shortArray = inArrayA.count > inArrayB.count ? inArrayB : inArrayA

    if shortArray.count == 1 && longArray.count == 1 {
        // Single character strings.
        if shortArray[0] == longArray[0] {
            // this case is not covered by the tests so I put a assert here.
            // please file a bug if it is hit!
            assertionFailure("Please file a bug!")
            return [Diff(operation: .Equal, array: shortArray)]
        }

        return [
            Diff(operation: .Delete, array: inArrayA),
            Diff(operation: .Insert, array: inArrayB),
        ]
    }

    return diff_bisectOfArrays(arrayA: inArrayA, arrayB: inArrayB)
}

// yes this method is way too long. Pull requests welcome!

// swiftlint:disable function_body_length
func diff_bisectOfArrays<T: Equatable>(arrayA inArrayA: Array<T>, arrayB inArrayB: Array<T>) -> Array<Diff<T>> {
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

    var v1: Array<Int> = Array()
    var v2: Array<Int> = Array()

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
        // we have not found a shortest snake so we couldn't cut the problem in half.
        // This means we have no common element. Just add the diffs straight away.
        diffs = [Diff(operation: .Delete, array: inArrayA)]
        #if swift(>=3.0)
            diffs.append(contentsOf:[Diff(operation: .Insert, array: inArrayB)])
        #else
            diffs.appendContentsOf([Diff(operation: .Insert, array: inArrayB)])
        #endif
    }

    return diffs
}
// swiftlint:enable function_body_length

private func diff_bisectSplitOfArrays<T: Equatable>(arrayA inArrayA: Array<T>,
                                      arrayB inArrayB: Array<T>,
                                      x inX: Int,
                                      y inY: Int) -> Array<Diff<T>> {
    let arrayAa = diff_subArrayToIndex(array: inArrayA, index: inX)
    let arrayBa = diff_subArrayToIndex(array: inArrayB, index: inY)
    let arrayAb = diff_subArrayFromIndex(array: inArrayA, index: inX)
    let arrayBb = diff_subArrayFromIndex(array: inArrayB, index: inY)

    let diffsA = diffBetweenArrays(arrayA: arrayAa, arrayB: arrayBa)
    let diffsB = diffBetweenArrays(arrayA: arrayAb, arrayB: arrayBb)

    let diffs = diff_appendDiffsAndCompact(array: diffsA, diffs: diffsB)

    return diffs
}
