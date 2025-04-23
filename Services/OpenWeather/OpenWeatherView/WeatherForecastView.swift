//
//  WeatherForecastView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 22/4/25.
//

import SwiftUI

struct WeatherForecastView: View {
    // MARK: - Properties
    @EnvironmentObject var weatherVM: WeatherViewModel
    @Environment(\.themeColor) var themeColor
    let selectedDate: Date
    
    // MARK: - Body
    var body: some View {
        if let weather = weatherVM.weatherForDate(selectedDate), weatherVM.forecastCity == weatherVM.forecastCity {
            weatherInfoView(weather: weather)
        } else {
            loadingView
        }
    }

    // MARK: - Weather Info View
    private func weatherInfoView(weather: (temp: Double, condition: String, icon: String)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: weather.icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(weatherVM.forecastCity)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(Int(weather.temp))°C, \(weather.condition)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text("Chất lượng không khí: \(weatherVM.aqiDescription)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.3), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        Text("Đang tải thời tiết cho \(weatherVM.forecastCity)...")
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview
#Preview {
    WeatherForecastView(selectedDate: Date())
        .environmentObject(WeatherViewModel())
        .environment(\.themeColor, .blue)
}
