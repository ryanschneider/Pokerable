//
//  Pokerable.swift
//  Pods
//
//  Created by Ryan Schneider on 5/13/17.
//
//

import Foundation

public struct Card {
    var compact: UInt8
    
    public enum Suit: UInt8 {
        case spades     = 0b00010000
        case hearts     = 0b00100000
        case diamonds   = 0b01000000
        case clubs      = 0b10000000

        var compact: UInt8 {
            return self.rawValue
        }
    }

    public enum Rank: UInt8, Comparable, Strideable {
        case two    = 1
        case three  = 2
        case four   = 3
        case five   = 4
        case six    = 5
        case seven  = 6
        case eight  = 7
        case nine   = 8
        case ten    = 9
        case jack   = 10
        case queen  = 11
        case king   = 12
        case ace    = 13

        public typealias Stride = Int

        public func advanced(by n: Int) -> Card.Rank {
            let new = UInt8(
                Int(self.rawValue) + n
            )
            return Card.Rank(rawValue: new)!
        }
        
        public func distance(to other: Card.Rank) -> Int {
            return Int(other.rawValue) - Int(self.rawValue)
        }

        var compact: UInt8 {
            return self.rawValue
        }
    }

    public var suit: Suit {
        return Suit(rawValue: self.compact & 0b11110000)!
    }

    public var rank: Rank {
        return Rank(rawValue: self.compact & 0b00001111)!
    }

    init(compact: UInt8) {
        self.compact = compact
    }

    public init(suit: Suit, rank: Rank) {
        self.compact = suit.compact | rank.compact
    }
}

public struct Hand {
    public enum Rank: Int {
        case invalid = 0
        case highCard
        case pair
        case twoPair
        case threeOfAKind
        case straight
        case flush
        case fullHouse
        case fourOfAKind
        case straightFlush
    }

    // Bytes:  0 1 2 3 4 5 6 7
    // Card:   0 1 2 3 4 - - -
    // Rank:   - - - - - - R R

    var _cards: UInt64

    subscript(index: Int) -> Card {
        get {
            switch index {
            case 0:
                return Card(compact: UInt8((_cards & 0xFF_00_00_00_00_00_00_00) >> (64 - 8 )))
            case 1:
                return Card(compact: UInt8((_cards & 0x00_FF_00_00_00_00_00_00) >> (64 - 16)))
            case 2:
                return Card(compact: UInt8((_cards & 0x00_00_FF_00_00_00_00_00) >> (64 - 24)))
            case 3:
                return Card(compact: UInt8((_cards & 0x00_00_00_FF_00_00_00_00) >> (64 - 32)))
            case 4:
                return Card(compact: UInt8((_cards & 0x00_00_00_00_FF_00_00_00) >> (64 - 40)))
            default:
                fatalError("Invalid index \(index).  Valid indices are 0-4.")
            }
        }

        set(newValue) {
            switch index {
            case 0:
                _cards |= UInt64(newValue.compact) << (64-8)
            case 1:
                _cards |= UInt64(newValue.compact) << (64-16)
            case 2:
                _cards |= UInt64(newValue.compact) << (64-24)
            case 3:
                _cards |= UInt64(newValue.compact) << (64-32)
            case 4:
                _cards |= UInt64(newValue.compact) << (64-40)
            default:
                fatalError("Invalid index \(index).  Valid indices are 0-4.")
            }
        }
    }

    public var rank: Hand.Rank {
        return Hand.Rank(from: self.value)
    }

    public init(cards: [Card]) {
        _cards = 0

        for (i, card) in cards.enumerated() {
            self[i] = card
        }

        if cards.count == 5 {
            self.value = evaluate()
        }
        else {
            self.value = Hand.Expanded.worst
        }
    }
}

public extension Card.Suit {
    init?(from string: String) {
        let l = string.lowercased()

        if l.hasSuffix("s") || l.hasSuffix("♤") || l.hasSuffix("♠") {
            self = .spades
            return
        }
        else if l.hasSuffix("h") || l.hasSuffix("♡") || l.hasSuffix("♥") {
            self = .hearts
            return
        }
        else if l.hasSuffix("d") || l.hasSuffix("♢")  || l.hasSuffix("♦") {
            self = .diamonds
            return
        }
        else if l.hasSuffix("c") || l.hasSuffix("♧") || l.hasSuffix("♣") {
            self = .clubs
            return
        }

        return nil
    }

    public var ascii: String {
        switch self {
        case .spades:
            return "s"
        case .hearts:
            return "h"
        case .diamonds:
            return "d"
        case .clubs:
            return "c"
        }
    }

    public var glyph: String {
        switch self {
        case .spades:
            return "♠\u{0000FE0E}"
        case .hearts:
            return "♥\u{0000FE0E}"
        case .diamonds:
            return "♦\u{0000FE0E}"
        case .clubs:
            return "♣\u{0000FE0E}"
        }
    }

    public var description: String {
        return self.glyph
    }
}

public extension Card.Rank {
    private static var lookup: [Card.Rank:String] {
        return [
            .two: "2",
            .three: "3",
            .four: "4",
            .five: "5",
            .six: "6",
            .seven: "7",
            .eight: "8",
            .nine: "9",
            .ten: "T",
            .jack: "J",
            .queen: "Q",
            .king: "K",
            .ace: "A"
        ]
    }
    init?(from string: String) {
        let u = string.uppercased()

        for (value, prefix) in Card.Rank.lookup {
            if u.hasPrefix(prefix) {
                self = value
                return
            }
        }

        return nil
    }

    public var glyph: String {
        return Card.Rank.lookup[self]!
    }

    public var description: String {
        return self.glyph
    }
}

public extension Card {
    init?(from string: String) {
        guard
            let rank = Card.Rank(from: string),
            let suit = Suit(from: string)
        else {
            return nil
        }

        self.init(suit: suit, rank: rank)
    }
}

public extension Hand {
    init(from string: String) {
        let possibles = string.components(separatedBy: ",").map {
            Card(from: $0)
        }

        self.init(cards: possibles.removeNils())
    }

    init(from strings: String...) {
        let possibles = strings.map {
            Card(from: $0)
        }
        self.init(cards: possibles.removeNils())
    }

    init(from cards: Card...) {
        self.init(cards: cards)
    }
}

public func ==(lhs: Card, rhs: Card) -> Bool {
    return lhs.suit == rhs.suit && lhs.rank == rhs.rank
}

public func < (left: Hand, right: Hand) -> Bool {
    return left.value > right.value
}

public func > (left: Hand, right: Hand) -> Bool {
    return left.value < right.value
}

public func ==(left: Hand, right: Hand) -> Bool {
    return left.value == right.value
}

public func <= (left: Hand, right: Hand) -> Bool {
    return left < right || left == right
}

public func >= (left: Hand, right: Hand) -> Bool {
    return left > right || left == right
}
