require 'open-uri'
require 'fileutils'

PROTOBUF_DEPS_DIR="./.protobuf"
PROTOBUF_OUT_DIR="./Sources/Tenderswift/TendermintTypes"
TENDERMINT_PROTOBUF="TendermintTypes.proto"

task default: :build_protobuf

desc "Download and properly extracts required protobuf dependency definitions"
task :get_protobuf_deps do
  FileUtils.mkdir_p(PROTOBUF_DEPS_DIR)

  get_protobuf_dependency("gogo/protobuf",
    version: "v1.2.1",
    dest_dir: PROTOBUF_DEPS_DIR,
    include_paths: {
      "gogoproto" => "github.com/gogo/protobuf/gogoproto",
      "protobuf/google/protobuf" => "google/protobuf"
    }
  )
  get_protobuf_dependency("tendermint/tendermint",
    version: "master",
    dest_dir: PROTOBUF_DEPS_DIR,
    include_paths: {
      "crypto/merkle" => "github.com/tendermint/tendermint/crypto/merkle",
      "libs/common" => "github.com/tendermint/tendermint/libs/common",
      "abci/types" => ""
    }
  )

  sh "mv #{File.join(PROTOBUF_DEPS_DIR, 'types.proto')} #{File.join(PROTOBUF_DEPS_DIR, TENDERMINT_PROTOBUF)}"
end

task :clean_protobuf_deps do
  FileUtils.rm_rf(PROTOBUF_DEPS_DIR)
end

task :install_swift_protobuf do
  # TODO Add support for Linux
  sh "brew install swift-protobuf"
end

desc "Builds Tendermint ABCI types from protobuf definitions"
task build_protobuf: [:get_protobuf_deps] do
  build_all_protobuf
  generate_xcode_project
end

#
# Local utility functions
#
def generate_xcode_project
  sh "swift package generate-xcodeproj"
end

def build_all_protobuf
  FileUtils.mkdir_p(PROTOBUF_OUT_DIR)
  include_dir = "-I=#{PROTOBUF_DEPS_DIR} " + Dir.glob("#{PROTOBUF_DEPS_DIR}/**/*/").join(" -I=")
  Dir.glob("#{PROTOBUF_DEPS_DIR}/**/*.proto").each do |file|
    sh "protoc #{include_dir} --swift_out=#{PROTOBUF_OUT_DIR} #{file}"
  end
end

def get_protobuf_dependency(repo, version:, dest_dir:"./", include_paths:{})
  local_file_path = download_repository(repo, version: version, dest_dir: dest_dir)
  extraction_dir = extract_archive(local_file_path, dest_dir)
  include_paths.each do |path, import_path|
    dep_import_dir = File.join(dest_dir, import_path)
    FileUtils.mkdir_p(dep_import_dir)
    sh "cp #{File.join(extraction_dir, path, '*.proto')} #{dep_import_dir}"
  end
  FileUtils.rm_rf(extraction_dir)
  FileUtils.rm_rf(local_file_path)
end

def download_repository(repo, version:, dest_dir:"./")
  file_name_suffix = "#{version}.tar.gz"
  file_name =  "#{repo.gsub('/', '_')}_#{file_name_suffix}"
  local_file_path = File.join(dest_dir, file_name)
  archive_url = "https://github.com/#{repo}/archive/#{file_name_suffix}"
  puts "Downloading '#{archive_url}' to '#{local_file_path}' ..."
  File.write(local_file_path, open(archive_url).read)
  local_file_path
end

def extract_archive(archive_file_path, dest_dir)
  extract_dir = File.basename(archive_file_path).gsub(".tar.gz", "")
  dest_dir = File.join(dest_dir, extract_dir)
  FileUtils.mkdir_p(dest_dir)
  sh "tar -C #{dest_dir} --strip-components=1 -xvzf #{archive_file_path}"
  dest_dir
end
