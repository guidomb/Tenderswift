import NIO
import TendermintCore
import Foundation
import SwiftProtobuf

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
    
    mutating func readData(into data: inout Data) -> Bool {
        guard let bytes = self.readBytes(length: self.readableBytes) else {
            return false
        }
        
        data.append(contentsOf: bytes)
        return true
    }
    
    mutating func readData(length: Int) -> Data? {
        if length < self.readableBytes {
            return self.readBytes(length: length)
                .map { Data(bytes: $0, count: length) }
        } else {
            return self.readData()
        }
    }
    
    mutating func readVarint() -> Int? {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        let initialReadIndex = self.readerIndex

        while true {
            guard let c: UInt8 = self.readInteger() else {
                // ran out of bytes. Reset the read pointer and return nil.
                self.moveReaderIndex(to: initialReadIndex)
                return nil
            }

            value |= UInt64(c & 0x7F) << shift
            if c & 0x80 == 0 {
                return Int(value)
            }
            shift += 7
            if shift > 63 {
                fatalError("Invalid varint, requires shift (\(shift)) > 64")
            }
        }
    }
    
}

class TendermintSocketProtocolHandler: ChannelInboundHandler {
    
    typealias InboundIn = ByteBuffer
    
    private var messageDataBuffer = Data()
    
    func channelRegistered(context: ChannelHandlerContext) {
        print("New inboud TendermintSocketProtocolHandler channel registered")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var byteBuffer = unwrapInboundIn(data)
        guard byteBuffer.readableBytes > 0 else {
            print("WARN: data read from channel is empty")
            return
        }
        
        
        guard let messageSize = byteBuffer.readVarint() else {
            print("Ignoring inbound read. Message size could not be read.")
            return
        }
        print("Message size: \(messageSize)")
        print("Byte buffer size: \(byteBuffer.readableBytes)")
        print("Message data buffer size: \(messageDataBuffer.count)")
        
        guard byteBuffer.readData(into: &messageDataBuffer) else {
            print("Ignoring inbound read. Message data could not be read.")
            return
        }
        
        guard messageDataBuffer.count > messageSize else {
            let remainingBytes = messageSize - messageDataBuffer.count
            print("Request data appended. \(remainingBytes) remaining bytes.")
            return
        }
        
        do {
            let request = try Request(serializedData: messageDataBuffer)
            handleRequest(request)
        } catch let error {
            print("Error - Request data could not parsed. \(error)")
        }
        
        messageDataBuffer = Data(capacity: byteBuffer.readableBytes)
        if byteBuffer.readableBytes > 0 && !byteBuffer.readData(into: &messageDataBuffer) {
            print("Error - Remaining data could not be read")
        }
    }
        
}


func handleRequest(_ request: Request) {
    guard let value = request.value else {
        print("Ignoring inbound request. Request has no value.")
        return
    }
    
    print("Handling request \(request)")
    switch value {
    case .echo(_):
        return
    case .flush(_):
        return
    case .info(_):
        return
    case .setOption(_):
        return
    case .initChain(_):
        return
    case .query(_):
        return
    case .beginBlock(_):
        return
    case .checkTx(_):
        return
    case .deliverTx(_):
        return
    case .endBlock(_):
        return
    case .commit(_):
        return
    }
}




if CommandLine.argc < 2 {
    fatalError("You need to pass a UNIX socket path")
}
let unixSocketPath = CommandLine.arguments[1]

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
let serverBootstrap = ServerBootstrap(group: eventLoopGroup)
    .childChannelInitializer { channel in
        channel.pipeline.addHandler(BackPressureHandler(), name: "BackPressureHandler").flatMap { _ in channel.pipeline.addHandler(TendermintSocketProtocolHandler(), name: "TendermintSocketProtocolHandler")
        }
    }

do {
    let channel = try serverBootstrap.bind(unixDomainSocketPath: unixSocketPath).wait()
    _ = try channel.closeFuture.wait()
} catch let error {
    print("Error while waiting on socket '\(unixSocketPath)': \(error)")
}
