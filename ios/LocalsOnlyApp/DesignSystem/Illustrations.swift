import SwiftUI

// MARK: - Brand Shapes

struct PalmTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        let cx = w * 0.50, cy = h * 0.42

        p.move(to: CGPoint(x: w * 0.44, y: h * 0.44))
        p.addQuadCurve(to: CGPoint(x: w * 0.40, y: h), control: CGPoint(x: w * 0.41, y: h * 0.72))
        p.addLine(to: CGPoint(x: w * 0.58, y: h))
        p.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.44), control: CGPoint(x: w * 0.60, y: h * 0.72))
        p.closeSubpath()

        func leaf(tip: CGPoint, out: CGPoint, back: CGPoint) {
            p.move(to: CGPoint(x: cx, y: cy))
            p.addQuadCurve(to: tip, control: out)
            p.addQuadCurve(to: CGPoint(x: cx, y: cy), control: back)
            p.closeSubpath()
        }

        leaf(tip: .init(x: 0, y: h * 0.55),
             out: .init(x: w * 0.12, y: h * 0.28), back: .init(x: w * 0.20, y: h * 0.48))
        leaf(tip: .init(x: w * 0.05, y: h * 0.12),
             out: .init(x: w * 0.18, y: h * 0.12), back: .init(x: w * 0.28, y: h * 0.26))
        leaf(tip: .init(x: w * 0.35, y: 0),
             out: .init(x: w * 0.36, y: h * 0.15), back: .init(x: w * 0.44, y: h * 0.16))
        leaf(tip: .init(x: w * 0.85, y: h * 0.05),
             out: .init(x: w * 0.72, y: h * 0.08), back: .init(x: w * 0.70, y: h * 0.24))
        leaf(tip: .init(x: w * 0.95, y: h * 0.22),
             out: .init(x: w * 0.80, y: h * 0.14), back: .init(x: w * 0.76, y: h * 0.32))
        leaf(tip: .init(x: w, y: h * 0.50),
             out: .init(x: w * 0.88, y: h * 0.28), back: .init(x: w * 0.80, y: h * 0.44))

        return p
    }
}

struct SeagullShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * 0.75))
        p.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.55),
                       control: CGPoint(x: w * 0.22, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: h * 0.75),
                       control: CGPoint(x: w * 0.78, y: 0))
        return p
    }
}

// MARK: - Default Avatars

enum AvatarVariant {
    case beachGuy, beachGirl

    static func forUser(_ id: UUID) -> AvatarVariant {
        id.uuid.15 % 2 == 0 ? .beachGuy : .beachGirl
    }
}

struct DefaultAvatarView: View {
    let variant: AvatarVariant
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color.coastalSand.opacity(0.15))
            avatarCanvas
                .foregroundStyle(Color.vintageInk)
                .padding(size * 0.15)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var avatarCanvas: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let lw = max(1.5, w * 0.045)
            let headR = w * 0.19, headY = h * 0.30

            ctx.stroke(
                Circle().path(in: CGRect(x: w / 2 - headR, y: headY - headR,
                                         width: headR * 2, height: headR * 2)),
                with: .foreground, lineWidth: lw)

            let er = max(1.0, w * 0.028)
            ctx.fill(Circle().path(in: CGRect(x: w * 0.41 - er, y: headY - er * 0.5,
                                              width: er * 2, height: er * 2)), with: .foreground)
            ctx.fill(Circle().path(in: CGRect(x: w * 0.59 - er, y: headY - er * 0.5,
                                              width: er * 2, height: er * 2)), with: .foreground)

            var smile = Path()
            smile.move(to: CGPoint(x: w * 0.43, y: headY + w * 0.08))
            smile.addQuadCurve(to: CGPoint(x: w * 0.57, y: headY + w * 0.08),
                               control: CGPoint(x: w * 0.50, y: headY + w * 0.14))
            ctx.stroke(smile, with: .foreground,
                       style: StrokeStyle(lineWidth: lw * 0.7, lineCap: .round))

            let neckBase = headY + headR + w * 0.05
            var body = Path()
            body.move(to: CGPoint(x: w * 0.08, y: h * 0.90))
            body.addQuadCurve(to: CGPoint(x: w * 0.50, y: neckBase),
                              control: CGPoint(x: w * 0.22, y: neckBase))
            body.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.90),
                              control: CGPoint(x: w * 0.78, y: neckBase))
            ctx.stroke(body, with: .foreground,
                       style: StrokeStyle(lineWidth: lw, lineCap: .round))

            switch variant {
            case .beachGuy:
                var hair = Path()
                let top = headY - headR
                hair.move(to: CGPoint(x: w * 0.38, y: top + w * 0.02))
                hair.addLine(to: CGPoint(x: w * 0.41, y: top - w * 0.08))
                hair.move(to: CGPoint(x: w * 0.48, y: top - w * 0.01))
                hair.addLine(to: CGPoint(x: w * 0.50, y: top - w * 0.10))
                hair.move(to: CGPoint(x: w * 0.58, y: top + w * 0.01))
                hair.addLine(to: CGPoint(x: w * 0.61, y: top - w * 0.07))
                ctx.stroke(hair, with: .foreground,
                           style: StrokeStyle(lineWidth: lw, lineCap: .round))

            case .beachGirl:
                var hair = Path()
                hair.move(to: CGPoint(x: w * 0.32, y: headY - headR * 0.3))
                hair.addQuadCurve(to: CGPoint(x: w * 0.22, y: headY + headR * 1.2),
                                  control: CGPoint(x: w * 0.18, y: headY))
                hair.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.72),
                                  control: CGPoint(x: w * 0.28, y: headY + headR * 1.8))
                hair.move(to: CGPoint(x: w * 0.68, y: headY - headR * 0.3))
                hair.addQuadCurve(to: CGPoint(x: w * 0.78, y: headY + headR * 1.2),
                                  control: CGPoint(x: w * 0.82, y: headY))
                hair.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.72),
                                  control: CGPoint(x: w * 0.72, y: headY + headR * 1.8))
                ctx.stroke(hair, with: .foreground,
                           style: StrokeStyle(lineWidth: lw, lineCap: .round))

                let fc = CGPoint(x: w * 0.70, y: headY - headR * 0.65)
                let pr = w * 0.035
                for i in 0..<5 {
                    let a = Double(i) * .pi * 2 / 5 - .pi / 2
                    ctx.fill(
                        Circle().path(in: CGRect(
                            x: fc.x + cos(a) * pr * 1.5 - pr,
                            y: fc.y + sin(a) * pr * 1.5 - pr,
                            width: pr * 2, height: pr * 2)),
                        with: .foreground)
                }
            }
        }
    }
}

// MARK: - Category Icons

struct CategoryIconView: View {
    let category: String
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let lw = max(1.5, sz.width * 0.055)
            switch CategoryKind.from(category) {
            case .drink:  drawCocktail(ctx: ctx, sz: sz, lw: lw)
            case .coffee: drawCoffee(ctx: ctx, sz: sz, lw: lw)
            case .food:   drawForkKnife(ctx: ctx, sz: sz, lw: lw)
            case .general: drawPalm(ctx: ctx, sz: sz)
            }
        }
        .frame(width: size, height: size)
    }

    private func drawCocktail(ctx: GraphicsContext, sz: CGSize, lw: CGFloat) {
        let w = sz.width, h = sz.height
        var glass = Path()
        glass.move(to: CGPoint(x: w * 0.15, y: h * 0.18))
        glass.addLine(to: CGPoint(x: w * 0.50, y: h * 0.55))
        glass.addLine(to: CGPoint(x: w * 0.85, y: h * 0.18))
        glass.move(to: CGPoint(x: w * 0.50, y: h * 0.55))
        glass.addLine(to: CGPoint(x: w * 0.50, y: h * 0.78))
        glass.move(to: CGPoint(x: w * 0.32, y: h * 0.78))
        glass.addLine(to: CGPoint(x: w * 0.68, y: h * 0.78))
        ctx.stroke(glass, with: .foreground,
                   style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
        let r = w * 0.055
        ctx.fill(Circle().path(in: CGRect(x: w * 0.60 - r, y: h * 0.30 - r,
                                          width: r * 2, height: r * 2)), with: .foreground)
    }

    private func drawCoffee(ctx: GraphicsContext, sz: CGSize, lw: CGFloat) {
        let w = sz.width, h = sz.height
        let cup = CGRect(x: w * 0.18, y: h * 0.38, width: w * 0.50, height: h * 0.42)
        ctx.stroke(RoundedRectangle(cornerRadius: w * 0.06).path(in: cup),
                   with: .foreground, lineWidth: lw)
        var handle = Path()
        handle.move(to: CGPoint(x: cup.maxX, y: h * 0.48))
        handle.addQuadCurve(to: CGPoint(x: cup.maxX, y: h * 0.68),
                            control: CGPoint(x: w * 0.86, y: h * 0.58))
        ctx.stroke(handle, with: .foreground,
                   style: StrokeStyle(lineWidth: lw, lineCap: .round))
        var steam = Path()
        steam.move(to: CGPoint(x: w * 0.32, y: h * 0.32))
        steam.addQuadCurve(to: CGPoint(x: w * 0.32, y: h * 0.14),
                           control: CGPoint(x: w * 0.22, y: h * 0.22))
        steam.move(to: CGPoint(x: w * 0.48, y: h * 0.30))
        steam.addQuadCurve(to: CGPoint(x: w * 0.48, y: h * 0.12),
                           control: CGPoint(x: w * 0.58, y: h * 0.20))
        ctx.stroke(steam, with: .foreground,
                   style: StrokeStyle(lineWidth: lw * 0.7, lineCap: .round))
    }

    private func drawForkKnife(ctx: GraphicsContext, sz: CGSize, lw: CGFloat) {
        let w = sz.width, h = sz.height
        var fork = Path()
        fork.move(to: CGPoint(x: w * 0.30, y: h * 0.80))
        fork.addLine(to: CGPoint(x: w * 0.30, y: h * 0.42))
        fork.move(to: CGPoint(x: w * 0.20, y: h * 0.42))
        fork.addLine(to: CGPoint(x: w * 0.20, y: h * 0.20))
        fork.move(to: CGPoint(x: w * 0.30, y: h * 0.42))
        fork.addLine(to: CGPoint(x: w * 0.30, y: h * 0.20))
        fork.move(to: CGPoint(x: w * 0.40, y: h * 0.42))
        fork.addLine(to: CGPoint(x: w * 0.40, y: h * 0.20))
        fork.move(to: CGPoint(x: w * 0.20, y: h * 0.42))
        fork.addLine(to: CGPoint(x: w * 0.40, y: h * 0.42))
        ctx.stroke(fork, with: .foreground,
                   style: StrokeStyle(lineWidth: lw, lineCap: .round))
        var knife = Path()
        knife.move(to: CGPoint(x: w * 0.68, y: h * 0.80))
        knife.addLine(to: CGPoint(x: w * 0.68, y: h * 0.38))
        knife.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.18),
                           control: CGPoint(x: w * 0.82, y: h * 0.28))
        ctx.stroke(knife, with: .foreground,
                   style: StrokeStyle(lineWidth: lw, lineCap: .round))
    }

    private func drawPalm(ctx: GraphicsContext, sz: CGSize) {
        let inset = sz.width * 0.15
        ctx.fill(PalmTreeShape().path(in: CGRect(x: inset, y: inset * 0.5,
                                                  width: sz.width - inset * 2,
                                                  height: sz.height - inset * 1.5)),
                 with: .foreground)
    }
}

enum CategoryKind {
    case drink, food, coffee, general

    static func from(_ cat: String) -> CategoryKind {
        let s = cat.lowercased()
        if s.contains("drink") || s.contains("bar") || s.contains("cocktail") { return .drink }
        if s.contains("coffee") || s.contains("cafe") || s.contains("tea") { return .coffee }
        if s.contains("food") || s.contains("restaurant") { return .food }
        return .general
    }
}

// MARK: - Placeholder Hero Scenes

struct PlaceholderHeroView: View {
    let category: String
    var height: CGFloat? = nil

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            guard w > 0, h > 0 else { return }
            let lw = max(1.5, min(w, h) * 0.012)
            let ink = Color.coastalSand.opacity(0.5)

            switch CategoryKind.from(category) {
            case .food:   drawFoodScene(ctx: ctx, w: w, h: h, lw: lw, ink: ink)
            case .drink:  drawDrinkScene(ctx: ctx, w: w, h: h, lw: lw, ink: ink)
            case .coffee: drawCoffeeScene(ctx: ctx, w: w, h: h, lw: lw, ink: ink)
            case .general: drawGeneralScene(ctx: ctx, w: w, h: h, lw: lw, ink: ink)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height ?? .infinity)
        .background(Color.coastalSand.opacity(0.06))
    }

    private func drawFoodScene(ctx: GraphicsContext, w: CGFloat, h: CGFloat, lw: CGFloat, ink: Color) {
        let bowlY = h * 0.55
        var bowl = Path()
        bowl.addArc(center: CGPoint(x: w * 0.5, y: bowlY),
                    radius: w * 0.18, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        bowl.closeSubpath()
        ctx.stroke(bowl, with: .color(ink), style: StrokeStyle(lineWidth: lw * 2, lineCap: .round))

        var rim = Path()
        rim.move(to: CGPoint(x: w * 0.28, y: bowlY))
        rim.addLine(to: CGPoint(x: w * 0.72, y: bowlY))
        ctx.stroke(rim, with: .color(ink), style: StrokeStyle(lineWidth: lw * 2, lineCap: .round))

        for i in 0..<3 {
            let cx = w * (0.40 + Double(i) * 0.10)
            var steam = Path()
            steam.move(to: CGPoint(x: cx, y: bowlY - w * 0.02))
            let ctrl = i % 2 == 0 ? cx - w * 0.03 : cx + w * 0.03
            steam.addQuadCurve(to: CGPoint(x: cx, y: bowlY - w * 0.14),
                               control: CGPoint(x: ctrl, y: bowlY - w * 0.08))
            ctx.stroke(steam, with: .color(ink.opacity(0.6)),
                       style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round))
        }

        var chop1 = Path()
        chop1.move(to: CGPoint(x: w * 0.62, y: h * 0.25))
        chop1.addLine(to: CGPoint(x: w * 0.50, y: bowlY - w * 0.02))
        var chop2 = Path()
        chop2.move(to: CGPoint(x: w * 0.67, y: h * 0.25))
        chop2.addLine(to: CGPoint(x: w * 0.55, y: bowlY - w * 0.02))
        ctx.stroke(chop1, with: .color(ink), style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round))
        ctx.stroke(chop2, with: .color(ink), style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round))
    }

    private func drawDrinkScene(ctx: GraphicsContext, w: CGFloat, h: CGFloat, lw: CGFloat, ink: Color) {
        let cx = w * 0.5, baseY = h * 0.78
        var glass = Path()
        glass.move(to: CGPoint(x: cx - w * 0.16, y: h * 0.28))
        glass.addLine(to: CGPoint(x: cx - w * 0.10, y: baseY))
        glass.addLine(to: CGPoint(x: cx + w * 0.10, y: baseY))
        glass.addLine(to: CGPoint(x: cx + w * 0.16, y: h * 0.28))
        ctx.stroke(glass, with: .color(ink),
                   style: StrokeStyle(lineWidth: lw * 2, lineCap: .round, lineJoin: .round))

        var liquid = Path()
        liquid.move(to: CGPoint(x: cx - w * 0.13, y: h * 0.42))
        liquid.addLine(to: CGPoint(x: cx + w * 0.13, y: h * 0.42))
        ctx.stroke(liquid, with: .color(ink.opacity(0.4)),
                   style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round))

        let sliceC = CGPoint(x: cx + w * 0.12, y: h * 0.32)
        let sr = w * 0.06
        ctx.stroke(Circle().path(in: CGRect(x: sliceC.x - sr, y: sliceC.y - sr,
                                             width: sr * 2, height: sr * 2)),
                   with: .color(ink), lineWidth: lw * 1.5)

        var umbrella = Path()
        umbrella.move(to: CGPoint(x: cx - w * 0.04, y: h * 0.12))
        umbrella.addQuadCurve(to: CGPoint(x: cx + w * 0.14, y: h * 0.12),
                              control: CGPoint(x: cx + w * 0.05, y: h * 0.02))
        umbrella.move(to: CGPoint(x: cx + w * 0.05, y: h * 0.12))
        umbrella.addLine(to: CGPoint(x: cx + w * 0.03, y: h * 0.34))
        ctx.stroke(umbrella, with: .color(ink),
                   style: StrokeStyle(lineWidth: lw * 1.5, lineCap: .round))
    }

    private func drawCoffeeScene(ctx: GraphicsContext, w: CGFloat, h: CGFloat, lw: CGFloat, ink: Color) {
        let cupRect = CGRect(x: w * 0.30, y: h * 0.42, width: w * 0.30, height: h * 0.36)
        ctx.stroke(RoundedRectangle(cornerRadius: w * 0.03).path(in: cupRect),
                   with: .color(ink), lineWidth: lw * 2)

        var handle = Path()
        handle.move(to: CGPoint(x: cupRect.maxX, y: h * 0.50))
        handle.addQuadCurve(to: CGPoint(x: cupRect.maxX, y: h * 0.68),
                            control: CGPoint(x: w * 0.72, y: h * 0.59))
        ctx.stroke(handle, with: .color(ink),
                   style: StrokeStyle(lineWidth: lw * 2, lineCap: .round))

        var saucer = Path()
        saucer.move(to: CGPoint(x: w * 0.24, y: h * 0.80))
        saucer.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.80),
                            control: CGPoint(x: w * 0.47, y: h * 0.86))
        ctx.stroke(saucer, with: .color(ink),
                   style: StrokeStyle(lineWidth: lw * 2, lineCap: .round))

        for i in 0..<3 {
            let sx = w * (0.37 + Double(i) * 0.07)
            var steam = Path()
            steam.move(to: CGPoint(x: sx, y: h * 0.38))
            let ctrl = i % 2 == 0 ? sx - w * 0.025 : sx + w * 0.025
            steam.addQuadCurve(to: CGPoint(x: sx, y: h * 0.18),
                               control: CGPoint(x: ctrl, y: h * 0.28))
            ctx.stroke(steam, with: .color(ink.opacity(0.5)),
                       style: StrokeStyle(lineWidth: lw * 1.2, lineCap: .round))
        }
    }

    private func drawGeneralScene(ctx: GraphicsContext, w: CGFloat, h: CGFloat, lw: CGFloat, ink: Color) {
        let palmW = min(w, h) * 0.65
        let palmH = h * 0.78
        let palmRect = CGRect(x: (w - palmW) / 2, y: (h - palmH) / 2,
                              width: palmW, height: palmH)
        ctx.fill(PalmTreeShape().path(in: palmRect), with: .color(ink.opacity(0.5)))
    }
}
