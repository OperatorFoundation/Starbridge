//
//  StarbridgeUniverse.swift
//  
//
//  Created by Joshua Clark on 6/27/22.
//

import Foundation
import Logging

import Datable
import ReplicantSwift
import Spacetime
import TransmissionTypes
import Universe

public class StarbridgeUniverse: Universe
{
    public func starbridgeListen(config: StarbridgeServerConfig, logger: Logger) throws -> UniverseListener
    {
        let starburstServer = Starburst(.SMTPServer)
        let polishServerConfig = PolishServerConfig(serverAddress: config.serverAddress, serverPrivateKey: config.serverPrivateKey)
        let replicantConfig = ReplicantServerConfig(serverAddress: config.serverAddress, polish: polishServerConfig, toneBurst: starburstServer, transport: "Replicant")
        return try ReplicantUniverseListener(universe: self, address: config.serverIP, port: Int(config.serverPort), config: replicantConfig, logger: logger)
    }

    public func starbridgeConnect(config: StarbridgeClientConfig, _ logger: Logger) throws -> TransmissionTypes.Connection
    {
        let starburstClient = Starburst(.SMTPClient)
        let polishClientConfig = PolishClientConfig(serverAddress: config.serverAddress, serverPublicKey: config.serverPublicKey)
        guard let replicantConfig = ReplicantClientConfig(serverAddress: config.serverAddress, polish: polishClientConfig, toneBurst: starburstClient, transport: "Replicant") else {
            throw StarbridgeUniverseError.badConfig
        }
        let network = try super.connect(config.serverIP, Int(config.serverPort))

        guard let connection = network as? ConnectConnection else
        {
            throw StarbridgeUniverseError.wrongConnectionType
        }

        return try connection.replicantClientTransformation(replicantConfig, logger)
    }
}

public enum StarbridgeUniverseError: Error
{
    case wrongConnectionType
    case badConfig
    case invalidServerPort(serverAddress: String)
    
    public var description: String
    {
        switch self
        {
        case .wrongConnectionType:
            return "Wrong connection type."
        case .badConfig:
            return "Invalid config."
        case .invalidServerPort(let serverAddress):
            return "Error decoding Starbride config data: Invalid server port from address: \(serverAddress)"
        }
    }
}
