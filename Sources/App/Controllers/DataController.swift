import PrivilegeSystemDriver
import VaporTube
import Foundation

public struct DataController: RouteCollection, Sendable {
    /// 查询 API 设计：
    ///
    ///     查询模型记录:
    ///         所有: http://URL/MODEL_NAME
    ///         条件: http://URL/MODEL_NAME?id=XXX
    ///     查询模型关系:
    ///         所有: http://URL/relation/RELATION_NAME
    ///         条件: http://URL/relation/RELATION_NAME?LEFT_ID=XXX
    ///         条件: http://URL/relation/RELATION_NAME?RIGHT_ID=XXX
    public func boot(routes: any RoutesBuilder) throws {
        // Domain
        let relation = routes.grouped("relation")
        routes.get("domain", use: fetchDomain)
        relation.get("domain_user", use: fetchRelDomainUser)
        
        // ...
    }
}

// MARK: - Domain

public extension DataController {
    @Sendable
    func fetchDomain(req: Request) async throws -> [QDomain] {
        let id = req.query[UUID.self, at: "id"]
        var query = QDomain.query(on: PrivilegeSystem.main)
        if let id = id { query = query.filter(\.id == id) }
        return try await query.all()
    }
    
    // Queries
    @Sendable
    func fetchRelDomainUser(req: Request) async throws -> [UserTDomain] {
        struct DomainUser: Content {
            let domainId: UUID?
            let userId: UUID?
            
            enum CodingKeys: String, CodingKey {
                case domainId = "domain_id"
                case userId = "user_id"
            }
        }
        
        let parameters = try req.query.decode(DomainUser.self)
        var query = UserTDomain.query(on: PrivilegeSystem.main)
        if let domainId = parameters.domainId { query = query.filter(\.domainId == domainId) }
        if let userId = parameters.userId { query = query.filter(\.userId == userId) }
        return try await query.all()
    }
}
