import NIO
import TendermintCore

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

