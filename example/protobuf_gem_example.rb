require "protobuf"
require_relative "protobuf-gem/a.pb.rb"

request = SearchRequest.decode("")
request.corpus = :VIDEO

request.corpus = SearchRequest::Corpus::WEB

corpus = request.corpus

query = request[:query]


req = SearchRequest.new(corpus: :VIDEO, query: "Hello world")


response = SearchResponse.new()

response.result.each do |result|

end

response.result.clear
response.result[0] = nil

project = Project.new
project.projects["sub project 1"] = Project.new
