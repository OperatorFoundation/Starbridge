import Foundation

import Gardener
import ReplicantSwift
import ShadowSwift

public struct StarbridgeServerConfig: Codable
{
    public var serverAddress: String
    public var serverPrivateKey: String
    public var transport = "starbridge"
    
    public init?(serverAddress: String, serverPrivateKey: String)
    {
        self.serverAddress = serverAddress
        self.serverPrivateKey = serverPrivateKey
    }
    
    public init?(withConfigAtPath path: String)
    {
        guard let config = StarbridgeServerConfig.parseJSON(atPath: path)
        else
        {
            return nil
        }
        
        self = config
    }
    
    /// Creates and returns a JSON representation of the StarbridgeServerConfig struct.
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
            print("Failed to encode Server config into JSON format: \(error)")
            return nil
        }
    }
    
    /// Checks for a valid JSON at the provided path and attempts to decode it into a Starbridge server configuration file. Returns a StarbridgeConfig struct if it is successful
    /// - Parameters:
    ///     - path: The complete path where the config file is located.
    /// - Returns: The StarbridgeServerConfig struct that was decoded from the JSON file located at the provided path, or nil if the file was invalid or missing.
    static public func parseJSON(atPath path: String) -> StarbridgeServerConfig?
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
            let config = try decoder.decode(StarbridgeServerConfig.self, from: jsonData)
            return config
        }
        catch (let error)
        {
            print("\nUnable to decode JSON into StarbridgeServerConfig: \(error)\n")
            return nil
        }
    }

}
