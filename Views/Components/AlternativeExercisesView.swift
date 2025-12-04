import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct AlternativeExerciseCard: View {
    let name: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                
                Text(name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
        
        // Validate YouTube URL
        if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            // Open in Safari
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        } else {
            // Invalid URL - could show alert
            print("Invalid YouTube URL: \(urlString)")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AlternativeExercisesView(
            exerciseName: "Bench Press",
            alternatives: ["Push-ups", "Dumbbell Press", "Incline Push-ups"],
            onSelectAlternative: { _ in }
        )
        
        VideoTutorialButton(
            videoURL: "https://www.youtube.com/watch?v=rT7DgCr-3pg",
            exerciseName: "Bench Press"
        )
    }
    .padding()
    .background(AppColors.background)
}

