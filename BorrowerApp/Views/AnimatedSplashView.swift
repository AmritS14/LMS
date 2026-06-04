import SwiftUI
import AudioToolbox

struct AnimatedSplashView: View {
    var onCompletion: () -> Void
    
    // Animation States
    @State private var scaleBG: CGFloat = 0.0
    @State private var offsetHand: CGFloat = 300.0
    @State private var opacityHand: Double = 0.0
    @State private var offsetBag: CGFloat = -400.0
    @State private var scaleBagY: CGFloat = 1.0
    @State private var scaleBagX: CGFloat = 1.0
    @State private var opacityBag: Double = 0.0
    @State private var scaleRupee: CGFloat = 0.0
    @State private var opacityRupee: Double = 0.0
    @State private var textProgress: CGFloat = 0.0
    @State private var logoGlow: CGFloat = 0.0
    
    // Particle Burst States
    @State private var particles: [SparkleParticle] = []
    
    // Constants
    private let brandBlue = Color(red: 0.0, green: 0.46, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.lmsBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Logo Container
                ZStack {
                    // Logo Blue Background (rounded squircle)
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .fill(brandBlue)
                        .shadow(color: brandBlue.opacity(0.4), radius: logoGlow * 15, x: 0, y: 8)
                        .frame(width: 220, height: 220)
                        .scaleEffect(scaleBG)
                    
                    // Inside the Blue Card: Vector Logo elements
                    ZStack {
                        // Unified Hand Group (Cuff, Shape, and Crease Lines animate in unison)
                        ZStack {
                            // 1. Hand Cuff / Sleeve (slanted pill)
                            Capsule()
                                .fill(.white)
                                .frame(width: 18, height: 48)
                                .rotationEffect(.degrees(24))
                                .offset(x: -54, y: 44)
                            
                            // 2. The Main Hand Shape
                            HandShape()
                                .fill(.white)
                                .frame(width: 220, height: 220)
                            
                            // 3. Hand Crease Lines (blue overlays for detail and depth)
                            HandCreaseShape()
                                .stroke(brandBlue, lineWidth: 4.5)
                                .frame(width: 220, height: 220)
                        }
                        .opacity(opacityHand)
                        .offset(y: offsetHand)
                        
                        // 4. Money Bag
                        Group {
                            // Bag Ruffles (Top)
                            MoneyBagRuffles()
                                .fill(.white)
                            
                            // Bag Body
                            MoneyBagShape()
                                .fill(.white)
                            
                            // Neck Ribbon/Tie
                            Capsule()
                                .fill(brandBlue)
                                .frame(width: 44, height: 8)
                                .offset(y: -28)
                            
                            // Rupee Symbol (₹)
                            Text("₹")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(brandBlue)
                                .offset(y: 10)
                                .scaleEffect(scaleRupee)
                                .opacity(opacityRupee)
                        }
                        .frame(width: 140, height: 140)
                        .offset(y: -15) // center inside the card
                        .scaleEffect(x: scaleBagX, y: scaleBagY, anchor: .bottom)
                        .offset(y: offsetBag)
                        .opacity(opacityBag)
                        
                        // 5. Contact Point / Particle Burst Layer
                        ZStack {
                            ForEach(particles) { particle in
                                Circle()
                                    .fill(particle.color)
                                    .frame(width: particle.size, height: particle.size)
                                    .offset(x: particle.x, y: particle.y)
                                    .scaleEffect(particle.scale)
                                    .opacity(particle.opacity)
                            }
                        }
                        .offset(y: 18) // position at impact zone (hand top)
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                }
                .frame(width: 220, height: 220)
                
                // App Title with tracking/expansion animation
                VStack(spacing: 8) {
                    Text("LMS BORROWER")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .tracking(10 * (1.0 - textProgress))
                        .opacity(Double(textProgress))
                        .offset(y: (1.0 - textProgress) * 20)
                    
                    Text("Secure Portal")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .opacity(Double(textProgress) * 0.8)
                        .offset(y: (1.0 - textProgress) * 10)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Footer
                Text("RELIABLE • SECURE • FAST")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .tracking(2)
                    .opacity(Double(textProgress) * 0.6)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            runAnimationSequence()
        }
    }
    
    // MARK: - Animation Sequence
    private func runAnimationSequence() {
        // Phase 1: Royal blue background zooms in with a bouncy spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            scaleBG = 1.0
        }
        
        // Phase 2: Hand slides up and settles in one go
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78, blendDuration: 0)) {
                offsetHand = 0.0
                opacityHand = 1.0
            }
        }
        
        // Phase 3: Money bag falls from above after hand is settled (accompanied by falling whoosh sound)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            AudioServicesPlaySystemSound(1001) // Whoosh / mail-sent sound
            
            withAnimation(.easeIn(duration: 0.35)) {
                offsetBag = 0.0
                opacityBag = 1.0
            }
        }
        
        // Phase 4: Bag lands in hand -> squish bounce + particle burst + logo glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            // Impact compression animation (squish and stretch)
            withAnimation(.easeOut(duration: 0.12)) {
                scaleBagY = 0.75
                scaleBagX = 1.15
            }
            
            // Play crisp impact sound and trigger haptic tick
            AudioServicesPlaySystemSound(1052) // Tink / coin clink
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
            
            // Trigger particle burst
            triggerParticleBurst()
            
            // Rebound bounce back to normal scale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6, blendDuration: 0)) {
                    scaleBagY = 1.0
                    scaleBagX = 1.0
                    logoGlow = 1.0
                }
            }
        }
        
        // Phase 5: Rupee symbol reveals inside bag
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                scaleRupee = 1.0
                opacityRupee = 1.0
            }
        }
        
        // Phase 6: Brand text tracking and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            // Play positive brand resolve success chime
            AudioServicesPlaySystemSound(1397)
            
            withAnimation(.easeOut(duration: 0.8)) {
                textProgress = 1.0
            }
        }
        
        // Phase 7: Completion callback (transition to Login/Dashboard)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            onCompletion()
        }
    }
    
    // MARK: - Particles
    private func triggerParticleBurst() {
        // Create a circular burst of gold coin-like and sparkle particles
        let colors = [
            Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
            Color(red: 1.0, green: 0.90, blue: 0.4), // Light Gold
            Color.white
        ]
        
        var newParticles: [SparkleParticle] = []
        for i in 0..<14 {
            let angle = Double(i) * (2 * Double.pi) / 14.0
            let speed = Double.random(in: 45...85)
            let xTarget = CGFloat(cos(angle) * speed)
            let yTarget = CGFloat(sin(angle) * speed * 0.6) // flatter ellipse burst
            
            let p = SparkleParticle(
                x: 0,
                y: 0,
                size: CGFloat.random(in: 6...12),
                scale: 1.0,
                opacity: 1.0,
                color: colors.randomElement() ?? .white
            )
            newParticles.append(p)
            
            // Animate each particle outwards
            let delay = Double.random(in: 0...0.05)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let index = self.particles.firstIndex(where: { $0.id == p.id }) {
                    withAnimation(.easeOut(duration: 0.65)) {
                        self.particles[index].x = xTarget
                        self.particles[index].y = yTarget
                        self.particles[index].scale = 0.2
                        self.particles[index].opacity = 0.0
                    }
                }
            }
        }
        self.particles = newParticles
    }
}

// MARK: - Particle Model
struct SparkleParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

// MARK: - Vector Shapes for Logo

// 1. Money Bag Body
struct MoneyBagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Body starts at neck left:
        path.move(to: CGPoint(x: w * 0.38, y: h * 0.30))
        
        // Curve out left and down bulbously (smooth and symmetrical)
        path.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.62),
                      control1: CGPoint(x: w * 0.26, y: h * 0.40),
                      control2: CGPoint(x: w * 0.16, y: h * 0.52))
        
        // Curve along bottom left to bottom center
        path.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.88),
                      control1: CGPoint(x: w * 0.26, y: h * 0.78),
                      control2: CGPoint(x: w * 0.38, y: h * 0.88))
        
        // Curve along bottom right to body right
        path.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.62),
                      control1: CGPoint(x: w * 0.62, y: h * 0.88),
                      control2: CGPoint(x: w * 0.74, y: h * 0.78))
        
        // Curve up to neck right
        path.addCurve(to: CGPoint(x: w * 0.62, y: h * 0.30),
                      control1: CGPoint(x: w * 0.84, y: h * 0.52),
                      control2: CGPoint(x: w * 0.74, y: h * 0.40))
        
        path.closeSubpath()
        return path
    }
}

// 2. Money Bag Top Ruffles
struct MoneyBagRuffles: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Start neck left
        path.move(to: CGPoint(x: w * 0.38, y: h * 0.30))
        
        // Left ruffle: curve up/left to top opening
        path.addCurve(to: CGPoint(x: w * 0.30, y: h * 0.16),
                      control1: CGPoint(x: w * 0.34, y: h * 0.25),
                      control2: CGPoint(x: w * 0.30, y: h * 0.21))
        
        // Wave ruffles along the top opening (3 rounded scallops)
        path.addQuadCurve(to: CGPoint(x: w * 0.43, y: h * 0.16),
                          control: CGPoint(x: w * 0.365, y: h * 0.10))
        
        path.addQuadCurve(to: CGPoint(x: w * 0.57, y: h * 0.16),
                          control: CGPoint(x: w * 0.50, y: h * 0.10))
        
        path.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.16),
                          control: CGPoint(x: w * 0.635, y: h * 0.10))
        
        // Right ruffle: curve down to neck right
        path.addCurve(to: CGPoint(x: w * 0.62, y: h * 0.30),
                      control1: CGPoint(x: w * 0.70, y: h * 0.21),
                      control2: CGPoint(x: w * 0.66, y: h * 0.25))
        
        path.closeSubpath()
        return path
    }
}

// 3. Hand Silhouette
struct HandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Start at wrist bottom-left:
        path.move(to: CGPoint(x: w * 0.28, y: h * 0.81))
        
        // Wrist curve up to thumb base
        path.addCurve(to: CGPoint(x: w * 0.29, y: h * 0.69),
                      control1: CGPoint(x: w * 0.27, y: h * 0.77),
                      control2: CGPoint(x: w * 0.28, y: h * 0.73))
        
        // Thumb curves up and left:
        path.addCurve(to: CGPoint(x: w * 0.21, y: h * 0.63),
                      control1: CGPoint(x: w * 0.24, y: h * 0.68),
                      control2: CGPoint(x: w * 0.21, y: h * 0.65))
        
        // Thumb tip:
        path.addCurve(to: CGPoint(x: w * 0.26, y: h * 0.57),
                      control1: CGPoint(x: w * 0.21, y: h * 0.60),
                      control2: CGPoint(x: w * 0.24, y: h * 0.57))
        
        // Thumb inner edge going down to hand web:
        path.addCurve(to: CGPoint(x: w * 0.38, y: h * 0.64),
                      control1: CGPoint(x: w * 0.31, y: h * 0.57),
                      control2: CGPoint(x: w * 0.35, y: h * 0.61))
        
        // Fingers top edge (index finger cradling the bag):
        path.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.61),
                      control1: CGPoint(x: w * 0.48, y: h * 0.66),
                      control2: CGPoint(x: w * 0.62, y: h * 0.63))
        
        // Index finger tip (rounded on the right):
        path.addCurve(to: CGPoint(x: w * 0.75, y: h * 0.66),
                      control1: CGPoint(x: w * 0.75, y: h * 0.60),
                      control2: CGPoint(x: w * 0.76, y: h * 0.63))
        
        // Bottom fingers crease / sweep (cradling palm):
        path.addCurve(to: CGPoint(x: w * 0.44, y: h * 0.81),
                      control1: CGPoint(x: w * 0.65, y: h * 0.74),
                      control2: CGPoint(x: w * 0.54, y: h * 0.81))
        
        // Back to wrist bottom-left:
        path.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.81),
                      control1: CGPoint(x: w * 0.38, y: h * 0.81),
                      control2: CGPoint(x: w * 0.33, y: h * 0.81))
        
        path.closeSubpath()
        return path
    }
}

// 4. Hand Crease Lines (Overlay to separate thumb and define finger crease)
struct HandCreaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Crease 1: Separate the thumb from palm (clean curve)
        path.move(to: CGPoint(x: w * 0.34, y: h * 0.63))
        path.addCurve(to: CGPoint(x: w * 0.37, y: h * 0.75),
                      control1: CGPoint(x: w * 0.34, y: h * 0.68),
                      control2: CGPoint(x: w * 0.35, y: h * 0.72))
        
        // Crease 2: Separates index finger from middle finger
        path.move(to: CGPoint(x: w * 0.71, y: h * 0.66))
        path.addCurve(to: CGPoint(x: w * 0.44, y: h * 0.71),
                      control1: CGPoint(x: w * 0.62, y: h * 0.67),
                      control2: CGPoint(x: w * 0.52, y: h * 0.70))
        
        // Crease 3: Separates middle finger from ring finger
        path.move(to: CGPoint(x: w * 0.62, y: h * 0.71))
        path.addCurve(to: CGPoint(x: w * 0.46, y: h * 0.74),
                      control1: CGPoint(x: w * 0.56, y: h * 0.72),
                      control2: CGPoint(x: w * 0.51, y: h * 0.73))
        
        return path
    }
}

// MARK: - Previews
#Preview {
    AnimatedSplashView(onCompletion: {})
}
