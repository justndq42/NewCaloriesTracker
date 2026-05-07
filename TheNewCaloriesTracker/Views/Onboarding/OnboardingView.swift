import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.ColorToken.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(step <= vm.currentStep ? AppTheme.ColorToken.primary : AppTheme.ColorToken.disabledFill)
                            .frame(height: 4)
                            .animation(.easeInOut, value: vm.currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Steps
                TabView(selection: $vm.currentStep) {
                    OnboardingStep1(vm: vm).tag(1)
                    OnboardingStep2(vm: vm).tag(2)
                    OnboardingStep3(vm: vm) {
                        vm.saveProfile(context: context)
                    }.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: vm.currentStep)
            }
        }
    }
}
