import SwiftUI

// MARK: - German theme illustrations
//
// A small library of hand-drawn (vector) cartoon illustrations with a German
// theme: the national flag (still + waving), the Brandenburg Gate, a beer
// stein, and a tricolour accent stripe. All are pure SwiftUI so they stay
// crisp at any size and adapt to light/dark mode.
//
// Colours come from the asset catalog: GermanBlack / GermanRed / GermanGold.

enum German {
    static let black = Color("GermanBlack")
    static let red   = Color("GermanRed")
    static let gold  = Color("GermanGold")
}

// MARK: - Tricolour stripe (decorative accent)

/// A thin black/red/gold bar — the German flag rendered as a horizontal accent.
/// Use under headers or as a section divider.
struct GermanFlagStripe: View {
    var height: CGFloat = 5
    var cornerRadius: CGFloat = 3

    var body: some View {
        HStack(spacing: 0) {
            German.black
            German.red
            German.gold
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

// MARK: - Flag badge (still tricolour)

/// A rounded German flag with three horizontal bands — handy as a small icon.
struct GermanFlagBadge: View {
    var size: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            German.black
            German.red
            German.gold
        }
        .frame(width: size * 1.5, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
        .accessibilityLabel("German flag")
    }
}

// MARK: - Waving flag (animated hero)

/// A tricolour flag on a pole whose cloth gently ripples. Great as a hero image.
struct WavingGermanFlag: View {
    var width: CGFloat = 150
    var height: CGFloat = 110

    @State private var phase: CGFloat = 0

    private var flagWidth: CGFloat { width - poleWidth }
    private let poleWidth: CGFloat = 8

    var body: some View {
        HStack(spacing: 0) {
            // Pole with a gold finial
            VStack(spacing: 0) {
                Circle()
                    .fill(German.gold)
                    .frame(width: poleWidth * 1.6, height: poleWidth * 1.6)
                    .offset(x: poleWidth * 0.3)
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(.systemGray2), Color(.systemGray4)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: poleWidth)
            }
            .frame(height: height)

            // Cloth — three rippling bands sharing one wave
            ZStack {
                band(index: 0, color: German.black)
                band(index: 1, color: German.red)
                band(index: 2, color: German.gold)
            }
            .frame(width: flagWidth, height: height * 0.82)
            .shadow(color: .black.opacity(0.12), radius: 4, x: 2, y: 3)
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
        .accessibilityLabel("Waving German flag")
    }

    private func band(index: Int, color: Color) -> some View {
        WaveBand(phase: phase, bandIndex: index, bandCount: 3, amplitude: 6, waves: 1.4)
            .fill(color)
    }
}

/// One rippling horizontal band of a flag. Adjacent bands share the same wave
/// so they stack seamlessly into a tricolour.
private struct WaveBand: Shape {
    var phase: CGFloat
    var bandIndex: Int
    var bandCount: Int
    var amplitude: CGFloat
    var waves: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let bandHeight = rect.height / CGFloat(bandCount)
        let topRest = rect.minY + bandHeight * CGFloat(bandIndex)
        let bottomRest = topRest + bandHeight
        let k = (.pi * 2 * waves) / rect.width
        // The wave's vertical offset grows toward the free (right) edge.
        func offset(atX x: CGFloat) -> CGFloat {
            let falloff = x / rect.width                 // 0 at pole, 1 at free edge
            return sin(k * x + phase) * amplitude * falloff
        }

        var p = Path()
        let step: CGFloat = 4
        // Top edge, left → right
        p.move(to: CGPoint(x: rect.minX, y: topRest + offset(atX: 0)))
        var x = rect.minX
        while x <= rect.maxX {
            p.addLine(to: CGPoint(x: x, y: topRest + offset(atX: x)))
            x += step
        }
        // Bottom edge, right → left
        x = rect.maxX
        while x >= rect.minX {
            p.addLine(to: CGPoint(x: x, y: bottomRest + offset(atX: x)))
            x -= step
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Brandenburg Gate

/// A simplified, cartoon Brandenburg Gate — Germany's most famous landmark —
/// complete with its copper-green quadriga on top.
struct BrandenburgGate: View {
    var width: CGFloat = 160
    var tint: Color = Color(.systemGray)

    private var height: CGFloat { width * 0.72 }

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let stone = tint
            let stoneDark = tint.opacity(0.65)
            let patina = Color(red: 0.25, green: 0.65, blue: 0.58) // copper-green quadriga

            // Base platform
            let base = CGRect(x: w * 0.04, y: h * 0.86, width: w * 0.92, height: h * 0.10)
            ctx.fill(Path(roundedRect: base, cornerRadius: 3), with: .color(stoneDark))

            // Columns (six Doric columns with gaps you can see through)
            let colCount = 6
            let colAreaX = w * 0.10
            let colAreaW = w * 0.80
            let colW = colAreaW / CGFloat(colCount) * 0.62
            let gap = (colAreaW - colW * CGFloat(colCount)) / CGFloat(colCount - 1)
            let colTop = h * 0.34
            let colBottom = h * 0.86
            for i in 0..<colCount {
                let x = colAreaX + CGFloat(i) * (colW + gap)
                let rect = CGRect(x: x, y: colTop, width: colW, height: colBottom - colTop)
                ctx.fill(Path(roundedRect: rect, cornerRadius: colW * 0.2), with: .color(stone))
                // subtle fluting line
                let line = CGRect(x: x + colW * 0.45, y: colTop, width: colW * 0.1, height: colBottom - colTop)
                ctx.fill(Path(rect: line), with: .color(stoneDark.opacity(0.4)))
            }

            // Entablature (the wide horizontal block the columns hold up)
            let entab = CGRect(x: w * 0.05, y: h * 0.22, width: w * 0.90, height: h * 0.13)
            ctx.fill(Path(roundedRect: entab, cornerRadius: 4), with: .color(stone))
            // Cornice cap
            let cornice = CGRect(x: w * 0.08, y: h * 0.17, width: w * 0.84, height: h * 0.06)
            ctx.fill(Path(roundedRect: cornice, cornerRadius: 3), with: .color(stoneDark))

            // Quadriga (chariot + four horses) — a small green silhouette on top
            let chariotW = w * 0.10
            let chariotX = w * 0.5 - chariotW * 0.5
            let chariotY = h * 0.085
            // wheel
            ctx.fill(Path(ellipseIn: CGRect(x: chariotX, y: chariotY + h * 0.05, width: h * 0.06, height: h * 0.06)),
                     with: .color(patina))
            // chariot body
            ctx.fill(Path(roundedRect: CGRect(x: chariotX, y: chariotY + h * 0.02, width: chariotW, height: h * 0.05), cornerRadius: 2),
                     with: .color(patina))
            // horses (suggested by a sweep of short verticals ahead of the chariot)
            for i in 0..<4 {
                let hx = chariotX + chariotW + CGFloat(i) * (w * 0.03)
                let leg = CGRect(x: hx, y: chariotY + h * 0.02, width: w * 0.018, height: h * 0.07)
                ctx.fill(Path(roundedRect: leg, cornerRadius: 2), with: .color(patina))
            }
            // horses' backs
            let backs = CGRect(x: chariotX + chariotW, y: chariotY, width: w * 0.15, height: h * 0.035)
            ctx.fill(Path(roundedRect: backs, cornerRadius: 3), with: .color(patina))
        }
        .frame(width: width, height: height)
        .accessibilityLabel("Brandenburg Gate")
    }
}

// MARK: - Beer stein

/// A frothy German beer stein (Maßkrug) — a cheerful nod to Oktoberfest.
struct BeerStein: View {
    var size: CGFloat = 90

    var body: some View {
        Canvas { ctx, canvas in
            let w = canvas.width
            let h = canvas.height
            let amber = Color(red: 0.90, green: 0.66, blue: 0.23)
            let amberDark = Color(red: 0.80, green: 0.54, blue: 0.16)
            let glass = Color.white.opacity(0.35)

            // Mug body
            let body = CGRect(x: w * 0.20, y: h * 0.30, width: w * 0.46, height: h * 0.60)
            ctx.fill(Path(roundedRect: body, cornerRadius: w * 0.06), with: .color(amber))
            // Beer fill line / darker base
            let base = CGRect(x: w * 0.20, y: h * 0.62, width: w * 0.46, height: h * 0.28)
            ctx.fill(Path(roundedRect: base, cornerRadius: w * 0.06), with: .color(amberDark))
            // Glass shine
            let shine = CGRect(x: w * 0.26, y: h * 0.36, width: w * 0.07, height: h * 0.46)
            ctx.fill(Path(roundedRect: shine, cornerRadius: w * 0.035), with: .color(glass))

            // Handle
            var handle = Path()
            handle.move(to: CGPoint(x: w * 0.66, y: h * 0.44))
            handle.addCurve(to: CGPoint(x: w * 0.66, y: h * 0.78),
                            control1: CGPoint(x: w * 0.92, y: h * 0.46),
                            control2: CGPoint(x: w * 0.92, y: h * 0.76))
            ctx.stroke(handle, with: .color(amberDark), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))

            // Foam — overlapping white blobs spilling over the rim
            let foam = Color.white
            let blobs: [(CGFloat, CGFloat, CGFloat)] = [
                (0.24, 0.24, 0.16), (0.36, 0.18, 0.20), (0.52, 0.22, 0.17), (0.44, 0.30, 0.14)
            ]
            for (bx, by, bs) in blobs {
                ctx.fill(Path(ellipseIn: CGRect(x: w * bx, y: h * by, width: w * bs, height: w * bs)),
                         with: .color(foam))
            }
            // foam base across the rim
            let foamBase = CGRect(x: w * 0.18, y: h * 0.30, width: w * 0.50, height: h * 0.10)
            ctx.fill(Path(roundedRect: foamBase, cornerRadius: w * 0.05), with: .color(foam))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Beer stein")
    }
}

// MARK: - Culture badge (emoji in a themed ring)

/// A round badge wrapping a cartoon glyph in a gold ring — used for a row of
/// German cultural icons (pretzel, sausage, etc.).
struct CultureBadge: View {
    let emoji: String
    var size: CGFloat = 56
    var label: String? = nil

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(
                Circle().fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                Circle().strokeBorder(German.gold, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
            .accessibilityLabel(label ?? emoji)
    }
}

// MARK: - Previews

#Preview("Flag stripe") {
    VStack(spacing: 24) {
        GermanFlagStripe()
            .padding(.horizontal, 40)
        GermanFlagBadge(size: 50)
    }
    .padding()
}

#Preview("Waving flag") {
    WavingGermanFlag(width: 180, height: 130)
        .padding()
}

#Preview("Brandenburg Gate") {
    BrandenburgGate(width: 220)
        .padding()
}

#Preview("Beer stein") {
    BeerStein(size: 140)
        .padding()
}

#Preview("Culture badges") {
    HStack(spacing: 14) {
        CultureBadge(emoji: "🥨", label: "Pretzel")
        CultureBadge(emoji: "🍺", label: "Beer")
        CultureBadge(emoji: "🥖", label: "Bread")
        CultureBadge(emoji: "🧇", label: "Waffle")
    }
    .padding()
}
