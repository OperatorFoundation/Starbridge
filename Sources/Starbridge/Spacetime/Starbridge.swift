//
//  Starbridge.swift
//  
//
//  Created by Joshua Clark on 6/27/22.
//

import Crypto
import Foundation
#if os(macOS)
import os.log
#else
import Logging
#endif

import Gardener
import KeychainTypes
import ReplicantSwift
import Simulation
import Spacetime
import TransmissionTypes
import Universe

public class Starbridge
{
    var logger: Logger
    let simulation: Simulation
    let universe: StarbridgeUniverse

    public init(logger: Logger, config: StarburstConfig)
    {
        self.logger = logger
        let sim = Simulation(capabilities: Capabilities(.display, .random, .networkConnect, .networkListen))
        self.simulation = sim
        self.universe = StarbridgeUniverse(effects: self.simulation.effects, events: self.simulation.events, logger: logger)
    }

    public func listen(config: StarbridgeServerConfig) throws -> TransmissionTypes.Listener
    {
        return try self.universe.starbridgeListen(config: config, logger: self.logger)
    }

    public func connect(config: StarbridgeClientConfig) throws -> TransmissionTypes.Connection
    {
        return try self.universe.starbridgeConnect(config: config, self.logger)
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
    public static func generateNewConfigPair(serverAddress: String) -> (serverConfig: StarbridgeServerConfig, clientConfig: StarbridgeClientConfig)?
    {
        guard let keys = try? generateKeys() else
        {
            return nil
        }
        
        guard let serverConfig = StarbridgeServerConfig(serverAddress: serverAddress, serverPrivateKey: keys.privateKey) else
        {
            print("Failed to create a StarbridgeServerConfig")
            return nil
        }
        
        guard let clientConfig = StarbridgeClientConfig(serverAddress: serverAddress, serverPublicKey: keys.publicKey) else
        {
            print("Failed to create a StarbridgeClientConfig")
            return nil
        }
        
        return (serverConfig, clientConfig)
    }
    
    /// Creates a Starbridge config file pair with a randomly generated key pair and the specified server attributes at the given location.
    /// - Parameters:
    ///     - saveDirectory: URL  The directory where the new config files should be saved.
    ///     - serverIP: String The IP address of the Starbridge server
    ///     - serverPort: UInt16 The port the Starbridge server will listen on
    /// - Returns: true if the operation was successful, otherwise false.
    public static func createNewConfigFiles(inDirectory saveDirectory: URL, serverAddress: String)  -> Bool
    {
        guard saveDirectory.isDirectory else
        {
            print("The provided destination is not a directory: \(saveDirectory.path)")
            return false
        }
        
        guard let newConfigs = generateNewConfigPair(serverAddress: serverAddress) else
        {
            return false
        }
        
        let encoder = JSONEncoder()
        
        do
        {
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

