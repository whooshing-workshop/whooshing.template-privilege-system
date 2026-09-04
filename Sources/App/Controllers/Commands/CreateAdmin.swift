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
            context.console.error("创建管理员失败: \(error.localizedDescription)")
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

        let passwordHash = try Crypto.hash(password).get()
        
        try await PrivilegeSystem.main.createAdminIfNotExist(to: Woo.nexus.config.id, for: PUser(email: email, hashedPassword: passwordHash))
    }
}
