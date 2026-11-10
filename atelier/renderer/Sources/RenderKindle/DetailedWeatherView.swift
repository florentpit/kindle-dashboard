import SwiftUI

/// Same information, typography scale and vector icons as generator/generate.py.
/// Fixed design coordinates preserve the reference layout at every editor zoom.
struct DetailedWeatherView: View {
    let block:PageBlock
    let page:KindlePage
    var date=Date()
    private var weather:WeatherSnapshot? { page.sources.weather["\(block.city)|\(block.unit)"] }
    private var header:Bool { block.weatherHeader != false }
    static let designWidth:Double=984
    static func designHeight(header:Bool)->Double { header ? 683:558 }
    var body:some View {
        let width=max(1,block.width-block.padding*2),height=max(1,block.height-block.padding*2)
        let scale=min(width/Self.designWidth,height/Self.designHeight(header:header))
        content
            .frame(width:Self.designWidth,height:Self.designHeight(header:header),alignment:.topLeading)
            .scaleEffect(scale,anchor:.topLeading)
            .frame(width:width,height:height,alignment:.topLeading)
            .lineSpacing(0)
    }
    private var content:some View {
        VStack(spacing:0) {
            if header {
                HStack(alignment:.bottom) {
                    VStack(alignment:.leading,spacing:6) {
                        Text(location.uppercased()).font(.custom("Inter",size:28 * block.fontSize / 32).weight(.bold)).tracking(3)
                        Text(formatted(date,"EEEE d MMMM").prefix(1).uppercased()+formatted(date,"EEEE d MMMM").dropFirst())
                            .font(.custom(block.fontName,size:66 * block.fontSize / 32).weight(.semibold)).lineLimit(1).minimumScaleFactor(0.65)
                    }
                    Spacer(minLength:20)
                    VStack(alignment:.trailing,spacing:4) {
                        Text("Mis à jour")
                        Text(updateTime).bold()
                    }.font(.custom("Inter",size:28 * block.fontSize / 32))
                }.padding(.bottom,14).frame(height:122,alignment:.bottom)
                rule(3)
            }
            HStack(spacing:28) {
                WeatherGlyph(code:weather?.code ?? -1,isDay:weather?.isDay ?? true,stroke:1.4).frame(width:148,height:148)
                Text(WeatherText.number(weather?.temperature)+"°").font(.custom(block.fontName,size:170 * block.fontSize / 32).weight(.medium))
                    .tracking(-5).frame(width:180,alignment:.leading).lineLimit(1).minimumScaleFactor(0.65)
                VStack(alignment:.leading,spacing:10) {
                    Text(weather.map{WeatherText.condition($0.code)} ?? "Données à charger")
                        .font(.custom(block.fontName,size:52 * block.fontSize / 32).weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6)
                    VStack(alignment:.leading,spacing:3) {
                        Text("Ressenti \(WeatherText.number(weather?.apparentTemperature))° · Vent \(WeatherText.number(weather?.windSpeed)) km/h \(WeatherText.wind(weather?.windDirection))")
                        Text("Humidité \(WeatherText.number(weather?.humidity)) % · UV \(WeatherText.number(weather?.uvIndex))")
                    }.font(.custom("Inter",size:32 * block.fontSize / 32)).lineLimit(1).minimumScaleFactor(0.65)
                }.frame(maxWidth:.infinity,alignment:.leading)
            }.frame(height:184)
            HStack(spacing:16) {
                (Text(WeatherText.number(weather?.high)+"°").bold()+Text(" max · ")+Text(WeatherText.number(weather?.low)+"°").bold()+Text(" min"))
                Spacer(minLength:0)
                (Text("Pluie ")+Text(WeatherText.number(weather?.rainProbability)+" %").bold()+Text(" · "+WeatherText.number(weather?.rainAmount,digits:1)+" mm"))
                Spacer(minLength:0)
                Text("Soleil \(time(weather?.sunrise)) – \(time(weather?.sunset))")
            }.font(.custom("Inter",size:30 * block.fontSize / 32)).lineLimit(1).minimumScaleFactor(0.75).frame(height:56)
            rule(2)
            HStack(spacing:0) {
                ForEach(0..<4,id:\.self) { index in
                    if index>0 { Rectangle().fill(Color(white:0.6)).frame(width:1) }
                    let hours=weather?.hours ?? []
                    let hour=hours.indices.contains(index) ? hours[index]:nil
                    HStack {
                        VStack(alignment:.leading,spacing:5) {
                            Text(hour.map{formatted($0.time,"HH'h'")} ?? "—h").font(.custom("Inter",size:32 * block.fontSize / 32).weight(.semibold))
                            Text(WeatherText.number(hour?.temperature)+"°").font(.custom("Inter",size:46 * block.fontSize / 32).weight(.bold))
                        }
                        Spacer(minLength:8)
                        WeatherGlyph(code:hour?.code ?? -1,isDay:hour?.isDay ?? true).frame(width:64,height:64)
                    }.padding(.horizontal,18).frame(maxWidth:.infinity)
                }
            }.frame(height:124)
            rule(2)
            HStack(alignment:.top,spacing:28) {
                ForEach(0..<3,id:\.self) { index in
                    let days=weather?.days ?? []
                    let day=days.indices.contains(index) ? days[index]:nil
                    VStack(alignment:.leading,spacing:6) {
                        HStack {
                            Text(day?.day ?? "J+\(index+1)").font(.custom("Inter",size:32 * block.fontSize / 32).weight(.bold))
                            Spacer()
                            WeatherGlyph(code:day?.code ?? -1).frame(width:56,height:56)
                        }
                        (Text(WeatherText.number(day?.high)+"°").bold()+Text(" "+WeatherText.number(day?.low)+"°").foregroundColor(Color(white:0.2)))
                            .font(.custom("Inter",size:44 * block.fontSize / 32))
                        Text(WeatherText.number(day?.rainProbability)+" % pluie").font(.custom("Inter",size:30 * block.fontSize / 32))
                    }.frame(maxWidth:.infinity,alignment:.leading)
                }
            }.padding(.top,12).frame(height:188,alignment:.top)
            rule(2)
        }.foregroundStyle(Color(white:block.ink)).lineSpacing(0)
    }
    private var location:String {
        let region=block.region ?? (block.city=="Bouliac" ? "Gironde":"")
        return block.city+(region.isEmpty ? "":" · "+region)
    }
    private var updateTime:String {
        WeatherText.updateTime(page.sources.fetchedAt ?? weather?.observedAt,relativeTo:date,timezone:page.schedule.timezone)
    }
    private func time(_ date:Date?)->String { date.map{formatted($0,"HH:mm")} ?? "—" }
    private func formatted(_ date:Date,_ format:String)->String {
        let f=DateFormatter();f.locale=Locale(identifier:"fr_FR");f.timeZone=TimeZone(identifier:page.schedule.timezone);f.dateFormat=format;return f.string(from:date)
    }
    private func rule(_ height:Double)->some View { Rectangle().frame(height:height) }
}
