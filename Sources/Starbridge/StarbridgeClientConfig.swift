//
//  File.swift
//  
//
//  Created by Joshua Clark on 6/28/22.
//

import Foundation

import ReplicantSwift
import ShadowSwift
import Song

public struct StarbridgeClientConfig: Codable
{
    public let replicantConfig: ReplicantClientConfig
    
    public init?(serverPersistantPublicKey: String, serverIP: String, port: UInt16)
    {
        let shadowConfig = ShadowConfig(key: serverPersistantPublicKey, serverIP: serverIP, port: port, mode: .DARKSTAR)
        let polish = PolishClientConfig.darkStar(shadowConfig)
        let starburstConfig = StarburstConfig.SMTPClient
        let toneburst = ToneBurstClientConfig.starburst(config: starburstConfig)
        let replicantConfig = ReplicantClientConfig(serverIP: serverIP, port: port, polish: polish, toneBurst: toneburst)
        self.replicantConfig = replicantConfig
    }
    
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
        let filemanager = FileManager()
        let decoder = JSONDecoder()
        
        guard let jsonData = filemanager.contents(atPath: path)
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
