//
//  DateHelper.swift
//  SmartTask
//
//  Created by Loi Nguyen on 14/3/25.
//

import Foundation

struct DateHelper {
    static let shared = DateHelper()
    
    func formatDate(_ date: Date, format: String = "dd/MM/yyyy HH:mm", locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = locale
        return formatter.string(from: date)
    }
    
    func parseDate(_ dateString: String, format: String = "dd/MM/yyyy HH:mm") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: dateString)
    }
    
    func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    func daysBetween(_ start: Date, _ end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, equalTo: date2, toGranularity: .month)
    }
}
