import Foundation

struct FakeDataService: Sendable {
  func user() -> FakeUser {
    FakeUser(
      id: UUID(),
      name: random(["Ava Chen", "Leo Wang", "Mia Zhang", "Noah Li", "Iris Lin"]),
      email: random(["ava@example.com", "leo@example.com", "mia@example.com", "noah@example.com", "iris@example.com"]),
      avatar: "/img/200x200?bg=mesh&theme=aurora&shape=circle&text=AI"
    )
  }

  func product() -> FakeProduct {
    FakeProduct(
      id: UUID(),
      title: random(["Mesh Card", "Mock API Pro", "Dev Canvas", "Pixel Kit", "Vapor Lab"]),
      price: Double(Int.random(in: 19...299)) + 0.99,
      image: "/img/800x500?bg=mesh&theme=\(random(["sunset", "ocean", "candy", "neon"]))&text=Preview"
    )
  }

  func banner() -> FakeBanner {
    FakeBanner(
      id: UUID(),
      title: random(["Build faster", "Mock anything", "Generate useful placeholders"]),
      image: "/img/1200x480?bg=mesh&theme=\(random(["sunset", "aurora", "grape"]))&text=Dev Toolkit"
    )
  }

  private func random<T>(_ values: [T]) -> T {
    values.randomElement()!
  }
}
