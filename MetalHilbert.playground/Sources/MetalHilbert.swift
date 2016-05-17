import Foundation
import Metal

public struct MetalHilbert {
    
    public var curve : [(UInt32,UInt32)]
    
    public static func hilbertXYToIndex<S: _ArrayType where S.Generator.Element == Hilbertable, S.Index.Distance == Int>(n:UInt32, xy:S) -> [S.Generator.Element]? {
        
        var n = n
        let hilbertXPoints = xy.map { $0.x }
        let hilbertYPoints = xy.map { $0.y }
        
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
        
        let threads : Int
        let groups : Int
        let bufferSize : Int
        
        if device.maxThreadsPerThreadgroup.width < xy.count {
            threads = device.maxThreadsPerThreadgroup.width
            groups = (xy.count / threads) + 1
            bufferSize = groups * threads
        } else {
            threads = xy.count
            groups = 1
            bufferSize = xy.count
        }
        
        let hilbertXBuffer = device.newBufferWithBytes(hilbertXPoints, length: bufferSize * sizeof(uint), options: [])
        let hilbertYBuffer = device.newBufferWithBytes(hilbertYPoints, length: bufferSize * sizeof(uint), options: [])
        let hilbertNBuffer = device.newBufferWithBytes(&n, length: sizeof(uint), options: [])
        var outputVector = [uint](count: bufferSize, repeatedValue: 0)
        let outputMetalBuffer = device.newBufferWithBytes(outputVector, length: bufferSize * sizeof(uint), options: [])
        
        let buffer = commandQueue.commandBuffer()
        let encoder = buffer.computeCommandEncoder()
        
        encoder.setComputePipelineState(hilbertPipelineState)
        
        encoder.setBuffer(hilbertNBuffer, offset: 0, atIndex: 0)
        encoder.setBuffer(hilbertXBuffer, offset: 0, atIndex: 1)
        encoder.setBuffer(hilbertYBuffer, offset: 0, atIndex: 2)
        encoder.setBuffer(outputMetalBuffer, offset: 0, atIndex: 3)
        
        let threadgroupCounts = MTLSize(width: threads, height: 1, depth: 1)
        let threadgroups = MTLSize(width: groups, height: 1, depth: 1)
        
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
        
        var output : [S.Generator.Element] = []
        
        for (index,element) in xy.enumerate() {
            var subject = element
            subject.hilbertIndices[n] = outputVector[index]
            output.append(subject)
        }
        
        return output
    }
    
    
    public static func hilbertIndexToXY(n:UInt32, i:Int) -> MetalHilbert? {
        
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
    
    public static func hilbertIndexToXY(n:UInt32) -> MetalHilbert? {
        
        let i = pow(4, Double(n))
        
        return hilbertIndexToXY(n, i: Int(i))
    }
}

