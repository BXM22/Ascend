//
//  ContentView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

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
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Content
                Group {
                    switch selectedTab {
                    case .dashboard:
                        DashboardView(
                            progressViewModel: progressViewModel,
                            workoutViewModel: workoutViewModel
                        )
                    case .workout:
                        WorkoutView(viewModel: workoutViewModel)
                    case .progress:
                        ProgressView(viewModel: progressViewModel)
                    case .templates:
                        TemplatesView(
                            viewModel: templatesViewModel,
                            workoutViewModel: workoutViewModel,
                            onStartTemplate: {
                                selectedTab = .workout
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // Connect ViewModels
                    workoutViewModel.progressViewModel = progressViewModel
                    workoutViewModel.settingsManager = settingsManager
                }
                
                // Bottom Navigation
                BottomNavigationBar(selectedTab: $selectedTab, themeManager: themeManager)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .sheet(isPresented: $templatesViewModel.showCreateTemplate) {
            TemplateEditView(
                template: nil,
                onSave: { template in
                    templatesViewModel.saveTemplate(template)
                },
                onCancel: {
                    templatesViewModel.showCreateTemplate = false
                }
            )
        }
        .sheet(isPresented: $templatesViewModel.showEditTemplate) {
            if let template = templatesViewModel.editingTemplate {
                TemplateEditView(
                    template: template,
                    onSave: { updatedTemplate in
                        templatesViewModel.saveTemplate(updatedTemplate)
                    },
                    onCancel: {
                        templatesViewModel.showEditTemplate = false
                        templatesViewModel.editingTemplate = nil
                    },
                    onDelete: {
                        templatesViewModel.deleteTemplate(template)
                        templatesViewModel.showEditTemplate = false
                        templatesViewModel.editingTemplate = nil
                    }
                )
            }
        }
    }
}

struct BottomNavigationBar: View {
    @Binding var selectedTab: ContentView.Tab
    @ObservedObject var themeManager: ThemeManager
    @State private var showThemePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Theme Picker (when shown)
            if showThemePicker {
                ThemePickerView(themeManager: themeManager)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 0)
                    )
            }
            
            HStack(spacing: 0) {
                NavButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == .dashboard
                ) {
                    selectedTab = .dashboard
                }
                
                Spacer()
                
                NavButton(
                    icon: "dumbbell.fill",
                    title: "Workout",
                    isSelected: selectedTab == .workout
                ) {
                    selectedTab = .workout
                }
                
                Spacer()
                
                NavButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    isSelected: selectedTab == .progress
                ) {
                    selectedTab = .progress
                }
                
                Spacer()
                
                NavButton(
                    icon: "list.bullet.rectangle",
                    title: "Templates",
                    isSelected: selectedTab == .templates
                ) {
                    selectedTab = .templates
                }
                
                Spacer()
                
                // Theme Toggle Button
                Button(action: {
                    withAnimation {
                        showThemePicker.toggle()
                    }
                }) {
                    Image(systemName: showThemePicker ? "paintbrush.fill" : "paintbrush")
                        .font(AppTypography.heading3)
                        .foregroundColor(selectedTab == .templates ? AppColors.primary : AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.card)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppColors.border),
                alignment: .top
            )
        }
    }
}

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                ThemeButton(mode: mode, themeManager: themeManager)
            }
        }
    }
}

struct ThemeButton: View {
    let mode: ThemeManager.ThemeMode
    @ObservedObject var themeManager: ThemeManager
    
    private var iconName: String {
        switch mode {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    private var isSelected: Bool {
        themeManager.themeMode == mode
    }
    
    private var foregroundColor: Color {
        isSelected ? AppColors.alabasterGrey : AppColors.foreground
    }
    
    private var background: some View {
        Group {
            if isSelected {
                LinearGradient.primaryGradient
            } else {
                AppColors.secondary
            }
        }
    }
    
    var body: some View {
        Button(action: {
            themeManager.themeMode = mode
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                
                Text(mode.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct NavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(AppTypography.heading3)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                Text(title)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}

