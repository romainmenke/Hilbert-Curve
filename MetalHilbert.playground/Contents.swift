//: Playground - noun: a place where people can play

import XCPlayground
import Cocoa
import Metal





let lat = 51.2199261
let long = 4.433957
let latInt : UInt32 = UInt32(lat * pow(10, 6))
let longInt : UInt32 = UInt32(long * pow(10, 6))

let geo1 = GeoPoint(latitude: lat, longitude: long)
geo1.normaliseGeoPointForHilbert()

GeoPoint.deNormaliseGeoPointForHilbert(geo1.normaliseGeoPointForHilbert().0,long: geo1.normaliseGeoPointForHilbert().1)

extension City : GeoPointType {}


var dataSet = DataSet()

for i in 1...16 {
    dataSet.cities = dataSet.cities.generateHilbertIndices(order: UInt32(i))!
}

let maxIndex = dataSet.cities.first!.hilbertIndices.keys.sort().last!

print(dataSet.cities.first!.hilbertIndices)

//for city in cities! {
//    let matches = cities?.filter { $0.hilbertIndices[maxIndex]! == city.hilbertIndices[maxIndex]! && $0 != city }
//    for match in matches! {
//        print(match)
//        print(city)
//        print("\n")
//        print(match.x, match.y)
//        print(city.x, city.y)
//        print("\n")
//        print(match.hilbertIndices[maxIndex]!)
//        print(city.hilbertIndices[maxIndex]!)
//        print("\n")
//    }
//}


var jsonData = dataSet.cities.JSONIndices

print(jsonData.keys.count)


SimpleJSON.writeJSONToFile(jsonData)



//let hilbert = MetalHilbert.hilbertIndexToXY(9)



