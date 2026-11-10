import Foundation

enum WeatherService {
    static func url(block: PageBlock, timezone: String) throws -> URL {
        guard block.latitude.isFinite, block.longitude.isFinite, (-90...90).contains(block.latitude), (-180...180).contains(block.longitude), TimeZone(identifier: timezone) != nil else { throw PageError.invalid("Localisation ou fuseau météo invalide.") }
        var c=URLComponents(string:"https://api.open-meteo.com/v1/forecast")!
        c.queryItems=[
            .init(name:"latitude",value:String(block.latitude)),.init(name:"longitude",value:String(block.longitude)),
            .init(name:"current",value:"temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,is_day"),
            .init(name:"hourly",value:"temperature_2m,weather_code,is_day"),
            .init(name:"daily",value:"weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,sunrise,sunset,uv_index_max"),
            .init(name:"temperature_unit",value:block.unit),.init(name:"wind_speed_unit",value:"kmh"),.init(name:"precipitation_unit",value:"mm"),
            .init(name:"timezone",value:timezone),.init(name:"timeformat",value:"unixtime"),.init(name:"forecast_days",value:"4")]
        return c.url!
    }
    private struct Response: Decodable {
        struct Current: Decodable {
            let time: Double
            let temperature_2m: Double
            let weather_code: Int
            let apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m: Double?
            let is_day: Int?
        }
        struct Daily: Decodable {
            let time:[Double]
            let temperature_2m_min,temperature_2m_max:[Double?]
            let weather_code:[Int?]
            let precipitation_probability_max,precipitation_sum,sunrise,sunset,uv_index_max:[Double?]?
        }
        struct Hourly: Decodable {
            let time:[Double]
            let temperature_2m:[Double?]
            let weather_code,is_day:[Int?]
        }
        let current:Current
        let daily:Daily
        let hourly:Hourly
    }
    static func decode(_ data:Data,timezone:String,now:Date=Date()) throws -> WeatherSnapshot {
        let response=try JSONDecoder().decode(Response.self,from:data)
        let c=response.current,d=response.daily,h=response.hourly
        guard c.temperature_2m.isFinite,c.time.isFinite,!d.time.isEmpty else { throw PageError.invalid("Données météo invalides.") }
        func value<T>(_ values:[T?]?,_ i:Int=0)->T? { guard let values,values.indices.contains(i) else { return nil };return values[i] }
        let format=DateFormatter();format.locale=Locale(identifier:"fr_FR");format.timeZone=TimeZone(identifier:timezone);format.dateFormat="EEE d"
        var days:[ForecastDay]=[]
        for i in 1..<min(4,d.time.count,d.temperature_2m_min.count,d.temperature_2m_max.count,d.weather_code.count) {
            if let low=d.temperature_2m_min[i],let high=d.temperature_2m_max[i],let code=d.weather_code[i] {
                days.append(.init(day:format.string(from:Date(timeIntervalSince1970:d.time[i])).capitalized,low:low,high:high,code:code,rainProbability:value(d.precipitation_probability_max,i)))
            }
        }
        let count=min(h.time.count,h.temperature_2m.count,h.weather_code.count,h.is_day.count)
        let start=(0..<count).first { h.time[$0]>now.timeIntervalSince1970 }
        let hours:[HourlyWeather]=start.map { start in
            stride(from:start,to:min(count,start+12),by:3).map { i in
                .init(time:Date(timeIntervalSince1970:h.time[i]),temperature:h.temperature_2m[i],code:h.weather_code[i],isDay:h.is_day[i].map{$0==1})
            }
        } ?? []
        return .init(temperature:c.temperature_2m,code:c.weather_code,days:days,apparentTemperature:c.apparent_temperature,humidity:c.relative_humidity_2m,windSpeed:c.wind_speed_10m,windDirection:c.wind_direction_10m,isDay:c.is_day.map{$0==1},high:value(d.temperature_2m_max),low:value(d.temperature_2m_min),rainProbability:value(d.precipitation_probability_max),rainAmount:value(d.precipitation_sum),uvIndex:value(d.uv_index_max),sunrise:value(d.sunrise).map{Date(timeIntervalSince1970:$0)},sunset:value(d.sunset).map{Date(timeIntervalSince1970:$0)},observedAt:Date(timeIntervalSince1970:c.time),hours:hours)
    }
}

enum WeatherText {
    static func updateTime(_ updated:Date?,relativeTo now:Date,timezone:String)->String {
        guard let updated else {return "—"}
        let zone=TimeZone(identifier:timezone) ?? TimeZone(secondsFromGMT:0)!
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=zone
        let formatter=DateFormatter();formatter.locale=Locale(identifier:"fr_FR");formatter.timeZone=zone
        formatter.dateFormat=calendar.isDate(updated,inSameDayAs:now) ? "HH:mm":"dd/MM HH:mm"
        return formatter.string(from:updated)
    }

    static func number(_ value:Double?,digits:Int=0)->String {
        guard let value,value.isFinite else { return "—" }
        return String(format:digits==0 ? "%.0f":"%.1f",locale:Locale(identifier:"fr_FR"),value)
    }
    static func wind(_ degrees:Double?)->String {
        guard let degrees,degrees.isFinite else { return "—" }
        let normalized=(degrees.truncatingRemainder(dividingBy:360)+360).truncatingRemainder(dividingBy:360)
        return ["N","NE","E","SE","S","SO","O","NO"][Int((normalized/45+0.5).rounded(.down))%8]
    }
    static func glyph(_ code:Int,isDay:Bool=true)->String {
        let key:String
        switch code {
        case 0,1:key="clear"
        case 2:key="partly"
        case 45,48:key="fog"
        case 51...57:key="drizzle"
        case 61...67,80...82:key="rain"
        case 71...77,85,86:key="snow"
        case 95...99:key="storm"
        default:key="cloud"
        }
        return !isDay && ["clear","partly"].contains(key) ? key+"-n":key
    }
    static func condition(_ code:Int)->String {
        switch code {
        case 0:"Ciel dégagé"
        case 1:"Plutôt dégagé"
        case 2:"Partiellement nuageux"
        case 3:"Couvert"
        case 45:"Brouillard"
        case 48:"Brouillard givrant"
        case 51:"Bruine légère"
        case 53:"Bruine"
        case 55:"Bruine dense"
        case 56,57:"Bruine verglaçante"
        case 61:"Pluie faible"
        case 63:"Pluie"
        case 65:"Forte pluie"
        case 66,67:"Pluie verglaçante"
        case 71:"Neige faible"
        case 73:"Neige"
        case 75:"Forte neige"
        case 77:"Grains de neige"
        case 80,81:"Averses"
        case 82:"Fortes averses"
        case 85,86:"Averses de neige"
        case 95:"Orage"
        case 96,99:"Orage et grêle"
        default:"Conditions indisponibles"
        }
    }
}
