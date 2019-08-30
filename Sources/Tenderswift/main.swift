import NIO
import TendermintCore
import Foundation

class PrintHandler: ChannelInboundHandler {
    
    typealias InboundIn = ByteBuffer
    
    func channelRegistered(context: ChannelHandlerContext) {
        print("New inboud PrintHandler channel registered")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var byteBuffer = unwrapInboundIn(data)
        if let message = byteBuffer.readString(length: byteBuffer.readableBytes) {
            print("Received message: \(message)")
        } else {
            print("Error could not read string message from byte buffer")
        }
    }
    
}

extension ByteBuffer {
    
    mutating func readData() -> Data? {
        let count = self.readableBytes
        return self.readBytes(length: count).map { Data(bytes: $0, count: count) }

    }
    
}

class TendermintSocketProtocolHandler: ChannelInboundHandler {
    
    enum State {
        
        case idle
        case waitingForMessageData(remainingLength: UInt64, data: Data)
        
    }
    
    typealias InboundIn = ByteBuffer
    
    private var state: State = .idle
    
    func channelRegistered(context: ChannelHandlerContext) {
        print("New inboud TendermintSocketProtocolHandler channel registered")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var byteBuffer = unwrapInboundIn(data)
        guard byteBuffer.readableBytes > 0 else {
            print("WARN: data read from channel is empty")
            return
        }
        
        switch state {
        case .idle:
            guard let encodedLengthSize = byteBuffer.readInteger(endianness: .big, as: Int.self) else {
                fatalError("byteBuffer is empty but it should not be empty")
            }
            
            guard byteBuffer.readableBytes >= encodedLengthSize else {
                fatalError("Unable to read encoded message length size. ByteBuffer is too small")
            }
         
            if encodedLengthSize > 8 {
                fatalError("Message too long")
            } else {
                guard let bytes = byteBuffer.readBytes(length: encodedLengthSize) else {
                    fatalError("ERROR: Unable to read byte buffer")
                }
                let messageLength = Data(bytes: bytes, count: bytes.count).withUnsafeBytes {
                    $0.load(as: UInt64.self)
                }
                guard let data = byteBuffer.readData() else {
                    fatalError("Unable to read message data")
                }
                
                if data.count < messageLength {
                    state = .waitingForMessageData(remainingLength: messageLength - UInt64(data.count), data: data)
                } else {
                    // TODO desearilize
                }
            }
            
            
        case .waitingForMessageData(let remainingLength, let previousData):
            guard byteBuffer.readableBytes <= remainingLength else {
                fatalError("TODO cannot handle packets with two messages")
            }
            guard let data = byteBuffer.readData() else {
                fatalError("Unable to read message data while waitingForMessageData")
            }
            
            if data.count < remainingLength {
                var accum = Data(capacity: previousData.count + data.count)
                accum.append(previousData)
                accum.append(data)
                state = .waitingForMessageData(remainingLength: remainingLength - UInt64(data.count), data: accum)
            } else {
                // TODO desearilize
            }
        }
    }
    
}

if CommandLine.argc < 2 {
    fatalError("You need to pass a UNIX socket path")
}
let unixSocketPath = CommandLine.arguments[1]

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let serverBootstrap = ServerBootstrap(group: eventLoopGroup)
    .childChannelInitializer { channel in
        channel.pipeline.addHandler(BackPressureHandler(), name: "BackPressureHandler").flatMap { _ in channel.pipeline.addHandler(PrintHandler(), name: "EchoHandler")
        }
    }

do {
    let channel = try serverBootstrap.bind(unixDomainSocketPath: unixSocketPath).wait()
    _ = try channel.closeFuture.wait()
} catch let error {
    print("Error while waiting on socket '\(unixSocketPath)': \(error)")
}

