@testable import App
import VaporTesting
import Testing
import Fluent
import FileStorage
import FileStorageDriver
import VaporTube

@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Nexus<VaporTube>) async throws -> ()) async throws {
        let logger = Logger(label: "testing")
        
        let bootstrap = try await Bootstrap.run(
            .testing(DebuggingParameters.configData(dbServiceConfigs: Woo.dbServices)),
            driverKeys: Woo.driverKeys,
            logger: logger
        ).get()
        
        let tube = try await VaporTube.make(bootstrap).get()
        let nexus = Nexus(tube: tube, bootstrap: bootstrap)
        do {
            try await configure(nexus)
            try await nexus.tube.app.autoMigrate()
            try await test(nexus)
            try await nexus.tube.app.autoRevert()
        } catch {
            try? await nexus.tube.app.autoRevert()
            try await nexus.asyncShutdown()
            throw error
        }
        try await nexus.asyncShutdown()
    }
}

extension Data {
    static func random(size: Int) -> Data {
        guard size > 0 else { return Data() }
        var data = Data(count: size)
        var rng = SystemRandomNumberGenerator()
        data.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
            for i in 0..<size {
                buffer[i] = UInt8.random(in: 0...255, using: &rng)
            }
        }
        return data
    }
}
