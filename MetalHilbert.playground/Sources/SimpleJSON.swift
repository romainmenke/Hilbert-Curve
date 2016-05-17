import Foundation
import Cocoa

public class SimpleJSON {
    
    public static func writeJSONToFile(object:AnyObject) -> Bool {
        
        if NSJSONSerialization.isValidJSONObject(object) {
            do {
                let rawData = try NSJSONSerialization.dataWithJSONObject(object, options: .PrettyPrinted)
                return SimpleFileWriter.writeToFile(text: (NSString(data: rawData, encoding: NSUTF8StringEncoding) ?? "") as String)
            } catch {
                return false
            }
        } else { return false }
    }
}


public class SimpleFileWriter {
    
    public static func writeToFile(text text: String) -> Bool {
        
        let path = "/Users/romainmenke/Desktop/Hilbert-Curve/MetalHilbert.playground/Resources/indices.json"
        
        do {
            try text.writeToFile(path, atomically:true, encoding:NSUTF8StringEncoding)
            return true
        } catch {
            return false
        }
    }
}