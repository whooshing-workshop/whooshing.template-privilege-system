import Vapor
import Fluent
import PrivilegeSystemDriver

struct CreateAdminCommand: AsyncCommand {
    // 定义命令行支持的参数与选项
    struct Signature: CommandSignature {
        @Option(name: "email", short: "u", help: "管理员邮箱")
        var email: String?

        @Option(name: "pass", short: "p", help: "管理员密码")
        var pass: String?
    }

    // 命令的帮助信息 (运行 `vapor run create-admin --help` 时展示)
    let help = "在数据库中创建或初始化管理员账号"

    func run(using context: CommandContext, signature: Signature) async throws {
        do {
            try await execute(using: context, signature: signature)
        } catch {
            // 捕获所有业务或数据库错误，优雅输出到终端，不抛出异常导致进程崩溃
            context.console.error("创建管理员失败: \(error.localizedDescription)")
            
            // 如果需要输出更详细的调试信息：
            context.console.warning("错误详情: \(error)")
        }
    }
    
    func execute(using context: CommandContext, signature: Signature) async throws {
        // 获取参数，若命令行未传入则进入终端交互式输入
        let email: String
        if let e = signature.email {
            email = e
        } else {
            email = context.console.ask("请输入管理员邮箱: ")
        }

        let password: String
        if let pass = signature.pass {
            password = pass
        } else {
            // 终端交互输入密码时不回显
            password = context.console.ask("请输入管理员密码: ", isSecure: true)
        }

        guard !email.isEmpty, !password.isEmpty else {
            context.console.error("邮箱或密码不能为空！")
            return
        }

        context.console.info("正在检查 \"admin\" 角色是否已存在 ...")
        
        let role: QRole
        
        if
            let r = try await QRole.query(on: PrivilegeSystem.main)
                .filter(\.name == "admin")
                .first()
        {
            context.console.info("\"admin\" 角色已存在。")
            role = r
        } else {
            context.console.print("\"admin\" 角色不存在，正在创建 ...")
            let r = PRole(name: "admin", summary: "系统最高管理者")
            guard let rCreated = try await PrivilegeSystem.main.role.create(roles: [r]).first else {
                context.console.error("创建 admin 角色失败，未知错误")
                return
            }
            role = rCreated
            
            context.console.info("正在创建 admin 权限")
            
            let policy = PPolicy<Role>(moduleId: Woo.nexus.config.id, policy: "allow if { true }")
            
            try await PrivilegeSystem.main.policy.create(to: Role.self) {
                OrderedSet([policy]) => role.id
            }
        }
        
        context.console.info("正在检查用户是否已存在...")

        // 检查数据库是否存在同名用户
        let existingUser = try await QUser.query(on: PrivilegeSystem.main)
            .filter(\.email == email)
            .first()

        if existingUser != nil {
            context.console.warning("用户 [\(email)] 已存在，操作已取消。")
            return
        }

        context.console.info("正在创建管理员用户 \(email)...")
        
        // 哈希加密并保存
        let passwordHash = try Crypto.hash(password).get()
        let admin = PUser(email: email, hashedPassword: passwordHash)
        
        // 将 admin 角色指定给新用户
        let res = try await PrivilegeSystem.main.account.register(for: admin)
        try await PrivilegeSystem.main.role.appoint {
            OrderedSet([role]) => OrderedSet([res])
        }
        
        context.console.success("成功创建管理员账号: \(res.email)")
    }
}
