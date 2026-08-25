import PrivilegeSystemDriver
import VaporTube
import Foundation

public struct DataController: RouteCollection, Sendable {
    public func boot(routes: any RoutesBuilder) throws {
        routes.get("domain", use: fetchDomain)
        routes.get(":domainId", use: domainDetails)
    }
}

public extension DataController {
    @Sendable
    func fetchDomain(req: Request) async throws -> [QDomain] {
        try await QDomain.query(on: PrivilegeSystem.main).all()
    }
    
    @Sendable
    func domainDetails(req: Request) async throws -> QDomain {
        let domainId = try parameter("domainId", from: req) { UUID(uuidString: $0) }
        
        guard
            let res = try await QDomain.query(on: PrivilegeSystem.main)
                .filter(\.id == domainId)
                .first()
        else {
            throw Abort(.notFound, reason: "ID 不存在 (\(domainId))")
        }
        
        return res
    }
}
