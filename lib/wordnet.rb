#!/usr/bin/env ruby
#encoding: utf-8

require 'loggability'
require 'sequel'

# This is a Ruby interface to the WordNet® lexical database. It uses the WordNet-SQL
# project's databases instead of reading from the canonical flatfiles for speed and
# easy modification.
module WordNet
	extend Loggability

	# Loggability API -- Set up a logger for WordNet classes
	log_as :wordnet


	# Release version
	VERSION = '1.0.0'

	# VCS revision
	REVISION = %q$Revision: $

	# Abort if not >=1.9.2
	abort "This version of WordNet requires Ruby 1.9.3 or greater." unless
		RUBY_VERSION >= '1.9.3'


	### Lexicon exception - something has gone wrong in the internals of the
	### lexicon.
	class LexiconError < StandardError ; end

	### Lookup error - the object being looked up either doesn't exist or is
	### malformed
	class LookupError < StandardError ; end


	require 'wordnet/constants'
	include WordNet::Constants

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

