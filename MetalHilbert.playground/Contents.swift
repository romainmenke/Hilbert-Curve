//: Playground - noun: a place where people can play

import XCPlayground
import Cocoa
import Metal


typealias XView = NSView
typealias XColor = NSColor
typealias XBezierPath = NSBezierPath


extension NSView {
    
    var backgroundColor : XColor? {
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

    func addLineToPoint(point:CGPoint) {
        lineToPoint(point)
    }
    
    func CGPath(forceClose forceClose:Bool = false) -> CGPathRef? {
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


struct MetalHilbert {
    
    var curve : [(UInt32,UInt32)]
    
    static func hilbertXYToIndex(n:UInt32, xy:[(x:UInt32, y:UInt32)]) -> [UInt32]? {
        
        var n = n
        let hilbertXPoints = xy.map { $0.0 }
        let hilbertYPoints = xy.map { $0.1 }
        
        let maybeDevice = MTLCopyAllDevices().filter{ $0.lowPower }.first ?? MTLCreateSystemDefaultDevice()
        
        let maybeCommandQueue = maybeDevice?.newCommandQueue()
        let maybeShaderSource = try? String(contentsOfURL: [#FileReference(fileReferenceLiteral: "Shader.metal")#])
        
        guard let device = maybeDevice, commandQueue = maybeCommandQueue, shaderSource = maybeShaderSource else {
            return nil
        }
        
        let maybeLibrary = try? device.newLibraryWithSource(shaderSource, options: nil)
        let maybeHilbertShader = maybeLibrary?.newFunctionWithName("hilbertXYToIndex")
        
        guard let hilbertShader = maybeHilbertShader else {
            return nil
        }
        
        let maybeHilbertPipelineState = try? device.newComputePipelineStateWithFunction(hilbertShader)
        
        guard let hilbertPipelineState = maybeHilbertPipelineState else {
            return nil
        }
        
        
        let hilbertXBuffer = device.newBufferWithBytes(hilbertXPoints, length: xy.count * sizeof(uint), options: [])
        let hilbertYBuffer = device.newBufferWithBytes(hilbertYPoints, length: xy.count * sizeof(uint), options: [])
        let hilbertNBuffer = device.newBufferWithBytes(&n, length: sizeof(uint), options: [])
        var outputVector = [uint](count: xy.count, repeatedValue: 0)
        let outputMetalBuffer = device.newBufferWithBytes(outputVector, length: xy.count * sizeof(uint), options: [])
        
        let buffer = commandQueue.commandBuffer()
        let encoder = buffer.computeCommandEncoder()
        
        encoder.setComputePipelineState(hilbertPipelineState)
        
        encoder.setBuffer(hilbertNBuffer, offset: 0, atIndex: 0)
        encoder.setBuffer(hilbertXBuffer, offset: 0, atIndex: 1)
        encoder.setBuffer(hilbertYBuffer, offset: 0, atIndex: 2)
        encoder.setBuffer(outputMetalBuffer, offset: 0, atIndex: 3)
        
        let threadgroupCounts = MTLSize(width: min(device.maxThreadsPerThreadgroup.width, outputVector.count), height: 1, depth: 1)
        let threadgroups = MTLSize(width: max((outputVector.count / device.maxThreadsPerThreadgroup.width), 1), height: 1, depth: 1)
        
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        
        // Finalize configuration
        encoder.endEncoding()
        
        // Start job
        buffer.commit()
        
        // Wait for it to finish
        buffer.waitUntilCompleted()
        
        // Get output data from Metal/GPU into Swift
        let data = NSData(bytesNoCopy: outputMetalBuffer.contents(),
                          length: outputVector.count*sizeof(uint), freeWhenDone: false)
        data.getBytes(&outputVector, length:outputVector.count * sizeof(uint))
        
        return outputVector

    }
    
    
    static func hilbertIndexToXY(n:UInt32, i:Int) -> MetalHilbert? {
        
        var n = n
        
        let maybeDevice = MTLCopyAllDevices().filter{ $0.lowPower }.first ?? MTLCreateSystemDefaultDevice()
        
        let maybeCommandQueue = maybeDevice?.newCommandQueue()
        let maybeShaderSource = try? String(contentsOfURL: [#FileReference(fileReferenceLiteral: "Shader.metal")#])
        
        guard let device = maybeDevice, commandQueue = maybeCommandQueue, shaderSource = maybeShaderSource else {
            return nil
        }
        
        let maybeLibrary = try? device.newLibraryWithSource(shaderSource, options: nil)
        let maybeHilbertShader = maybeLibrary?.newFunctionWithName("hilbertIndexToXY")
        
        guard let hilbertShader = maybeHilbertShader else {
            return nil
        }
        
        let maybeHilbertPipelineState = try? device.newComputePipelineStateWithFunction(hilbertShader)
        
        guard let hilbertPipelineState = maybeHilbertPipelineState else {
            return nil
        }
        
        let hilbertNBuffer = device.newBufferWithBytes(&n, length: sizeof(uint), options: [])
        var outputVectorX = [uint](count: i, repeatedValue: 0)
        var outputVectorY = [uint](count: i, repeatedValue: 0)
        let outputMetalBufferX = device.newBufferWithBytes(outputVectorX, length: i * sizeof(uint), options: [])
        let outputMetalBufferY = device.newBufferWithBytes(outputVectorY, length: i * sizeof(uint), options: [])
        
        let buffer = commandQueue.commandBuffer()
        let encoder = buffer.computeCommandEncoder()
        
        encoder.setComputePipelineState(hilbertPipelineState)
        
        encoder.setBuffer(hilbertNBuffer, offset: 0, atIndex: 0)
        encoder.setBuffer(outputMetalBufferX, offset: 0, atIndex: 1)
        encoder.setBuffer(outputMetalBufferY, offset: 0, atIndex: 2)
        
        let threadgroupCounts = MTLSize(width: min(device.maxThreadsPerThreadgroup.width, i), height: 1, depth: 1)
        let threadgroups = MTLSize(width: max((i / device.maxThreadsPerThreadgroup.width), 1), height: 1, depth: 1)
        
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
        
        // Finalize configuration
        encoder.endEncoding()
        
        // Start job
        buffer.commit()
        
        // Wait for it to finish
        buffer.waitUntilCompleted()
        
        // Get output data from Metal/GPU into Swift
        let xdata = NSData(bytesNoCopy: outputMetalBufferX.contents(), length: outputVectorX.count*sizeof(uint), freeWhenDone: false)
        xdata.getBytes(&outputVectorX, length:outputVectorX.count * sizeof(uint))
        
        let ydata = NSData(bytesNoCopy: outputMetalBufferY.contents(), length: outputVectorY.count*sizeof(uint), freeWhenDone: false)
        ydata.getBytes(&outputVectorY, length:outputVectorY.count * sizeof(uint))
        
        return MetalHilbert(curve: zip(outputVectorX, outputVectorY).map { $0 })
        
    }
}

extension MetalHilbert : CustomPlaygroundQuickLookable {
    
    func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        
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



let hilbert = MetalHilbert.hilbertIndexToXY(5, i: 200)

