import PrivilegeSystemDriver
import Foundation

public struct AccountController: RouteCollection, Sendable {
    public func boot(routes: any RoutesBuilder) throws {
        let account = routes.grouped("account")
        account.post("register", use: register)
        account.post("login", use: login)
        account.post("authenticate", use: authenticate)
        account.put("change_password", use: changePasswordWithoutAuth)
        let authed = account.grouped(
            TokenAuthenticator(),
            QToken.guardMiddleware()
        )
        authed.post("change_password", use: changePassword)
    }
    
    @Sendable
    func register(req: Request) async throws -> QUser {
        let infos = try req.content.decode(PUser.self)
        let result = try await PrivilegeSystem.main.account.register(for: infos)
        return result
    }
    
    @Sendable
    func login(req: Request) async throws -> QToken {
        let account = try req.content.decode(PUser.self)
        let result = try await PrivilegeSystem.main.account.login(by: account)
        return result
    }
    
    @Sendable
    func authenticate(req: Request) async throws -> AuthData {
        let token = try req.content.decode(EncryptedToken.self)
        let result = try await PrivilegeSystem.main.account.authenticate(token: token)
        return result
    }
    
    @Sendable
    func changePasswordWithoutAuth(req: Request) async throws -> QUser {
        struct PasswordChangeInput: Content {
            let user: PUser
            let newPassword: String
        }
        
        let input = try req.content.decode(PasswordChangeInput.self)
        return try await PrivilegeSystem.main.account.changePassword(for: input.user, to: input.newPassword)
    }
    
    @Sendable
    func changePassword(req: Request) async throws -> QUser {
        struct PasswordChangeInput: Content {
            let newPassword: String
        }
        
        let token = try req.auth.require(QToken.self)
        let input = try req.content.decode(PasswordChangeInput.self)
        return try await PrivilegeSystem.main.account.changePassword(for: token.user, to: input.newPassword)
    }
}

public struct ApiAccountController: RouteCollection, Sendable {
    public func boot(routes: any RoutesBuilder) throws {
        let account = routes.grouped("account")
        account.post("change_password", use: changePassword)
    }
    
    @Sendable
    func changePassword(req: Request) async throws -> QUser {
        let token = try req.auth.require(QToken.self)
        let newPassword = try req.content.decode(String.self)
        return try await PrivilegeSystem.main.account.changePassword(for: token.user, to: newPassword)
    }
}
