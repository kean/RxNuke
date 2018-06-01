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

public extension Nuke.ImagePipeline {
    public func loadImage(with url: URL) -> RxSwift.Single<Nuke.ImageResponse> {
        return loadImage(with: ImageRequest(url: url))
    }

    public func loadImage(with request: Nuke.ImageRequest) -> RxSwift.Single<Nuke.ImageResponse> {
        return Single<Nuke.ImageResponse>.create { observer in
            if let image = self.cachedResponse(for: request) {
                observer(.success(image)) // return syncrhonously
                return Disposables.create() // nop
            } else {
                let task = self.loadImage(with: request) { response, error in
                    if let response = response {
                        observer(.success(response))
                    } else {
                        observer(.error(error ?? ImagePipeline.Error.processingFailed)) // error always non-nil
                    }
                }
                return Disposables.create { task.cancel() }
            }
        }
    }

    private func cachedResponse(for request: Nuke.ImageRequest) -> Nuke.ImageResponse? {
        guard request.memoryCacheOptions.isReadAllowed else { return nil }
        return configuration.imageCache?.cachedResponse(for: request)
    }
}
