//
//  StarbridgeError.swift
//
//
//  Created by Joseph Bragel on 3/20/24.
//

import Foundation

public enum StarbridgeError: Error, CustomStringConvertible
{
    case failedToLaunchServer
    case failedToSaveFile(filePath: String)
    case missingPortInformation(address: String)
    case urlIsNotDirectory(urlPath: String)
    
    public var description: String
    {
        switch self {
            case .failedToLaunchServer:
                "Failed to launch the Starbridge server."
            case .failedToSaveFile(filePath: let filePath):
                "Unable to create a file at the path: \(filePath)"
            case .missingPortInformation(address: let address):
                "Unable to find valid port information in the provided server address: \(address)"
            case .urlIsNotDirectory(urlPath: let urlPath):
                "A directory was needed but the provided path is not a directory: \(urlPath)"
        }
    }
}
