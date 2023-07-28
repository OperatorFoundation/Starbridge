//
//  StarbridgeUniverse.swift
//  
//
//  Created by Joshua Clark on 6/27/22.
//

import Foundation
#if os(macOS)
import os.log
#else
import Logging
#endif

import Datable
import ReplicantSwift
import Spacetime
import TransmissionTypes
import Universe

public class StarbridgeUniverse: Universe
{
    public func starbridgeListen(config: StarbridgeServerConfig, logger: Logger) throws -> UniverseListener
    {
        let addressArray = config.serverAddress.split(separator: ":")
        let host = String(addressArray[0])
        let port = Int(addressArray[1])
        let starburstServer = Starburst(.SMTPServer)
        let polishServerConfig = PolishServerConfig(serverAddress: config.serverAddress, serverPrivateKey: config.serverPrivateKey)
        let replicantConfig = ReplicantServerConfig(serverAddress: config.serverAddress, polish: polishServerConfig, toneBurst: starburstServer, transport: "Replicant")
        return try ReplicantUniverseListener(universe: self, address: host, port: port!, config: replicantConfig, logger: logger)
    }

    public func starbridgeConnect(config: StarbridgeClientConfig, _ logger: Logger) throws -> TransmissionTypes.Connection
    {
        let addressArray = config.serverAddress.split(separator: ":")
        let host = String(addressArray[0])
        let port = Int(addressArray[1])
        let starburstClient = Starburst(.SMTPClient)
        let polishClientConfig = PolishClientConfig(serverAddress: config.serverAddress, serverPublicKey: config.serverPublicKey)
        guard let replicantConfig = ReplicantClientConfig(serverAddress: config.serverAddress, polish: polishClientConfig, toneBurst: starburstClient, transport: "Replicant") else {
            throw StarbridgeUniverseError.badConfig
        }
        let network = try super.connect(host, port!)

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
}
