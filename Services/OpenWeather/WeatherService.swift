//
//  WeatherService.swift
//  SmartTask
//
//  Created by Loi Nguyen on 22/4/25.
//

import Foundation
import CoreLocation

class WeatherService {
    static let shared = WeatherService()
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let apiKey = Config.openWeatherMapAPIKey
    
    private init() {}
    
    // Lấy thời tiết hiện tại theo vị trí
    func fetchCurrentWeather(lat: Double, lon: Double, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let weather = try decoder.decode(WeatherResponse.self, from: data)
                completion(.success(weather))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Lấy chất lượng không khí
    func fetchAirQuality(lat: Double, lon: Double, completion: @escaping (Result<AirQualityResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let airQuality = try decoder.decode(AirQualityResponse.self, from: data)
                completion(.success(airQuality))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    

    // Lấy dự báo thời tiết
    func fetchWeatherForecast(lat: Double, lon: Double, completion: @escaping (Result<ForecastResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Forecast error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                _ = String(data: data, encoding: .utf8) ?? "Unable to decode JSON"
                let decoder = JSONDecoder()
                let forecast = try decoder.decode(ForecastResponse.self, from: data)
                completion(.success(forecast))
            } catch {
                print("❌ Forecast decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchWeatherByCity(city: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/weather?q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let weather = try decoder.decode(WeatherResponse.self, from: data)
                completion(.success(weather))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchForecastByCity(city: String, completion: @escaping (Result<ForecastResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/forecast?q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let forecast = try decoder.decode(ForecastResponse.self, from: data)
                completion(.success(forecast))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchAirQualityByCity(city: String, completion: @escaping (Result<AirQualityResponse, Error>) -> Void) {
        // Lấy tọa độ từ tên thành phố trước
        fetchWeatherByCity(city: city) { result in
            switch result {
            case .success(let weather):
                let lat = weather.coord.lat
                let lon = weather.coord.lon
                self.fetchAirQuality(lat: lat, lon: lon, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    struct CitySuggestion: Codable {
        let name: String
        let lat: Double
        let lon: Double
        let country: String
    }
    
    struct GeocodingResponse: Codable {
        let name: String
        let lat: Double
        let lon: Double
        let country: String
    }

    func fetchCitySuggestions(query: String, completion: @escaping (Result<[GeocodingResponse], Error>) -> Void) {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(query)&limit=5&appid=\(apiKey)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ City suggestion fetch error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let suggestions = try JSONDecoder().decode([GeocodingResponse].self, from: data)
                completion(.success(suggestions))
            } catch {
                print("❌ City suggestion decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
