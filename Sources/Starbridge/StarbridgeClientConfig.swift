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
    
    enum CodingKeys: CodingKey {
        case serverAddress
        case serverPublicKey
        case transport
    }
    
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
        let url = URL(fileURLWithPath: path)
        
        do
        {
            let data = try Data(contentsOf: url)
            self.init(from: data)
        }
        catch
        {
            print("Error decoding a Starbridge Client config file: \(error)")
            
            return nil
        }
    }
    
    public init?(from data: Data)
    {
        let decoder = JSONDecoder()
        do
        {
            let decoded = try decoder.decode(StarbridgeClientConfig.self, from: data)
            
            self = decoded
        }
        catch
        {
            print("Error received while attempting to decode a Starbridge Client config json file: \(error)")
            return nil
        }
    }
    
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(String.self, forKey: .serverAddress)
        let addressStrings = address.split(separator: ":")
        let ipAddress = String(addressStrings[0])
        guard let port = UInt16(addressStrings[1]) else
        {
            print("Error decoding StarbridgeServerConfig data: invalid server port")
            throw StarbridgeUniverseError.invalidServerPort(serverAddress: address)
        }
        
        self.serverAddress = address
        self.serverIP = ipAddress
        self.serverPort = port
        self.serverPublicKey = try container.decode(PublicKey.self, forKey: .serverPublicKey)
        self.transport = try container.decode(String.self, forKey: .transport)
    }
    
    /// Creates and returns a JSON representation of the StarbridgeClientConfig struct.
    public func createJSON() -> Data?
    {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        
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
