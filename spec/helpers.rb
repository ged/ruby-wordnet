# -*- ruby -*-
#encoding: utf-8
# coding: utf-8

# SimpleCov test coverage reporting; enable this using the :coverage rake task
require 'simplecov' if ENV['COVERAGE']

$LOAD_PATH.unshift( 'wordnet-defaultdb/lib' )

require 'rspec'
require 'loggability/spechelpers'
require 'wordnet'
require 'wordnet/defaultdb'


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
	config.example_status_persistence_file_path = "spec/.state"

	if Gem::Specification.find_all_by_name( 'pg' ).any?
		$dburi = 'postgres:/sqlunet50'
	else
		config.filter_run_excluding( :requires_pg )
		unless (( $dburi = WordNet::Lexicon.default_db_uri ))
			config.filter_run_excluding( :requires_database )
		end
	end

	$stderr.puts "Using database: %p" % [ $dburi ]

	config.include( WordNet::SpecHelpers )
	config.include( Loggability::SpecHelpers )
end

# vim: set nosta noet ts=4 sw=4:

