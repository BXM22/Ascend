# Ascend API & Component Reference

Comprehensive reference for Ascend's public SwiftUI APIs, view models, helper managers, and reusable UI components. Use this guide to integrate the modules into another project, extend existing features, or onboard new contributors.

## Table of Contents
1. [Application Shell](#application-shell)
2. [Domain Models](#domain-models)
3. [Managers & Data Providers](#managers--data-providers)
4. [View Models](#view-models)
5. [Views & UI Components](#views--ui-components)
6. [Theme System](#theme-system)
7. [Usage Patterns & Examples](#usage-patterns--examples)
8. [Testing & Validation Hooks](#testing--validation-hooks)

---

## Application Shell

- **App entry point** initializes the SwiftUI scene and hosts `ContentView`.

```1:10:WorkoutTrackerApp.swift
@main
struct WorkoutTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- **ContentView** wires together the primary view models, propagates them to feature tabs, and exposes bottom navigation plus theme picker.

```10:25:Views/ContentView.swift
struct ContentView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @StateObject private var templatesViewModel = TemplatesViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsManager = SettingsManager()
    @State private var selectedTab: Tab = .dashboard
    @Environment(\.colorScheme) var systemColorScheme
    
    enum Tab {
        case dashboard, workout, progress, templates
    }
    
    var effectiveColorScheme: ColorScheme {
        themeManager.colorScheme ?? systemColorScheme
    }
```
```

**Usage:** Present `ContentView()` anywhere inside a `NavigationView` or `WindowGroup` to get the full experience with dashboard, workout logging, charts, and templates. View models are created per-App launch; inject custom instances (e.g., `WorkoutViewModel(settingsManager: customManager)`) when you need shared state across host apps.

---

## Domain Models

All models live in `Models/` and are value types optimized for SwiftUI bindings.

### Workout & Exercise Models

- `ExerciseSet`: immutable snapshot of weight/reps/holds per set.
- `Exercise`: runtime state for an exercise, including recorded sets, current set counter, metadata, alternatives, and linked media.

```4:22:Models/Models.swift
struct ExerciseSet: Identifiable, Equatable {
    let id = UUID()
    let setNumber: Int
    let weight: Double
    let reps: Int
    let holdDuration: Int?
    
    init(setNumber: Int, weight: Double, reps: Int, holdDuration: Int? = nil) {
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.holdDuration = holdDuration
    }
    
    static func == (lhs: ExerciseSet, rhs: ExerciseSet) -> Bool {
        return lhs.id == rhs.id
    }
}
```

```31:61:Models/Models.swift
struct Exercise: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var sets: [ExerciseSet]
    var currentSet: Int
    let targetSets: Int
    let exerciseType: ExerciseType
    let targetHoldDuration: Int?
    let alternatives: [String]
    let videoURL: String?
    
    var type: ExerciseType {
        exerciseType
    }
    
    init(name: String, targetSets: Int, exerciseType: ExerciseType, holdDuration: Int? = nil, alternatives: [String] = [], videoURL: String? = nil) {
        self.name = name
        self.sets = []
        self.currentSet = 1
        self.targetSets = targetSets
        self.exerciseType = exerciseType
        self.targetHoldDuration = holdDuration
        self.alternatives = alternatives
        self.videoURL = videoURL
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.id == rhs.id
    }
}
```

- `WorkoutTemplate`, `Workout`, and `PersonalRecord` describe templated workouts, live sessions, and PR history respectively (`Models.swift`).

### Skill Progression Models

- `SkillProgressionLevel` + `CalisthenicsSkill` capture progression tracks, hold/reps targets, and metadata.

```4:33:Models/SkillProgression.swift
struct SkillProgressionLevel: Identifiable {
    let id = UUID()
    let level: Int
    let name: String
    let description: String
    let targetHoldDuration: Int?
    let targetReps: Int?
    let isCompleted: Bool
    
    init(level: Int, name: String, description: String, targetHoldDuration: Int? = nil, targetReps: Int? = nil, isCompleted: Bool = false) {
        self.level = level
        self.name = name
        self.description = description
        self.targetHoldDuration = targetHoldDuration
        self.targetReps = targetReps
        self.isCompleted = isCompleted
    }
}

struct CalisthenicsSkill: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let progressionLevels: [SkillProgressionLevel]
    let videoURL: String?
    let category: SkillCategory
    
    enum SkillCategory: String {
        case push = "Push"
        case pull = "Pull"
        case core = "Core"
        case fullBody = "Full Body"
    }
}
```

### Program Models

- `WorkoutDay`, `ProgramExercise`, and `WorkoutProgram` define multi-day plans.

```4:31:Models/WorkoutProgram.swift
struct WorkoutDay: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let name: String
    let description: String
    let exercises: [ProgramExercise]
    let estimatedDuration: Int
    
    init(dayNumber: Int, name: String, description: String, exercises: [ProgramExercise], estimatedDuration: Int) {
        self.dayNumber = dayNumber
        self.name = name
        self.description = description
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
    }
}
```

```42:64:Models/WorkoutProgram.swift
struct WorkoutProgram: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let days: [WorkoutDay]
    let frequency: String
    let category: ProgramCategory
    
    enum ProgramCategory: String {
        case calisthenics = "Calisthenics"
        case strength = "Strength"
        case hypertrophy = "Hypertrophy"
        case skill = "Skill Progression"
    }
    
    init(name: String, description: String, days: [WorkoutDay], frequency: String, category: ProgramCategory) {
        self.name = name
        self.description = description
        self.days = days
        self.frequency = frequency
        self.category = category
    }
}
```

---

## Managers & Data Providers

### CalisthenicsSkillManager
Singleton containing curated skill definitions plus helpers to fetch by name or category.

```162:169:Models/SkillProgression.swift
func getSkill(named name: String) -> CalisthenicsSkill? {
    return skills.first { $0.name == name }
}

func getSkillsByCategory(_ category: CalisthenicsSkill.SkillCategory) -> [CalisthenicsSkill] {
    return skills.filter { $0.category == category }
}
```

### WorkoutProgramManager
Provides structured workout programs (e.g., 2-day muscle-up split) and query helpers.

```141:147:Models/WorkoutProgram.swift
func getProgram(named name: String) -> WorkoutProgram? {
    return programs.first { $0.name == name }
}

func getProgramsByCategory(_ category: WorkoutProgram.ProgramCategory) -> [WorkoutProgram] {
    return programs.filter { $0.category == category }
}
```

### ExerciseDataManager
Central lookup for exercise alternatives and tutorial URLs with validation helpers.

```86:131:ViewModels/ExerciseDataManager.swift
func getAlternatives(for exerciseName: String) -> [String] {
    if let info = exerciseDatabase[exerciseName] {
        return info.alternatives
    }
    
    for (skillName, info) in exerciseDatabase {
        if exerciseName.contains(skillName) {
            return info.alternatives
        }
    }
    
    return []
}

func getVideoURL(for exerciseName: String) -> String? {
    if let info = exerciseDatabase[exerciseName] {
        return info.videoURL
    }
    
    for (skillName, info) in exerciseDatabase {
        if exerciseName.contains(skillName) {
            return info.videoURL
        }
    }
    
    for skill in CalisthenicsSkillManager.shared.skills {
        if exerciseName.contains(skill.name) {
            return skill.videoURL
        }
    }
    
    return nil
}
```

### SettingsManager & ThemeManager

- `SettingsManager` persists rest timer duration via `UserDefaults` (`ViewModels/SettingsManager.swift`).
- `ThemeManager` exposes light/dark/system overrides and persists selection.

```5:34:ViewModels/ThemeManager.swift
class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
    
    @Published var themeMode: ThemeMode = .system {
        didSet {
            updateColorScheme()
            saveThemePreference()
        }
    }
    
    init() {
        loadThemePreference()
    }
    
    private func updateColorScheme() {
        switch themeMode {
        case .system:
            colorScheme = nil
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
```
```

---

## View Models

### WorkoutViewModel
Handles real-time workout state, timers, PR detection, alternative swaps, and sheet presentation.

```5:35:ViewModels/WorkoutViewModel.swift
class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var currentExerciseIndex: Int = 0
    @Published var elapsedTime: Int = 0
    @Published var restTimerActive: Bool = false
    @Published var restTimeRemaining: Int = 60
    @Published var showPRBadge: Bool = false
    @Published var prMessage: String = ""
    @Published var showAddExerciseSheet: Bool = false
    @Published var showSettingsSheet: Bool = false
    
    var settingsManager: SettingsManager?
    var progressViewModel: ProgressViewModel?
    
    private var timer: Timer?
    private var restTimer: Timer?
    private var workoutStartTime: Date?
    
    var currentExercise: Exercise? {
        guard let workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else {
            return nil
        }
        return workout.exercises[currentExerciseIndex]
    }
```

```111:144:ViewModels/WorkoutViewModel.swift
func completeSet(weight: Double, reps: Int) {
    guard var exercise = currentExercise,
          var workout = currentWorkout else { return }
    
    let set = ExerciseSet(
        setNumber: exercise.currentSet,
        weight: weight,
        reps: reps
    )
    
    exercise.sets.append(set)
    exercise.currentSet += 1
    
    workout.exercises[currentExerciseIndex] = exercise
    currentWorkout = workout
    
    if let progressVM = progressViewModel {
        if !progressVM.availableExercises.contains(exercise.name) {
            progressVM.addInitialExerciseEntry(exercise: exercise.name, weight: weight, reps: reps)
        } else {
            checkForPR(exercise: exercise.name, weight: weight, reps: reps)
        }
    } else {
        checkForPR(exercise: exercise.name, weight: weight, reps: reps)
    }
    
    startRestTimer()
}
```

**Key behaviors**
- Automatically instantiates `Exercise` objects from templates and calisthenics progressions (`determineExerciseType`).
- Starts/stops timers when workouts start/finish (`startTimer`, `pauseWorkout`, `finishWorkout`).
- Integrates with `ProgressViewModel` to seed new exercises and detect PRs (`checkForPR`).

### ProgressViewModel
Tracks PR history, workout streaks, and view selection state.

```5:38:ViewModels/ProgressViewModel.swift
class ProgressViewModel: ObservableObject {
    @Published var prs: [PersonalRecord] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var workoutDates: [Date] = []
    @Published var totalVolume: Int = 15000
    @Published var workoutCount: Int = 12
    @Published var selectedView: ProgressViewType = .week
    @Published var selectedExercise: String = ""
    
    enum ProgressViewType {
        case week, month
    }
    
    var availableExercises: [String] {
        Array(Set(prs.map { $0.exercise })).sorted()
    }
```

```152:189:ViewModels/ProgressViewModel.swift
func addOrUpdatePR(exercise: String, weight: Double, reps: Int, date: Date = Date()) -> Bool {
    let existingPRs = prs.filter { $0.exercise == exercise }
    let isNewPR: Bool
    
    if existingPRs.isEmpty {
        isNewPR = true
    } else {
        let currentPR = existingPRs.max { pr1, pr2 in
            if pr1.weight != pr2.weight {
                return pr1.weight < pr2.weight
            }
            return pr1.reps < pr2.reps
        }
        
        if let current = currentPR {
            isNewPR = weight > current.weight || (weight == current.weight && reps > current.reps)
        } else {
            isNewPR = true
        }
    }
    
    if isNewPR {
        let newPR = PersonalRecord(exercise: exercise, weight: weight, reps: reps, date: date)
        prs.append(newPR)
        updateSelectedExerciseIfNeeded()
    }
    
    return isNewPR
}
```

### TemplatesViewModel
Owns the list of templates (including generated skill progressions) and sheet state.

```5:30:ViewModels/TemplatesViewModel.swift
class TemplatesViewModel: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []
    
    init() {
        loadSampleTemplates()
    }
    
    func loadSampleTemplates() {
        templates = [
            WorkoutTemplate(
                name: "Push Day",
                exercises: ["Bench Press", "Overhead Press", "Incline Dumbbell", "Tricep Dips", "Lateral Raises", "Chest Flyes"],
                estimatedDuration: 60
            ),
            WorkoutTemplate(
                name: "Pull Day",
                exercises: ["Deadlift", "Pull-ups", "Barbell Rows", "Cable Rows", "Face Pulls"],
                estimatedDuration: 50
            ),
            WorkoutTemplate(
                name: "Leg Day",
                exercises: ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curls", "Calf Raises", "Lunges", "Leg Extensions"],
                estimatedDuration: 70
            )
        ]
```

```67:84:ViewModels/TemplatesViewModel.swift
func saveTemplate(_ template: WorkoutTemplate) {
    if let editingTemplate = editingTemplate,
       let index = templates.firstIndex(where: { $0.id == editingTemplate.id }) {
        templates[index] = template
    } else {
        templates.append(template)
    }
    showEditTemplate = false
    showCreateTemplate = false
    editingTemplate = nil
}
```

---

## Views & UI Components

### High-Level Screens

| View | Purpose | Key Dependencies |
| --- | --- | --- |
| `DashboardView` | Overview metrics, quick stats, streak card, activity feed | `ProgressViewModel`, `WorkoutViewModel` |
| `WorkoutView` | Active workout logging, timers, rest control, add exercise | `WorkoutViewModel`, `ExerciseDataManager`, `SettingsManager` |
| `ProgressView` | PR tracker and streak analytics | `ProgressViewModel` |
| `TemplatesView` | Start/edit workout & skill templates | `TemplatesViewModel`, `WorkoutViewModel` |
| `CalisthenicsSkillView` | Deep-dive into single skill progression | `CalisthenicsSkill`, `WorkoutViewModel` |
| `WorkoutProgramView` | Inspect multi-day programs and start a day | `WorkoutProgram`, `WorkoutViewModel` |

#### Workout Screen

```10:44:Views/WorkoutView.swift
struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var weight: String = "185"
    @State private var reps: String = "8"
    @State private var holdDuration: String = "30"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                WorkoutHeader(
                    title: viewModel.currentWorkout?.name ?? "Workout",
                    onPause: { viewModel.pauseWorkout() },
                    onFinish: { viewModel.finishWorkout() },
                    onSettings: { viewModel.showSettingsSheet = true }
                )
                
                WorkoutTimerBar(time: viewModel.formatTime(viewModel.elapsedTime))
                
                if let workout = viewModel.currentWorkout, workout.exercises.count > 1 {
                    ExerciseNavigationView(
                        exercises: workout.exercises,
                        currentIndex: viewModel.currentExerciseIndex,
                        onSelect: { index in
                            viewModel.currentExerciseIndex = index
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                if let exercise = viewModel.currentExercise {
                    if exercise.type == .hold {
                        HoldExerciseCard(
                            exercise: exercise,
                            holdDuration: $holdDuration,
                            onCompleteSet: {
                                if let duration = Int(holdDuration) {
                                    viewModel.completeHoldSet(duration: duration)
                                }
                            }
                        )
```

The view dynamically swaps in `ExerciseCard` vs `HoldExerciseCard`, exposes Rest timer controls, and presents `AddExerciseView` & `SettingsView` sheets.

#### Templates Screen

```10:55:Views/TemplatesView.swift
struct TemplatesView: View {
    @ObservedObject var viewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartTemplate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TemplatesHeader(onCreate: {
                    viewModel.createTemplate()
                })
                
                VStack(spacing: AppSpacing.lg) {
                    WorkoutProgramsSection(workoutViewModel: workoutViewModel, onStart: onStartTemplate)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                    
                    CalisthenicsSkillsSection(workoutViewModel: workoutViewModel, onStart: onStartTemplate)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Workout Templates")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        ForEach(viewModel.templates.filter { !$0.name.contains("Progression") }) { template in
                            TemplateCard(
                                template: template,
                                onStart: {
                                    viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                    onStartTemplate()
                                },
                                onEdit: {
                                    viewModel.editTemplate(template)
                                }
                            )
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .background(AppColors.background)
    }
}
```

Includes `WorkoutProgramsSection` and `CalisthenicsSkillsSection` for browsing structured content, and `TemplateCard`/`TemplateEditView` for CRUD.

### Reusable Components

- **AlternativeExercisesView**: lists equipment-free swaps and hooks into `WorkoutViewModel.switchToAlternative`.
- **RestTimerView**: circular countdown with skip/complete callbacks.
- **PreviousSetsView**: displays recent sets for the active exercise.
- **CalisthenicsSkillsSection** / **WorkoutProgramsSection**: horizontal carousels that present detail sheets and auto-start workouts when the user taps "Start".

```6:34:Views/Components/AlternativeExercisesView.swift
struct AlternativeExercisesView: View {
    let exerciseName: String
    let alternatives: [String]
    let onSelectAlternative: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                
                Text("Alternative Exercises")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            if alternatives.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Text("No Equipment? Try these bodyweight options!")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(alternatives, id: \.self) { alternative in
                        AlternativeExerciseCard(
                            name: alternative,
                            onTap: {
                                onSelectAlternative(alternative)
                            }
                        )
                    }
                }
            }
        }
```
```

```10:44:Views/Components/RestTimerView.swift
struct RestTimerView: View {
    let timeRemaining: Int
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    private var minutes: Int {
        timeRemaining / 60
    }
    
    private var seconds: Int {
        timeRemaining % 60
    }
    
    private var progress: Double {
        let total = 90.0
        return 1.0 - (Double(timeRemaining) / total)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            ZStack {
                Circle()
                    .stroke(AppColors.secondary, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.prussianBlue, AppColors.duskBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: AppColors.prussianBlue.opacity(0.5), radius: 8)
```
```

```3:35:Views/WorkoutProgramView.swift
struct WorkoutProgramView: View {
    let program: WorkoutProgram
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var selectedDayIndex: Int = 0
    @Environment(\.dismiss) var dismiss
    
    var selectedDay: WorkoutDay {
        program.days[selectedDayIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                ProgramHeader(program: program)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                
                DaySelector(
                    days: program.days,
                    selectedIndex: $selectedDayIndex
                )
                .padding(.horizontal, AppSpacing.lg)
                
                DayDetailsView(
                    day: selectedDay,
                    onStartWorkout: {
                        startWorkoutForDay(selectedDay)
                    }
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 100)
            }
        }
        .background(AppColors.background)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

### VideoTutorialButton
Reusable button that safely opens YouTube tutorials when available.

```83:122:Views/Components/AlternativeExercisesView.swift
struct VideoTutorialButton: View {
    let videoURL: String?
    let exerciseName: String
    
    var body: some View {
        if let urlString = videoURL, !urlString.isEmpty {
            Button(action: {
                openYouTubeVideo(urlString: urlString)
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Watch Tutorial")
                        .font(AppTypography.bodyMedium)
                }
                .foregroundColor(AppColors.accentForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(LinearGradient.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private func openYouTubeVideo(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        } else {
            print("Invalid YouTube URL: \(urlString)")
        }
    }
}
```

---

## Theme System

Centralized design tokens live under `Theme/`.

- **Colors & Gradients** (`Theme/AppColors.swift`): palette, semantic colors, adaptive gradients, `Color(hex:)` helpers.
- **Spacing** (`Theme/Spacing.swift`): `AppSpacing.xs` → `AppSpacing.xl` definitions.
- **Typography** (`Theme/Typography.swift`): heading/body/caption font presets.

```6:35:Theme/AppColors.swift
struct AppColors {
    static let inkBlack = Color(hex: "0d1b2a")
    static let prussianBlue = Color(hex: "1b263b")
    static let duskBlue = Color(hex: "415a77")
    static let dustyDenim = Color(hex: "778da9")
    static let alabasterGrey = Color(hex: "e0e1dd")
    
    static let background = Color(light: alabasterGrey, dark: inkBlack)
    static let foreground = Color(light: inkBlack, dark: Color(hex: "e8eaed"))
    static let card = Color(light: .white, dark: prussianBlue)
    static let primary = prussianBlue
    static let secondary = Color(light: Color(hex: "f5f5f5"), dark: Color(hex: "1e2936"))
    static let muted = Color(light: Color(hex: "f0f0f0"), dark: Color(hex: "2a3847"))
    static let mutedForeground = Color(light: dustyDenim, dark: Color(hex: "a8b8cc"))
    static let border = Color(light: dustyDenim, dark: duskBlue)
    static let input = Color(light: Color(hex: "f5f5f5"), dark: Color(hex: "1e2936"))
    static let accent = duskBlue
    static let accentForeground = Color(light: alabasterGrey, dark: Color(hex: "f0f2f5"))
}
```

Use these constants inside new views to maintain consistent styling (e.g., `Text("Title").font(AppTypography.heading2).foregroundColor(AppColors.textPrimary)`).

---

## Usage Patterns & Examples

### Start a Workout From a Template

```swift
let workoutVM = WorkoutViewModel()
let templatesVM = TemplatesViewModel()
if let pushDay = templatesVM.templates.first(where: { $0.name == "Push Day" }) {
    workoutVM.startWorkoutFromTemplate(pushDay)
}
```

After calling `startWorkoutFromTemplate`, bind `WorkoutView(viewModel: workoutVM)` inside your UI to drive the session.

### Log a Weight/Rep Set and Track PRs

```swift
// assumes workoutVM.currentWorkout and currentExercise exist
if workoutVM.validateSetCompletion(weight: 200, reps: 5) {
    workoutVM.completeSet(weight: 200, reps: 5)
}
```

If the set is a PR, `WorkoutViewModel` flips `showPRBadge` and `ProgressViewModel` records the new entry automatically.

### Configure Rest Timer Duration

```swift
let settings = SettingsManager()
settings.restTimerDuration = 120 // persists via UserDefaults
workoutVM.settingsManager = settings
```

Timers in `WorkoutView` now default to 2 minutes.

### Create or Edit Templates Programmatically

```swift
let template = WorkoutTemplate(
    name: "Upper Body Strength",
    exercises: ["Bench Press", "Pull-ups", "Shoulder Press"],
    estimatedDuration: 55
)
let templatesVM = TemplatesViewModel()
templatesVM.saveTemplate(template)
```

### Start a Calisthenics Skill Session

```swift
let skill = CalisthenicsSkillManager.shared.skills.first!
let workoutVM = WorkoutViewModel()
// mimic CalisthenicsSkillView button tap
workoutVM.startWorkout(name: "\(skill.name) Training")
workoutVM.addExercise(
    name: "\(skill.name) - \(skill.progressionLevels[0].name)",
    targetSets: 3,
    type: skill.progressionLevels[0].targetHoldDuration == nil ? .weightReps : .hold,
    holdDuration: skill.progressionLevels[0].targetHoldDuration
)
```

---

## Testing & Validation Hooks

`WorkoutViewModel+Validation.swift` exposes simple guards for testability and form validation.

```4:65:ViewModels/WorkoutViewModel+Validation.swift
extension WorkoutViewModel {
    func validateWorkoutStart() -> Bool {
        return currentWorkout == nil || currentWorkout?.exercises.isEmpty == true
    }
    
    func validateSetCompletion(weight: Double, reps: Int) -> Bool {
        guard let exercise = currentExercise else { return false }
        guard weight > 0, reps > 0 else { return false }
        
        if exercise.exerciseType == .hold {
            return false
        }
        
        return true
    }
    
    func validateAlternativeSwitch(alternativeName: String) -> Bool {
        guard currentWorkout != nil,
              currentExerciseIndex < (currentWorkout?.exercises.count ?? 0) else {
            return false
        }
        
        return !alternativeName.isEmpty
    }
}

extension ProgressViewModel {
    func validatePRAddition(exercise: String, weight: Double, reps: Int) -> Bool {
        guard !exercise.isEmpty, weight > 0, reps > 0 else {
            return false
        }
        
        return true
    }
    
    func isNewPR(exercise: String, weight: Double, reps: Int) -> Bool {
        let existingPRs = prs.filter { $0.exercise == exercise }
        
        guard !existingPRs.isEmpty else {
            return true
        }
        
        let currentPR = existingPRs.max { pr1, pr2 in
            if pr1.weight != pr2.weight {
                return pr1.weight < pr2.weight
            }
            return pr1.reps < pr2.reps
        }
        
        guard let current = currentPR else { return true }
        
        return weight > current.weight || (weight == current.weight && reps > current.reps)
    }
}
```

Use these helpers in unit/UI tests to confirm user inputs before invoking side-effecting operations.

---

**Need help extending the API surface or integrating these modules into another host?** Reach out by opening an issue or continue collaborating within Cursor.
