import SwiftUI
import AudioToolbox
import UIKit

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

struct StartupAnimationView: View {
    @Binding var isPresented: Bool
    
    // Animation states
    @State private var handOpacity: Double = 0.0
    @State private var handOffsetY: CGFloat = 300.0
    @State private var handScaleY: CGFloat = 1.0
    
    @State private var bagOpacity: Double = 0.0
    @State private var bagOffsetY: CGFloat = -500.0
    @State private var bagScaleY: CGFloat = 1.0
    
    @State private var particles: [Particle] = []
    @State private var showSparkles = false
    
    // Theme color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 1/255, green: 93/255, blue: 254/255)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                ZStack {
                    // Particles (Coin Burst)
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: 8, height: 8)
                            .scaleEffect(particle.scale)
                            .opacity(particle.opacity)
                            .offset(x: particle.x, y: particle.y)
                    }
                    
                    // The Money Bag
                    Image("money_bag")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 130)
                        .scaleEffect(x: 1.0, y: bagScaleY, anchor: .bottom)
                        .opacity(bagOpacity)
                        .offset(y: bagOffsetY)
                    
                    // The Hand
                    Image("hand")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 130, height: 130)
                        .scaleEffect(x: 1.0, y: handScaleY, anchor: .top)
                        .opacity(handOpacity)
                        .offset(y: handOffsetY)
                }
                .frame(height: 350)
                
                // LMS Brand Text (Fades in slightly after hand)
                VStack(spacing: 8) {
                    Text("Loan Management System")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Secure Borrower Portal")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(handOpacity)
                .offset(y: 40)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Step 1: Hand slides up and fades in
        withAnimation(.easeOut(duration: 0.6)) {
            handOpacity = 1.0
            handOffsetY = 80.0 // target position
        }
        
        // Step 2: Money bag falls from top with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.15)) {
                bagOpacity = 1.0
            }
            
            // Spring animation for realistic heavy fall
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
                bagOffsetY = 0.0 // Lands directly on the hand
            }
            
            // Step 3: Impact effects (exactly when the bag hits the hand, approx 0.45s after start of bag drop)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                playImpactEffects()
            }
        }
        
        // Step 4: Dismiss splash screen and transition to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isPresented = false
            }
        }
    }
    
    private func playImpactEffects() {
        // 1. Play sound
        SoundManager.shared.playSound(named: "cash_register")
        
        // 2. Play Haptics
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        // 3. Impact squish animation (squashes bag and depresses hand)
        withAnimation(.easeOut(duration: 0.08)) {
            bagScaleY = 0.85
            handScaleY = 0.9
            handOffsetY = 90.0 // Pushed down slightly
        }
        
        // Spring back
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 8).delay(0.08)) {
            bagScaleY = 1.0
            handScaleY = 1.0
            handOffsetY = 80.0
        }
        
        // 4. Trigger Particle Burst (gold coins/sparks)
        triggerParticles()
    }
    
    private func triggerParticles() {
        let goldColors = [
            Color(red: 255/255, green: 215/255, blue: 0/255),   // Gold
            Color(red: 255/255, green: 223/255, blue: 0/255),   // Golden yellow
            Color(red: 218/255, green: 165/255, blue: 32/255),  // Goldenrod
            Color.yellow
        ]
        
        // Create 20 particles moving in random directions
        for _ in 0..<20 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = Double.random(in: 60...160)
            let particle = Particle(
                x: 0,
                y: -10, // Burst point (contact area between bag and hand)
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                color: goldColors.randomElement() ?? .yellow
            )
            particles.append(particle)
            
            // Animate each particle to fly out and fade away
            let index = particles.count - 1
            withAnimation(.easeOut(duration: Double.random(in: 0.6...1.0))) {
                particles[index].x = CGFloat(cos(angle) * speed)
                particles[index].y = CGFloat(sin(angle) * speed) - CGFloat.random(in: 20...50) // gravity pull upwards/outwards
                particles[index].opacity = 0.0
                particles[index].scale = 0.1
            }
        }
    }
}

#Preview {
    StartupAnimationView(isPresented: .constant(true))
}
