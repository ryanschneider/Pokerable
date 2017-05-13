//
//  Pokerable+CKImpl.swift
//  Pods
//
//  Created by Ryan Schneider on 5/13/17.
//
//

import Foundation

// Contains all the internal implmentation details
// As pertaining to using CactusKev's evaluator

extension Card {
    typealias Expanded = UInt32

    var expanded: Expanded {
        let r = self.rank.expanded
        let s = self.suit.expanded
        return Expanded(CKEvaluator.data.primes[r] | (r << 8) | s | (1 << (16+r)))
    }
}

extension Card.Suit {
    var expanded: Int {
        switch self {
        case .spades:
            return 0x1000
        case .hearts:
            return 0x2000
        case .diamonds:
            return 0x4000
        case .clubs:
            return 0x8000
        }
    }
}

extension Card.Rank {
    var expanded: Int {
        return Int(self.rawValue - 1)
    }
}

extension Hand {
    typealias Expanded = UInt32

    var value: Expanded {
        get {
            return Expanded(_cards & 0xFFFF)
        }
        set {
            _cards |= UInt64(newValue & 0xFFFF)
        }
    }

    func evaluate() -> Hand.Expanded {
        return CKEvaluator.evaluate(
            c1: self[0].expanded,
            c2: self[1].expanded,
            c3: self[2].expanded,
            c4: self[3].expanded,
            c5: self[4].expanded
        )
    }
}

extension Hand.Expanded {
    static let worst: Hand.Expanded = Hand.Expanded(UInt16.max)
}

extension Hand.Rank {
    init(from value: Hand.Expanded) {
        if value > 7462 {
            self = .invalid
            return
        }
        else if value > 6185 {
            self = .highCard
            return
        }
        else if value > 3325 {
            self = .pair
            return
        }
        else if value > 2467 {
            self = .twoPair
            return
        }
        else if value > 1609 {
            self = .threeOfAKind
            return
        }
        else if value > 1599 {
            self = .straight
            return
        }
        else if value > 322 {
            self = .flush
            return
        }
        else if value > 166 {
            self = .fullHouse
            return
        }
        else if value > 10 {
            self = .fourOfAKind
            return
        }
        else if value >= 0 {
            self = .straightFlush
            return
        }

        assertionFailure("This should be unreachable")
        self = .invalid
    }
}

struct CKEvaluator {
    static let data = CKArrayData()

    static func evaluate(
        c1: Card.Expanded,
        c2: Card.Expanded,
        c3: Card.Expanded,
        c4: Card.Expanded,
        c5: Card.Expanded
        ) -> Hand.Expanded {

        let q = (c1 | c2 | c3 | c4 | c5) >> 16

        // check for flushes and straight flushes
        let isFlush = c1 & c2 & c3 & c4 & c5 & 0xf000
        if isFlush != 0 {
            return Hand.Expanded(data.flushes[Int(q)]);
        }

        // check for straights and high card hands
        let uniqueValue = data.unique5[Int(q)]
        if uniqueValue != 0 {
            return Hand.Expanded(uniqueValue)
        }

        let i = (c1 & 0xff) * (c2 & 0xff) * (c3 & 0xff) * (c4 & 0xff) * (c5 & 0xff)
        let ff = find_fast(i: i)
        return Hand.Expanded(data.hash_values[Int(ff)])
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


