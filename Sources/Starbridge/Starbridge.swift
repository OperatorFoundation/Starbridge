//
//  AsyncDarkstar.swift
//  
//
//  Created by Mafalda on 3/4/24.
//

import Foundation


import Crypto
import Foundation
import Logging

import Gardener
import KeychainTypes
import ReplicantSwift
import TransmissionAsync

public class Starbridge
{
    let logger: Logger

    public init(logger: Logger)
    {
        self.logger = logger
    }

    public func listen(config: StarbridgeServerConfig) throws -> AsyncListener
    {
        let serverToneburst = Starburst(.SMTPServer)
        let polishServerConfig = PolishServerConfig(serverAddress: config.serverAddress, serverPrivateKey: config.serverPrivateKey)
        let replicant = Replicant(logger: self.logger, polish: polishServerConfig, toneburst: serverToneburst)
        return try ReplicantListener(replicant: replicant, serverIP: config.serverIP, serverPort: Int(config.serverPort), logger: self.logger)
    }

    public func connect(config: StarbridgeClientConfig) async throws -> AsyncConnection
    {
        let clientToneburst = Starburst(.SMTPClient)
        let polishClientConfig = PolishClientConfig(serverAddress: config.serverAddress, serverPublicKey: config.serverPublicKey)
        let replicant = Replicant(logger: self.logger, polish: polishClientConfig, toneburst: clientToneburst)
        let network = try await AsyncTcpSocketConnection(config.serverIP, Int(config.serverPort), logger)

        return try await replicant.replicantClientTransformation(connection: network)
    }
    
    /// Creates  a randomly generated P-256 and returns the hex format of their respective raw (data) representations. This is a format suitable for JSON config files.
    /// - Returns: A private key and its corresponding public key as hex strings.
    public static func generateKeys() throws -> (privateKey: PrivateKey, publicKey: PublicKey)
    {
        let privateKey = try PrivateKey(type: .P256KeyAgreement)
        
        return(privateKey, privateKey.publicKey)
    }
    
    /// Creates and returns a Starbridge config file pair with a randomly generated key pair and the specified server attributes.
    /// - Parameters:
    ///     - serverIP: String The IP address of the Starbridge server
    ///     - serverPort: UInt16 The port the Starbridge server will listen on
    /// - Returns: A StarbridgeServerConfig and a StarbridgeClientConfig if the operation was successful, otherwise nil.
    public static func generateNewConfigPair(serverAddress: String) throws -> (serverConfig: StarbridgeServerConfig, clientConfig: StarbridgeClientConfig)
    {
        let keys = try generateKeys()
        let serverConfig = try StarbridgeServerConfig(serverAddress: serverAddress, serverPrivateKey: keys.privateKey)
        let clientConfig = try StarbridgeClientConfig(serverAddress: serverAddress, serverPublicKey: keys.publicKey)
        
        return (serverConfig, clientConfig)
    }
    
    /// Creates a Starbridge config file pair with a randomly generated key pair and the specified server attributes at the given location.
    /// - Parameters:
    ///     - saveDirectory: URL  The directory where the new config files should be saved.
    ///     - serverIP: String The IP address of the Starbridge server
    ///     - serverPort: UInt16 The port the Starbridge server will listen on
    /// - Returns: true if the operation was successful, otherwise false.
    public static func createNewConfigFiles(inDirectory saveDirectory: URL, serverAddress: String) throws -> Bool
    {
        guard saveDirectory.isDirectory else
        {
            print("The provided destination is not a directory: \(saveDirectory.path)")
            return false
        }
        
        do
        {
            let newConfigs = try generateNewConfigPair(serverAddress: serverAddress)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
            
            let serverJson = try encoder.encode(newConfigs.serverConfig)
            let serverConfigFilename = "StarbridgeServerConfig.json"
            let serverConfigFilePath = saveDirectory.appendingPathComponent(serverConfigFilename).path
            
            guard File.put(serverConfigFilePath, contents: serverJson) else
            {
                return false
            }
            
            let clientJson = try encoder.encode(newConfigs.clientConfig)
            let clientConfigFilename = "StarbridgeClientConfig.json"
            let clientConfigFilePath = saveDirectory.appendingPathComponent(clientConfigFilename).path
            
            guard File.put(clientConfigFilePath, contents: clientJson) else
            {
                return false
            }
            
            return true
        }
        catch
        {
            print("Failed to save a new Starbridge config pair. Error: \(error)")
            return false
        }
    }
}
