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

    public func loadImage(with url: URL) -> Single<ImageResponse> {
        return self.loadImage(with: ImageRequest(url: url))
    }

    public func loadImage(with request: ImageRequest) -> Single<ImageResponse> {
        return Single<ImageResponse>.create { single in
            if let image = self.cachedResponse(for: request) {
                single(.success(image)) // return synchronously
                return Disposables.create() // nop
            } else {
                let task = self.base.loadImage(with: request) { response, error in
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
