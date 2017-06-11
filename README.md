# RxNuke


Single trait.
https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#single


# Usage

## Basics

Let's start with the basics. Here's an example of how to use a new `RxNuke.Loading` implemented by `Nuke.Manager` to load an image and bind the result to an image view.

```swift
Nuke.Manager.shared.loadImage(with: url).asObservable()
            .subscribeOn(MainScheduler.instance)
            .bind(to: imageView.rx.image)
            .disposed(by: disposeBag)
```

An alternative version which doesn't use bindings:

```swift
Nuke.Manager.shared.loadImage(with: url)
	.subscribeOn(MainScheduler.instance)
	.subscribe(onSuccess: { [weak self] image in
		self?.imageView.image = image
	}).disposed(by: disposeBag)
```

## Auto Retries

Auto-retry up to 3 times with an exponentially increasing delay using a retry operator provided by [RxSwiftExt](https://github.com/RxSwiftCommunity/RxSwiftExt).

```swift
loader.loadImage(with: request).asObservable()
    .retry(.exponentialDelayed(maxCount: 3, initial: 3.0, multiplier: 1.0))
    .subscribeOn(MainScheduler.instance)
    .bind(to: imageView.rx.image)
    .disposed(by: disposeBag)
 ```

> See [A Smarter Retry with RxSwiftExt](http://rx-marin.com/post/rxswift-retry-with-delay/) for more info about auto retries


## Load low-res first, high-res second

1. serial
2. concurrent

## Load stale first, validate next

1. serial
2. concurrent

# Activity Indicator

# Cache Thumbnails of locally stored images (?)

https://github.com/kean/Nuke/issues/66

## In a Table/Collection View

Here's n example of an `ImageCell` 

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