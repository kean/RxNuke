<p align="center"><img src="https://user-images.githubusercontent.com/1567433/27010376-bc53fa6c-4eab-11e7-9ce3-7d49063fce7f.png" height="180"/>

<p align="center">
<img src="https://img.shields.io/cocoapods/v/RxNuke.svg?label=version">
<img src="https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-green.svg">
<img src="https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg">
</p>

[RxSwift](https://github.com/ReactiveX/RxSwift) extensions for [Nuke](https://github.com/kean/Nuke).

```swift
public protocol Loading {
    func loadImage(with url: URL) -> RxSwift.Single<Image>
    func loadImage(with urlRequest: URLRequest) -> RxSwift.Single<Image>
    func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image>
}
```

> See [Traits](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#single) to learn more about `Single`

# <a name="h_usage"></a>Usage

## Basics

Let's start with the basics. Here's an example of how to use a new `RxNuke.Loading` implemented by `Nuke.Manager` to load an image and display the result on success.

```swift
Nuke.Manager.shared.loadImage(with: url)
    .observeOn(MainScheduler.instance)
    .subscribe(onSuccess: { imageView.image = $0 })
    .disposed(by: disposeBag)
```


## Going From Low to High Resolution

Suppose you want to show users a high-resolution, slow-to-download image. Rather than let them stare a placeholder for a while, you might want to quickly download a smaller thumbnail first. There are at least two ways to implement this using `RxNuke`.

1. Uses [`concat`](http://reactivex.io/documentation/operators/concat.html) operator that results in a **serial** execution. It would first start a thumbnal request, wait until it finishes, and only then start a request for a high-resolution image.

```swift
Observable.concat(loader.loadImage(with: lowResUrl).orEmpty,
                  loader.loadImage(with: highResUtl).orEmpty)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
```swift

> `orEmpty` is a custom operator which dismisses errors and complete the sequence instead
> (equivalent to `func catchErrorJustComplete()` from [RxSwiftExt](https://github.com/RxSwiftCommunity/RxSwiftExt)

2. Uses [`switch`](http://reactivex.io/documentation/operators/switch.html) operator that results in a **concurrent** execution. Both of the requests are going to be started at the same time. If the high-resolution requests finishes first the thumbnail request get cancelled.

// FIXME:


## Loading the First Available Image

Suppose you have multiple URLs for the same image. For instance, you might have uploaded an image taken from the camera. In such case, it would be beneficial to first try to get the local URL, and if even that fails, try to get the network URL. It would be a shame to download the image that we may have already locally.

```swift
Observable.concat(loader.loadImage(with: localUrl).orEmpty,
                  loader.loadImage(with: networkUrl).orEmpty)
    .take(1)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
```

> This use case is very similar "Going From Low to High Resolution", but an addition of `.take(1)` gurantees that we stop execution as soon as we receive the first result.


## Showing Stale Image While Validating It

Suppose you want to show users a stale image stored in a disk cache (`Foundation.URLCache`) while you go to the server to validate it.

```swift
let cacheRequest = URLRequest(url: imageUrl, cachePolicy: .returnCacheDataDontLoad)
let networkRequest = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy)

Observable.concat(loader.loadImage(with: cacheRequest).orEmpty,
                  loader.loadImage(with: networkRequest).orEmpty)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
```

2. concurrent

// FIXME:


> See [Image Caching](https://kean.github.io/post/image-caching) to learn more about HTTP cache


## Load Multiple Images, Display All at Once

Suppose you want to load two icons for a button, one icon for `.normal` state and one for `.selected` state. Only when both icons are loaded you can show the button to the user. This can be done using a [`combineLatest`](http://reactivex.io/documentation/operators/combinelatest.html) operator:

```swift
Observable.combineLatest(loader.loadImage(with: iconUrl).asObservable(),
                         loader.loadImage(with: iconSelectedUrl).asObservable())
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { icon, iconSelected in
        button.isHidden = false
        button.setImage(icon, for: .normal)
        button.setImage(iconSelected, for: .selected)
    }).disposed(by: disposeBag)
```


## Auto Retrying

Auto-retry up to 3 times with an exponentially increasing delay using a retry operator provided by [RxSwiftExt](https://github.com/RxSwiftCommunity/RxSwiftExt).

```swift
loader.loadImage(with: request).asObservable()
    .retry(.exponentialDelayed(maxCount: 3, initial: 3.0, multiplier: 1.0))
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
 ```

> See [A Smarter Retry with RxSwiftExt](http://rx-marin.com/post/rxswift-retry-with-delay/) for more info about auto retries


# Activity Indicator

Suppose you want to show an activity indicator while waiting for an image to load. Here's how you can do it using `ActivityIndicator` class provided by [`RxSwiftUtilities`](https://github.com/RxSwiftCommunity/RxSwiftUtilities):

```swift
let isBusy = ActivityIndicator()

loader.loadImage(with: imageUrl)
    .observeOn(MainScheduler.instance)
    .trackActivity(isBusy)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)

isBusy.asDriver()
    .drive(activityIndicator.rx.isAnimating)
    .disposed(by: disposeBag)
```


# Display Placeholder on Failure

Shows binding + shows how to dispaly a placeholder if the request fails.

```swift
Nuke.Manager.shared.loadImage(with: url).asObservable()
    .subscribeOn(MainScheduler.instance)
    .catchErrorJustReturn(placeholder)
    .bind(to: imageView.rx.image)
    .disposed(by: disposeBag)
```

## In a Table/Collection View

Here's an example of an `ImageCell` 

```swift
final class ImageCell: UICollectionViewCell {

    private var imageView: UIImageView!
    private var loader: RxNuke.Loading = Nuke.Manager.shared

    // As an alternative you could use a dispose bag provided by
    // https://github.com/RxSwiftCommunity/NSObject-Rx#nsobjectrx
    private var disposeBag = DisposeBag()

    // <.. create an image view using your prefered way ..>

    func setImage(_ url: URL) {

        // Create a new dispose bag, previous dispose bag gets deallocated
        // and cancells all previous subscriptions.
        disposeBag = DisposeBag()

        imageView.image = nil

        // Load an image and display the result on success.
        loader.loadImage(with: url)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                self?.imageView.image = image
            }).disposed(by: disposeBag)
    }
}
```
