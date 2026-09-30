// 앱 아이콘 생성: swift scripts/make_icon.swift <출력 경로>
// 크림 배경 위 먹색 점 4개, 그중 하나만 토마토색 (DESIGN IC-11)
import AppKit

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

color(0xF4EFE6).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

let dot: CGFloat = 250, gap: CGFloat = 70
let origin = (CGFloat(size) - (dot * 2 + gap)) / 2
for row in 0..<2 {
    for col in 0..<2 {
        let x = origin + CGFloat(col) * (dot + gap)
        let y = origin + CGFloat(row) * (dot + gap)
        let rect = NSRect(x: x, y: y, width: dot, height: dot)
        // 오른쪽 아래(좌표계상 row 0, col 1)만 토마토
        (row == 0 && col == 1 ? color(0xE4572E) : color(0x1C1B1A)).setFill()
        NSBezierPath(ovalIn: rect).fill()
    }
}
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
