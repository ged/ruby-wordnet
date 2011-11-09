#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'wordnet'


### RSpec helper functions.
module WordNet::SpecHelpers

	# A logger that logs to an array.
	class ArrayLogger
		### Create a new ArrayLogger that will append content to +array+.
		def initialize( array )
			@array = array
		end

		### Write the specified +message+ to the array.
		def write( message )
			@array << message
		end

		### No-op -- this is here just so Logger doesn't complain
		def close; end

	end # class ArrayLogger


	unless defined?( LEVEL )
		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }
	end


	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Reset the logging subsystem to its default state.
	def reset_logging
		WordNet.reset_logger
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		if LEVEL.key?( level )
			level = LEVEL[ level ]
		end

		logger = Logger.new( $stderr )
		WordNet.logger = logger
		WordNet.logger.level = level

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			Thread.current['logger-output'] = []
			logdevice = ArrayLogger.new( Thread.current['logger-output'] )
			WordNet.logger = Logger.new( logdevice )
			# WordNet.logger.level = level
			WordNet.logger.formatter = WordNet::HtmlLogFormatter.new( logger )
		end
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

	c.filter_run_excluding( :ruby_1_9_only => true ) if
		WordNet::SpecHelpers.vvec( RUBY_VERSION ) <= WordNet::SpecHelpers.vvec('1.9.1')
	unless Gem::Specification.find_all_by_name( 'pg' ).empty?
		c.filter_run_excluding( :requires_pg => true )
		$stderr.puts "Enabled requires_pg tests"
	else
		$stderr.puts ">>> No requires_pg tests!!"
	end

	begin
		uri = WordNet::Lexicon.default_db_uri
		WordNet.log.info "Database tests will use: #{uri}"
	rescue WordNet::LexiconError
		c.filter_run_excluding( :requires_database => true )
	end
end

# vim: set nosta noet ts=4 sw=4:

