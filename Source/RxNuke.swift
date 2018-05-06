// The MIT License (MIT)
//
// Copyright (c) 2017-2018 Alexander Grebenyuk (github.com/kean).

import Nuke
import RxSwift

public extension Nuke.ImagePipeline {
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
        guard request.memoryCacheOptions.readAllowed else { return nil }
        return configuration.imageCache?.cachedResponse(for: request)
    }
}

// MARK: - Deprecated

@available(*, deprecated, message: "Please use `ImagePipeline` instead")
public protocol Loading {
    func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image>
}

@available(*, deprecated, message: "Please use `ImagePipeline` instead")
public extension Loading {
    public func loadImage(with url: URL) -> RxSwift.Single<Image> {
        return loadImage(with: Nuke.Request(url: url))
    }

    public func loadImage(with urlRequest: URLRequest) -> RxSwift.Single<Image> {
        return loadImage(with: Nuke.Request(urlRequest: urlRequest))
    }
}

@available(*, deprecated, message: "Please use `ImagePipeline` instead")
extension Nuke.Manager: Loading {
    public func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image> {
        return Single<Image>.create { observer in
            if let image = self.cachedImage(for: request) {
                observer(.success(image))
                return Disposables.create() // nop
            } else {
                return _loadImage(loader: self, request: request, observer: observer)
            }
        }
    }

    private func cachedImage(for request: Request) -> Image? {
        guard request.memoryCacheOptions.readAllowed else { return nil }
        return cache?[request]
    }
}

@available(*, deprecated, message: "Please use `ImagePipeline` instead")
extension Nuke.Loader: Loading {
    public func loadImage(with request: Nuke.Request) -> RxSwift.Single<Image> {
        return Single<Image>.create {
            _loadImage(loader: self, request: request, observer: $0)
        }
    }
}

@available(*, deprecated, message: "Please use `ImagePipeline` instead")
fileprivate func _loadImage<T: Nuke.Loading>(loader: T, request: Nuke.Request, observer: @escaping Single<Image>.SingleObserver) -> Disposable {
    let cts = CancellationTokenSource()
    loader.loadImage(with: request, token: cts.token) { result in
        switch result {
        case let .success(image): observer(.success(image))
        case let .failure(error): observer(.error(error))
        }
    }
    return Disposables.create { cts.cancel() }
}

@available(*, deprecated, message: "Please add an this extension in your codebase.")
extension RxSwift.PrimitiveSequence where Trait == RxSwift.SingleTrait, Element == Nuke.Image {
    public var orEmpty: Observable<Element> {
        return self.asObservable().catchError { _ in
            return .empty()
        }
    }
}
