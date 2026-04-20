import Foundation
import Vapor

struct FakeDataController: RouteCollection {
  private let service = FakeDataService()

  func boot(routes: any RoutesBuilder) throws {
    let fake = routes.grouped("fake")
    fake.get("user", use: user)
    fake.get("product", use: product)
    fake.get("banner", use: banner)
    fake.get("list", use: list)
  }

  func user(req: Request) async throws -> FakeUser {
    service.user()
  }

  func product(req: Request) async throws -> FakeProduct {
    service.product()
  }

  func banner(req: Request) async throws -> FakeBanner {
    service.banner()
  }

  func list(req: Request) async throws -> [FakePayload] {
    let type = req.query[String.self, at: "type"] ?? "product"
    let count = min(max(req.query[Int.self, at: "count"] ?? 10, 1), 100)

    return (0..<count).map { _ in
      switch type {
      case "user":
        return .user(service.user())
      case "banner":
        return .banner(service.banner())
      default:
        return .product(service.product())
      }
    }
  }
}

struct FakeUser: Content {
  let id: UUID
  let name: String
  let email: String
  let avatar: String
}

struct FakeProduct: Content {
  let id: UUID
  let title: String
  let price: Double
  let image: String
}

struct FakeBanner: Content {
  let id: UUID
  let title: String
  let image: String
}

enum FakePayload: Content {
  case user(FakeUser)
  case product(FakeProduct)
  case banner(FakeBanner)

  func encode(to encoder: any Encoder) throws {
    switch self {
    case .user(let user):
      try user.encode(to: encoder)
    case .product(let product):
      try product.encode(to: encoder)
    case .banner(let banner):
      try banner.encode(to: encoder)
    }
  }
}
