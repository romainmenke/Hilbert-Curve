
import Foundation

extension Array {
    
    func safeRead(index:Int) -> Element? {
        if count > index { return self[index] } else { return nil }
    }
}


public class DataSet {
    
    public var cities : [City]
    public var populations : [Population] = []
    
    public init() {
        cities = SimpleCSV.generateBelgianCityData()
        populations = SimpleCSV.generatePopulationData()
        let worldCities = SimpleCSV.generateCityData()
        
        for city in cities {
            if let wCity = (worldCities.filter { $0.name == city.name }).first {
                city.merge(withCity: wCity)
            }
        }
        
        for city in cities {
            let same = cities.filter {
                if $0.name == city.name && $0.latitude == city.latitude && $0.longitude == city.longitude {
                    return true
                } else if $0.zip == city.zip && $0.latitude == city.latitude && $0.longitude == city.longitude {
                    return true
                } else {
                    return false
                }
            }
            if let main = (same.sort { $0.zip < $1.zip }).first {
                cities = cities.filter { $0.name != city.name }
                cities.append(main)
            }
        }
        
        for (index,pop) in populations.enumerate() {
            if let city = (cities.filter { $0.name == pop.cityName }).first {
                city.population = pop
                populations[index].city = city
            }
        }
    }
}

public class City : Hilbertable, Hashable {
    
    public var name : String = ""
    public var city_ascii : String = ""
    public var latitude : Double = 0
    public var longitude : Double = 0
    public var zip : String = ""
    public var country : String = ""
    public var iso2 : String = ""
    public var iso3 : String = ""
    public var province : String = ""
    
    public var population : Population? = nil
    
    public var x : UInt32 = 0
    public var y : UInt32 = 0
    public var hilbertIndices : [UInt32:UInt32] = [:]
    
    public var hashValue: Int { get { return "\(name)\(zip)\(longitude)\(latitude)".hashValue } }
    
    public required init(latitude : Double, longitude : Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(dataString:String) {
        let data = dataString.componentsSeparatedByString(",")
        
        name = (data.safeRead(0) ?? "").lowercaseString
        city_ascii = (data.safeRead(1) ?? "")
        latitude = Double((data.safeRead(2) ?? "")) ?? 0
        longitude = Double((data.safeRead(3) ?? "")) ?? 0
        country = (data.safeRead(5) ?? "").lowercaseString
        iso2 = (data.safeRead(6) ?? "")
        iso3 = (data.safeRead(7) ?? "")
        province = (data.safeRead(8) ?? "").lowercaseString
    }
    
    public init(belgianDataString:String) {
        var data = belgianDataString.componentsSeparatedByString(",")
        
        zip = (data.safeRead(0) ?? "")
        name = (data.safeRead(1) ?? "").lowercaseString
        latitude = Double((data.popLast() ?? "")) ?? 0
        longitude = Double((data.popLast() ?? "")) ?? 0
    }
    
    func merge(withCity city : City) {
        if city_ascii.isEmpty { city_ascii = city.city_ascii }
        if zip.isEmpty { zip = city.zip }
        if iso2.isEmpty { iso2 = city.iso2 }
        if iso3.isEmpty { iso3 = city.iso3 }
        if province.isEmpty { province = city.province }
    }
}

public func ==(lhs:City,rhs:City) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension City : CustomStringConvertible {
    
    public var description : String {
        get {
            var descr : String = ""
            descr += "<------- City ------->\n"
            descr += "name    : \(name)\n"
            descr += "lat     : \(latitude) long: \(longitude)\n"
            descr += "zip     : \(zip)\n"
            descr += "country : \(country)\n"
            descr += "<-------------------->"
            if let population = population {
                descr += "\n"
                descr += population.description
            }
            return descr
        }
    }
}

extension City : JSONConvertible {
    
    public var JSONDict : [String:AnyObject] {
        get {
            var dict : [String:AnyObject] = [:]
            if !name.isEmpty { dict["name"] = name }
            if latitude != 0 { dict["latitude"] = latitude }
            if longitude != 0 { dict["longitude"] = longitude }
            if !zip.isEmpty { dict["zip"] = zip }
            dict["country"] = "BE"
            if !iso2.isEmpty { dict["iso2"] = iso2 }
            if !iso3.isEmpty { dict["iso3"] = iso3 }
            if !province.isEmpty { dict["province"] = province }
            
            if let population = population {
                if population.population != 0 { dict["population"] = population.population }
                if population.area != 0 { dict["area"] = population.area }
                if population.populationPerKM2 != 0 { dict["populationPerKM2"] = population.populationPerKM2 }
            }
            
//            if hilbertIndices.count > 0 {
//                var hilbertObject : [String:NSNumber] = [:]
//                for (key,value) in hilbertIndices {
//                    hilbertObject[key.description] = NSNumber(unsignedInt: value)
//                }
//                
//                dict["hilbertIndices"] = hilbertObject
//            }
            return dict
        }
    }
}

extension City : CustomPlaygroundQuickLookable {
    
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        return PlaygroundQuickLook.Text(description)
    }
}

public struct Population {
    
    public weak var city : City?
    public var cityName : String = ""
    public var population : Int = 0
    public var area : Int = 0
    public var populationPerKM2 : Int = 0
    
    public init() {}
    
    public init(dataString:String) {
        let data = dataString.componentsSeparatedByString(",")
        guard data.count > 0 else {
            return
        }
        cityName = (data.safeRead(0) ?? "").lowercaseString
        population = Int(data.safeRead(1) ?? "") ?? 0
        area = Int(data.safeRead(2) ?? "") ?? 0
        populationPerKM2 = Int(data.safeRead(3) ?? "") ?? 0
    }
}

extension Population : CustomStringConvertible {
    
    public var description : String {
        get {
            var descr : String = ""
            descr += "<------- Population ------->\n"
            descr += "name  : \(cityName)\n"
            descr += "pop   : \(population)\n"
            descr += "area  : \(area)\n"
            descr += "p/km2 : \(populationPerKM2)\n"
            descr += "<-------------------------->"
            
            return descr
        }
    }
}

extension Population : CustomPlaygroundQuickLookable {
    
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        return PlaygroundQuickLook.Text(description)
    }
}

public class SimpleCSV {
    
    public static func generateCityData() -> [City] {
        
        let csvString = try! String(contentsOfFile: "/Users/romainmenke/Desktop/Hilbert-Curve/MetalHilbert.playground/Resources/cities.csv")
        var rows = csvString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var cities : [City] = []
        let _ = rows.removeFirst()
        
        for row in rows {
            let city = City(dataString: row)
            cities.append(city)
        }
        
        return cities
    }
    
    public static func generateBelgianCityData() -> [City] {
        
        let csvString = try! String(contentsOfFile: "/Users/romainmenke/Desktop/Hilbert-Curve/MetalHilbert.playground/Resources/citiesBE.csv")
        var rows = csvString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var cities : [City] = []
        let _ = rows.removeFirst()
        
        for row in rows {
            let city = City(belgianDataString: row)
            cities.append(city)
        }
        
        return cities
    }
    
    public static func generatePopulationData() -> [Population] {
        
        let csvString = try! String(contentsOfFile: "/Users/romainmenke/Desktop/Hilbert-Curve/MetalHilbert.playground/Resources/bevolking.csv")
        var rows = csvString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var populations : [Population] = []
        let _ = rows.removeFirst()
        
        for row in rows {
            let population = Population(dataString: row)
            populations.append(population)
        }
        
        return populations
    }
}