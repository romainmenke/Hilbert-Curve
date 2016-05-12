/*:
 # Hello Hilber
 
 A Swift implementation of Hilbert Curves
 */

import UIKit
import XCPlayground

/*: source code from github
 [Source]:https://github.com/rawrunprotected/hilbert_curves
 For the original code : [Source]
*/

struct Hilbert {
    
    static func deinterleave(x:UInt32) -> UInt32 {
        var x = x & 0x55555555
        x = (x | (x >> 1)) & 0x33333333
        x = (x | (x >> 2)) & 0x0F0F0F0F
        x = (x | (x >> 4)) & 0x00FF00FF
        x = (x | (x >> 8)) & 0x0000FFFF
        return x
    }
    
    static func interleave(x:UInt32) -> UInt32 {
        var x = (x | (x << 8)) & 0x00FF00FF
        x = (x | (x << 4)) & 0x0F0F0F0F
        x = (x | (x << 2)) & 0x33333333
        x = (x | (x << 1)) & 0x55555555
        return x
    }
    
    static func prefixScan(x:UInt32) -> UInt32 {
        var x = (x >> 8) ^ x
        x = (x >> 4) ^ x
        x = (x >> 2) ^ x
        x = (x >> 1) ^ x
        return x
    }
    
    static func descan(x:UInt32) -> UInt32 {
        return x ^ (x >> 1)
    }
    
    static func hilbertIndexToXY(n:UInt32, i:UInt32, x:UInt32, y:UInt32) -> (UInt32,UInt32) {
        let i = i << (32 - 2 * n)
        
        let i0 = deinterleave(i)
        let i1 = deinterleave(i >> 1)
        
        let t0 = (i0 | i1) ^ 0xFFFF
        let t1 = i0 & i1
        
        let prefixT0 = prefixScan(t0)
        let prefixT1 = prefixScan(t1)
        
        let a = (((i0 ^ 0xFFFF) & prefixT1) | (i0 & prefixT0))
        
        let x = (a ^ i1) >> (16 - n)
        let y = (a ^ i0 ^ i1) >> (16 - n)
        return(x,y)
    }
    
    static func hilbertXYToIndex(n:UInt32, x:UInt32, y:UInt32) -> UInt32 {
        var x = x << (16 - n)
        var y = y << (16 - n)
        
        var (A, B, C, D) : (UInt32,UInt32,UInt32,UInt32) = (0,0,0,0)
        
        // Initial prefix scan round, prime with x and y
        func first() {
            let a : UInt32 = x ^ y
            let b : UInt32 = 0xFFFF ^ a
            let c : UInt32 = 0xFFFF ^ (x | y)
            let d : UInt32 = x & (y ^ 0xFFFF)
            
            A = a | (b >> 1)
            B = (a >> 1) ^ a
            
            C = ((c >> 1) ^ (b & (d >> 1))) ^ c
            D = ((a & (c >> 1)) ^ (d >> 1)) ^ d
        }
        
        func second() {
            let a : UInt32 = A
            let b : UInt32 = B
            let c : UInt32 = C
            let d : UInt32 = D
            
            A = ((a & (a >> 2)) ^ (b & (b >> 2)))
            B = ((a & (b >> 2)) ^ (b & ((a ^ b) >> 2)))
            
            C ^= ((a & (c >> 2)) ^ (b & (d >> 2)))
            D ^= ((b & (c >> 2)) ^ ((a ^ b) & (d >> 2)))
        }
        
        func third() {
            let a : UInt32 = A
            let b : UInt32 = B
            let c : UInt32 = C
            let d : UInt32 = D
            
            A = ((a & (a >> 4)) ^ (b & (b >> 4)))
            B = ((a & (b >> 4)) ^ (b & ((a ^ b) >> 4)))
            
            C ^= ((a & (c >> 4)) ^ (b & (d >> 4)))
            D ^= ((b & (c >> 4)) ^ ((a ^ b) & (d >> 4)))
        }
        
        // Final round and projection
        func fourth() {
            let a : UInt32 = A
            let b : UInt32 = B
            let c : UInt32 = C
            let d : UInt32 = D
            
            C ^= ((a & (c >> 8)) ^ (b & (d >> 8)))
            D ^= ((b & (c >> 8)) ^ ((a ^ b) & (d >> 8)))
        }
        
        first()
        second()
        third()
        fourth()
        
        // Undo transformation prefix scan
        let a : UInt32 = C ^ (C >> 1)
        let b : UInt32 = D ^ (D >> 1)
        
        // Recover index bits
        let i0 = x ^ y
        let i1 = b | (0xFFFF ^ (i0 | a))
        
        return ((interleave(i1) << 1) | interleave(i0)) >> (32 - 2 * n)
    }
    
    static func generateCurve(n:UInt32, count:Int) -> Hilbert {
        
        var curve : [(UInt32,UInt32)] = []
        
        for i in 0..<count {
            let (x2,y2) : (UInt32,UInt32)
            if i == 0 {
                x2 = 0
                y2 = 0
            } else {
                x2 = curve[i - 1].0
                y2 = curve[i - 1].1
            }
            let xy = Hilbert.hilbertIndexToXY(n, i: UInt32(i), x: x2, y: y2)
            curve.append(xy)
        }
        
        return Hilbert(curve: curve)
    }
    
    var curve : [(UInt32,UInt32)]
    
    
    
}

extension Hilbert : CustomPlaygroundQuickLookable {
    
    func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        
        guard curve.count > 1 else {
            return PlaygroundQuickLook.View(UIView(frame: CGRectZero))
        }

        func convertToFloat(xy:(UInt32,UInt32)) -> (CGFloat,CGFloat) { return (CGFloat(xy.0 * 10), CGFloat(xy.1 * 10)) }
        func convertToPoint(xy:(UInt32,UInt32)) -> CGPoint { return CGPoint(x:CGFloat(xy.0 * 10 + 10), y:CGFloat(xy.1 * 10 + 10)) }
        
        let maxX = ((curve.map { return $0.0 }).maxElement() ?? 0) * 10
        let maxY = ((curve.map { return $0.1 }).maxElement() ?? 0) * 10
        
        let path = UIBezierPath()
        path.moveToPoint(convertToPoint(curve[0]))
        for i in 1..<curve.count {
            path.addLineToPoint(convertToPoint(curve[i]))
        }
        
        let drawLayer = CAShapeLayer()
        drawLayer.path = path.CGPath
        drawLayer.strokeColor = UIColor.redColor().CGColor
        drawLayer.fillColor = UIColor.whiteColor().CGColor
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat(maxX) + 20, height: CGFloat(maxY) + 20))
        view.backgroundColor = UIColor.whiteColor()
        view.layer.addSublayer(drawLayer)
        
        return PlaygroundQuickLook.View(view)
    }
}


let hilbert = Hilbert.generateCurve(9, count: 1000)
print(hilbert.curve)




