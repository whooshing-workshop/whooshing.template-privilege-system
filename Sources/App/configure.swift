import VaporTube
import PrivilegeSystemDriver

public func configure(_ nexus: Nexus<VaporTube>) async throws {
    try routes(nexus)
}
