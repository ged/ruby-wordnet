#!/usr/bin/env ruby
#coding: utf-8

require 'logger'

# This is a Ruby interface to the WordNet® lexical database. It uses the WordNet-SQL 
# project's databases instead of reading from the canonical flatfiles for speed and 
# easy modification.
module WordNet

	# Release version
	VERSION = '0.99.0'

	# VCS revision
	REVISION = %q$Revision: $


	### Lexicon exception - something has gone wrong in the internals of the
	### lexicon.
	class LexiconError < StandardError ; end

	### Lookup error - the object being looked up either doesn't exist or is
	### malformed
	class LookupError < StandardError ; end


	require 'wordnet/constants'
	require 'wordnet/lexicon'
	require 'wordnet/utils'

	include WordNet::Constants


	### Logging
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


	# Now load the model mixins
	require 'wordnet/word'
	require 'wordnet/synset'


end # module WordNet

