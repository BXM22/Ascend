import Foundation
import SwiftUI
import Combine

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
    }
    
    @Published var showEditTemplate: Bool = false
    @Published var showCreateTemplate: Bool = false
    @Published var editingTemplate: WorkoutTemplate?
    
    func startTemplate(_ template: WorkoutTemplate, workoutViewModel: WorkoutViewModel) {
        workoutViewModel.startWorkoutFromTemplate(template)
    }
    
    func editTemplate(_ template: WorkoutTemplate) {
        editingTemplate = template
        showEditTemplate = true
    }
    
    func createTemplate() {
        editingTemplate = nil
        showCreateTemplate = true
    }
    
    func saveTemplate(_ template: WorkoutTemplate) {
        if let editingTemplate = editingTemplate,
           let index = templates.firstIndex(where: { $0.id == editingTemplate.id }) {
            // Update existing template
            templates[index] = template
        } else {
            // Add new template
            templates.append(template)
        }
        showEditTemplate = false
        showCreateTemplate = false
        editingTemplate = nil
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        templates.removeAll { $0.id == template.id }
    }
}

