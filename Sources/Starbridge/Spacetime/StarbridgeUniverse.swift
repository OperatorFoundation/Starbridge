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
        return try ReplicantUniverseListener(universe: self, address: config.serverIP, port: Int(config.port), config: config.replicantConfig, logger: logger)
    }

    public func starbridgeConnect(config: StarbridgeClientConfig, _ logger: Logger) throws -> TransmissionTypes.Connection
    {
        let network = try super.connect(config.replicantConfig.serverIP, Int(config.replicantConfig.port))

        guard let connection = network as? ConnectConnection else
        {
            throw StarbridgeUniverseError.wrongConnectionType
        }

        return try connection.replicantClientTransformation(config.replicantConfig, logger)
    }
}

public enum StarbridgeUniverseError: Error
{
    case wrongConnectionType
}
