import Foundation


public protocol Hilbertable {
    
    var x : UInt32 { get set }
    var y : UInt32 { get set }
    var hilbertIndices : [UInt32:UInt32] { get set }
    
}


extension SequenceType where Generator.Element : protocol<Hilbertable,JSONConvertible> {
    
    public var JSONIndices : [String:[String:[AnyObject]]] {
        get {
            var dict : [String:[String:[AnyObject]]] = [:]
            
            for element in self {
                for (order,hilbertIndex) in element.hilbertIndices {
                    if var orderDict = dict[order.description] {
                        if var indexDict = orderDict[hilbertIndex.description] {
                            indexDict.append(element.JSONDict)
                            orderDict[hilbertIndex.description] = indexDict
                        } else {
                            orderDict[hilbertIndex.description] = [element.JSONDict]
                        }
                        dict[order.description] = orderDict
                    } else {
                        dict[order.description] = [hilbertIndex.description:[element.JSONDict]]
                    }
                }
            }

            return dict
        }
    }
}
