//
//  WeatherViewModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 22/4/25.
//

import SwiftUI
import CoreLocation
import Combine

// MARK: - Weather Context
enum WeatherContext {
    case weather
    case forecast
    case widget
}

class WeatherViewModel: ObservableObject {
    // MARK: - Properties
    @Published var weather: WeatherResponse?
    @Published var airQuality: AirQualityResponse?
    @Published var forecast: ForecastResponse?
    @Published var errorMessage: String?
    @Published var locationName: String = "Unknown"
    @Published var searchCity: String = ""
    @Published var citySuggestions: [CitySuggestion] = []
    
    public let locationManager = LocationManager()
    public let weatherService = WeatherService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var weatherCity: String = "Thành phố Hồ Chí Minh"
    @Published var forecastCity: String {
        didSet {
            UserDefaults.standard.set(forecastCity, forKey: "forecastCity")
        }
    }
    @Published var widgetCity: String {
        didSet {
            UserDefaults.standard.set(widgetCity, forKey: "widgetCity")
        }
    }
    
    init() {
        self.forecastCity = UserDefaults.standard.string(forKey: "forecastCity") ?? "Thành phố Hồ Chí Minh"
        self.widgetCity = UserDefaults.standard.string(forKey: "widgetCity") ?? "Thành phố Hồ Chí Minh"
        self.locationName = weatherCity
        fetchWeatherByCity(city: weatherCity, context: .weather) // Khởi tạo với weatherCity ^^
    }
    
    struct CitySuggestion: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let country: String
        let lat: Double
        let lon: Double
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(country)
            hasher.combine(lat)
            hasher.combine(lon)
        }
        
        static func ==(lhs: CitySuggestion, rhs: CitySuggestion) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.country == rhs.country &&
                   lhs.lat == rhs.lat &&
                   lhs.lon == rhs.lon
        }
    }
    
    // MARK: - Location Name for Context
    func locationName(for context: WeatherContext) -> String {
        switch context {
        case .weather:
            return weatherCity
        case .forecast:
            return forecastCity
        case .widget:
            return widgetCity
        }
    }
    
    // MARK: - Fetch Weather and Air Quality
    func fetchWeatherAndAirQuality(lat: Double, lon: Double, context: WeatherContext = .weather) {
        weatherService.fetchCurrentWeather(lat: lat, lon: lon) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weather):
                    switch context {
                    case .weather, .widget:
                        self?.weather = weather
                        self?.locationName = weather.name
                    case .forecast:
                        break
                    }
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = "❌ Failed to fetch weather: \(error.localizedDescription)"
                }
            }
        }
        
        weatherService.fetchAirQuality(lat: lat, lon: lon) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let airQuality):
                    self?.airQuality = airQuality
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = "❌ Failed to fetch air quality: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Fetch Forecast
    func fetchForecast(lat: Double, lon: Double) {
        weatherService.fetchWeatherForecast(lat: lat, lon: lon) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let forecast):
                    self?.forecast = forecast
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = "❌ Failed to fetch forecast: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Fetch Weather by City
    func fetchWeatherByCity(city: String, context: WeatherContext = .weather) {
        weatherService.fetchWeatherByCity(city: city) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weather):
                    switch context {
                    case .weather:
                        self?.weatherCity = city
                        self?.weather = weather
                        self?.locationName = city
                        self?.fetchForecastByCity(city: city)
                    case .forecast:
                        self?.forecastCity = city
                        self?.locationName = city
                        self?.fetchForecastByCity(city: city)
                    case .widget:
                        self?.widgetCity = city
                        self?.weather = weather
                        self?.locationName = city
                    }
                    self?.errorMessage = nil
                    self?.fetchAirQualityByCity(city: city)
                case .failure(let error):
                    self?.errorMessage = "❌ Failed to fetch weather for \(city): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Fetch Forecast by City
    func fetchForecastByCity(city: String) {
        weatherService.fetchForecastByCity(city: city) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let forecast):
                    self?.forecast = forecast
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = "❌ Failed to fetch forecast for \(city): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Fetch Air Quality by City
    func fetchAirQualityByCity(city: String) {
        weatherService.fetchAirQualityByCity(city: city) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let airQuality):
                    self?.airQuality = airQuality
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.errorMessage = "❌ Failed to fetch air quality for \(city): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Get Location Name
    func getLocationName(from location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                self.locationName = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                print("📍 Geocoded: \(self.locationName)")
            } else {
                self.locationName = "Unknown"
                print("❌ Geocode error: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }
    
    // MARK: - Weather for Specific Date
    // Lấy thời tiết dự báo cho ngày cụ thể ^^
    func weatherForDate(_ date: Date) -> (temp: Double, condition: String, icon: String)? {
        guard let forecast = forecast else { return nil }
        
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let targetTimestamp = Int(targetDate.timeIntervalSince1970)
        
        let forecastsForDay = forecast.list.filter { item in
            let itemDate = Date(timeIntervalSince1970: Double(item.dt))
            return calendar.isDate(itemDate, inSameDayAs: targetDate)
        }
        
        guard !forecastsForDay.isEmpty else { return nil }
        
        let avgTemp = forecastsForDay.map { $0.main.temp }.reduce(0, +) / Double(forecastsForDay.count)
        let noonTimestamp = targetTimestamp + 12 * 3600
        let closestForecast = forecastsForDay.min { abs($0.dt - noonTimestamp) < abs($1.dt - noonTimestamp) }
        let condition = closestForecast?.weather.first?.description.capitalized ?? "Unknown"
        let weatherId = closestForecast?.weather.first?.id ?? 0
        
        let icon = weatherIcon(for: weatherId)
        return (temp: avgTemp, condition: condition, icon: icon)
    }
    
    // MARK: - Hourly Forecast
    // Lấy dự báo theo giờ cho ngày hiện tại ^^
    func hourlyForecast(for date: Date) -> [(time: String, temp: Double, condition: String, icon: String)] {
        guard let forecast = forecast else { return [] }
        
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let forecastsForDay = forecast.list.filter { item in
            let itemDate = Date(timeIntervalSince1970: Double(item.dt))
            return calendar.isDate(itemDate, inSameDayAs: targetDate)
        }
        
        return forecastsForDay.map { item in
            let date = Date(timeIntervalSince1970: Double(item.dt))
            let time = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            let temp = item.main.temp
            let condition = item.weather.first?.description.capitalized ?? "Unknown"
            let icon = weatherIcon(for: item.weather.first?.id ?? 0)
            return (time: time, temp: temp, condition: condition, icon: icon)
        }
    }
    
    // MARK: - Weather Icon
    // Ánh xạ biểu tượng thời tiết ^^
    private func weatherIcon(for weatherId: Int) -> String {
        switch weatherId {
        case 200, 201, 202, 230, 231, 232: return "cloud.bolt.rain.fill"
        case 210, 211, 212, 221: return "cloud.bolt.fill"
        case 300, 301, 302, 310, 311, 312, 321: return "cloud.drizzle.fill"
        case 313, 314: return "cloud.rain.fill"
        case 500, 501, 502, 503, 504: return "cloud.rain.fill"
        case 511: return "cloud.sleet.fill"
        case 520, 521, 522, 531: return "cloud.heavyrain.fill"
        case 600, 601, 602, 620, 621, 622: return "cloud.snow.fill"
        case 611, 612, 613, 615, 616: return "cloud.sleet.fill"
        case 701, 741: return "cloud.fog.fill"
        case 711, 762: return "smoke.fill"
        case 721: return "sun.haze.fill"
        case 731, 751, 761: return "sun.dust.fill"
        case 771: return "wind"
        case 781: return "tornado"
        case 800: return "sun.max.fill"
        case 801, 802, 803, 804: return "cloud.fill"
        default: return "cloud.fill"
        }
    }
    
    // MARK: - AQI Description
    // Lấy mô tả AQI = Air Quality Index – chỉ số chất lượng không khí ^^
    var aqiDescription: String {
        guard let aqi = airQuality?.list.first?.main.aqi else { return "Unknown" }
        switch aqi {
        case 0...50: return "Tốt"
        case 51...100: return "Trung bình"
        case 101...150: return "Kém"
        case 151...200: return "Xấu"
        case 201...300: return "Rất Xấu"
        case 301...: return "Nguy hại"
        default: return "Unknown"
        }
    }
    
    // MARK: - AQI Color
    var aqiColor: Color {
        guard let aqi = airQuality?.list.first?.main.aqi else { return .gray }
        switch aqi {
        case 0...50: return .green
        case 51...100: return .yellow
        case 101...150: return .orange
        case 151...200: return .red
        case 201...300: return .purple
        case 301...: return .black
        default: return .gray
        }
    }
    
    // MARK: - PM2.5 Description
    var pm25Description: String {
        guard let pm25 = airQuality?.list.first?.components.pm2_5 else { return "Unknown" }
        switch pm25 {
        case 0...35: return "Tốt"
        case 36...75: return "Trung bình"
        case 76...115: return "Kém"
        case 116...150: return "Xấu"
        case 151...250: return "Rất Xấu"
        case 251...: return "Nguy hại"
        default: return "Unknown"
        }
    }
    
    // MARK: - Sunrise/Sunset Time
    var sunriseTime: String {
        guard let sunrise = weather?.sys.sunrise else { return "Unknown" }
        let date = Date(timeIntervalSince1970: Double(sunrise))
        return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
    
    var sunsetTime: String {
        guard let sunset = weather?.sys.sunset else { return "Unknown" }
        let date = Date(timeIntervalSince1970: Double(sunset))
        return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
    
    // MARK: - Fetch City Suggestions
    func fetchCitySuggestions(query: String) {
        guard !query.isEmpty else {
            citySuggestions = []
            return
        }
        
        let queries = [query, query.lowercased().folding(options: .diacriticInsensitive, locale: .current)]
        var allSuggestions: [CitySuggestion] = []
        
        let group = DispatchGroup()
        
        for q in queries {
            group.enter()
            weatherService.fetchCitySuggestions(query: q) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let suggestions):
                        allSuggestions.append(contentsOf: suggestions.map {
                            CitySuggestion(name: $0.name, country: $0.country, lat: $0.lat, lon: $0.lon)
                        })
                        print("✅ Suggestions for '\(q)': \(suggestions.map { $0.name })")
                    case .failure(let error):
                        print("❌ City suggestion error for '\(q)': \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            let uniqueSuggestions = Array(Set(allSuggestions)).sorted { $0.name < $1.name }
            self?.citySuggestions = uniqueSuggestions
            
            if queries.contains(where: { $0.lowercased().contains("Ho Chi Minh") }) {
                if !uniqueSuggestions.contains(where: { $0.name == "Thành phố Hồ Chí Minh" }) {
                    self?.citySuggestions.append(CitySuggestion(name: "Thành phố Hồ Chí Minh", country: "VN", lat: 10.7769, lon: 106.7009))
                }
            }
        }
    }
    
    // MARK: - Fetch Weather by Coordinates
    func fetchWeatherByCoordinates(lat: Double, lon: Double, cityName: String, context: WeatherContext = .weather) {
        switch context {
        case .weather:
            self.weatherCity = cityName
            self.locationName = cityName
            fetchForecast(lat: lat, lon: lon)
        case .forecast:
            self.forecastCity = cityName
            self.locationName = cityName
            fetchForecast(lat: lat, lon: lon)
        case .widget:
            self.widgetCity = cityName
            self.locationName = cityName
        }
        fetchWeatherAndAirQuality(lat: lat, lon: lon, context: context)
    }
    
    // MARK: - Refresh Layout
    func refreshLayout() {
        objectWillChange.send()
    }
}
