// https://github.com/Quick/Quick

import Quick
import Nimble
import Pokerable

class PokerableSpec: QuickSpec {
    override func spec() {
        describe("a simple 5-card poker evaluator") {
            it("can evaluate basic poker hands") {
                let h = Hand(from: "As,Ad,2c,3h,Kh")
                expect(h.rank) == Hand.Rank.pair
            }

            it("can compare two poker hands") {
                let h1 = Hand(from: "As", "Ac", "Ad", "2s", "2h")
                let h2 = Hand(from: "4h", "2h", "3d", "5s", "6c")

                expect(h1 > h2) == true
                expect(h1 == h2) == false
                expect(h1 < h2) == false
            }

            it("can evaluate all poker hands") {
                var deck = [Card]()
                for rank in Card.Rank.two...Card.Rank.ace {
                    for suit in [Card.Suit.spades, Card.Suit.hearts, Card.Suit.diamonds, Card.Suit.clubs] {
                        deck.append(Card(suit: suit, rank: rank))
                    }

                }

                expect(deck.count).to(equal(52))

                var frequencies = Dictionary<Hand.Rank, Int>()

                for a in 0 ..< 48 {
                    for b in a+1 ..< 49 {
                        for c in b+1 ..< 50 {
                            for d in c+1 ..< 51 {
                                for e in d+1 ..< 52 {
                                    let h = Hand(from: deck[a], deck[b], deck[c], deck[d], deck[e])
                                    let rank = h.rank
                                    if let count = frequencies[rank] {
                                        frequencies[rank] = count + 1
                                    }
                                    else {
                                        frequencies[rank] = 1
                                    }
                                }
                            }
                        }
                    }
                }

                expect(frequencies[.invalid]).to(beNil())
                expect(frequencies[.highCard]).to(equal(1302540))
                expect(frequencies[.pair]).to(equal(1098240))
                expect(frequencies[.twoPair]).to(equal(123552))
                expect(frequencies[.threeOfAKind]).to(equal(54912))
                expect(frequencies[.straight]).to(equal(10200))
                expect(frequencies[.flush]).to(equal(5108))
                expect(frequencies[.fullHouse]).to(equal(3744))
                expect(frequencies[.fourOfAKind]).to(equal(624))
                expect(frequencies[.straightFlush]).to(equal(40))
            }
        }
    }
}
