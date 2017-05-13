//
//  CKEvaluator.swift
//  Pods
//
//  Created by Ryan Schneider on 5/13/17.
//
//

import Foundation

struct CKEvaluator {
    static let data = CKArrayData()

    static func evaluate(
        c1: CardValue,
        c2: CardValue,
        c3: CardValue,
        c4: CardValue,
        c5: CardValue
    ) -> HandValue {

        let q = (c1 | c2 | c3 | c4 | c5) >> 16

        // check for flushes and straight flushes
        let isFlush = c1 & c2 & c3 & c4 & c5 & 0xf000
        if isFlush != 0 {
            return HandValue(data.flushes[Int(q)]);
        }

        // check for straights and high card hands
        let uniqueValue = data.unique5[Int(q)]
        if uniqueValue != 0 {
            return UInt32(uniqueValue)
        }

        let i = (c1 & 0xff) * (c2 & 0xff) * (c3 & 0xff) * (c4 & 0xff) * (c5 & 0xff)
        let ff = find_fast(i: i)
        return HandValue(data.hash_values[Int(ff)])
    }

    static func find_fast(i: UInt32) -> UInt32 {
        var u = i + 0xe91aaa35
        u ^= u >> 16
        u = u &+ (u << 8)
        u ^= u >> 4
        let b : UInt32 = (u >> 8) & 0x1ff
        let a  = (u &+ (u << 2)) >> 19
        let x = data.hash_adjust[Int(b)]
        let r  = a ^ UInt32(x)
        return r
    }
}
