import Fluent
import VaporTube
import PrivilegeSystemDriver

func routes(_ nexus: Nexus<VaporTube>) throws {
    try nexus.tube.app.register(collection: AccountController())
    
    let dataRouter = nexus.tube.app.grouped("data")
    try dataRouter.register(collection: DataController())
    
    let inlineProtected = nexus.tube.app.grouped("inline").grouped(ServiceValidator())
    try inlineProtected.register(collection: ArbitrateController())
    
    let apiProtected = nexus.tube.app.grouped("api").grouped(TokenAuthenticator(), QToken.guardMiddleware())
    try apiProtected.register(collection: PrivilegeController())
    try apiProtected.register(collection: ApiAccountController())

    if Woo.isIndependentDebug {
        // 用于模拟 Manager 模块的服务模块 ID 验证 API
        // 仅在测试或开发环境下，才会加载此路由
        // 正式发布可删除这段代码
        try nexus.tube.app.register(collection: DebugingModuleController())
    }
}
