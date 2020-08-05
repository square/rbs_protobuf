require "protobuf"
require_relative "protobuf-gem/a.pb.rb"
require_relative "protobuf-gem/b.pb.rb"

request = Rbs_protobuf::Example::SearchRequest.decode("")
request.corpus = :VIDEO

request.corpus = Rbs_protobuf::Example::SearchRequest::Corpus::WEB

corpus = request.corpus

query = request[:query]


req = Rbs_protobuf::Example::SearchRequest.new(corpus: :VIDEO, query: "Hello world")


response = Rbs_protobuf::Example::SearchResponse.new()

response.result.each do |result|

end

response.result.clear
response.result[0] = nil

project = Rbs_protobuf::Example::Project.new
project.projects["sub project 1"] = Rbs_protobuf::Example::Project.new

project = Rbs_protobuf::Example::Project.new
s = project.new_name
project.new_name = "Hello world"
