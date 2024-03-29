// The MIT License (MIT)
//
// Copyright (c) 2017-2023 Alexander Grebenyuk (github.com/kean).

import Nuke
import RxSwift
import Foundation

extension ImagePipeline: ReactiveCompatible {}

extension Reactive where Base: ImagePipeline {
    /// Loads an image with a given url. Emits the value synchronously if the
    /// image was found in memory cache.
    public func loadImage(with url: URL) -> Single<ImageResponse> {
        return self.loadImage(with: ImageRequest(url: url))
    }

    /// Loads an image with a given request. Emits the value synchronously if the
    /// image was found in memory cache.
    public func loadImage(with request: ImageRequest) -> Single<ImageResponse> {
        return Single<ImageResponse>.create { single in
            if let image = self.base.cache[request] {
                single(.success(ImageResponse(container: image, request: request))) // return synchronously
                return Disposables.create() // nop
            } else {
                let task = self.base.loadImage(with: request, completion: { result in
                    switch result {
                    case let .success(response):
                        single(.success(response))
                    case let .failure(error):
                        single(.failure(error))
                    }
                })
                return Disposables.create { task.cancel() }
            }
        }
    }
}
