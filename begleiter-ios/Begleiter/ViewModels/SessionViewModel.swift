import Foundation
import Observation

enum SessionPhase {
    case loading
    case active
    case feedback(isCorrect: Bool)
    case summary
    case error(Error)
}

@Observable
final class SessionViewModel {
    var exercises: [Exercise] = []
    var currentIndex: Int = 0
    var answers: [Answer] = []
    var summary: SessionSummary?
    var phase: SessionPhase = .loading
    var startTime: Date = Date()

    private let profileVM: ProfileViewModel

    init(profileVM: ProfileViewModel) {
        self.profileVM = profileVM
    }

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var progress: Double {
        exercises.isEmpty ? 0 : Double(currentIndex) / Double(exercises.count)
    }

    var isLastExercise: Bool { currentIndex >= exercises.count - 1 }

    // MARK: - Session lifecycle

    @MainActor
    func loadSession() async {
        phase = .loading
        guard let profile = profileVM.profile else { return }
        do {
            exercises = try await SessionService.shared.buildSession(profile: profile)
            currentIndex = 0
            answers = []
            startTime = Date()
            phase = .active
        } catch {
            phase = .error(error)
        }
    }

    @MainActor
    func recordAnswer(userAnswer: String, isCorrect: Bool) async {
        guard let ex = currentExercise else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let correctAnswer: String
        switch ex {
        case .multipleChoice(let e): correctAnswer = e.correct
        case .fillBlank(let e):      correctAnswer = e.blank
        case .matchPairs:            correctAnswer = ""
        case .reorderWords(let e):   correctAnswer = e.correct
        }
        let answer = Answer(exerciseId: ex.id, topic: ex.topic, isCorrect: isCorrect,
                            userAnswer: userAnswer, correctAnswer: correctAnswer, timeSeconds: elapsed)
        answers.append(answer)
        await profileVM.transitionTopic(ex.topic, isCorrect: isCorrect)
        phase = .feedback(isCorrect: isCorrect)
    }

    @MainActor
    func next() async {
        if isLastExercise {
            await finishSession()
        } else {
            currentIndex += 1
            startTime = Date()
            phase = .active
        }
    }

    @MainActor
    func finishSession() async {
        phase = .loading
        await profileVM.updateStreak()
        guard let profile = profileVM.profile else { return }
        do {
            summary = try await SessionService.shared.buildSummary(profile: profile, answers: answers)
        } catch {
            summary = SessionSummary(strongTopics: [], weakTopics: [], recommendation: "Great session!")
        }
        phase = .summary
    }

    @MainActor
    func reset() {
        exercises = []
        currentIndex = 0
        answers = []
        summary = nil
        phase = .loading
    }
}
