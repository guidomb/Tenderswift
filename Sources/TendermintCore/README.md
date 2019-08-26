# TendermintCore

This is a hack to get Tendermint protocol buffer [types](https://github.com/tendermint/tendermint/blob/master/abci/types/types.proto) compile using [SwiftProtobuf](https://github.com/apple/swift-protobuf).

The main issue resides on the fact that Tendermint's protobuf types build process is heavily coupled with how go resolves depedencies and also that the [gogo protobuf](https://github.com/gogo/protobuf) extension are being used.

In order to get the Tendermint protobuf types compiled I have to:

 * Edit all `.proto` files to remove use of gogo protobuf extensions.
 * Remove `package` directive to avoid package naming prefix for Swift generated types. For example `Types_RequestEcho` instead of `RequestEcho`. Swift modules are used for namespace collision.
 * Edit imports to used local version of other `.proto` dependencies

To generate Swift files you need to run:

 * `brew install swift-protobuf`
 * `./compile.sh`

For a long term solution, Tendermint maintainers should avoid using go specific extensions and refactor its build process to make it more friendly for non-go code generation.
