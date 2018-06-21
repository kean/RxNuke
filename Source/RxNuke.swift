// The MIT License (MIT)
//
// Copyright (c) 2017-2018 Alexander Grebenyuk (github.com/kean).

import Nuke
import RxSwift

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImagePipeline: ReactiveCompatible {}

public extension Reactive where Base: ImagePipeline {
    /// Loads an image with a given url. Emits a single ImageResponse value otherwise error.
    public func loadImage(with url: URL) -> Single<ImageResponse> {
        let imageRequest = ImageRequest(url: url)
        return self.load(with: imageRequest)
    }

    /// Loads an image with a given request. Emits a single ImageResponse value otherwise error.
    public func loadImage(with request: ImageRequest) -> Single<ImageResponse> {
        return self.load(with: request)
    }
    
    /// Loads an image with a given url. Emits ImageResponse otherwise
    /// dismisses errors and completes the sequence.
    public func loadImage(with url: URL) -> Observable<ImageResponse> {
        return self.load(with: ImageRequest(url: url)).orEmpty()
    }

    /// Loads an image with a given request. Emits ImageResponse otherwise
    /// dismisses errors and completes the sequence.
    public func loadImage(with request: ImageRequest) -> Observable<ImageResponse> {
        return self.load(with: request).orEmpty()
    }
    
    private func load(with imageRequest: ImageRequest) -> Single<ImageResponse> {
        return Single<ImageResponse>.create { single in
            if let image = self.cachedResponse(for: imageRequest) {
                single(.success(image)) // return synchronously
                return Disposables.create() // nop
            } else {
                let task = self.base.loadImage(with: imageRequest) { response, error in
                    if let response = response {
                        single(.success(response))
                    } else {
                        single(.error(error ?? ImagePipeline.Error.processingFailed)) // error always non-nil
                    }
                }
                return Disposables.create { task.cancel() }
            }
        }
    }

    private func cachedResponse(for request: ImageRequest) -> ImageResponse? {
        guard request.memoryCacheOptions.isReadAllowed else { return nil }
        return base.configuration.imageCache?.cachedResponse(for: request)
    }
}

private extension PrimitiveSequence where Trait == SingleTrait {
    /// Dismiss errors and complete the sequence instead
    /// - returns: An observable sequence that never errors.
    func orEmpty() -> Observable<Element> {
        return asObservable().catchError { _ in .empty() }
    }
}

// MARK: - Deprecated

extension ImagePipeline {
    @available(*, deprecated, message: "Please use `rx.loadImage(with:)` instead.")
    public func loadImage(with url: URL) -> Single<ImageResponse> {
        return rx.loadImage(with: url)
    }

    @available(*, deprecated, message: "Please use `rx.loadImage(with:)` instead.")
    public func loadImage(with request: ImageRequest) -> Single<ImageResponse> {
        return rx.loadImage(with: request)
    }
}
