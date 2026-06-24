@testable import App
import VaporTesting
import Testing
import Fluent
import FileStorage
import FileStorageDriver
import WhooshingServer

@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Whooshing<Https>, Application) async throws -> ()) async throws {
        let logger = Logger(label: "testing")
        let bootstrap = try await Whooshing<Https>.bootstrap(
            .testing(DebuggingParameters.httpsDebuggingData(dbServiceConfigs: Woo.dbServices)),
            driverKeys: DebuggingParameters.driverKeys,
            logger: logger
        ).get()
        let woo = try await Whooshing.make(bootstrap).get()
        do {
            try await Configuration.https(woo, app: woo.app)
            for db in woo.databases {
                try await Configuration.migrationRegister(in: db, for: [woo])
            }
            try await woo.app.autoMigrate()
            try await test(woo, woo.app)
            try await woo.app.autoRevert()
        } catch {
            try? await woo.app.autoRevert()
            try await woo.asyncShutdown().get()
            throw error
        }
        try await woo.asyncShutdown().get()
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
