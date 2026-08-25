import VaporTube

public struct DebugingModuleController: RouteCollection, Sendable {
    /// 该模块接受的来源服务的 ID
    ///
    /// 若有其他服务模块访问该模块，其 ServiceId 必须在以下白名单中，
    /// 且访问者的 serviceId != 被访问者的 serviceId，否则将会被拒绝连线
    /// 作为例子仅提供 6 个，你可以按需添加或减少
    static let serviceIds = [
        UUID(uuidString: "9D61FB39-D7EF-46B6-8690-4DDD23E561A4")!,
        UUID(uuidString: "F1ECC1D7-6E19-4F50-9B89-68FAA332B415")!,
        UUID(uuidString: "2AC424F7-F26A-4EA4-BE44-202ABC7CC514")!,
        UUID(uuidString: "74854475-1C1A-48E2-BAC9-E9C752942F88")!,
        UUID(uuidString: "C59C74DC-AF7F-4497-854B-75561D9FE995")!,
        UUID(uuidString: "F02F2803-BF88-4B51-A743-B3AA0F3FF804")!
    ]
    
    public func boot(routes: any RoutesBuilder) throws {
        let modules = routes.grouped("modules")
        modules.get(use: fetchAllModules)
        // [GET] /modules/:moduleId/verify
        modules.get(":moduleId", "verify", use: verifyModule)
    }
    
    @Sendable
    func fetchAllModules(req: Request) async throws -> ModuleListResponse {
        ModuleListResponse(moduleIds: Self.serviceIds)
    }

    @Sendable
    func verifyModule(req: Request) async throws -> ModuleVerifyResponse {
        let moduleId = try parameter("moduleId", from: req) { UUID(uuidString: $0) }

        return ModuleVerifyResponse(allowed: Self.serviceIds.contains(moduleId))
    }
}

struct ModuleVerifyResponse: Content {
    let allowed: Bool
}

struct ModuleListResponse: Content {
    let moduleIds: [UUID]
}
