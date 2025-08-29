//
//  ContentView.swift
//  saverage
//
//  Created by Andreas Resch on 20.07.25.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {

    @State private var viewModel = HealthDataViewModel()
    @State var startDate: Date = Date().addingTimeInterval(-86400 * 7)
    @State var endDate: Date = Date()
    
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone
    
    func printDate(date: Date?) -> String {
        if date == nil {
            return "-"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: date ?? Date())
        return date
    }
    
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 1970, month: 1, day: 1)
        let endComponents = DateComponents()
        return calendar.date(from:startComponents)!
            ...
            Date()
    }()


    var body: some View {
        var attributedString = AttributedString("Now if you go to Apple Health app you will see your sleep average of 6 months, which will be pretty good.")
        if let range = attributedString.range(of: "Apple Health app") {
                    attributedString[range].link = URL(string: "x-apple-health://sleep")
                    attributedString[range].foregroundColor = .blue
                    attributedString[range].underlineStyle = .single
                }
        return NavigationStack {
            ScrollView {
                Text("you think you sleep enough? think again...").foregroundStyle(.gray)
                HStack {
                    DatePicker("From", selection: $startDate, in: dateRange, displayedComponents: .date)
                        .datePickerStyle(.compact).labelsHidden()
                        .onChange(of: startDate) { oldValue, newValue in
                            print(oldValue)
                            print(newValue)
                            Task {
                                await viewModel.fetchAllHealthData(startDate: newValue, endDate: endDate)
                            }
                        }
                    Text(" to ")
                    DatePicker("To", selection: $endDate, in: dateRange, displayedComponents: .date)
                        .datePickerStyle(.compact).labelsHidden()
                        .onChange(of: endDate) { oldValue, newValue in
                            Task {
                                await viewModel.fetchAllHealthData(startDate: startDate, endDate: newValue)
                            }
                        }
                }
                Button("give me 6 months from there") {
                    startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate)!
                }
                if (viewModel.sleepData.ready) {
                    Chart {
                        ForEach(viewModel.sleepData.sleepDurationByDate(), id: \.date.hashValue) { day in
                            BarMark(
                                x: .value("date", day.date.formatted(.dateTime.day().month(.twoDigits))),
                                y: .value("amount", day.amount)
                            )
                            .cornerRadius(5)
                        }
                    }.padding().frame(width: 400, height: 300).chartScrollableAxes([.horizontal]).labelsHidden()
                }
                Text("from \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted)) you slept:")
                if (viewModel.sleepData.ready) {
                    Text(durationToHoursAndMinutes(duration: viewModel.sleepData.sleepDuration) + " h").font(.title)
                } else {
                    Text("looaading").font(.title)
                }
                Text("on average")
                Text(attributedString)
                           .padding()
                if (viewModel.sleepData.ready) {
                    Text(durationToHoursAndMinutes(duration: viewModel.sleepData.appleSleepDuration) + " h").font(.title)
                } else {
                    Text("looaading").font(.title)
                }
                Text("± 1-2 minutes, dont sue me.").font(.caption2)
                Text("why?").font(.subheadline)
                Text("well, for some reason time works differently in Cupertino. Whilst days and months seem to pass at the same rate as in the rest of the world, Apple Health has a different time feeling when it comes to 6 Months.").padding()
                Text("Apple Health takes all your sleep data, calculates the sum of your sleep over the last 6 months and then divides that by the number of days in that period - almost.").padding()
                Text("for some reason Apple strongly believes that 6 months is a long time, but not as long as it actually is. When you take your average sleep duration over 6 months \(Int(viewModel.sleepData.days)), it's actually only dividing by roughly 147 days instead of the correct number.").padding()
                Spacer()
                VStack(spacing: 20) {
                    if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    } else if !viewModel.isAuthorized {
                        ProgressView("Requesting HealthKit authorization...")
                            .padding()
                    } else if !(viewModel.sleepData.ready) {
                        ProgressView("Crunching numbers...")
                            .padding()
                    } else {
                    }
                }
            }.navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Image("saverage")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text("saverage")
                        }
                    }
                }
            .navigationTitle("")
        }
    }
}

struct HealthInfoView<Label: View, Value: View>: View {
    let label: Label
    let value: Value
    var color: Color = .orange

    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(color.gradient)
            .frame(width: 200, height: 150)
            .overlay {
                VStack {
                    label
                    value
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            }
    }
}

func durationToHoursAndMinutes(duration: Double) -> String {
    if duration.isNaN || duration.isInfinite {
        return "-.-"
    }
    let hours = Int(duration)
    let minutes = Int((duration.truncatingRemainder(dividingBy: 1)) * 60)
    return String(format: "%02d:%02d", hours, minutes)
}


#Preview {
    let startDate: Date = Date().addingTimeInterval(-86400 * 7)
    let endDate: Date = Date()
    ContentView(startDate: startDate, endDate: endDate)
}
