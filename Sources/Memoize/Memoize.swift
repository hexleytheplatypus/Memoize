//===--- Memoize.swift ----------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A protocol for memoization, which optimizes the performance of recursive calls
/// by caching their results.
public protocol Memoize {
    associatedtype Key: Hashable
    associatedtype Value

    static var shared: Self { get set }

    /// Storage for cached values.
    static var storage: Dictionary<Key, Value> { get set }
    /// The function to return a cached or computed value.
    static var memoized: ((Key) -> Value, Key) -> Value { get }
}

extension Memoize {
    /// Initializes the underlying shared instance and precomputes the value for
    /// the specified key.
    /// - Parameter precompute: A key for which to precompute (and cache) the value.
    public init(_ precompute: Key) {
        self = Self.shared
        let _ = Self.shared.memoize(precompute)
    }
    
    /// Compute the value for the given key or retrieve it from the cache.
    /// - Parameter key: The key for which to memoize the value.
    /// - Returns: The memoized value associated with the key.
    public func memoize(_ key: Key) -> Value {
        let invocation = Self.shared.memoize { Self.memoized($0, $1) }
        return invocation(key)
    }
}

extension Memoize {
    fileprivate mutating func memoize(_ closure: @escaping ((Key) -> Value, Key) -> Value) -> ((Key) -> Value) {
        var result: ((Key) -> Value)!
        result = { key in
            if let lookup = Self.storage[key] { return lookup }
            let generated = closure(result, key)
            Self.storage[key] = generated
            return generated
        }
        return result
    }
}
