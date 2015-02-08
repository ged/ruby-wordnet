#!/usr/bin/ruby
# coding: utf-8

# SimpleCov test coverage reporting; enable this using the :coverage rake task
require 'simplecov' if ENV['COVERAGE']

require 'rspec'
require 'loggability/spechelpers'
require 'wordnet'


### RSpec helper functions.
module WordNet::SpecHelpers
end


### Mock with Rspec
RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.order = 'random'
	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	if Gem::Specification.find_all_by_name( 'pg' ).empty?
		config.filter_run_excluding( :requires_pg )
	end

	begin
		uri = WordNet::Lexicon.default_db_uri
		WordNet.log.info "Database tests will use: #{uri}"
	rescue WordNet::LexiconError
		config.filter_run_excluding( :requires_database )
	end

	config.include( WordNet::SpecHelpers )
	config.include( Loggability::SpecHelpers )
end

# vim: set nosta noet ts=4 sw=4:

