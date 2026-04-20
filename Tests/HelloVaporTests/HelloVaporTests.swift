@testable import HelloVapor
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct HelloVaporTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "hello", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            })
        }
    }
    
    @Test("Getting all the Todos")
    func getAllTodos() async throws {
        try await withApp { app in
            let sampleTodos = [Todo(title: "sample1"), Todo(title: "sample2")]
            try await sampleTodos.create(on: app.db)
            
            try await app.testing().test(.GET, "todos", afterResponse: { res async throws in
                #expect(res.status == .ok)
                #expect(try
                    res.content.decode([TodoDTO].self).sorted(by: { ($0.title ?? "") < ($1.title ?? "") }) ==
                    sampleTodos.map { $0.toDTO() }.sorted(by: { ($0.title ?? "") < ($1.title ?? "") })
                )
            })
        }
    }
    
    @Test("Creating a Todo")
    func createTodo() async throws {
        let newDTO = TodoDTO(id: nil, title: "test")
        
        try await withApp { app in
            try await app.testing().test(.POST, "todos", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let models = try await Todo.query(on: app.db).all()
                #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
            })
        }
    }
    
    @Test("Deleting a Todo")
    func deleteTodo() async throws {
        let testTodos = [Todo(title: "test1"), Todo(title: "test2")]
        
        try await withApp { app in
            try await testTodos.create(on: app.db)
            
            try await app.testing().test(.DELETE, "todos/\(testTodos[0].requireID())", afterResponse: { res async throws in
                #expect(res.status == .noContent)
                let model = try await Todo.find(testTodos[0].id, on: app.db)
                #expect(model == nil)
            })
        }
    }

    @Test("Mock hit records request log")
    func mockHitRecordsRequestLog() async throws {
        try await withApp { app in
            let mock = MockAPI(
                method: "GET",
                path: "/api/observed",
                statusCode: 201,
                responseBody: "{\"ok\":true}",
                contentType: "application/json",
                isEnabled: true
            )
            try await mock.save(on: app.db)

            try await app.testing().test(.GET, "api/observed?flag=1", beforeRequest: { req in
                req.headers.add(name: "X-Forwarded-For", value: "203.0.113.10")
                req.headers.add(name: "User-Agent", value: "HelloVaporTests")
            }, afterResponse: { res async throws in
                #expect(res.status == .created)
                #expect(res.body.string == "{\"ok\":true}")

                let logs = try await MockAPIRequestLog.query(on: app.db).all()
                #expect(logs.count == 1)
                #expect(logs.first?.mockID == mock.id)
                #expect(logs.first?.method == "GET")
                #expect(logs.first?.path == "/api/observed")
                #expect(logs.first?.query == "flag=1")
                #expect(logs.first?.requestIP == "203.0.113.10")
                #expect(logs.first?.userAgent == "HelloVaporTests")
                #expect(logs.first?.statusCode == 201)
            })
        }
    }

    @Test("Image generator returns PNG")
    func imageGeneratorReturnsPNG() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "img/64x32?bg=mesh&theme=neon&text=AI", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .png)
                #expect(res.body.readableBytes > 8)

                let bytes = Array(res.body.readableBytesView.prefix(8))
                #expect(bytes == [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
            })
        }
    }

    @Test("Image generator caches identical requests")
    func imageGeneratorCachesIdenticalRequests() async throws {
        try await withApp { app in
            let path = "img/65x33?bg=mesh&theme=forest&text=Cache"

            try await app.testing().test(.GET, path, afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.first(name: "X-Image-Cache") == "MISS")
            })

            try await app.testing().test(.GET, path, afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.first(name: "X-Image-Cache") == "HIT")
            })
        }
    }

    @Test("Disabled image preset is not publicly accessible")
    func disabledImagePresetIsNotPubliclyAccessible() async throws {
        try await withApp { app in
            let preset = ImageGeneratorPreset(
                name: "disabled-smoke",
                description: "disabled smoke test",
                width: 80,
                height: 40,
                background: "mesh",
                fromColor: "ff6b6b",
                toColor: "4d96ff",
                theme: "neon",
                foreground: "ffffff",
                text: "Off",
                shape: "rect",
                borderWidth: 0,
                borderColor: "ffffff",
                radius: 0,
                format: "png",
                isEnabled: false
            )
            try await preset.save(on: app.db)
            let id = try preset.requireID()

            try await app.testing().test(.GET, "img/presets/\(id)", afterResponse: { res async in
                #expect(res.status == .notFound)
            })

            preset.isEnabled = true
            try await preset.save(on: app.db)

            try await app.testing().test(.GET, "img/presets/\(id)", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .png)
            })
        }
    }

    @Test("Fake list respects type and count")
    func fakeListRespectsTypeAndCount() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "fake/list?type=user&count=3", afterResponse: { res async throws in
                #expect(res.status == .ok)

                let users = try res.content.decode([FakeUser].self)
                #expect(users.count == 3)
                #expect(users.allSatisfy { !$0.name.isEmpty && !$0.email.isEmpty })
            })
        }
    }
}

extension TodoDTO: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}
