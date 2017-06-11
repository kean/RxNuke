# CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build RxNuke.

To integrate RxNuke into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'RxNuke'
end
```

Then, run the following command:

```bash
$ pod install
```

# Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate RxNuke into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "kean/RxNuke"
```

Run `carthage update` to build the framework and drag the built `RxNuke.framework` into your Xcode project.
