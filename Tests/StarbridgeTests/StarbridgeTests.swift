import XCTest

import Crypto
import KeychainTypes
import Logging

import ReplicantSwift

@testable import Starbridge

final class StarbridgeTests: XCTestCase
{
    //let filePath = NSString(string: "~").expandingTildeInPath
    #if (os(macOS))
    func testStarbridge()
    {
        do
        {
            let serverSendData = "success".data
            let clientSendData = "pass".data
            let (privateKeyString, publicKeyString) = try generateKeys()

            let logger = Logger(label: "Starbridge")
            let starbridgeServer = Starbridge(logger: logger)
            
            let starbridgeServerConfig = try StarbridgeServerConfig(serverAddress: "127.0.0.1:1234", serverPrivateKey: privateKeyString)
            
            let starbridgeListener = try starbridgeServer.listen(config: starbridgeServerConfig)
            
            Task
            {
                let starbridgeServerConnection = try starbridgeListener.accept()
                
                guard let serverReadData = starbridgeServerConnection.read(size: clientSendData.count) else
                {
                    XCTFail()
                    return
                }
                
                guard starbridgeServerConnection.write(data: serverSendData) else
                {
                    XCTFail()
                    return
                }
                
                XCTAssertEqual(serverReadData.string, clientSendData.string)
            }
            
            let starbridgeClient = Starbridge(logger: logger)
            
            let starbridgeClientConfig = try StarbridgeClientConfig(serverAddress: "127.0.0.1:1234", serverPublicKey: publicKeyString)
            
            let starbridgeClientConnection = try starbridgeClient.connect(config: starbridgeClientConfig)
            
            guard starbridgeClientConnection.write(data: clientSendData) else
            {
                XCTFail()
                return
            }
            
            guard let clientReadData = starbridgeClientConnection.read(size: serverSendData.count) else
            {
                XCTFail()
                return
            }
            
            XCTAssertEqual(clientReadData.string, serverSendData.string)
        }
        catch
        {
            XCTFail()
        }
    }
    
    func testAsyncStarbridgeEcho() async
    {
        do
        {
            let starbridgeClientConfigPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("StarbridgeClientConfig.json")
            
            let clientMessage = "pass"
            let logger = Logger(label: "AsyncStarbridge")
            
            let asyncStarbridgeClient = AsyncStarbridge(logger: logger)
            
            guard let starbridgeClientConfig = StarbridgeClientConfig(withConfigAtPath: starbridgeClientConfigPath.path) else
            {
                XCTFail()
                return
            }
            print("Trying to connect using: ")
            print("ServerAddress: \(starbridgeClientConfig.serverAddress)")
            print("TransportName: \(starbridgeClientConfig.transport)")
            
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
    
    func testCreateNewConfigFiles()
    {
        // TODO: Add directory for iOS
        let configDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Configs", isDirectory: true)
        
        XCTAssert(try Starbridge.createNewConfigFiles(inDirectory: configDirectory, serverAddress: "127.0.0.1:1234"))
        
        let serverConfigPath = configDirectory.appendingPathComponent("StarbridgeServerConfig.json", isDirectory: false)
        let clientConfigPath = configDirectory.appendingPathComponent("StarbridgeClientConfig.json", isDirectory: false)
        
        guard StarbridgeServerConfig(withConfigAtPath: serverConfigPath.path) != nil else {
            XCTFail()
            return
        }
        
        guard StarbridgeClientConfig(withConfigAtPath: clientConfigPath.path) != nil else {
            XCTFail()
            return
        }
    }
    
    func testConfigs() throws
    {
        // TODO: Add directory for iOS
        let configDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Configs", isDirectory: true)
        
        if (!FileManager.default.fileExists(atPath: configDirectory.path))
        {
            do
            {
                try FileManager.default.createDirectory(atPath: configDirectory.path, withIntermediateDirectories: true)
            }
            catch
            {
                print("Failed to create the config directory: \(error)")
                XCTFail()
            }
        }
        
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
    #endif
    
    func generateKeys() throws -> (privateKey: PrivateKey, publicKey: PublicKey)
    {
        let privateKey = try PrivateKey(type: .P256KeyAgreement)
        
        return(privateKey, privateKey.publicKey)
    }
}
