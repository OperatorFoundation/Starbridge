//
//  Starbridge.swift
//
//

import Foundation
import Logging

import KeychainTypes
import ReplicantSwift
import TransmissionAsync

public class Starbridge
{
    let logger: Logger
    
    public init(logger: Logger)
    {
        self.logger = logger
    }
    
    public func listen(config: StarbridgeServerConfig) throws -> AsyncListener
    {
        let serverToneburst = Starburst(.SMTPServer)
        let polishConfig = PolishServerConfig(serverAddress: config.serverAddress, serverPrivateKey: config.serverPrivateKey)
        let replicant = Replicant(logger: self.logger, polish: polishConfig, toneburst: serverToneburst)
        return try ReplicantListener(replicant: replicant, serverIP: config.serverIP, serverPort: Int(config.serverPort), logger: self.logger)
    }
    
    public func connect(config: StarbridgeClientConfig) async throws -> AsyncConnection
    {
        let clientToneburst = Starburst(.SMTPClient)
        let polishConfig = PolishClientConfig(serverAddress: config.serverAddress, serverPublicKey: config.serverPublicKey)
        let replicant = Replicant(logger: self.logger, polish: polishConfig, toneburst: clientToneburst)
        let network = try await AsyncTcpSocketConnection(config.serverIP, Int(config.serverPort), logger)
        
        return try await replicant.replicantClientTransformation(connection: network)
    }
}
