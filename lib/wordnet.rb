#!/usr/bin/env ruby
#encoding: utf-8

require 'logger'
require 'sequel'

# This is a Ruby interface to the WordNet® lexical database. It uses the WordNet-SQL 
# project's databases instead of reading from the canonical flatfiles for speed and 
# easy modification.
module WordNet

	# Release version
	VERSION = '1.0.0'

	# VCS revision
	REVISION = %q$Revision: $

	# Abort if not >=1.9.2
	vvec = lambda {|version| version.split('.').collect {|v| v.to_i }.pack('N*') }
	abort "This version of WordNet requires Ruby 1.9.2 or greater." unless
		vvec[RUBY_VERSION] >= vvec['1.9.2']


	### Lexicon exception - something has gone wrong in the internals of the
	### lexicon.
	class LexiconError < StandardError ; end

	### Lookup error - the object being looked up either doesn't exist or is
	### malformed
	class LookupError < StandardError ; end


	require 'wordnet/constants'
	include WordNet::Constants
	require 'wordnet/utils'

	#
	# Logging
	#

	@default_logger = Logger.new( $stderr )
	@default_logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

	@default_log_formatter = WordNet::LogFormatter.new( @default_logger )
	@default_logger.formatter = @default_log_formatter

	@logger = @default_logger

	class << self
		# @return [Logger::Formatter] the log formatter that will be used when the logging 
		#    subsystem is reset
		attr_accessor :default_log_formatter

		# @return [Logger] the logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# @return [Logger] the logger that's currently in effect
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=
	end


	### Reset the global logger object to the default
	### @return [void]
	def self::reset_logger
		self.logger = self.default_logger
		self.logger.level = Logger::WARN
		self.logger.formatter = self.default_log_formatter
	end


	### Returns +true+ if the global logger has not been set to something other than
	### the default one.
	def self::using_default_logger?
		return self.logger == self.default_logger
	end


	### Get the WordNet version.
	### @return [String] the library's version
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end


	require 'wordnet/lexicon'

	require 'wordnet/model'
	require 'wordnet/sense'
	require 'wordnet/synset'
	require 'wordnet/semanticlink'
	require 'wordnet/lexicallink'
	require 'wordnet/word'
	require 'wordnet/morph'
	require 'wordnet/sumoterm'

	#
	# Backward-compatibility stuff
	#

	# :section: Backward-compatibility

	# Backward-compatibility constant
	Noun      = :n

	# Backward-compatibility constant
	Verb      = :v

	# Backward-compatibility constant
	Adjective = :a

	# Backward-compatibility constant
	Adverb    = :r

	# Backward-compatibility constant
	Other     = :s



end # module WordNet

