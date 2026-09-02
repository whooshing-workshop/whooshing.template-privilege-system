import Fluent
import VaporTube
import PrivilegeSystemDriver

func routes(_ nexus: Nexus<VaporTube>) throws {
    try nexus.tube.app.register(collection: AccountController())
    
    let dataRouter = nexus.tube.app.grouped("data")
    try dataRouter.register(collection: DataController())
    
    let inlineProtected = nexus.tube.app.grouped("inline").grouped(ServiceValidator(), ServiceValidator.Identifier.guardMiddleware())
    try inlineProtected.register(collection: ArbitrateController())
    
    let apiProtected = nexus.tube.app.grouped("api").grouped(TokenAuthenticator(), QToken.guardMiddleware())
    try apiProtected.register(collection: PrivilegeController())
    try apiProtected.register(collection: ApiAccountController())
}
