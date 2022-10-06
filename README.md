# Operator Foundation

[Operator](https://operatorfoundation.org) makes usable tools to help people around the world with censorship, security, and privacy.

# Starbridge

Starbridge is a Pluggable Transport that requires only minimal configuration information from the user. Under the hood, it uses the [Replicant](https://github.com/OperatorFoundation/ReplicantSwift) Pluggable Transport technology for network protocol obfuscation. Replicant is more complex to configure, so Starbridge is a good starting point for those wanting to use the technology to circumvent Internet cenorship, but wanting a minimal amount of setup.

## Shapeshifter

The Shapeshifter project provides network protocol shapeshifting technology
(also sometimes referred to as obfuscation). The purpose of this technology is
to change the characteristics of network traffic so that it is not identified
and subsequently blocked by network filtering devices.

There are two components to Shapeshifter: transports and the dispatcher. Each
transport provide different approach to shapeshifting. ReplicantSwift is provided as a 
Swift library which can be integrated directly into applications.

If you are a tool developer working in the Swift programming language, then you
are in the right place. If you are a tool developer working in other languages we have 
several other tools available to you:

- A Go transports library that can be used directly in your application:
[shapeshifter-transports](https://github.com/OperatorFoundation/shapeshifter-transports)

- A Kotlin transports library that can be used directly in your Android application (currently supports Shadow):
[ShapeshifterAndroidKotlin](https://github.com/OperatorFoundation/ShapeshifterAndroidKotlin)

- A Java transports library that can be used directly in your Android application (currently supports Shadow):
[ShapeshifterAndroidJava](https://github.com/OperatorFoundation/ShapeshifterAndroidJava)

If you want a end user that is trying to circumvent filtering on your network or
you are a developer that wants to add pluggable transports to an existing tool
that is not written in the Swift programming language, then you probably want the
dispatcher. Please note that familiarity with executing programs on the command
line is necessary to use this tool.
<https://github.com/OperatorFoundation/shapeshifter-dispatcher>

If you are looking for a complete, easy-to-use VPN that incorporates
shapeshifting technology and has a graphical user interface, consider
[Moonbounce](https://github.com/OperatorFoundation/Moonbounce), an application for macOS which incorporates shapeshifting without
the need to write code or use the command line.

### Shapeshifter Transports

Shapeshifter Transports is a suite of pluggable transports implemented in a variety of langauges. This repository 
is an implementation of the Replicant transport in the Swift programming language. 

If you are looking for a tool which you can install and
use from the command line, take a look at [shapeshifter-dispatcher](https://github.com/OperatorFoundation/shapeshifter-dispatcher.git) instead.

Starbridge implements the Pluggable Transports 3.0 specification available here:
<https://github.com/Pluggable-Transports/Pluggable-Transports-spec/tree/main/releases/PTSpecV3.0> Specifically,
they implement the [Swift Transports API v3.0](https://github.com/Pluggable-Transports/Pluggable-Transports-spec/blob/main/releases/PTSpecV3.0/Pluggable%20Transport%20Specification%20v3.0%20-%20Swift%20Transport%20API%20v3.0.md).

The purpose of the transport library is to provide a set of different
transports. Each transport implements a different method of shapeshifting
network traffic. The goal is for application traffic to be sent over the network
in a shapeshifted form that bypasses network filtering, allowing
the application to work on networks where it would otherwise be blocked or
heavily throttled.

## Prerequisites

Starbridge uses the Swift programming language minimum version 5.6. If you are using a Linux system follow the instructions on swift.org to install Swift. If you are using macOS we recommend that you install Xcode.

## Using the Library

### Add the dependency to your project

This can be done through the Xcode GUI or by updating your Package.swift file
```
dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/OperatorFoundation/Starbridge", branch: "main"),
    ],
```

```
targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MyApp",
            dependencies: [
                "Starbridge",
            ]),
        .testTarget(
            name: "MyAppTests",
            dependencies: ["MyApp"]),
    ],
```

### Server:

1. Create a server instance of Starbridge with a Starburst server config.
```
    let logger = Logging.Logger(label: "Starbridge")
    let starburstServerConfig = StarburstConfig.SMTPServer
    let starbridgeServer = Starbridge(logger: logger, config: starburstServerConfig)
```

2. Create a StarbridgeServerConfig.
```
    guard let starbridgeServerConfig = StarbridgeServerConfig(serverPersistentPrivateKey: privateKeyHex, serverIP: "127.0.0.1", port: 1234) else
    {
      // handle error
      return
    }
```

3. Create a listener with the StarbridgeServerConfig.
```
    do
    {
      let starbridgeListener = try starbridgeServer.listen(config: starbridgeServerConfig)
    } 
    catch
    {
      // handle error
    }
```

4. Call accept() on the listener.
```
    Task
    {
      do 
      {
        let starbridgeServerConnection = try starbridgeListener.accept()
        ...
      }
      catch
      {
        // handle error
      }
    }
```

5. Call .read() and .write() on starbridgeServerConnection inside the Task block.

### Client:

1. Create a client instance of Starbridge with a Starburst client config.
```
    let starburstClientConfig = StarburstConfig.SMTPClient
    let starbridgeClient = Starbridge(logger: logger, config: starburstClientConfig)
```

2. Create a StarbridgeClientConfig.
```
    guard let starbridgeClientConfig = StarbridgeClientConfig(serverPersistantPublicKey: publicKeyHex, serverIP: "127.0.0.1", port: 1234) else
    {
        // handle error
        return
    }
```

3. Create a client connection with the StarbridgeClientConfig.
```
    do
    {
      let starbridgeClientConnection = try starbridgeClient.connect(config: starbridgeClientConfig)
    }
    catch
    {
      // handle error
    }
```

4. Call .read() and .write() on starbridgeClientConnection.

### Config Files

To generate and save a server and client config pair to your project's directory:

```
	let success = Starbridge.createNewConfigFiles(inDirectory: <URL>, serverIP: "127.0.0.1", serverPort: 1234)
```

### Credits
* Shadowsocks was developed by the Shadowsocks team. [whitepaper](https://shadowsocks.org/assets/whitepaper.pdf)
