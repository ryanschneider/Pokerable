//
//  CKArrayData.swift
//  Pods
//
//  Created by Ryan Schneider on 5/13/17.
//
//

import Foundation

// Wrapper around CKArrayConstants, which used to be so slow to 
// compile with Swift 1.x that I loaded it from a static file.  
//
// However, with Swift 3 that seems to no longer be the case
struct CKArrayData {
    var primes : [Int]  {
        return CKArrayConstants.primes
    }

    var hash_adjust : [UInt16] {
        return CKArrayConstants.hash_adjust
    }

    var hash_values : [UInt16] {
        return CKArrayConstants.hash_values
    }

    /*
     ** this is a table lookup for all "flush" hands (e.g.  both
     ** flushes and straight-flushes.  entries containing a zero
     ** mean that combination is not possible with a five-card
     ** flush hand.
     */
    var flushes : [UInt16] {
        return CKArrayConstants.flushes
    }

    /*
     ** this is a table lookup for all non-flush hands consisting
     ** of five unique ranks (i.e.  either Straights or High Card
     ** hands).  it's similar to the above "flushes" array.
     */
    var unique5 : [UInt16] {
        return CKArrayConstants.unique5
    }
}
