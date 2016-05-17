import Cocoa


extension MetalHilbert : CustomPlaygroundQuickLookable {
    
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        
        guard curve.count > 1 else {
            return PlaygroundQuickLook.View(NSView(frame: CGRectZero))
        }
        
        func convertToFloat(xy:(UInt32,UInt32)) -> (CGFloat,CGFloat) { return (CGFloat(xy.0 * 10), CGFloat(xy.1 * 10)) }
        func convertToPoint(xy:(UInt32,UInt32)) -> CGPoint { return CGPoint(x:CGFloat(xy.0 * 10 + 10), y:CGFloat(xy.1 * 10 + 10)) }
        
        let maxX = ((curve.map { return $0.0 }).maxElement() ?? 0) * 10
        let maxY = ((curve.map { return $0.1 }).maxElement() ?? 0) * 10
        
        let path = XBezierPath()
        path.moveToPoint(convertToPoint(curve[0]))
        for i in 1..<curve.count {
            if curve[i] == (0,0) { continue }
            path.addLineToPoint(convertToPoint(curve[i]))
        }
        
        let drawLayer = CAShapeLayer()
        drawLayer.path = path.CGPath()
        drawLayer.strokeColor = XColor.redColor().CGColor
        drawLayer.fillColor = XColor.whiteColor().CGColor
        
        let view = XView(frame: CGRect(x: 0, y: 0, width: CGFloat(maxX) + 20, height: CGFloat(maxY) + 20))
        view.wantsLayer = true
        view.backgroundColor = XColor.whiteColor()
        view.layer?.addSublayer(drawLayer)
        
        return PlaygroundQuickLook.View(view)
    }
}