<p align="center"><img src="https://user-images.githubusercontent.com/1567433/27010376-bc53fa6c-4eab-11e7-9ce3-7d49063fce7f.png" height="180"/>

<p align="center">
<img src="https://img.shields.io/cocoapods/v/RxNuke.svg?label=version">
<img src="https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage-green.svg">
<img src="https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg">
</p>

This repository contains [RxSwift](https://github.com/ReactiveX/RxSwift) extensions for [Nuke](https://github.com/kean/Nuke) as well as examples of common [use cases](#h_use_cases) solved by Rx.


# <a name="h_use_cases"></a>Use Cases

- [Going From Low to High Resolution](#huc_low_to_high) 
- [Loading the First Available Image](#huc_loading_first_avail)
- [Load Multiple Images, Display All at Once](#huc_load_multiple_display_once)
- [Showing Stale Image While Validating It](#huc_showing_stale_first)
- [Auto Retry](#huc_auto_retry)
- [Tracking Activities](#huc_activity_indicator)
- [Display Placeholder on Failure](#huc_placeholder_on_fail)
- [Table or Collection View](#huc_table_collection_view)

# <a name="h_getting_started"></a>Getting Started

- [Installation Guide](https://github.com/kean/RxNuke/blob/master/Documentation/Guides/Installation%20Guide.md)
- [Getting Started with RxSwift](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/GettingStarted.md)


# <a name="h_usage"></a>Usage

`RxNuke` adds a new `Loading` protocol with a set of methods which returns `RxSwift.Single` observables:

```swift
public protocol Loading {
    func loadImage(with url: URL) -> Single<Image>
    func loadImage(with urlRequest: URLRequest) -> Single<Image>
    func loadImage(with request: Nuke.Request) -> Single<Image>
}
```

> A `Single` is a variation of `Observable` that, instead of emitting a series of elements, is always guaranteed to emit either a single element or an error. The common use case of `Single` is to wrap HTTP requests. See [Traits](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#single) for more info.

Let's start with the basics. Here's an example of how to use a new `RxNuke.Loading` protocol to load an image and display the result on success:

```swift
Nuke.Manager.shared.loadImage(with: url)
    .observeOn(MainScheduler.instance)
    .subscribe(onSuccess: { imageView.image = $0 })
    .disposed(by: disposeBag)
```

### <a name="huc_low_to_high"></a>Going From Low to High Resolution

Suppose you want to show users a high-resolution, slow-to-download image. Rather than let them stare a placeholder for a while, you might want to quickly download a smaller thumbnail first. 

You can implement this using [`concat`](http://reactivex.io/documentation/operators/concat.html) operator which results in a **serial** execution. It would first start a thumbnail request, wait until it finishes, and only then start a request for a high-resolution image.

```swift
Observable.concat(loader.loadImage(with: lowResUrl).orEmpty,
                  loader.loadImage(with: highResUtl).orEmpty)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
```

> `orEmpty` is a custom operator which dismisses errors and completes the sequence instead
> (equivalent to `func catchErrorJustComplete()` from [RxSwiftExt](https://github.com/RxSwiftCommunity/RxSwiftExt)


### <a name="huc_loading_first_avail"></a>Loading the First Available Image

Suppose you have multiple URLs for the same image. For instance, you might have uploaded an image taken from the camera. In such case, it would be beneficial to first try to get the local URL, and if that fails, try to get the network URL. It would be a shame to download the image that we may have already locally.

This use case is very similar [Going From Low to High Resolution](#huc_low_to_high), but an addition of `.take(1)` guarantees that we stop execution as soon as we receive the first result.

```swift
Observable.concat(loader.loadImage(with: localUrl).orEmpty,
                  loader.loadImage(with: networkUrl).orEmpty)
    .take(1)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
```


### <a name="huc_load_multiple_display_once"></a>Load Multiple Images, Display All at Once

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


### <a name="huc_showing_stale_first"></a>Showing Stale Image While Validating It

Suppose you want to show users a stale image stored in a disk cache (`Foundation.URLCache`) while you go to the server to validate it. This use case is actually similar to [Going From Low to High Resolution](#huc_low_to_high).

```swift
let cacheRequest = URLRequest(url: imageUrl, cachePolicy: .returnCacheDataDontLoad)
let networkRequest = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy)

Observable.concat(loader.loadImage(with: cacheRequest).orEmpty,
                  loader.loadImage(with: networkRequest).orEmpty)
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
```

> See [Image Caching](https://kean.github.io/post/image-caching) to learn more about HTTP cache


### <a name="huc_auto_retry"></a>Auto Retry

Auto-retry up to 3 times with an exponentially increasing delay using a retry operator provided by [RxSwiftExt](https://github.com/RxSwiftCommunity/RxSwiftExt).

```swift
loader.loadImage(with: request).asObservable()
    .retry(.exponentialDelayed(maxCount: 3, initial: 3.0, multiplier: 1.0))
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { imageView.image = $0 })
    .disposed(by: disposeBag)
 ```

> See [A Smarter Retry with RxSwiftExt](http://rx-marin.com/post/rxswift-retry-with-delay/) for more info about auto retries


### <a name="huc_activity_indicator"></a>Tracking Activities

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


### <a name="huc_table_collection_view"></a>In a Table or Collection View

Here's how you can integrate the code provided in the previous examples into your table or collection view cells:

```swift
final class ImageCell: UICollectionViewCell {

    private var imageView: UIImageView!
    private var disposeBag = DisposeBag()

    // <.. create an image view using your preferred way ..>

    func display(_ image: Single<Image>) {

        // Create a new dispose bag, previous dispose bag gets deallocated
        // and cancels all previous subscriptions.
        disposeBag = DisposeBag()

        imageView.image = nil

        // Load an image and display the result on success.
        image.subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] image in
                self?.imageView.image = image
            }).disposed(by: disposeBag)
    }
}
```


# Requirements<a name="h_requirements"></a>

- iOS 9.0 / watchOS 2.0 / macOS 10.11 / tvOS 9.0
- Xcode 8
- Swift 3


# License

RxNuke is available under the MIT license. See the LICENSE file for more info.
