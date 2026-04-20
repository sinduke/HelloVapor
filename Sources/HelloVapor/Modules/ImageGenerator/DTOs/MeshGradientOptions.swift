import Foundation

struct MeshGradientOptions: Sendable {
  let columns: Int
  let rows: Int
  let colors: [RGBColor]

  static func preset(named rawName: String) -> MeshGradientOptions {
    let name = rawName.lowercased()
    let hexColors: [String]

    switch name {
    case "aurora":
      hexColors = ["113c5a", "2dd4bf", "a7f3d0", "312e81", "7c3aed", "f0abfc", "0f766e", "38bdf8", "e0f2fe"]
    case "ocean":
      hexColors = ["082f49", "0369a1", "38bdf8", "0f766e", "06b6d4", "a7f3d0", "164e63", "2563eb", "ecfeff"]
    case "candy":
      hexColors = ["ff80b5", "f9a8d4", "fde68a", "c084fc", "f0abfc", "fef3c7", "7dd3fc", "a7f3d0", "fda4af"]
    case "neon":
      hexColors = ["111827", "ff0080", "00f5ff", "7928ca", "2afadf", "facc15", "0f172a", "22c55e", "f97316"]
    case "forest":
      hexColors = ["052e16", "166534", "84cc16", "14532d", "22c55e", "bef264", "064e3b", "0d9488", "ecfccb"]
    case "grape":
      hexColors = ["2e1065", "6d28d9", "c084fc", "4c1d95", "a855f7", "f0abfc", "581c87", "be185d", "fce7f3"]
    default:
      hexColors = ["7f1d1d", "fb7185", "fbbf24", "9a3412", "f97316", "fde68a", "581c87", "a855f7", "f0abfc"]
    }

    return MeshGradientOptions(
      columns: 3,
      rows: 3,
      colors: hexColors.map { (try? HexColorParser.parse($0)) ?? .gray }
    )
  }
}
