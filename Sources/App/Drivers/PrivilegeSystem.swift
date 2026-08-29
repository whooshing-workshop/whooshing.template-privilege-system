import PrivilegeSystemDriver

/// 在此处配置权限主模块，仅允许配置一个，默认为全局单例模式
/// 权限主模块需要保存权限结构至数据库中，因此需要绑定一个数据库实例
/// 使用 `Woo.inline.syncMakePrivilegeSystem` 初始化一个 PrivilegeSystem 对象，可在全局使用
/// 一旦初始化失败将会导致服务崩溃
extension PrivilegeSystem {
    
    /// 主要的权限主模块，使用数据库服务 "default" 中的 "privilege_system" 数据库存储权限结构
    /// 创建了一个最基本的 Logger，仅将日志记录打印在程序输出中
    /// 若在独立测试环境中，则启动 debugging 模式，否则使用正常的生产或开发模式
    static let main: PrivilegeSystem = {
        Woo.nexus.syncMakePrivilegeSystem(
            for: db(name: "privilege_system", from: "default"),
            logger: Woo.logger,
            debugging: Woo.isIndependentDebug
        )
    }()
}

extension Request {
    public var privilegeSystem: PrivilegeSystem { PrivilegeSystem.main }
}
