#!/usr/bin/ruby

require 'pathname'

require 'wordnet' unless defined?( WordNet )
require 'wordnet/mixins'


# WordNet lexicon class - abstracts access to the WordNet lexical
# database, and provides factory methods for looking up words and synsets.
class WordNet::Lexicon
	include WordNet::Constants,
	        WordNet::Loggable

	# Add the logger device to the default options after it's been loaded
	WordNet::DEFAULT_DB_OPTIONS.merge!( :logger => [WordNet.logger] )


	### Get the Sequel URI of the default database, if it's installed.
	def self::default_db_uri
		WordNet.log.debug "Fetching the default db URI"

		if gem_datadir = Gem.datadir( 'wordnet-defaultdb' )
			WordNet.log.debug "  using the wordnet-defaultdb datadir: %p" % [ gem_datadir ]
			return "sqlite://#{gem_datadir}/wordnet30.sqlite"
		else
			WordNet.log.debug "  no defaultdb gem; looking for the development database"
			datadir = Pathname( __FILE__ ).dirname.parent.parent +
				'wordnet-defaultdb/data/wordnet-defaultdb'
			WordNet.log.debug "  datadir is: %s" % [ datadir ]

			if datadir.exist?
				return "sqlite://#{datadir}/wordnet30.sqlite"
			else
				raise WordNet::LexiconError,
					"no default wordnet SQL database! You can install it via the " +
					"wordnet-defaultdb gem, or download a version yourself from " +
					"http://sourceforge.net/projects/wnsql/"
			end
		end
	end


	#############################################################
	### I N S T A N C E	  M E T H O D S
	#############################################################

	### Create a new WordNet::Lexicon object that will use the database connection specified by
	### the given +dbconfig+.
	def initialize( *args )
		if args.empty?
			uri = WordNet::Lexicon.default_db_uri
		else
			uri = args.shift if args.first.is_a?( String )
		end

		options = WordNet::DEFAULT_DB_OPTIONS.merge( args.shift || {} )

		if uri
			self.log.debug "Connecting using uri + options style: uri = %s, options = %p" %
				[ uri, options ]
			@db = Sequel.connect( uri, options )
		else
			self.log.debug "Connecting using hash style connect: options = %p" % [ options ]
			@db = Sequel.connect( options )
		end

		@uri = @db.uri
		self.log.debug "  setting model db to: %s" % [ @uri ]

		require 'wordnet/model'
		@db.sql_log_level = :debug
		WordNet::Model.db = @db

		require 'wordnet/sense'
		require 'wordnet/synset'
		require 'wordnet/semanticlink'
		require 'wordnet/lexicallink'
		require 'wordnet/word'
		require 'wordnet/morph'
	end


	######
	public
	######

	# The database URI the lexicon will use to look up WordNet data
	attr_reader :uri

	# The Sequel::Database object that model tables read from
	attr_reader :db


	### Find a word in the WordNet database and return it.
	### @param [String, #to_s] word  the word to look up
	### @return [WordNet::Word, nil] the word object if it was found, nil if it wasn't.
	def []( word )
		if word.is_a?( Integer )
			return WordNet::Word[ word ]
		else
			return WordNet::Word.filter( :lemma => word.to_s ).first
		end
	end


	# :section: Backwards-compatibility methods

	### Look up synsets (Wordnet::Synset objects) matching +text+ as a
	### +part_of_speech+, where +part_of_speech+ is one of the keys of
	### WordNet::Synset.postypes.
	### 
	### Without +sense+, #lookup_synsets will return all matches that are a
	### +part_of_speech+. If +sense+ is specified, only the synset object that
	### matches that particular +part_of_speech+ and +sense+ is returned.
	### 
	### 
	def lookup_synsets( word, part_of_speech, sense=nil )
		
	end

end # class WordNet::Lexicon

