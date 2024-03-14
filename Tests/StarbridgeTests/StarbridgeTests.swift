import XCTest

import Crypto
import KeychainTypes
import Logging

import ReplicantSwift

@testable import Starbridge

final class StarbridgeTests: XCTestCase
{
    let configDirectory = FileManager.default.homeDirectoryForCurrentUser
    
    let starbridgeClientConfigPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("StarbridgeClientConfig.json")
    
    func testAsyncStarbridgeEcho() async
    {
        let clientMessage = "pass"
        let logger = Logger(label: "AsyncStarbridge")
        
        let asyncStarbridgeClient = Starbridge(logger: logger)
        
        guard let starbridgeClientConfig = StarbridgeClientConfig(withConfigAtPath: starbridgeClientConfigPath.path) else
        {
            XCTFail()
            return
        }
        print("Trying to connect using: ")
        print("ServerAddress: \(starbridgeClientConfig.serverAddress)")
        print("TransportName: \(starbridgeClientConfig.transport)")
        
        do
        {
            let asyncStarbridgeClientConnection = try await asyncStarbridgeClient.connect(config: starbridgeClientConfig)
            
            print("AsyncStarbridgeClient connected to server.")
            
            try await asyncStarbridgeClientConnection.write(clientMessage.data)
            
            print("AsyncStarbridgeClient wrote to server.")
            
            let response = try await asyncStarbridgeClientConnection.read()
            print("Server response: \(response.string)")
            
            XCTAssertEqual(clientMessage, response.string)
        }
        catch
        {
            XCTFail()
        }

    }
    
    // TODO: Update after config refactor
    func testConfigs() throws
    {
        let keys = try generateKeys()
        
        let serverConfigPath = configDirectory.appendingPathComponent("StarbridgeServerConfig.json", isDirectory: false)
        let clientConfigPath = configDirectory.appendingPathComponent("StarbridgeClientConfig.json", isDirectory: false)
        
        let serverConfig = try StarbridgeServerConfig(serverAddress: "127.0.0.1:1234", serverPrivateKey: keys.privateKey)
        
        let clientConfig = try StarbridgeClientConfig(serverAddress: "127.0.0.1:1234", serverPublicKey: keys.publicKey)
        
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
    
    func generateKeys() throws -> (privateKey: PrivateKey, publicKey: PublicKey)
    {
        let privateKey = try PrivateKey(type: .P256KeyAgreement)
        
        return(privateKey, privateKey.publicKey)
    }
}
