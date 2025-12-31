import Foundation

class TaptiqueEngine {
    // Configuration
    private let maxTapInterval: TimeInterval = 2.0  // Reset if no tap for 2 seconds
    private let minTapsForBPM = 2                   // Need at least 2 taps to calculate
    private let smoothingFactor: Double = 0.3       // EMA smoothing (lower = smoother)
    private let maxHistorySize = 8                  // Keep last 8 intervals for averaging

    // State
    private var tapTimes: [Date] = []
    private var smoothedBPM: Double?
    private var resetTimer: Timer?

    var currentBPM: Int? {
        guard let bpm = smoothedBPM else { return nil }
        return Int(round(bpm))
    }

    func tap() {
        let now = Date()

        // Cancel any pending reset
        resetTimer?.invalidate()

        // Check if we should reset due to long gap
        if let lastTap = tapTimes.last {
            let interval = now.timeIntervalSince(lastTap)
            if interval > maxTapInterval {
                reset()
            }
        }

        // Add new tap
        tapTimes.append(now)

        // Keep only recent taps
        if tapTimes.count > maxHistorySize + 1 {
            tapTimes.removeFirst()
        }

        // Calculate BPM if we have enough taps
        if tapTimes.count >= minTapsForBPM {
            calculateBPM()
        }

        // Schedule reset timer
        resetTimer = Timer.scheduledTimer(withTimeInterval: maxTapInterval, repeats: false) { [weak self] _ in
            self?.reset()
        }
    }

    private func calculateBPM() {
        guard tapTimes.count >= 2 else { return }

        // Calculate intervals between taps
        var intervals: [TimeInterval] = []
        for i in 1..<tapTimes.count {
            let interval = tapTimes[i].timeIntervalSince(tapTimes[i-1])
            intervals.append(interval)
        }

        // Remove outliers using median-based filtering
        let sortedIntervals = intervals.sorted()
        let median = sortedIntervals[sortedIntervals.count / 2]
        let filteredIntervals = intervals.filter { interval in
            let ratio = interval / median
            return ratio > 0.5 && ratio < 2.0  // Within 2x of median
        }

        // Use filtered intervals if we have enough, otherwise use all
        let intervalsToUse = filteredIntervals.count >= 2 ? filteredIntervals : intervals

        // Calculate average interval
        let averageInterval = intervalsToUse.reduce(0, +) / Double(intervalsToUse.count)

        // Convert to BPM
        let rawBPM = 60.0 / averageInterval

        // Clamp to reasonable range
        let clampedBPM = min(max(rawBPM, 20.0), 300.0)

        // Apply exponential moving average for smoothing
        if let existing = smoothedBPM {
            smoothedBPM = (smoothingFactor * clampedBPM) + ((1 - smoothingFactor) * existing)
        } else {
            smoothedBPM = clampedBPM
        }
    }

    func reset() {
        tapTimes.removeAll()
        smoothedBPM = nil
        resetTimer?.invalidate()
        resetTimer = nil
    }
}
