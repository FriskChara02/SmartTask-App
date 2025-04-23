//
//  WeatherModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 22/4/25.
//
import Foundation

struct WeatherResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let main: Main
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let timezone: Int
    let name: String
}

struct Coord: Codable {
    let lon: Double
    let lat: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let pressure: Int
    let humidity: Int
    let tempMin: Double
    let tempMax: Double
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case pressure
        case humidity
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
}

struct Clouds: Codable {
    let all: Int
}

struct Sys: Codable {
    let sunrise: Int
    let sunset: Int
}

struct AirQualityResponse: Codable {
    let list: [AirQuality]
}

struct AirQuality: Codable {
    let main: AirQualityMain
    let components: AirQualityComponents
}

struct AirQualityMain: Codable {
    let aqi: Int
}

struct AirQualityComponents: Codable {
    let pm2_5: Double
    let pm10: Double
    let co: Double
    let no: Double
    let no2: Double
    let o3: Double
    let so2: Double
    let nh3: Double
}

// Dành cho phần ở AddTaskView và AddEventView

struct ForecastResponse: Codable {
    let cod: String
    let message: Int
    let cnt: Int
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: Int
    let main: Main
    let weather: [Weather]
    let clouds: Clouds
    let wind: Wind
    let visibility: Int
    let pop: Double
    let sys: ForecastSys
    let dtTxt: String
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, sys
        case dtTxt = "dt_txt"
    }
}

struct ForecastCity: Codable {
    let name: String
    let coord: Coord
    let country: String
    let timezone: Int
}

struct ForecastSys: Codable {
    let pod: String
}
