//
//  SleepAmountByDate.swift
//  saverage
//
//  Created by Andreas Resch on 29.08.25.
//

import Foundation
import HealthKit


struct SleepAmountByDate {
    var date: Date
    var stages: [HKCategorySample]
    
    var amount: Double {
        let amount = stages.reduce(0) {
            if !isAsleep(sample: $1) {
                return $0
            }
            return $0 + sleepDurationInHours(of: $1)
        }
        return amount
    }
}
