//
//  Starburst.swift
//
//

import Foundation

import Chord
import Datable
import Ghostwriter
import ReplicantSwift
import TransmissionAsync

public enum StarburstMode: String, Codable
{
    case SMTPClient
    case SMTPServer
    
}

public class Starburst: ToneBurst
{
    let mode: StarburstMode
    
    enum CodingKeys: String, CodingKey
    {
        case mode
    }
    
    public init(_ mode: StarburstMode)
    {
        self.mode = mode
        super.init()
    }
    
    required init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superDecoder = try container.superDecoder()
        
        self.mode = try container.decode(StarburstMode.self, forKey: .mode)
        try super.init(from: superDecoder)
    }

    public override func perform(connection: TransmissionAsync.AsyncConnection) async throws
    {
        let instance = StarburstInstance(self.mode, connection)
        try await instance.perform()
    }
    
    public override func encode(to encoder: any Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.mode, forKey: .mode)
        let superEncoder = container.superEncoder()
        try super.encode(to: superEncoder)
    }
}

public struct StarburstInstance
{
    let connection: TransmissionAsync.AsyncConnection
    let mode: StarburstMode

    public init(_ mode: StarburstMode, _ connection: TransmissionAsync.AsyncConnection)
    {
        self.mode = mode
        self.connection = connection
    }

    public func perform() async throws
    {
        switch mode
        {
            case .SMTPClient:
                try await handleSMTPClient()
            case .SMTPServer:
                try await handleSMTPServer()
            
        }
    }
    
    func listen(structuredText: StructuredText, maxSize: Int = 255) async throws -> MatchResult
    {
        var buffer = Data()
        while buffer.count < maxSize
        {
            let byte = try await connection.readSize(1)

            buffer.append(byte)

            guard let string = String(data: buffer, encoding: .utf8) else
            {
                // This could fail because we're in the middle of a UTF8 rune.
                continue
            }

            let result = structuredText.match(string: string)
            switch result
            {
                case .FAILURE:
                    return result

                case .SHORT:
                    continue

                case .SUCCESS(_):
                    return result
            }
        }
        
        throw StarburstError.maxSizeReached
    }
    
    func speak(structuredText: StructuredText) async throws
    {
        do
        {
            let string = structuredText.string
            try await connection.writeString(string: string)
        }
        catch
        {
            print(error)
            throw StarburstError.writeFailed
        }
    }
    
    private func handleSMTPClient() async throws
    {
        try await Timeout(Duration.seconds(10)).wait
        {
            let _ = try await self.listen(structuredText: StructuredText(TypedText.text("220 "), TypedText.regexp("^([a-zA-Z0-9.-]+)"), TypedText.text(" SMTP service ready"), TypedText.newline(Newline.crlf)))
        }

        try await self.speak(structuredText: StructuredText(TypedText.text("EHLO mail.imc.org"), TypedText.newline(Newline.crlf)))
        try await Timeout(Duration.seconds(10)).wait
        {
            let _ = try await self.listen(structuredText: StructuredText(TypedText.text("250 STARTTLS"), TypedText.newline(Newline.crlf)))
        }

        try await self.speak(structuredText: StructuredText(TypedText.text("STARTTLS"), TypedText.newline(Newline.crlf)))
        try await Timeout(Duration.seconds(10)).wait
        {
            let _ = try await self.listen(structuredText: StructuredText(TypedText.regexp("^(.+)$"), TypedText.newline(Newline.crlf)))
        }

        return
    }

    private func handleSMTPServer() async throws
    {
        try await self.speak(structuredText: StructuredText(TypedText.text("220 mail.imc.org SMTP service ready"), TypedText.newline(Newline.crlf)))
        try await Timeout(Duration.seconds(10)).wait
        {
            let _ = try await self.listen(structuredText: StructuredText(TypedText.text("EHLO "), TypedText.regexp("^([a-zA-Z0-9.-]+)$"), TypedText.newline(Newline.crlf)), maxSize: 253)
        }

        try await self.speak(structuredText: StructuredText(TypedText.text("250-mail.imc.org offers a warm hug of welcome"), TypedText.newline(Newline.crlf), TypedText.text("250-8BITMIME"), TypedText.newline(Newline.crlf), TypedText.text("250-DSN"), TypedText.newline(Newline.crlf), TypedText.text("250 STARTTLS"), TypedText.newline(Newline.crlf)))
        try await Timeout(Duration.seconds(10)).wait
        {
            let _ = try await self.listen(structuredText: StructuredText(TypedText.text("STARTTLS"), TypedText.newline(Newline.crlf)), maxSize: 253)
        }

        try await self.speak(structuredText: StructuredText(TypedText.text("220 Go ahead"), TypedText.newline(Newline.crlf)))
    }

}

public enum StarburstError: Error
{
    case timeout
    case connectionClosed
    case writeFailed
    case readFailed
    case listenFailed
    case speakFailed
    case maxSizeReached
    case unimplemented
}
