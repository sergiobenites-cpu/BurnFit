extension Int {
    /// 75 -> "01:15"
    var mmss: String {
        let s = Swift.max(0, self)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    /// 45 -> "45 s", 1500 -> "25 min", 3725 -> "1h 02m"
    var durataBreve: String {
        let s = Swift.max(0, self)
        if s < 60 { return "\(s) s" }
        let ore = s / 3600
        let minuti = (s % 3600) / 60
        if ore > 0 { return "\(ore)h \(String(format: "%02d", minuti))m" }
        return "\(minuti) min"
    }
}


