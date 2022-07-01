//
//  Starbridge.swift
//  
//
//  Created by Joshua Clark on 6/27/22.
//

import Foundation
import Logging

import Simulation
import Spacetime
import TransmissionTypes
import Universe
import ReplicantSwift

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
        self.universe = StarbridgeUniverse(effects: self.simulation.effects, events: self.simulation.events)
    }

    public func listen(config: StarbridgeServerConfig) throws -> TransmissionTypes.Listener
    {
        return try self.universe.starbridgeListen(config: config, logger: self.logger)
    }

    public func connect(config: StarbridgeClientConfig) throws -> TransmissionTypes.Connection
    {
        return try self.universe.starbridgeConnect(config: config, self.logger)
    }
}

