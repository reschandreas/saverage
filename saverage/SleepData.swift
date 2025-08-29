//
//  SleepData.swift
//  saverage
//
//  Created by Andreas Resch on 28.08.25.
//

import Foundation
import HealthKit

@Observable
class SleepData {
    
    var startDate: Date
    var endDate: Date
    var data: [HKCategorySample] = []
    var inBedDuration: Double = 0
    var awakeDuration: Double = 0
    var sleepDuration : Double = 0
    var appleSleepDuration: Double = 0
    var sleepStagesByDate: [String:[HKCategorySample]] = [:]
    var ready: Bool = false
    let dateFormatter: DateFormatter = .init()
    var days: Double = 7
    
    init(startDate: Date, endDate: Date) {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.startDate = startDate
        self.endDate = endDate
    }
    
    func addSample(_ sample: HKCategorySample) {
        data.append(sample)
    }
    
    func sleepDurationByDate() -> [SleepAmountByDate] {
        var list = self.sleepStagesByDate.map( { (key, value) in
            return SleepAmountByDate(
                date: dateFormatter.date(from: key)!,
                stages: value
            )
        })
        list.sort {
            $0.date < $1.date
        }
        return list
    }
    
    func calculate() {
        self.ready = false
        var totalAmount: Double = 0
        var notsleeping: Double = 0
        var inbed: Double = 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    
        for sample in data {
            var stages: [HKCategorySample] = []
            let key = dateFormatter.string(from: sample.startDate)

            if self.sleepStagesByDate.contains(where: { $0.key == key }) {
                stages = self.sleepStagesByDate[dateFormatter.string(from: sample.startDate)]!
            }
            stages.append(sample)
            self.sleepStagesByDate.updateValue(stages, forKey: key)
            if !isAsleep(sample: sample) {
                if HKCategoryValueSleepAnalysis.awake.rawValue == sample.value {
                    notsleeping += sleepDurationInHours(of: sample)
                }
                else if HKCategoryValueSleepAnalysis.inBed.rawValue == sample.value {
                    inbed += sleepDurationInHours(of: sample)
                } else {
                    print("idk what you were doing")
                }
            } else {
                totalAmount += sleepDurationInHours(of: sample)
            }
        }
        self.days = Double(Calendar.current.dateComponents([.day], from: self.startDate, to: self.endDate).day!)
        self.inBedDuration = inbed / self.days
        self.awakeDuration = notsleeping / self.days
        var _ = self.sleepStagesByDate
        var _: [String] = []

        let smonthsago = Calendar.current.date(byAdding: .month, value: -6, to: endDate)!
        let is6Months = Calendar.current.dateComponents([.day], from: smonthsago, to: self.startDate).day! == 0
        
        let appleDays = is6Months ? 146 : self.days
        self.sleepDuration = totalAmount / self.days
        self.appleSleepDuration = totalAmount / appleDays
//        print("apple duration: \(self.appleSleepDuration)")
//        print("sleep duration: \(self.sleepDuration)")
//        print("in bed duration: \(inbed / self.days)")
        self.ready = true
    }
}

func sleepDurationInHours(of sleep: HKCategorySample) -> Double {
    return (sleep.endDate.timeIntervalSince1970 - sleep.startDate.timeIntervalSince1970) / 3600
}

func isAsleep(sample: HKCategorySample) -> Bool {
    return Set(HKCategoryValueSleepAnalysis.allAsleepValues.map { $0.rawValue }).contains(sample.value)
}
