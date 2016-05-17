import Cocoa

public typealias XView = NSView
public typealias XColor = NSColor
public typealias XBezierPath = NSBezierPath


extension NSView {
    
    public var backgroundColor : XColor? {
        get {
            if let bgColor = layer?.backgroundColor {
                return XColor(CGColor: bgColor)
            }
            return nil
        }
        set(color) {
            if let layer = layer, color = color { layer.backgroundColor = color.CGColor }
        }
    }
    
}


extension NSBezierPath {
    
    public func addLineToPoint(point:CGPoint) {
        lineToPoint(point)
    }
    
    public func CGPath(forceClose forceClose:Bool = false) -> CGPathRef? {
        var cgPath:CGPathRef? = nil
        
        let numElements = self.elementCount
        if numElements > 0 {
            let newPath = CGPathCreateMutable()
            let points = NSPointArray.alloc(3)
            var bDidClosePath:Bool = true
            
            for i in 0 ..< numElements {
                
                switch elementAtIndex(i, associatedPoints:points) {
                    
                case NSBezierPathElement.MoveToBezierPathElement:
                    CGPathMoveToPoint(newPath, nil, points[0].x, points[0].y )
                    
                case NSBezierPathElement.LineToBezierPathElement:
                    CGPathAddLineToPoint(newPath, nil, points[0].x, points[0].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.CurveToBezierPathElement:
                    CGPathAddCurveToPoint(newPath, nil, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.ClosePathBezierPathElement:
                    CGPathCloseSubpath(newPath)
                    bDidClosePath = true
                }
                
                if forceClose && !bDidClosePath {
                    CGPathCloseSubpath(newPath)
                }
            }
            cgPath = CGPathCreateCopy(newPath)
        }
        return cgPath
    }
}