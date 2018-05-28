//
//  Locks.swift
//  L-Systems
//
//  Created by Spizzace on 5/27/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import Foundation

final class ReadWriteLock {
    
    private var lock = pthread_rwlock_t()
    
    public init() {
        let status = pthread_rwlock_init(&lock, nil)
        assert(status == 0)
    }
    
    deinit {
        let status = pthread_rwlock_destroy(&lock)
        assert(status == 0)
    }
    
    @discardableResult
    public func withReadLock<Result>(_ body: () throws -> Result) rethrows -> Result {
        pthread_rwlock_rdlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return try body()
    }
    
    @discardableResult
    public func withWriteLock<Return>(_ body: () throws -> Return) rethrows -> Return {
        pthread_rwlock_wrlock(&lock)
        defer { pthread_rwlock_unlock(&lock) }
        return try body()
    }
}
