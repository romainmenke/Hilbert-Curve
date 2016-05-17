import Foundation
import Cocoa

public protocol GeoPointType {
    
    var latitude : Double { get set }
    var longitude : Double { get set }
    
    init(latitude : Double, longitude : Double)
    
}

extension GeoPointType {
    
    public init(latitude : Float, longitude : Float) {
        self.init(latitude: Double(latitude),longitude: Double(longitude))
    }
    
    public func normaliseGeoPointForHilbert() -> (UInt32,UInt32) {
        
        func convertGeoToUInt32(double:Double) -> UInt32 {
            return UInt32(abs(min(360, double + 180)) / 360 * 4294967295)
        }
        
        return (convertGeoToUInt32(latitude),convertGeoToUInt32(longitude))
    }
    
    public static func deNormaliseGeoPointForHilbert(lat:UInt32,long:UInt32) -> Self {
        func convertUInt32ToGeo(uint:UInt32) -> Double {
            return (Double(uint) / 4294967295 * 360) - 180
        }
        return Self(latitude: convertUInt32ToGeo(lat),longitude: convertUInt32ToGeo(long))
    }
}

public struct GeoPoint : GeoPointType {
    
    public var latitude : Double
    public var longitude : Double
    
    public init(latitude : Double, longitude : Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension GeoPoint : CustomPlaygroundQuickLookable {
    
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        return PlaygroundQuickLook.Text("latitude : \(latitude), longitude : \(longitude)")
    }
}

extension SequenceType where Generator.Element : protocol<GeoPointType,Hilbertable,Hashable> {
    
    public func generateHilbertIndices(order order:UInt32) -> [Generator.Element]? {
        
        var array : [Hilbertable] = []
        
        for var element in self {
            let norm = element.normaliseGeoPointForHilbert()
            element.x = norm.0
            element.y = norm.1
            array.append(element)
        }
        
        if let hilbertIndices = MetalHilbert.hilbertXYToIndex(order, xy: array) {
            var result : [Generator.Element] = []
            for element in hilbertIndices {
                if let hilbertable = element as? Generator.Element {
                    result.append(hilbertable)
                }
            }
            return result
        }
        
        return nil
    }
    
    public func generateHilbertIndicesFullSpread(withMargin margin: UInt32) -> [Generator.Element]? {
        
        var reachedFullSpread = false
        var currentOrder : UInt32 = 1
        
        var result : [Generator.Element]?
        
        while reachedFullSpread == false {
            if let indexed = generateHilbertIndices(order: currentOrder) {
                
                let indices = indexed.map { ($0.hilbertIndices[currentOrder]!,$0.x,$0.y) }
                
                for (index,x,y) in indices {
                    let matches = indices.filter {
                        if $0.0 == index {
                            if $0.1 == x && $0.2 == y {
                                return false
                            } else {
                                return true
                            }
                        } else {
                            return false
                        }
                    }
                    if matches.count > 0 {
                        currentOrder += 1
                        break
                    } else {
                        result = indexed
                        reachedFullSpread = true
                    }
                }
            }
        }
        
        for i in currentOrder..<(currentOrder + margin) { result = generateHilbertIndices(order: i) }
        
        return result
    }
}
