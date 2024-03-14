import Foundation

import Gardener
import KeychainTypes
import ReplicantSwift
import ShadowSwift

public struct StarbridgeServerConfig: Codable
{
    public var serverAddress: String
    public let serverIP: String
    public let serverPort: UInt16
    public var serverPrivateKey: PrivateKey
    public var transport = "Starbridge"
    
    enum CodingKeys: CodingKey {
        case serverAddress
        case serverPrivateKey
        case transport
    }
    
    public init(serverAddress: String, serverPrivateKey: PrivateKey) throws
    {
        self.serverAddress = serverAddress
        
        let addressStrings = serverAddress.split(separator: ":")
        self.serverIP = String(addressStrings[0])
        guard let port = UInt16(addressStrings[1]) else
        {
            print("Error decoding StarbridgeServerConfig data: Invalid server port \(addressStrings[1])")
            throw StarbridgeError.invalidServerPort(serverAddress: serverAddress)
        }
        
        self.serverPort = port
        self.serverPrivateKey = serverPrivateKey
    }
    
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
            print("Error decoding a Starbridge Server config file: \(error)")
            
            return nil
        }
    }
    
    public init?(from data: Data)
    {
        let decoder = JSONDecoder()
        do
        {
            let decoded = try decoder.decode(StarbridgeServerConfig.self, from: data)
            
            self = decoded
        }
        catch
        {
            print("Error received while attempting to decode a Starbridge Server config json file: \(error)")
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
            throw StarbridgeError.invalidServerPort(serverAddress: address)
        }
        
        self.serverAddress = address
        self.serverIP = ipAddress
        self.serverPort = port
        self.serverPrivateKey = try container.decode(PrivateKey.self, forKey: .serverPrivateKey)
        self.transport = try container.decode(String.self, forKey: .transport)
    }
    
    /// Creates and returns a JSON representation of the StarbridgeServerConfig struct.
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
