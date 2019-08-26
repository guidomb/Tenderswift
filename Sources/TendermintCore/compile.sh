#!/bin/bash

# brew install protoc
protoc --swift_opt=Visibility=Public --swift_out=./ ./common/types.proto &&
protoc --swift_opt=Visibility=Public --swift_out=./ ./merkle/merkle.proto &&
protoc --swift_opt=Visibility=Public --swift_out=./ ./Tendermint.proto
