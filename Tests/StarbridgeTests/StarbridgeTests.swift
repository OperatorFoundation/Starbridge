import XCTest

import Crypto

@testable import Starbridge

final class StarbridgeTests: XCTestCase
{
    func testConfigs() throws
    {
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
        
        let keys = generateKeys()
        
        let serverConfigPath = configDirectory.appendingPathComponent("StarbridgeServerConfig.json", isDirectory: false)
        let clientConfigPath = configDirectory.appendingPathComponent("StarbridgeClientConfig.json", isDirectory: false)
        
        guard let serverConfig = StarbridgeServerConfig(serverPersistentPrivateKey: keys.privateKey, serverIP: "127.0.0.1", port: 1234) else {
            XCTFail()
            return
        }
        
        guard let clientConfig = StarbridgeClientConfig(serverPersistantPublicKey: keys.publicKey, serverIP: "127.0.0.1", port: 1234) else {
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
    
    func generateKeys() -> (privateKey: String, publicKey: String)
    {
        let privateKey = P256.KeyAgreement.PrivateKey()
        let privateKeyData = privateKey.rawRepresentation
        let privateKeyHex = privateKeyData.hex

        let publicKey = privateKey.publicKey
        let publicKeyData = publicKey.compactRepresentation
        let publicKeyHex = publicKeyData!.hex

        print("Private key: \(privateKeyHex)")
        print("Public key: \(publicKeyHex)")
        
        return(privateKeyHex, publicKeyHex)
    }
}
