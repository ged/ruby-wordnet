#!/usr/bin/env ruby

require 'loggability'
require 'sequel'

# This is a Ruby interface to the WordNet® lexical database. It uses the SqlUNet
# project's databases instead of reading from the canonical flatfiles for speed,
# easy modification, and correlation with other linguistic lexicons.
module WordNet
	extend Loggability

	# Loggability API -- Set up a logger for WordNet classes
	log_as :wordnet


	# Release version
	VERSION = '1.2.0'

	# VCS revision
	REVISION = %q$Revision: $


	### Lexicon exception - something has gone wrong in the internals of the
	### lexicon.
	class LexiconError < StandardError ; end

	### Lookup error - the object being looked up either doesn't exist or is
	### malformed
	class LookupError < StandardError ; end


	require 'wordnet/constants'
	include WordNet::Constants

	### Get the WordNet version.
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
		return vstring
	end


	require 'wordnet/lexicon'
	require 'wordnet/model'

	WordNet::Model.register_model( 'wordnet/sense' )
	WordNet::Model.register_model( 'wordnet/synset' )
	WordNet::Model.register_model( 'wordnet/semanticlink' )
	WordNet::Model.register_model( 'wordnet/lexicallink' )
	WordNet::Model.register_model( 'wordnet/word' )
	WordNet::Model.register_model( 'wordnet/morph' )
	WordNet::Model.register_model( 'wordnet/sumoterm' )

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

