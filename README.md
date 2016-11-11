# FURRDiff
a diffing framework for Swift. You can diff two `Array`s of `Equatable`s and will get back an `Array` of `Diff` objects. Each `Diff` object contains an `Array` of the used `Equatable`s and the information whether those were added, removed or stayed the same.

## Getting Started
### Prerequsites
The easiest way to start is using [Carthage](https://github.com/Carthage/Carthage).  

### Installing
Add `github "roddi/FURRDiff"` to your `Cartfile` and you are good to go. You might want to pin to a specific version and not go for `master`. See the Carthage page for all the details.

I haven't come around to doing a `Podfile`. Pull Requests welcome!

### Running the tests
Hit `command-u` in Xcode. 

## Example
For an example look at the last unit test case:

```
    func test013_debugDescription() {
        let a: [String] = ["h", "e", "l", "l", "o"]
        let b: [String] = ["w", "o", "r", "l", "d"]

        let diffs = diffBetweenArrays(arrayA: a, arrayB: b)

        print("debug description: \(diffs)")
    }
```

this will print out:

```
debug description: [delete ["h", "e", "l", "l"], insert ["w"], equal ["o"], insert ["r", "l", "d"]]
```


### Versioning

I use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/roddi/FURRDiff/tags). 

With the beginning of version 0.3 the `master` branch is on Swift 3 now. If you need Swift 2.3 code see the `swift2` branch.

### License

This project is licensed under the MIT License - see the LICENSE file for details
