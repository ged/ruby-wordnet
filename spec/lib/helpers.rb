#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	$stderr.puts "\n\n>>> Enabling coverage report.\n\n"
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
		add_group "Needing tests" do |file|
			file.covered_percent < 90
		end
	end
end

require 'rspec'
require 'loggability/spechelpers'
require 'wordnet'


### RSpec helper functions.
module WordNet::SpecHelpers

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Make a WordNet::Directory that will use the given +conn+ object as its
	### LDAP connection. Also pre-loads the schema object and fixtures some other
	### external data.
	def get_fixtured_directory( conn )
		LDAP::SSLConn.stub( :new ).and_return( @conn )
		conn.stub( :root_dse ).and_return( nil )
		directory = WordNet.directory( TEST_LDAPURI )
		directory.stub( :schema ).and_return( SCHEMA )

		return directory
	end

end


### Mock with Rspec
RSpec.configure do |c|
	c.mock_with :rspec
	c.include( WordNet::SpecHelpers )
	c.include( Loggability::SpecHelpers )

	c.treat_symbols_as_metadata_keys_with_true_values = true

	if Gem::Specification.find_all_by_name( 'pg' ).empty?
		c.filter_run_excluding( :requires_pg )
	end

	begin
		uri = WordNet::Lexicon.default_db_uri
		WordNet.log.info "Database tests will use: #{uri}"
	rescue WordNet::LexiconError
		c.filter_run_excluding( :requires_database )
	end
end

# vim: set nosta noet ts=4 sw=4:

