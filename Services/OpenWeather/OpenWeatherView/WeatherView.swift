//
//  WeatherView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 22/4/25.
//

import SwiftUI

struct WeatherView: View {
    // MARK: - Properties
    @EnvironmentObject var weatherVM: WeatherViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var cityInput: String = ""
    @State private var showForecastCityInput: Bool = false
    @State private var showWidgetCityInput: Bool = false
    @State private var newCityInput: String = ""
    @State private var lastContext: WeatherContext = .weather
    @State private var isAirQualityExpanded: Bool = false
    @State private var isWeatherDetailsExpanded: Bool = false
    @State private var isWeatherConditionsExpanded: Bool = false
    
    // MARK: - Weather Description Model
    struct WeatherDescription: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
    }
    
    let weatherDescriptions: [WeatherDescription] = [
        .init(icon: "sun.max.fill", title: "Clear - Trời quang", description: "Bầu trời trong xanh, không có mây."),
        .init(icon: "cloud.sun.fill", title: "Scattered Clouds - Mây rải rác", description: "Trời có mây, mây phân bố rải rác."),
        .init(icon: "cloud.fill", title: "Broken Clouds - Mây cụm", description: "Trời nhiều mây, có vài khoảng trời quang."),
        .init(icon: "smoke.fill", title: "Overcast - Trời âm u", description: "Bầu trời phủ đầy mây."),
        .init(icon: "cloud.drizzle.fill", title: "Light Rain - Mưa nhẹ", description: "Mưa nhỏ, giọt mưa bé."),
        .init(icon: "cloud.rain.fill", title: "Moderate Rain - Mưa vừa", description: "Mưa đều, không quá lớn."),
        .init(icon: "cloud.heavyrain.fill", title: "Heavy Rain - Mưa lớn", description: "Mưa mạnh, giọt mưa to."),
        .init(icon: "cloud.bolt.rain.fill", title: "Thunderstorm - Giông bão", description: "Mưa kèm sấm sét."),
        .init(icon: "snowflake", title: "Snow - Tuyết", description: "Tuyết rơi, nhẹ hoặc dày."),
        .init(icon: "cloud.fog.fill", title: "Mist - Sương mù nhẹ", description: "Sương mù mỏng, giảm tầm nhìn nhẹ."),
        .init(icon: "cloud.fog", title: "Fog - Sương mù", description: "Sương mù dày, giảm tầm nhìn nhiều."),
        .init(icon: "sun.haze.fill", title: "Haze - Sương khô", description: "Bụi hoặc khói làm mờ không khí.")
    ]
    
    // MARK: - Body
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Search Bar
                searchBarView
                
                // MARK: - City Selection Buttons
                citySelectionButtons
                
                // MARK: - Weather Overview
                weatherOverviewView
                
                // MARK: - Error Message
                if let error = weatherVM.errorMessage {
                    Text(error)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea(.all, edges: .horizontal)
        .onAppear {
            cityInput = weatherVM.weatherCity
            lastContext = .weather
        }
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Nhập tên thành phố 🏙️🌆🌃", text: $cityInput, onEditingChanged: { isEditing in
                    if isEditing && !cityInput.isEmpty {
                        weatherVM.fetchCitySuggestions(query: cityInput)
                    }
                })
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .padding(.vertical, 12)
                .padding(.horizontal, 15)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.systemFill), Color(UIColor.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Button(action: {
                    if !cityInput.isEmpty {
                        weatherVM.fetchWeatherByCity(city: cityInput, context: .weather)
                        lastContext = .weather
                        cityInput = ""
                        weatherVM.citySuggestions = []
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            
            if !weatherVM.citySuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(weatherVM.citySuggestions) { city in
                        Button(action: {
                            weatherVM.fetchWeatherByCoordinates(lat: city.lat, lon: city.lon, cityName: city.name, context: .weather)
                            lastContext = .weather
                            cityInput = ""
                            weatherVM.citySuggestions = []
                        }) {
                            Text("\(city.name), \(city.country)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(UIColor.systemBackground).opacity(0.95))
                                .cornerRadius(20)
                                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - City Selection Buttons
    private var citySelectionButtons: some View {
        VStack(spacing: 15) {
            Button(action: { showForecastCityInput = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Forecast: \(weatherVM.forecastCity)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(showForecastCityInput ? 0.95 : 1.0)
                .animation(.spring(), value: showForecastCityInput)
            }
            .alert("Nhập thành phố cho Forecast 🌤️", isPresented: $showForecastCityInput) {
                TextField("Tên thành phố ✦", text: $newCityInput)
                Button("OK (❀ᴗ͈ˬᴗ͈)⁾⁾") {
                    if !newCityInput.isEmpty {
                        weatherVM.fetchWeatherByCity(city: newCityInput, context: .forecast)
                        lastContext = .forecast
                        newCityInput = ""
                    }
                }
                Button("Hủy ✧", role: .cancel) { newCityInput = "" }
            }
            
            Button(action: { showWidgetCityInput = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.moon.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Widget: \(weatherVM.widgetCity)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor, Color.purple.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(showWidgetCityInput ? 0.95 : 1.0)
                .animation(.spring(), value: showWidgetCityInput)
            }
            .alert("Nhập thành phố cho Widget 🌙", isPresented: $showWidgetCityInput) {
                TextField("Tên thành phố ✦", text: $newCityInput)
                Button("OK (❁ᴗ͈ˬᴗ͈)⁾⁾") {
                    if !newCityInput.isEmpty {
                        weatherVM.fetchWeatherByCity(city: newCityInput, context: .widget)
                        lastContext = .widget
                        newCityInput = ""
                    }
                }
                Button("Hủy ✧", role: .cancel) { newCityInput = "" }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weather Overview View
    private var weatherOverviewView: some View {
        Group {
            if let weather = weatherVM.weather, let airQuality = weatherVM.airQuality {
                // MARK: - Title
                VStack(spacing: 4) {
                    Text("Tổng quan thời tiết ⟢")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("\(weatherVM.locationName(for: lastContext))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
                
                // MARK: - Current Weather & Sunrise/Sunset
                HStack(alignment: .top, spacing: 20) {
                    // Left: Current Weather
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ngày: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .center, spacing: 12) {
                            let currentHour = Calendar.current.component(.hour, from: Date())
                            let isDaytime = currentHour >= 6 && currentHour < 18
                            let weatherCondition = weather.weather.first?.main ?? "Unknown"
                            let iconName: String = {
                                switch weatherCondition {
                                case "Clear":
                                    return isDaytime ? "sun.max.fill" : "moon.stars.fill"
                                case "Clouds":
                                    return isDaytime ? "cloud.sun.fill" : "cloud.moon.fill"
                                case "Rain":
                                    return weather.weather.first?.description.contains("light") ?? false ? "cloud.drizzle.fill" : "cloud.rain.fill"
                                case "Thunderstorm":
                                    return "cloud.bolt.rain.fill"
                                case "Snow":
                                    return "snowflake"
                                case "Mist", "Fog":
                                    return "cloud.fog.fill"
                                case "Haze":
                                    return isDaytime ? "sun.haze.fill" : "moon.haze.fill"
                                default:
                                    return "cloud.fill"
                                }
                            }()
                            
                            Image(systemName: iconName)
                                .font(.system(size: 44))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(weather.main.temp))°C")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text(weather.weather.first?.description.capitalized ?? "Không xác định")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right: Sunrise/Sunset
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mặt trời mọc & lặn 🌅")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "sun.horizon.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            Text("Mọc: \(weatherVM.sunriseTime)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                            Text("Lặn: \(weatherVM.sunsetTime)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 5)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // MARK: - Air Quality
                airQualityView(airQuality: airQuality)
                
                // MARK: - Weather Details
                weatherDetailsView(weather: weather)
                
                // MARK: - 5-Day Forecast
                fiveDayForecastView
                
                // MARK: - Hourly Forecast
                hourlyForecastView
                
                // MARK: - Weather Condition Explanations
                weatherConditionExplanationsView
            } else {
                Text("Đang tải dữ liệu thời tiết... ⏳")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Air Quality View
    private func airQualityView(airQuality: AirQualityResponse) -> some View {
        Button(action: {
            isAirQualityExpanded.toggle() // Toggle khi nhấn khung ^^
        }) {
            DisclosureGroup(
                isExpanded: $isAirQualityExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "aqi.low")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("PM2.5: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.pm2_5 ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("- \(weatherVM.pm25Description)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "aqi.medium")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("PM10: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.pm10 ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "wind")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("CO: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.co ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "cloud.fog")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("NO: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.no ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "cloud.fog.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("NO₂: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.no2 ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "sun.dust")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("O₃: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.o3 ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "cloud.bolt")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("SO₂: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.so2 ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "leaf")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("NH₃: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", airQuality.list.first?.components.nh3 ?? 0)) µg/m³")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                },
                label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chất lượng không khí 🌬️")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Air Quality Index: \(weatherVM.aqiDescription)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(weatherVM.aqiColor)
                    }
                }
            )
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.5), value: isAirQualityExpanded)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Weather Details View
    private func weatherDetailsView(weather: WeatherResponse) -> some View {
        Button(action: {
            isWeatherDetailsExpanded.toggle()
        }) {
            DisclosureGroup(
                isExpanded: $isWeatherDetailsExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Độ ẩm: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(weather.main.humidity)%")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "barometer")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Áp suất: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(weather.main.pressure) hPa")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Tầm nhìn: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(weather.visibility / 1000) km")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "wind")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Tốc độ gió: ")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", weather.wind.speed)) m/s")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                },
                label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thông số thời tiết ☁️")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("🌡️ Cảm giác như: \(Int(weather.main.feelsLike))°C")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            )
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.5), value: isWeatherDetailsExpanded)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 5-Day Forecast View
    private var fiveDayForecastView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dự báo 5 ngày tới 📅")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(1...5, id: \.self) { dayOffset in
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()),
                   let forecast = weatherVM.weatherForDate(date) {
                    HStack {
                        Text(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Image(systemName: forecast.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                            .frame(width: 30, alignment: .center)
                        
                        Text("\(Int(forecast.temp))°C")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(forecast.condition)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 120, alignment: .leading)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                    ? [Color(UIColor.systemBackground).opacity(0.1), themeColor.opacity(0.1)]
                    : [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Hourly Forecast View
    private var hourlyForecastView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dự báo theo giờ ⏰")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(weatherVM.hourlyForecast(for: Date()), id: \.time) { forecast in
                HStack {
                    Text(forecast.time)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Image(systemName: forecast.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                        .frame(width: 30, alignment: .center)
                    
                    Text("\(Int(forecast.temp))°C")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 60, alignment: .leading)
                    
                    Text(forecast.condition)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(minWidth: 120, alignment: .leading)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                    ? [Color(UIColor.systemBackground).opacity(0.1), themeColor.opacity(0.1)]
                    : [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Weather Condition Explanations View
    private var weatherConditionExplanationsView: some View {
        Button(action: {
            isWeatherConditionsExpanded.toggle()
        }) {
            DisclosureGroup(
                isExpanded: $isWeatherConditionsExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(weatherDescriptions) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text(item.description)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(25)
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text("Giải thích điều kiện thời tiết 🌦️")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            )
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.5), value: isWeatherConditionsExpanded)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    WeatherView()
        .environmentObject(WeatherViewModel())
        .environment(\.themeColor, .blue)
}
