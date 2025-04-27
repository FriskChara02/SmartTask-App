//
//  WeatherWidgetView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 22/4/25.
//

import SwiftUI

struct WeatherWidgetView: View {
    // MARK: - Properties
    @EnvironmentObject var weatherVM: WeatherViewModel
    @Environment(\.themeColor) var themeColor
    @State private var showSuggestion = false
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            showSuggestion = true
        }) {
            // MARK: - Widget Content
            HStack(spacing: 6) {
                // Biểu tượng thời tiết
                Image(systemName: weatherIcon)
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                
                // Tên thành phố
                Text(weatherVM.widgetCity)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Nhiệt độ
                Text("\(Int(weatherVM.weather?.main.temp ?? 0))°C")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                
                // Trạng thái thời tiết
                Text(weatherVM.weather?.weather.first?.description.capitalized ?? "Loading...")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
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
        .alert(isPresented: $showSuggestion) {
            Alert(
                title: Text("Gợi ý thời tiết 🌤️"),
                message: Text(suggestionMessage),
                dismissButton: .default(Text("OK (✧ᴗ͈ˬᴗ͈)❀*.ﾟ"))
            )
        }
    }
    
    // MARK: - Weather Icon
    // Chọn biểu tượng thời tiết dựa trên mã ID
    private var weatherIcon: String {
        guard let weatherId = weatherVM.weather?.weather.first?.id else { return "cloud.fill" }
        
        switch weatherId {
        // 1xx - Thunderstorm (Giông bão)
        case 200: return "cloud.bolt.rain.fill" // Giông kèm mưa nhẹ
        case 201: return "cloud.bolt.rain.fill" // Giông kèm mưa
        case 202: return "cloud.bolt.rain.fill" // Giông kèm mưa lớn
        case 210: return "cloud.bolt.fill" // Giông nhẹ
        case 211: return "cloud.bolt.fill" // Giông
        case 212: return "cloud.bolt.fill" // Giông mạnh
        case 221: return "cloud.bolt.fill" // Giông dữ dội
        case 230: return "cloud.bolt.rain.fill" // Giông kèm mưa phùn nhẹ
        case 231: return "cloud.bolt.rain.fill" // Giông kèm mưa phùn
        case 232: return "cloud.bolt.rain.fill" // Giông kèm mưa phùn lớn
        
        // 3xx - Drizzle (Mưa phùn)
        case 300: return "cloud.drizzle.fill" // Mưa phùn nhẹ
        case 301: return "cloud.drizzle.fill" // Mưa phùn
        case 302: return "cloud.drizzle.fill" // Mưa phùn mạnh
        case 310: return "cloud.drizzle.fill" // Mưa phùn nhẹ có mưa
        case 311: return "cloud.drizzle.fill" // Mưa phùn có mưa
        case 312: return "cloud.drizzle.fill" // Mưa phùn mạnh có mưa
        case 313: return "cloud.rain.fill" // Mưa phùn kèm mưa rào
        case 314: return "cloud.rain.fill" // Mưa phùn mạnh kèm mưa rào
        case 321: return "cloud.drizzle.fill" // Mưa phùn lác đác
        
        // 5xx - Rain (Mưa)
        case 500: return "cloud.rain.fill" // Mưa nhẹ
        case 501: return "cloud.rain.fill" // Mưa vừa
        case 502: return "cloud.rain.fill" // Mưa lớn
        case 503: return "cloud.rain.fill" // Mưa rất lớn
        case 504: return "cloud.rain.fill" // Mưa cực lớn
        case 511: return "cloud.sleet.fill" // Mưa đóng băng
        case 520: return "cloud.heavyrain.fill" // Mưa rào nhẹ
        case 521: return "cloud.heavyrain.fill" // Mưa rào
        case 522: return "cloud.heavyrain.fill" // Mưa rào lớn
        case 531: return "cloud.heavyrain.fill" // Mưa rào không đều
        
        // 6xx - Snow (Tuyết)
        case 600: return "cloud.snow.fill" // Tuyết nhẹ
        case 601: return "cloud.snow.fill" // Tuyết
        case 602: return "cloud.snow.fill" // Tuyết dày
        case 611: return "cloud.sleet.fill" // Mưa tuyết
        case 612: return "cloud.sleet.fill" // Mưa tuyết rào
        case 613: return "cloud.sleet.fill" // Tuyết rào
        case 615: return "cloud.sleet.fill" // Mưa nhẹ kèm tuyết
        case 616: return "cloud.sleet.fill" // Mưa kèm tuyết
        case 620: return "cloud.snow.fill" // Tuyết rào nhẹ
        case 621: return "cloud.snow.fill" // Tuyết rào
        case 622: return "cloud.snow.fill" // Tuyết rào mạnh
        
        // 7xx - Atmosphere (Hiện tượng khí quyển)
        case 701: return "cloud.fog.fill" // Sương mù nhẹ
        case 711: return "smoke.fill" // Khói
        case 721: return "sun.haze.fill" // Mù khô
        case 731: return "sun.dust.fill" // Cát bụi xoáy
        case 741: return "cloud.fog.fill" // Sương mù
        case 751: return "sun.dust.fill" // Cát
        case 761: return "sun.dust.fill" // Bụi
        case 762: return "smoke.fill" // Tro bụi núi lửa
        case 771: return "wind" // Gió giật mạnh
        case 781: return "tornado" // Lốc xoáy
        
        // 800 - Clear (Trời quang)
        case 800: return "sun.max.fill" // Trời quang đãng
        
        // 80x - Clouds (Mây)
        case 801: return "cloud.fill" // Ít mây
        case 802: return "cloud.fill" // Mây rải rác
        case 803: return "cloud.fill" // Mây dày nhưng chưa kín
        case 804: return "cloud.fill" // Mây dày đặc
        
        default: return "cloud.fill"
        }
    }
    
    // MARK: - Suggestion Message
    // Gợi ý thông minh dựa trên thời tiết
    private var suggestionMessage: String {
        guard let weatherId = weatherVM.weather?.weather.first?.id,
              let temp = weatherVM.weather?.main.temp else {
            return "Đang tải dữ liệu thời tiết cho \(weatherVM.widgetCity)..."
        }
        
        if temp > 35 {
            return "Trời rất nóng! Nhớ mang theo nước và tránh ra ngoài vào buổi trưa nha! 🥤"
        } else if temp < 15 {
            return "Trời khá lạnh! Hãy mặc ấm và giữ sức khỏe nhé! 🧥"
        }
        
        switch weatherId {
        case 200, 201, 202, 230, 231, 232: // Giông kèm mưa
            return "Trời giông bão với mưa! Hãy ở trong nhà và mang ô lớn nếu ra ngoài! ⚡️"
        case 210, 211, 212, 221: // Giông không mưa
            return "Trời giông bão! Cẩn thận khi ra ngoài và tránh nơi trống trải! ⚡️"
        case 300, 301, 302, 310, 311, 312, 321: // Mưa phùn
            return "Mưa phùn lất phất! Mang ô nhỏ để tránh ướt nha! ☔"
        case 313, 314: // Mưa phùn kèm mưa rào
            return "Mưa phùn kèm mưa rào! Ưu tiên làm việc trong nhà hoặc mang ô lớn! 🌧️"
        case 500, 501, 502, 503, 504: // Mưa
            return "Trời mưa to! Ưu tiên làm việc trong nhà hoặc mang ô lớn! 🌧️"
        case 511: // Mưa đóng băng
            return "Mưa đóng băng! Cẩn thận đường trơn và giữ ấm! 🥶"
        case 520, 521, 522, 531: // Mưa rào
            return "Mưa rào bất chợt! Mang ô và cẩn thận đường ướt! 🌧️"
        case 600, 601, 602, 620, 621, 622: // Tuyết
            return "Trời tuyết rơi! Giữ ấm và cẩn thận khi di chuyển! ❄️"
        case 611, 612, 613, 615, 616: // Mưa tuyết
            return "Mưa tuyết lạnh giá! Mặc ấm và tránh đường trơn trượt! ❄️"
        case 701, 741: // Sương mù
            return "Sương mù dày đặc! Cẩn thận khi lái xe và bật đèn sương mù! 🌫️"
        case 711, 721, 731, 751, 761, 762: // Khói, bụi, cát
            return "Không khí nhiều bụi! Đeo khẩu trang và hạn chế ra ngoài! 😷"
        case 771: // Gió giật mạnh
            return "Gió giật mạnh! Cẩn thận khi ra ngoài và tránh vật nặng! 🌬️"
        case 781: // Lốc xoáy
            return "Lốc xoáy nguy hiểm! Tìm nơi trú ẩn an toàn ngay! 🌪️"
        case 800: // Trời quang
            return "Trời nắng đẹp! Tuyệt vời để ra ngoài hoặc làm việc ngoài trời! ☀️"
        case 801, 802, 803, 804: // Mây
            return "Trời nhiều mây! Thời tiết dễ chịu, phù hợp mọi kế hoạch! ☁️"
        default:
            return "Thời tiết ổn, hãy tiếp tục kế hoạch của bạn! 🌟"
        }
    }
}

// MARK: - Preview
#Preview {
    WeatherWidgetView()
        .environmentObject(WeatherViewModel())
        .environment(\.themeColor, .blue)
}
