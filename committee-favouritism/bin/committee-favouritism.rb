#!/usr/bin/env jruby

require 'rubygems'
require 'net/http'
require 'trollop'
require 'json'

require 'committee-favouritism/citation_parser'
require 'committee-favouritism/dblp'

include CommitteeFavouritism
include CommitteeFavouritism::DBLP

opts = Trollop::options(ARGV) do

  banner <<-END

Usage: committee-favouritism [-f file.json] -c committee.json <conf> <year>
  conf -> Conference short name (e.g. ICSE, VLDB, OOPSLA)
  year -> The year of the conference

If [-f] is passed, the program expects a file containing a DBLP search API
response.

Options:
  END

  opt :file, 'JSON file location', :short => 'f', :type => String
  opt :committee_file, 'program committee file location', :short => 'c', :type => String
end

Trollop::die :committee_file, "must exist" unless
  opts[:committee_file] and File.exist?(opts[:committee_file])
Trollop::die "Exactly two arguments are required if no input file specified" if
  opts[:file].nil? and ARGV.size != 2

doi_results = []

if ARGV.size == 2
  conf = ARGV[0]
  year = ARGV[1].to_i
    
  doi_results = CommitteeFavouritism::DBLP::query(conf, year)
else
  doi_results = JSON.parse(File.open(options[:file]).read)
end

program_committee = Array.new

File.open(opts[:committee_file]).each_line do |member|
  program_committee << member
end

citation_parser = CommitteeFavouritism::CitationParser.new
citation_parser.program_committee = program_committee

cited_authors = CommitteeFavouritism::DBLP::dois(doi_results).map do |doi|
  citation_parser.retrieve_cited_authors(doi)
end

puts "=== Results ==="

cited_authors.flatten.reduce([]) { |acc, x| acc << x unless x.nil?; acc }.each { |author|
  puts author
}
