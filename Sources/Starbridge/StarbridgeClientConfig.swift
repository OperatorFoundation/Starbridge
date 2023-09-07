//
//  File.swift
//  
//
//  Created by Joshua Clark on 6/28/22.
//

import Foundation

import Datable
import Gardener
import KeychainTypes
import ReplicantSwift
import ShadowSwift
import Song

public struct StarbridgeClientConfig: Codable
{
    public var serverAddress: String
    public let serverIP: String
    public let serverPort: UInt16
    public var serverPublicKey: PublicKey
    public var transport = "Starbridge"
    
    public init(serverAddress: String, serverPublicKey: PublicKey) throws
    {
        self.serverAddress = serverAddress
        
        let addressStrings = serverAddress.split(separator: ":")
        let ipAddress = String(addressStrings[0])
        guard let port = UInt16(addressStrings[1]) else
        {
            print("Error decoding StarbridgeClientConfig data: Invalid server port.")
            throw StarbridgeUniverseError.invalidServerPort(serverAddress: serverAddress)
        }
        
        self.serverIP = ipAddress
        self.serverPort = port
        self.serverPublicKey = serverPublicKey
    }
    
    /// Initializes StarbridgeClientConfig with the JSON file located at path. Returns nil if the file is not a valid JSON Starbridge config, or if the file does not exist.
    /// - Parameters:
    ///     - path: The complete path where the config file is located.
    public init?(withConfigAtPath path: String)
    {
        guard let config = StarbridgeClientConfig.parseJSON(atPath: path)
        else
        {
            return nil
        }
        
        self = config
    }
    
    /// Creates and returns a JSON representation of the StarbridgeClientConfig struct.
    public func createJSON() -> Data?
    {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do
        {
            let serverConfigData = try encoder.encode(self)
            return serverConfigData
        }
        catch (let error)
        {
            print("Failed to encode Client config into JSON format: \(error)")
            return nil
        }
    }
    
    /// Checks for a valid JSON at the provided path and attempts to decode it into a Starbridge server configuration file. Returns a StarbridgeConfig struct if it is successful
    /// - Parameters:
    ///     - path: The complete path where the config file is located.
    /// - Returns: The StarbridgeClientConfig struct that was decoded from the JSON file located at the provided path, or nil if the file was invalid or missing.
    static public func parseJSON(atPath path: String) -> StarbridgeClientConfig?
    {
        let decoder = JSONDecoder()
        
        guard let jsonData = File.get(path)
        else
        {
            print("\nUnable to get JSON data at path: \(path)\n")
            return nil
        }
        
        do
        {
            let config = try decoder.decode(StarbridgeClientConfig.self, from: jsonData)
            return config
        }
        catch (let error)
        {
            print("\nUnable to decode JSON into StarbridgeServerConfig: \(error)\n")
            return nil
        }
    }
}
