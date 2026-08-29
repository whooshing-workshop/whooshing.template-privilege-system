import VaporTube
import PrivilegeSystemDriver

public func configure(_ nexus: Nexus<VaporTube>) async throws {
    nexus.tube.app.asyncCommands.use(CreateAdminCommand(), as: "create-admin")
    try routes(nexus)
}
