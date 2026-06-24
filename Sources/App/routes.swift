import Vapor
import WhooshingServer
import Fluent

func routes(_ woo: Whooshing<Https>, _ app: Application) throws {
    try app.register(collection: AccountController())
}

func routes(_ woo: Whooshing<Api>, _ app: Application) throws {
    try app.register(collection: ApiAccountController())
    try app.register(collection: PrivilegeController())
}

func routes(_ woo: Whooshing<Inline>, _ app: Application) throws {
    
}
