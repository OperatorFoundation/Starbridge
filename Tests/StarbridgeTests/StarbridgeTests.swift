import XCTest

import Crypto
import KeychainTypes
#if os(macOS)
import os.log
#else
import Logging
#endif
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

            #if os(macOS)
            let logger = Logger(subsystem: "Starbridge", category: "Tests")
            #else
            let logger = Logger(label: "Starbridge")
            #endif
            let starbridgeServer = Starbridge(logger: logger)
            
            guard let starbridgeServerConfig = StarbridgeServerConfig(serverAddress: "127.0.0.1:1234", serverPrivateKey: privateKeyString) else
            {
                XCTFail()
                return
            }
            
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
            
            guard let starbridgeClientConfig = StarbridgeClientConfig(serverAddress: "127.0.0.1:1234", serverPublicKey: publicKeyString) else
            {
                XCTFail()
                return
            }
            
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
    
    func testCreateNewConfigFiles()
    {
        // TODO: Add directory for iOS
        let configDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Configs", isDirectory: true)
        
        XCTAssert(Starbridge.createNewConfigFiles(inDirectory: configDirectory, serverAddress: "127.0.0.1:1234"))
        
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
        
        guard let serverConfig = StarbridgeServerConfig(serverAddress: "127.0.0.1:1234", serverPrivateKey: keys.privateKey) else {
            XCTFail()
            return
        }
        
        guard let clientConfig = StarbridgeClientConfig(serverAddress: "127.0.0.1:1234", serverPublicKey: keys.publicKey) else {
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
    #endif
    
    func generateKeys() throws -> (privateKey: PrivateKey, publicKey: PublicKey)
    {
        let privateKey = try PrivateKey(type: .P256KeyAgreement)
        
        return(privateKey, privateKey.publicKey)
    }
}
