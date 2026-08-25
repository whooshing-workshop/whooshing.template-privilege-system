import PrivilegeSystemDriver
import VaporTube
import Foundation

/// 用户信息控制器：管理用户主信息（UserInfo）及其初始扩展切片的创建，
/// 以及主信息字段的更新与删除。
///
/// 创建请求体结构（每个元素为一条链式关系）：
///
///     [
///       {
///         "left": "USER_UUID",
///         "right": {
///           "left":  { PUserInfo },
///           "right": { "addresses": [...], "alternate_emails": [...], "phones": [...] }
///         }
///       }
///     ]
public struct UserInfoController: RouteCollection, Sendable {
    static let userInfo = PrivilegeSystem.main.userInfo

    public func boot(routes: any RoutesBuilder) throws {
        let userInfo = routes.grouped("user_info")
        userInfo.put(use: create)
        userInfo.delete(use: delete)

        userInfo.group(":userInfoId") { router in
            router.post("nickname", use: updateNickname)
            router.post("identifier", use: updateIdentifier)
            router.post("birthday", use: updateBirthday)
            router.post("other", use: updateOther)
        }
    }
}

// MARK: - 增

public extension UserInfoController {
    @Sendable
    func create(req: Request) async throws -> Bool {
        let relations = try req.content.decode(
            OrderedSet<OTORelation<UUID, OTORelation<PUserInfo, PExtendedInfo>>>.self
        )
        try await Self.userInfo.create(relations: relations)
        return true
    }
}

// MARK: - 删

public extension UserInfoController {
    @Sendable
    func delete(req: Request) async throws -> Bool {
        let ids = try req.content.decode(OrderedSet<UUID>.self)
        try await Self.userInfo.delete(infoIds: ids)
        return true
    }
}

// MARK: - 改

public extension UserInfoController {
    @Sendable
    func updateNickname(req: Request) async throws -> QUserInfo {
        let userInfoId = try parameter("userInfoId", from: req) { UUID(uuidString: $0) }
        let nickname = try req.content.decode(String.self)
        let updater = PUserInfo.Updater(userInfoId: userInfoId).update(nickname: nickname)
        return try await Self.userInfo.update(with: updater)
    }

    @Sendable
    func updateIdentifier(req: Request) async throws -> QUserInfo {
        let userInfoId = try parameter("userInfoId", from: req) { UUID(uuidString: $0) }
        let identifier = try req.content.decode(String.self)
        let updater = PUserInfo.Updater(userInfoId: userInfoId).update(identifier: identifier)
        return try await Self.userInfo.update(with: updater)
    }

    @Sendable
    func updateBirthday(req: Request) async throws -> QUserInfo {
        let userInfoId = try parameter("userInfoId", from: req) { UUID(uuidString: $0) }
        let birthday = try req.content.decode(Date.self)
        let updater = PUserInfo.Updater(userInfoId: userInfoId).update(birthday: birthday)
        return try await Self.userInfo.update(with: updater)
    }

    @Sendable
    func updateOther(req: Request) async throws -> QUserInfo {
        let userInfoId = try parameter("userInfoId", from: req) { UUID(uuidString: $0) }
        let other = try req.content.decode(String?.self)
        let updater = PUserInfo.Updater(userInfoId: userInfoId).update(other: other)
        return try await Self.userInfo.update(with: updater)
    }
}
