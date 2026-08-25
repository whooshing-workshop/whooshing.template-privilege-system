import PrivilegeSystemDriver
import VaporTube
import Foundation

public struct DomainController: RouteCollection, Sendable {
    let domain = PrivilegeSystem.main.domain
    
    public func boot(routes: any RoutesBuilder) throws {
        let domain = routes.grouped("domain")
        domain.put(use: create)
        domain.delete(use: delete)
        
        domain.group(":domainId") { router in
            domain.post("name", use: updateName)
            domain.post("summary", use: updateSummary)
        }
        
        domain.group("assign") { router in
            router.post("user", use: assignUser)
            router.post("group", use: assignGroup)
        }
        
        domain.group("unassign") { router in
            router.post("user", use: unassignUser)
            router.post("group", use: unassignGroup)
        }
    }
}

// MARK: - 增

public extension DomainController {
    @Sendable
    func create(req: Request) async throws -> [QDomain] {
        let domains = try req.content.decode(OrderedSet<PDomain>.self)
        return try await domain.create(domains: domains)
    }
}

// MARK: - 删

public extension DomainController {
    @Sendable
    func delete(req: Request) async throws -> Bool {
        let ids = try req.content.decode(OrderedSet<UUID>.self)
        try await domain.delete(domainIds: ids)
        return true
    }
}

// MARK: - 改

public extension DomainController {
    @Sendable
    func updateName(req: Request) async throws -> QDomain {
        let domainId = try parameter("domainId", from: req) { UUID(uuidString: $0) }
        let name = try req.content.decode(String.self)
        let updater = PDomain.Updater(domainId: domainId).update(name: name)
        return try await domain.update(with: updater)
    }
    
    @Sendable
    func updateSummary(req: Request) async throws -> QDomain {
        let domainId = try parameter("domainId", from: req) { UUID(uuidString: $0) }
        let summary = try req.content.decode(String?.self)
        let updater = PDomain.Updater(domainId: domainId).update(summary: summary)
        return try await domain.update(with: updater)
    }
}

// MARK: - 模型关系

public extension DomainController {
    @Sendable
    func assignUser(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTMRelation<UUID, UUID>>.self)
        try await domain.assign(domainToUser: relations)
        return true
    }
    
    @Sendable
    func assignGroup(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTMRelation<UUID, UUID>>.self)
        try await domain.assign(domainToGroup: relations)
        return true
    }
}

public extension DomainController {
    @Sendable
    func unassignUser(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTMRelation<UUID, UUID>>.self)
        try await domain.unassign(domainFromUser: relations)
        return true
    }
    
    @Sendable
    func unassignGroup(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTMRelation<UUID, UUID>>.self)
        try await domain.unassign(domainFromGroup: relations)
        return true
    }
}
