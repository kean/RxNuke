// The MIT License (MIT)
//
// Copyright (c) 2017-2019 Alexander Grebenyuk (github.com/kean).

import Nuke
import RxSwift

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImagePipeline: ReactiveCompatible {}

public extension Reactive where Base: ImagePipeline {
    /// Loads an image with a given url. Emits the value synchronously if the
    /// image was found in memory cache.
    func loadImage(with url: URL) -> Single<ImageResponse> {
        return self.loadImage(with: ImageRequest(url: url))
    }

    /// Loads an image with a given request. Emits the value synchronously if the
    /// image was found in memory cache.
    func loadImage(with request: ImageRequest) -> Single<ImageResponse> {
        return Single<ImageResponse>.create { single in
            if let image = self.cachedResponse(for: request) {
                single(.success(image)) // return synchronously
                return Disposables.create() // nop
            } else {
                let task = self.base.loadImage(with: request) { result in
                    switch result {
                    case let .success(response):
                        single(.success(response))
                    case let .failure(error):
                        single(.error(error))
                    }
                }
                return Disposables.create { task.cancel() }
            }
        }
    }

    private func cachedResponse(for request: ImageRequest) -> ImageResponse? {
        guard request.options.memoryCacheOptions.isReadAllowed else { return nil }
        return base.configuration.imageCache?.cachedResponse(for: request)
    }
}
