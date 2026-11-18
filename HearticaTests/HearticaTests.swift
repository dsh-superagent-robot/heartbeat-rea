import XCTest
@testable import Heartica

@MainActor
final class HearticaTests: XCTestCase {

    func testHRVDerivedMetrics() {
        let intervals: [Double] = [800, 810, 790, 805, 795, 800]
        let metrics = HRVCalculationService.calculate(intervals: intervals)
        XCTAssertEqual(metrics.pulse, 75, accuracy: 0.001)
        // mean 800, deviations: 0,10,-10,5,-5,0 -> variance = (0+100+100+25+25+0)/6
        XCTAssertEqual(metrics.sdnn, sqrt(250.0 / 6.0), accuracy: 0.2)
        // diffs: 10,-20,15,-10,5 -> squared sum 100+400+225+100+25 = 850 / 5
        XCTAssertEqual(metrics.rmssd, sqrt(850.0 / 5.0), accuracy: 0.2)
        // |diff| > 50: none -> 0
        XCTAssertEqual(metrics.pnn50, 0, accuracy: 0.001)
    }

    func testPNN50() {
        // diffs: 60, 20, 80, 10 -> 2 of 4 > 50 -> 50%
        let metrics = HRVCalculationService.calculate(intervals: [800, 860, 880, 800, 810])
        XCTAssertEqual(metrics.pnn50, 50, accuracy: 0.001)
    }

    func testEmptyIntervals() {
        let metrics = HRVCalculationService.calculate(intervals: [])
        XCTAssertEqual(metrics.pulse, 0)
        XCTAssertEqual(metrics.rmssd, 0)
        XCTAssertEqual(metrics.sdnn, 0)
    }

    func testIQRFilteringRemovesOutlier() {
        let filtered = HRVCalculationService.filteredIntervals([800, 810, 790, 805, 5000, 795])
        XCTAssertFalse(filtered.contains(5000))
    }

    func testIntervalValidation() {
        XCTAssertTrue(HRVCalculationService.validateInterval(800, recentAverageMs: nil))
        XCTAssertFalse(HRVCalculationService.validateInterval(200, recentAverageMs: nil))
        XCTAssertFalse(HRVCalculationService.validateInterval(1500, recentAverageMs: 850))
        XCTAssertTrue(HRVCalculationService.validateInterval(900, recentAverageMs: 850))
    }

    func testHeartAgeBuckets() {
        // Female thresholds: RMSSD 100+ -> bucket 0; 15 -> bucket 11; below -> 12
        XCTAssertEqual(HeartAgeCalculator.rmssdBucket(110, gender: .female), 0)
        XCTAssertEqual(HeartAgeCalculator.rmssdBucket(15, gender: .female), 11)
        XCTAssertEqual(HeartAgeCalculator.rmssdBucket(10, gender: .female), 12)
        // Male thresholds: 91+ -> bucket 0
        XCTAssertEqual(HeartAgeCalculator.rmssdBucket(95, gender: .male), 0)
        XCTAssertEqual(HeartAgeCalculator.rmssdBucket(95, gender: .notSet), 0)
        XCTAssertEqual(HeartAgeCalculator.ageBucket(30), 4)
        XCTAssertEqual(HeartAgeCalculator.ageBucket(14), 0)
        XCTAssertEqual(HeartAgeCalculator.ageBucket(72), 12)
        XCTAssertEqual(HeartAgeCalculator.clampBucket(0, ageBucket: 4), 1)
        XCTAssertEqual(HeartAgeCalculator.clampBucket(12, ageBucket: 4), 7)
    }

    func testPressureBands() {
        XCTAssertEqual(VitalsStatus.pressure(sys: 85).title, "Low")
        XCTAssertEqual(VitalsStatus.pressure(sys: 110).title, "Normal")
        XCTAssertEqual(VitalsStatus.pressure(sys: 125).title, "Elevated")
        XCTAssertEqual(VitalsStatus.pressure(sys: 135).title, "High")
        XCTAssertEqual(VitalsStatus.pressure(sys: 160).title, "Very High")
    }

    func testOxygenBands() {
        XCTAssertEqual(VitalsStatus.oxygen(85).title, "Very Low")
        XCTAssertEqual(VitalsStatus.oxygen(93).title, "Low")
        XCTAssertEqual(VitalsStatus.oxygen(98).title, "Normal")
    }

    func testGlucoseBands() {
        XCTAssertEqual(VitalsStatus.glucose(mgdl: 90, afterMeal: false).title, "Normal")
        XCTAssertEqual(VitalsStatus.glucose(mgdl: 110, afterMeal: false).title, "Elevated")
        XCTAssertEqual(VitalsStatus.glucose(mgdl: 130, afterMeal: false).title, "High")
        XCTAssertEqual(VitalsStatus.glucose(mgdl: 220, afterMeal: true).title, "High")
        XCTAssertEqual(VitalsStatus.glucose(mgdl: 150, afterMeal: true).title, "Elevated")
    }

    func testPulseBands() {
        XCTAssertEqual(MetricCatalog.pulseStatus(130).status, "veryHigh")
        XCTAssertEqual(MetricCatalog.pulseStatus(110).status, "high")
        XCTAssertEqual(MetricCatalog.pulseStatus(72).status, "normal")
        XCTAssertEqual(MetricCatalog.pulseStatus(50).status, "low")
    }

    func testBMIBands() {
        var profile = Profile()
        profile.weightKg = 80
        profile.heightCm = 180
        XCTAssertEqual(profile.bmi ?? 0, 24.69, accuracy: 0.02)
        XCTAssertEqual(profile.bmiBand, "Normal")
    }

    func testProfileFormBuildsMetricUnits() {
        var profile = Profile()
        profile.name = "Test"
        let model = ProfileEditorModel(profile: profile)
        model.age = "32"
        model.gender = .female
        model.weight = "65"
        model.heightCm = "170"
        let built = model.buildProfile(base: profile)
        XCTAssertEqual(built.age, 32)
        XCTAssertEqual(built.gender, .female)
        XCTAssertEqual(built.weightKg ?? 0, 65, accuracy: 0.01)
        XCTAssertEqual(built.heightCm ?? 0, 170, accuracy: 0.01)
    }

    func testGlucoseConversion() {
        XCTAssertEqual(GlucoseUnit.mmolL.displayValue(mgdl: 180), 10.0, accuracy: 0.001)
        XCTAssertEqual(GlucoseUnit.mmolL.mgdlValue(display: 5.0), 90.0, accuracy: 0.001)
    }

    func testChineseLocalization() {
        let previous = LanguageStore.shared.language
        defer { LanguageStore.shared.language = previous }
        LanguageStore.shared.language = .chinese
        XCTAssertEqual(L("Heart Health"), "心脏健康")
        XCTAssertEqual(L("Settings"), "设置")
        XCTAssertEqual(L("Measure Now"), "立即测量")
        XCTAssertEqual(L("Normal Heart Rate"), "正常心率")
        LanguageStore.shared.language = .english
        XCTAssertEqual(L("Heart Health"), "Heart Health")
    }

    func testCatalogIntegrity() {
        XCTAssertEqual(AchievementCatalog.all.count, 21)
        XCTAssertEqual(JourneyCatalog.levels.count, 100)
        XCTAssertEqual(JourneyCatalog.chapters.count, 12)
        XCTAssertEqual(JourneyCatalog.levels.first?.tasks.filter { $0.type == "core" }.count, 3)
        XCTAssertTrue(JourneyCatalog.levels.contains { $0.id == 100 })
    }
}
