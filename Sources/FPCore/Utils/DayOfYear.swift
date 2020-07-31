import Foundation


public struct DayOfYear {

    static private let janStart = 1
    static private let febStart = janStart + 31
    static private let marStart = febStart + 29
    static private let aprStart = marStart + 31
    static private let mayStart = aprStart + 30
    static private let junStart = mayStart + 31
    static private let julStart = junStart + 30
    static private let augStart = julStart + 31
    static private let sepStart = augStart + 31
    static private let octStart = sepStart + 30
    static private let novStart = octStart + 31
    static private let decStart = novStart + 30

    static private let monthStarts = [
        janStart, febStart, marStart, aprStart, mayStart, junStart,
        julStart, augStart, sepStart, octStart, novStart, decStart
    ]

    static public func from(date: Date) -> Int {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return from(month: components.month!, day: components.day!)
    }

    static public func from(month: Int, day: Int) -> Int {
        if month < 1 || month > 12 {
            return -1
        }

        if day < 1 || day > 31 {
            return -1
        }

        return monthStarts[month - 1] + (day - 1)
    }

    static public func toMonthDay(date: Date) -> (Int, Int) {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        return (components.month!, components.day!)
    }
}