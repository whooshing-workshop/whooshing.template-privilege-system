import PrivilegeSystemDriver
import Foundation

/// 权限系统总控制器：统一注册各权限子控制器（增删改与关系设置）。
///
/// 查询 API 统一由 DataController 提供（见 routes.swift 中的 /data 分组）。
public struct PrivilegeController: RouteCollection, Sendable {
    public func boot(routes: any RoutesBuilder) throws {
        try routes.register(collection: DomainController())
        try routes.register(collection: GroupController())
        try routes.register(collection: RoleController())
        try routes.register(collection: PolicyController())
        try routes.register(collection: InfoSliceController())
        try routes.register(collection: UserInfoController())
    }
}
