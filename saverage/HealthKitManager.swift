//
//  HealthKitManager.swift
//  saverage
//
//  Created by Andreas Resch on 20.07.25.
//

import Foundation
import HealthKit

@MainActor
class HealthKitManager {

    // 1.
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    // 2.
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    // 3.
    func fetchMostRecentSample(for identifier: HKQuantityTypeIdentifier) async throws -> HKQuantitySample? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples?.first as? HKQuantitySample)
                }
            }
            healthStore.execute(query)
        }
    }
}
