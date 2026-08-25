import PrivilegeSystemDriver
import VaporTube
import Foundation

/// 策略控制器：为已存在的域 / 角色单独追加或删除策略。
///
/// 若需要在创建域 / 角色的同时绑定策略，请使用
/// `PUT /domain/with_policies` 或 `PUT /role/with_policies`。
public struct PolicyController: RouteCollection, Sendable {
    static let policy = PrivilegeSystem.main.policy

    public func boot(routes: any RoutesBuilder) throws {
        let policy = routes.grouped("policy")

        policy.group("domain") { router in
            router.put(use: createDomainPolicies)
            router.put("returning", use: createDomainPoliciesReturning)
            router.delete(use: deleteDomainPolicy)
        }

        policy.group("role") { router in
            router.put(use: createRolePolicies)
            router.put("returning", use: createRolePoliciesReturning)
            router.delete(use: deleteRolePolicy)
        }
    }
}

// MARK: - 域策略

public extension PolicyController {
    /// 为已存在的域批量创建并绑定策略（关系右侧为域 ID）
    @Sendable
    func createDomainPolicies(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTORelation<PPolicy<Domain>, UUID>>.self)
        try await Self.policy.create(to: Domain.self, relations: relations)
        return true
    }

    /// 为已存在的域批量创建并绑定策略，并返回按域 ID 分组的策略数据
    @Sendable
    func createDomainPoliciesReturning(req: Request) async throws -> [String: [QPolicy<Domain>]] {
        let relations = try req.content.decode(OrderedSet<MTORelation<PPolicy<Domain>, UUID>>.self)
        let result = try await Self.policy.createWithReturning(to: Domain.self, relations: relations)
        return .init(uniqueKeysWithValues: result.map { ($0.key.uuidString, $0.value) })
    }

    /// 删除域策略：left 为完整的 QPolicy<Domain>（可从 DataController 查询获得），right 为其从属的域 ID
    @Sendable
    func deleteDomainPolicy(req: Request) async throws -> Bool {
        let relation = try req.content.decode(OTORelation<QPolicy<Domain>, UUID>.self)
        try await Self.policy.delete(from: Domain.self, policy: relation)
        return true
    }
}

// MARK: - 角色策略

public extension PolicyController {
    /// 为已存在的角色批量创建并绑定策略（关系右侧为角色 ID）
    @Sendable
    func createRolePolicies(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTORelation<PPolicy<Role>, UUID>>.self)
        try await Self.policy.create(to: Role.self, relations: relations)
        return true
    }

    /// 为已存在的角色批量创建并绑定策略，并返回按角色 ID 分组的策略数据
    @Sendable
    func createRolePoliciesReturning(req: Request) async throws -> [String: [QPolicy<Role>]] {
        let relations = try req.content.decode(OrderedSet<MTORelation<PPolicy<Role>, UUID>>.self)
        let result = try await Self.policy.createWithReturning(to: Role.self, relations: relations)
        return .init(uniqueKeysWithValues: result.map { ($0.key.uuidString, $0.value) })
    }

    /// 删除角色策略：left 为完整的 QPolicy<Role>（可从 DataController 查询获得），right 为其从属的角色 ID
    @Sendable
    func deleteRolePolicy(req: Request) async throws -> Bool {
        let relation = try req.content.decode(OTORelation<QPolicy<Role>, UUID>.self)
        try await Self.policy.delete(from: Role.self, policy: relation)
        return true
    }
}
