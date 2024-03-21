//
//  StarbridgeConfig.swift
//
//

import Foundation

import KeychainTypes

public class StarbridgeConfig: Codable
{
    public let serverAddress: String
    public let serverIP: String
    public let serverPort: UInt16
    public var transportName = "Starbridge"
    
    internal enum CodingKeys : String, CodingKey
    {
        case serverAddress
        case transportName = "transport"
    }
    
    public init(serverAddress: String) throws
    {
        self.serverAddress = serverAddress
        
        let addressStrings = serverAddress.replacingOccurrences(of: " ", with: "").split(separator: ":")
        self.serverIP = String(addressStrings[0])
        guard let port = UInt16(addressStrings[1]) else
        {
            print("Error decoding StarbridgeServerConfig data: invalid server port \(addressStrings[1])")
            throw StarbridgeError.missingPortInformation(address: serverAddress)
        }
        
        self.serverPort = port
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address = try container.decode(String.self, forKey: .serverAddress)
        let addressStrings = address.replacingOccurrences(of: " ", with: "").split(separator: ":")
        let ipAddress = String(addressStrings[0])
        guard let port = UInt16(addressStrings[1]) else
        {
            print("Error decoding StarbridgeConfig data: invalid server port")
            throw StarbridgeError.missingPortInformation(address: address)
        }
        
        self.serverAddress = address
        self.serverIP = ipAddress
        self.serverPort = port
        self.transportName = try container.decode(String.self, forKey: .transportName)
    }
    
    public func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.serverAddress, forKey: .serverAddress)
        try container.encode(self.transportName, forKey: .transportName)
    }
}

public class StarbridgeServerConfig: StarbridgeConfig, Equatable
{
    public static func == (lhs: StarbridgeServerConfig, rhs: StarbridgeServerConfig) -> Bool
    {
        return lhs.serverPrivateKey == rhs.serverPrivateKey && lhs.serverAddress == rhs.serverAddress
    }
    
    public static let serverConfigFilename = "StarbridgeServerConfig.json"
    public let serverPrivateKey: PrivateKey
    
    private enum CodingKeys : String, CodingKey
    {
        case serverPrivateKey
        case serverAddress
        case transportName = "transport"
    }
    
    public init(serverAddress: String, serverPrivateKey: PrivateKey) throws
    {
        self.serverPrivateKey = serverPrivateKey
        try super.init(serverAddress: serverAddress)
    }
    
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serverAddress = try container.decode(String.self, forKey: .serverAddress)
        self.serverPrivateKey = try container.decode(PrivateKey.self, forKey: .serverPrivateKey)
        try super.init(serverAddress: serverAddress)
    }
    
    public convenience init(from data: Data) throws
    {
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StarbridgeServerConfig.self, from: data)
        try self.init(serverAddress: decoded.serverAddress, serverPrivateKey: decoded.serverPrivateKey)
    }
    
    public convenience init(path: String) throws
    {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        try self.init(from: data)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serverPrivateKey, forKey: .serverPrivateKey)
        try container.encode(serverAddress, forKey: .serverAddress)
        try container.encode(transportName, forKey: .transportName)
    }
}

public class StarbridgeClientConfig: StarbridgeConfig, Equatable
{
    public static func == (lhs: StarbridgeClientConfig, rhs: StarbridgeClientConfig) -> Bool
    {
        return lhs.serverPublicKey == rhs.serverPublicKey && lhs.serverAddress == rhs.serverAddress
    }
    
    public static let clientConfigFilename = "StarbridgeClientConfig.json"
    public let serverPublicKey: PublicKey
    
    private enum CodingKeys : String, CodingKey
    {
        case serverPublicKey
        case serverAddress
        case transportName = "transport"
    }
    
    public init(serverAddress: String, serverPublicKey: PublicKey) throws
    {
        self.serverPublicKey = serverPublicKey
        try super.init(serverAddress: serverAddress)
    }
    
    public convenience init(from data: Data) throws
    {
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StarbridgeClientConfig.self, from: data)
        try self.init(serverAddress: decoded.serverAddress, serverPublicKey: decoded.serverPublicKey)
    }
    
    public convenience init(path: String) throws
    {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        try self.init(from: data)
    }
    
    public required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serverAddress = try container.decode(String.self, forKey: .serverAddress)
        self.serverPublicKey = try container.decode(PublicKey.self, forKey: .serverPublicKey)
        try super.init(serverAddress: serverAddress)
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serverPublicKey, forKey: .serverPublicKey)
        try container.encode(serverAddress, forKey: CodingKeys.serverAddress)
        try container.encode(transportName, forKey: .transportName)
    }
}

public func generateNewConfigPair(serverAddress: String) throws -> (serverConfig: StarbridgeServerConfig, clientConfig: StarbridgeClientConfig)
{
    let privateKey = try PrivateKey(type: .P256KeyAgreement)
    let publicKey = privateKey.publicKey

    let serverConfig = try StarbridgeServerConfig(serverAddress: serverAddress, serverPrivateKey: privateKey)
    let clientConfig = try StarbridgeClientConfig(serverAddress: serverAddress, serverPublicKey: publicKey)
    
    return (serverConfig, clientConfig)
}

public func createNewConfigFiles(inDirectory saveDirectory: URL, serverAddress: String) throws
{
    guard saveDirectory.hasDirectoryPath else
    {
        throw StarbridgeError.urlIsNotDirectory(urlPath: saveDirectory.path)
    }

    let configPair = try generateNewConfigPair(serverAddress: serverAddress)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    
    let serverJson = try encoder.encode(configPair.serverConfig)
    let serverConfigFilePath = saveDirectory.appendingPathComponent(StarbridgeServerConfig.serverConfigFilename).path
    
    guard FileManager.default.createFile(atPath: serverConfigFilePath, contents: serverJson) else
    {
        throw StarbridgeError.failedToSaveFile(filePath: serverConfigFilePath)
    }

    let clientJson = try encoder.encode(configPair.clientConfig)
    let clientConfigFilePath = saveDirectory.appendingPathComponent(StarbridgeClientConfig.clientConfigFilename).path

    guard FileManager.default.createFile(atPath: clientConfigFilePath, contents: clientJson) else
    {
        throw StarbridgeError.failedToSaveFile(filePath: clientConfigFilePath)
    }
}
