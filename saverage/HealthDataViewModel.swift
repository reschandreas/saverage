//
//  HealthDataViewModel.swift
//  saverage
//
//  Created by Andreas Resch on 20.07.25.
//
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
class HealthDataViewModel {
    
    var isAuthorized: Bool = false
    var errorMessage: String?
    let healthStore = HKHealthStore()
    var sleepStagesByDate: [String: [HKCategorySample]] = [:]
    
    var sleepData: SleepData
    
    init() {
        self.sleepData = SleepData(startDate: Date().addingTimeInterval(-86400 * 7), endDate: Date())
        Task {
            await requestAuthorization()
        }
    }

    func requestAuthorization() async {
        do {
            let success = try await HealthKitManager.shared.requestAuthorization()
                self.isAuthorized = success
            if success {
                await fetchAllHealthData(startDate: Date().addingTimeInterval(-86400 * 7), endDate: Date())
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func fetchAllHealthData(startDate: Date, endDate: Date) async {
        async let sleep: SleepData = fetchSleepDuration(startDate: startDate, endDate: endDate)
        self.sleepData.ready = false
        self.sleepData = await (sleep)
    }

    func fetchSleepDuration(startDate: Date, endDate: Date) async -> SleepData {
        let data = SleepData(startDate: startDate, endDate: endDate)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        let calendar = Calendar.current
        let days = Double(Calendar.current.dateComponents([.day], from: data.startDate, to: data.endDate).day!)
        let startOfPreviousNight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: data.startDate)!
        let endOfPreviousNight = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: data.endDate)!
        
        print("getting sleep data for \(days) days from \(data.startDate) to \(data.endDate)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfPreviousNight, end: endOfPreviousNight, options: .strictStartDate)
        
        
        func sleepDurationInHours(of sleep: HKCategorySample) -> Double {
            return (sleep.endDate.timeIntervalSince1970 - sleep.startDate.timeIntervalSince1970) / 3600
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            guard let samples = samples as? [HKCategorySample] else {
                // Handle no data available
                print("no data")
                return
            }
            for sample in samples {
                data.addSample(sample)
            }
            data.calculate()
        }
        healthStore.execute(query)
        
        return data
    }
}
