//
//  Pokerable.swift
//  Pods
//
//  Created by Ryan Schneider on 5/13/17.
//
//

import Foundation

public enum Suit: Int, CustomStringConvertible {
    case spades     = 0x1000
    case hearts     = 0x2000
    case diamonds   = 0x4000
    case clubs      = 0x8000
}

public enum CardRank: Int, CustomStringConvertible, Comparable, Strideable {
    case two = 0
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king
    case ace

    public typealias Stride = Int

    public func advanced(by n: Int) -> CardRank {
        return CardRank(rawValue: self.rawValue + n)!
    }

    public func distance(to other: CardRank) -> Int {
        return other.rawValue - self.rawValue
    }
}

public typealias CardValue = UInt32
public typealias HandValue = UInt32

public struct Card {
    public let suit: Suit
    public let rank: CardRank

    public var value: CardValue {
        let r = rank.rawValue
        let s = suit.rawValue

        return CardValue(CKEvaluator.data.primes[r] | (r << 8) | s | (1 << (16+r)))
    }

    public init(suit: Suit, rank: CardRank) {
        self.suit = suit
        self.rank = rank
    }
}

public enum HandRank: Int {
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

public extension HandValue {
    static let worst: HandValue = HandValue.max
}

public protocol Pokerable {
    var cards: [Card] { get }
    var value: HandValue { get set }
    var rank: HandRank { get }
}

public class Hand: Pokerable {
    public var cards: [Card]
    private var hash: Int

    public init() {
        self.cards = [Card]()
        self.hash = 0
        self.hash = currentHash()
    }

    public init(cards: [Card]) {
        self.cards = cards
        self.hash = 0
        self.hash = currentHash()
        self._value = self.evaluate()
    }

    private func currentHash() -> Int {
        return self.cards.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1.value.hashValue)
        }
    }

    private var _value: HandValue = .worst
    public var value: HandValue {
        get {
            if self.hash != currentHash() {
                self._value = self.evaluate()
            }
            return self._value
        }
        set {
            self._value = newValue
        }
    }

    public var rank: HandRank {
        return HandRank(from: self.value)
    }
}

public extension Pokerable {
    func evaluate() -> HandValue {
        if self.cards.count != 5 {
            return HandValue.worst
        }

        return CKEvaluator.evaluate(
            c1: self.cards[0].value,
            c2: self.cards[1].value,
            c3: self.cards[2].value,
            c4: self.cards[3].value,
            c5: self.cards[4].value
        )
    }
}

extension HandRank {
    init(from value: HandValue) {
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

public extension Suit {
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

public extension CardRank {
    private static var lookup: [CardRank:String] {
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

        for (value, prefix) in CardRank.lookup {
            if u.hasPrefix(prefix) {
                self = value
                return
            }
        }

        return nil
    }

    public var glyph: String {
        return CardRank.lookup[self]!
    }

    public var description: String {
        return self.glyph
    }
}

public extension Card {
    init?(from string: String) {
        guard
            let rank = CardRank(from: string),
            let suit = Suit(from: string)
        else {
            return nil
        }

        self.rank = rank
    self.suit = suit
    }
}

public extension Hand {
    convenience init(from string: String) {
        let possibles = string.components(separatedBy: ",").map {
            Card(from: $0)
        }

        self.init(cards: possibles.removeNils())
    }

    convenience init(from strings: String...) {
        let possibles = strings.map {
            Card(from: $0)
        }
        self.init(cards: possibles.removeNils())
    }

    convenience init(from cards: Card...) {
        self.init(cards: cards)
    }
}

public func ==(lhs: Card, rhs: Card) -> Bool {
    return lhs.suit == rhs.suit && lhs.rank == rhs.rank
}

public func < (left: Pokerable, right: Pokerable) -> Bool {
    return left.value > right.value
}

public func > (left: Pokerable, right: Pokerable) -> Bool {
    return left.value < right.value
}

public func ==(left: Pokerable, right: Pokerable) -> Bool {
    return left.value == right.value
}

public func <= (left: Pokerable, right: Pokerable) -> Bool {
    return left < right || left == right
}

public func >= (left: Pokerable, right: Pokerable) -> Bool {
    return left > right || left == right
}
