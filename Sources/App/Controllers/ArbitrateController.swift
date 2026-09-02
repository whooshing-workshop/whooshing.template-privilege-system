import PrivilegeSystemDriver
import Foundation

public struct ArbitrateData: Content, Sendable {
    let moduleId: UUID
    let userId: UUID
    let roleId: UUID
    let resource: AnyResource
    let operation: AnyOperation
    let privilegeIds: [UUID]
}

public struct ArbitrateController: RouteCollection, Sendable {
    public func boot(routes: any RoutesBuilder) throws {
        routes.post("arbitrate", use: arbitrate)
        routes.post("authenticate", use: authenticate)
    }
    
    @Sendable
    func authenticate(req: Request) async throws -> AuthData {
        let token = try req.content.decode(EncryptedToken.self)
        let result = try await PrivilegeSystem.main.account.authenticate(token: token)
        return result
    }
    
    @Sendable
    func arbitrate(req: Request) async throws -> Bool {
        let data = try req.content.decode(ArbitrateData.self)
        
        let report = try await PrivilegeSystem.main.arbitrator.judge(
            moduleId: data.moduleId,
            userId: data.userId,
            roleId: data.roleId,
            resource: data.resource,
            operation: data.operation,
            privilegeIds: .init(data.privilegeIds)
        )
        
        return report.result
    }
}
