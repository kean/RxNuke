<p align="center"><img src="https://user-images.githubusercontent.com/1567433/34322222-f47252a6-e832-11e7-972c-fb48d8ec97dc.png" height="180"/>

This repository contains [RxSwift](https://github.com/ReactiveX/RxSwift) extensions for [Nuke](https://github.com/kean/Nuke) as well as examples of common [use cases](#h_use_cases) solved by Rx.

# Usage

RxNuke provides a set of reactive extensions for Nuke:

```swift
extension Reactive where Base: ImagePipeline {
    public func loadImage(with url: URL) -> Single<ImageResponse>
    public func loadImage(with request: ImageRequest) -> Single<ImageResponse>
}
```

> A `Single` is a variation of `Observable` that, instead of emitting a series of elements, is always guaranteed to emit either a single element or an error. The common use case of `Single` is to wrap HTTP requests. See [Traits](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#single) for more info.
{:.info}

Here's a basic example where we load an image and display the result on success:

```swift
ImagePipeline.shared.rx.loadImage(with: url)
    .subscribe(onSuccess: { imageView.image = $0.image })
    .disposed(by: disposeBag)
```

## Going From Low to High Resolution

Let's say you want to show a user a high-resolution image that takes a while to loads. You can show a spinner while the high-resolution image is downloaded, but you can improve the user experience by quickly downloading and displaying a thumbnail.

> As an alternative, Nuke also supports progressive JPEG. To learn about it, see a [dedicated guide](/nuke/guides/progressive-decoding).
{:.info}

You can implement it using [`concat`](http://reactivex.io/documentation/operators/concat.html) operator. This operator results in a serial execution. It starts a thumbnail request, waits until it finishes, and only then starts a request for a high-resolution image.

```swift
Observable.concat(pipeline.rx.loadImage(with: lowResUrl).orEmpty,
                  pipeline.rx.loadImage(with: highResUtl).orEmpty)
    .subscribe(onNext: { imageView.image = $0.image })
    .disposed(by: disposeBag)
```

> `orEmpty` is a custom property which ignores errors and completes the sequence instead
> (equivalent to `func catchErrorJustComplete()` from [RxSwiftExt](https://github.com/RxSwiftCommunity/RxSwiftExt).
{:.info}

```swift
public extension RxSwift.PrimitiveSequence {
    var orEmpty: Observable<Element> {
        asObservable().catchError { _ in .empty() }
    }
}
````

## Loading the First Available Image

Let's say you have multiple URLs for the same image. For example, you uploaded the image from the camera to the server; you have the image stored locally. When you display this image, it would be beneficial to first load the local URL, and if that fails, try to download from the network.

This use case is very similar to [Going From Low to High Resolution](#going-from-low-to-high-resolution), except for the addition of the `.take(1)` operator that stops the execution when the first value is received.

```swift
Observable.concat(pipeline.rx.loadImage(with: localUrl).orEmpty,
                  pipeline.rx.loadImage(with: networkUrl).orEmpty)
    .take(1)
    .subscribe(onNext: { imageView.image = $0.image })
    .disposed(by: disposeBag)
```


## Load Multiple Images, Display All at Once

Let's say you want to load two icons for a button, one icon for a `.normal` state, and one for a `.selected` state. You want to update the button, only when both icons are fully loaded. This can be achieved using a [`combineLatest`](http://reactivex.io/documentation/operators/combinelatest.html) operator.

```swift
Observable.combineLatest(pipeline.rx.loadImage(with: iconUrl).asObservable(),
                         pipeline.rx.loadImage(with: iconSelectedUrl).asObservable())
    .subscribe(onNext: { icon, iconSelected in
        button.isHidden = false
        button.setImage(icon.image, for: .normal)
        button.setImage(iconSelected.image, for: .selected)
    }).disposed(by: disposeBag)
```

## Showing Stale Image While Validating It

Let's say you want to show the user a stale image stored in disk cache (`Foundation.URLCache`) while you go to the server to validate if the image is still fresh. It can be implemented using the same `append` operator that we covered [previously](#going-from-low-to-high-resolution).

```swift
let cacheRequest = URLRequest(url: imageUrl, cachePolicy: .returnCacheDataDontLoad)
let networkRequest = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy)

Observable.concat(pipeline.rx.loadImage(with: ImageRequest(urlRequest: cacheRequest).orEmpty,
                  pipeline.rx.loadImage(with: ImageRequest(urlRequest: networkRequest)).orEmpty)
    .subscribe(onNext: { imageView.image = $0.image })
    .disposed(by: disposeBag)
```

> See ["Image Caching"](/post/image-caching) to learn more about HTTP cache.
{:.info}

## Auto Retry

Auto-retry with an exponential backoff of other delay options (including immediate retry when a network connection is re-established) using [smart retry](https://kean.github.io/post/smart-retry).

```swift
pipeline.rx.loadImage(with: request).asObservable()
    .retry(3, delay: .exponential(initial: 3, multiplier: 1, maxDelay: 16))
    .subscribe(onNext: { imageView.image = $0.image })
    .disposed(by: disposeBag)
 ```


## Tracking Activities

Suppose you want to show an activity indicator while waiting for an image to load. Here's how you can do it using `ActivityIndicator` class provided by [`RxSwiftUtilities`](https://github.com/RxSwiftCommunity/RxSwiftUtilities):

```swift
let isBusy = ActivityIndicator()

pipeline.rx.loadImage(with: imageUrl)
    .trackActivity(isBusy)
    .subscribe(onNext: { imageView.image = $0.image })
    .disposed(by: disposeBag)

isBusy.asDriver()
    .drive(activityIndicator.rx.isAnimating)
    .disposed(by: disposeBag)
```


## In a Table or Collection View

Here's how you can integrate the code provided in the previous examples into your table or collection view cells:

```swift
final class ImageCell: UICollectionViewCell {
    private var imageView: UIImageView!
    private var disposeBag = DisposeBag()

    // <.. create an image view using your preferred way ..>

    func display(_ image: Single<ImageResponse>) {

        // Create a new dispose bag, previous dispose bag gets deallocated
        // and cancels all previous subscriptions.
        disposeBag = DisposeBag()

        imageView.image = nil

        // Load an image and display the result on success.
        image.subscribe(onSuccess: { [weak self] response in
            self?.imageView.image = response.image
        }).disposed(by: disposeBag)
    }
}
```

<a name="h_requirements"></a>
# Requirements

| RxNuke           | Swift                 | Xcode                | Platforms                                          |
|------------------|-----------------------|----------------------|----------------------------------------------------|
| RxNuke 3.0      | Swift 5.3       | Xcode 12.0      | iOS 11.0 / watchOS 4.0 / macOS 10.13 / tvOS 11.0  |
| RxNuke 1.0      | Swift 5.1       | Xcode 11.0      | iOS 11.0 / watchOS 4.0 / macOS 10.13 / tvOS 11.0  |
| RxNuke 0.8       | Swift 4.2 – 5.0       | Xcode 10.1 – 10.2    | iOS 10.0 / watchOS 3.0 / macOS 10.12 / tvOS 10.0   | 

# License

RxNuke is available under the MIT license. See the LICENSE file for more info.
