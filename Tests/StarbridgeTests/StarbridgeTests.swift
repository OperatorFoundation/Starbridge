import XCTest
@testable import Starbridge

final class StarbridgeTests: XCTestCase {
    func testConfigs() throws {
        let configDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Configs", isDirectory: true)
        let serverConfigPath = configDirectory.appendingPathComponent("StarbridgeServerConfig.json", isDirectory: false)
        let clientConfigPath = configDirectory.appendingPathComponent("StarbridgeClientConfig.json", isDirectory: false)
        
        guard let serverConfig = StarbridgeServerConfig(serverPersistentPrivateKey: "dd5e9e88d13e66017eb2087b128c1009539d446208f86173e30409a898ada148", serverIP: "127.0.0.1", port: 1234) else {
            XCTFail()
            return
        }
        
        guard let clientConfig = StarbridgeClientConfig(serverPersistantPublicKey: "d089c225ef8cda8d477a586f062b31a756270124d94944e458edf1a9e1e41ed6", serverIP: "127.0.0.1", port: 1234) else {
            XCTFail()
            return
        }
        
        guard let serverConfigData = serverConfig.createJSON() else {
            XCTFail()
            return
        }
        
        guard let clientConfigData = clientConfig.createJSON() else {
            XCTFail()
            return
        }
        
        do {
            try serverConfigData.write(to: serverConfigPath)
            try clientConfigData.write(to: clientConfigPath)
        } catch {
            XCTFail()
        }
        
        guard let parsedServerConfig = StarbridgeServerConfig(withConfigAtPath: serverConfigPath.path) else {
            XCTFail()
            return
        }
        
        guard let parsedClientConfig = StarbridgeClientConfig(withConfigAtPath: clientConfigPath.path) else {
            XCTFail()
            return
        }
        
        guard let parsedServerConfigData = parsedServerConfig.createJSON() else {
            XCTFail()
            return
        }
        
        guard let parsedClientConfigData = parsedClientConfig.createJSON() else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(serverConfigData, parsedServerConfigData)
        XCTAssertEqual(clientConfigData, parsedClientConfigData)
    }
}
