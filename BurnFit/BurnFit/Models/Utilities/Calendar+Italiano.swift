import Foundation
extension Calendar {
    /// Calendario gregoriano italiano, settimana che parte da lunedì
    static let italiano: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "it_IT")
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }()
}

