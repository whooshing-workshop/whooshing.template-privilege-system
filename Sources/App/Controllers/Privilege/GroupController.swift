import PrivilegeSystemDriver
import VaporTube
import Foundation

public struct GroupController: RouteCollection, Sendable {
    static let group = PrivilegeSystem.main.group

    public func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("group")
        group.put(use: create)
        group.delete(use: delete)

        group.group(":groupId") { router in
            router.post("name", use: updateName)
            router.post("summary", use: updateSummary)
        }

        group.group("join") { router in
            router.post("user", use: joinUser)
        }

        group.group("kick") { router in
            router.post("user", use: kickUser)
        }

        // 层级移动：将群组（含其子树）移动到新的父群组下
        group.post("move", use: move)

        // 批量查询“用户-群组”组内关系（用于获取 user_in_group 关系 ID）
        group.post("query", use: queryUserInGroup)
    }
}

// MARK: - 增

public extension GroupController {
    @Sendable
    func create(req: Request) async throws -> [QGroup] {
        let groups = try req.content.decode(OrderedSet<PGroup>.self)
        return try await Self.group.create(groups: groups)
    }
}

// MARK: - 删

public extension GroupController {
    @Sendable
    func delete(req: Request) async throws -> Bool {
        let ids = try req.content.decode(OrderedSet<UUID>.self)
        try await Self.group.delete(groupIds: ids)
        return true
    }
}

// MARK: - 改

public extension GroupController {
    @Sendable
    func updateName(req: Request) async throws -> QGroup {
        let groupId = try parameter("groupId", from: req) { UUID(uuidString: $0) }
        let name = try req.content.decode(String.self)
        let updater = PGroup.Updater(groupId: groupId).update(name: name)
        return try await Self.group.update(with: updater)
    }

    @Sendable
    func updateSummary(req: Request) async throws -> QGroup {
        let groupId = try parameter("groupId", from: req) { UUID(uuidString: $0) }
        let summary = try req.content.decode(String?.self)
        let updater = PGroup.Updater(groupId: groupId).update(summary: summary)
        return try await Self.group.update(with: updater)
    }
}

// MARK: - 模型关系

public extension GroupController {
    @Sendable
    func joinUser(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTMRelation<UUID, UUID>>.self)
        try await Self.group.join(userToGroup: relations)
        return true
    }

    @Sendable
    func kickUser(req: Request) async throws -> Bool {
        let relations = try req.content.decode(OrderedSet<MTMRelation<UUID, UUID>>.self)
        try await Self.group.kick(userFromGroup: relations)
        return true
    }

    /// 移动群组：left 为要移动的群组 ID，right 为新的父群组 ID（为 null 表示移动至顶层）
    @Sendable
    func move(req: Request) async throws -> Bool {
        let relation = try req.content.decode(OTORelation<UUID, UUID?>.self)
        try await Self.group.move(relation)
        return true
    }
}

// MARK: - 组内关系查询

public extension GroupController {
    /// 批量查询用户与群组之间的组内关系记录（UserTGroup）。
    ///
    /// 查询参数 `strict`（默认 true）：查出的记录条数与提供的关系数量不符时抛错。
    @Sendable
    func queryUserInGroup(req: Request) async throws -> [UserTGroup] {
        let relations = try req.content.decode(OrderedSet<PUserTGroup>.self)
        let strict = req.query[Bool.self, at: "strict"] ?? true
        return try await Self.group.query(relations: relations, strict: strict)
    }
}
