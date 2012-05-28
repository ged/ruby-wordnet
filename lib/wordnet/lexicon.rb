#!/usr/bin/ruby

require 'pathname'
require 'loggability'
require 'rubygems'

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/synset'
require 'wordnet/word'


# WordNet lexicon class - abstracts access to the WordNet lexical
# database, and provides factory methods for looking up words and synsets.
class WordNet::Lexicon
	extend Loggability
	include WordNet::Constants

	# Loggability API -- log to the WordNet module's logger
	log_to :wordnet

	# class LogTracer
	# 	def method_missing( sym, msg, &block )
	# 		if msg =~ /does not exist/
	# 			$stderr.puts ">>> DOES NOT EXIST TRACE"
	# 			$stderr.puts( caller(1).grep(/wordnet/i) )
	# 		end
	# 	end
	# end


	# Add the logger device to the default options after it's been loaded
	WordNet::DEFAULT_DB_OPTIONS.merge!( :logger => [Loggability[WordNet]] )
	# WordNet::DEFAULT_DB_OPTIONS.merge!( :logger => [LogTracer.new] )


	### Get the Sequel URI of the default database, if it's installed.
	def self::default_db_uri
		self.log.debug "Fetching the default db URI"

		datadir = nil
		if Gem.datadir( 'wordnet-defaultdb' )
			datadir = Pathname( Gem.datadir('wordnet-defaultdb') )
		else
			self.log.warn "  no defaultdb gem; looking for the development database"
			datadir = Pathname( __FILE__ ).dirname.parent.parent +
				'wordnet-defaultdb/data/wordnet-defaultdb'
		end

		dbfile = datadir + 'wordnet30.sqlite'
		self.log.debug "  dbfile is: %s" % [ dbfile ]

		if dbfile.exist?
			return "sqlite:#{dbfile}"
		else
			return nil
		end
	end


	#############################################################
	### I N S T A N C E	  M E T H O D S
	#############################################################

	### Create a new WordNet::Lexicon object that will use the database connection specified by
	### the given +dbconfig+.
	def initialize( *args )
		uri = if args.empty?
				WordNet::Lexicon.default_db_uri or
					raise WordNet::LexiconError,
						"No default WordNetSQL database! You can install it via the " +
						"wordnet-defaultdb gem, or download a version yourself from " +
						"http://sourceforge.net/projects/wnsql/"

			elsif args.first.is_a?( String )
				args.shift
			else
				nil
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

		@db.sql_log_level = :debug
		WordNet::Model.db = @db
	end


	######
	public
	######

	# The database URI the lexicon will use to look up WordNet data
	attr_reader :uri

	# The Sequel::Database object that model tables read from
	attr_reader :db


	### Find a Word or Synset in the WordNet database and return it. In the case of multiple
	### matching Synsets, only the first will be returned. If you want them all, you can use
	### #lookup_synsets instead.
	###
	### The +word+ can be one of:
	### [Integer]
	###   Looks up the corresponding Word or Synset by ID. This assumes that all Synset IDs are
	###   all 9 digits or greater, which is true as of WordNet 3.1. Any additional +args+ are
	###   ignored.
	### [Symbol, String]
	###   Look up a Word by its gloss using #lookup_synsets, passing any additional +args+,
	###   and return the first one that is found.
	def []( word, *args )
		if word.is_a?( Integer )
			# :TODO: Assumes Synset IDs are all >= 100_000_000
			if word.to_s.length > 8
				return WordNet::Synset[ word ]
			else
				return WordNet::Word[ word ]
			end
		else
			return self.lookup_synsets( word, 1, *args ).first
		end
	end


	### Look up synsets (Wordnet::Synset objects) associated with +word+, optionally filtered
	### by additional +args+.
	###
	### The *args* can contain:
	###
	### [Integer, Range]
	###   The sense/s of the Word (1-indexed) to use when searching for Synsets. If not specified,
	###   all senses of the +word+ are used.
	### [Regexp]
	###   The Word's Synsets are filtered by definition using an RLIKE filter. Note that not all
	###   databases (including the default one, sqlite3) support RLIKE.
	### [Symbol, String]
	###   If it matches one of either a lexical domain (e.g., "verb.motion") or a part of
	###   speech (e.g., "adjective", :noun, :v), the resulting Synsets are filtered by that
	###   criteria.
	###   If the doesn't match a lexical domain or part of speech, it's used to filter by
	###   definition using a LIKE query.
	###
	def lookup_synsets( word, *args )
		dataset = WordNet::Synset.filter( :words => WordNet::Word.filter(lemma: word.to_s) )
		self.log.debug "Looking up synsets for %p" % [ word.to_s ]

		# Add filters to the dataset for each argument
		args.each do |arg|
			self.log.debug "  constraint arg: %p" % [ arg ]
			case arg

			when Integer
				self.log.debug "  limiting to sense %d" % [ arg ]
				dataset = dataset.limit( 1, arg-1 )

			when Range
				self.log.debug "  limiting to range of senses: %p" % [ arg ]
				dataset = dataset.limit( arg.end - arg.begin, arg.begin - 1 )

			when Regexp
				self.log.debug "  filter: definition =~ %p" % [ arg ]
				dataset = dataset.filter( definition: arg )

			when Symbol, String
				# Lexical domain, e.g., "verb.motion"
				if domain = WordNet::Synset.lexdomains[ arg.to_s ]
					self.log.debug "  filter: lex domain: %s (%d)" % [ arg, domain[:lexdomainid] ]
					dataset = dataset.filter( lexdomainid: domain[:lexdomainid] )

				# Part of speech symbol, e.g., "v"
				elsif WordNet::Synset.postype_table.key?( arg.to_sym )
					self.log.debug "  filter: part of speech: %s" % [ arg ]
					dataset = dataset.filter( pos: arg.to_s )

				# Part of speech name, e.g., "verb"
				elsif pos = WordNet::Synset.postypes[ arg.to_s ]
					self.log.debug "  filter: part of speech: %s" % [ pos.to_s ]
					dataset = dataset.filter( pos: pos.to_s )

				# Assume it's a definition match
				else
					pattern = "%%%s%%" % [ arg ]
					self.log.debug "  filter: definition LIKE %p" % [ pattern ]
					dataset = dataset.filter { :definition.like(pattern) }
				end
			end
		end

		return dataset.all
	end

end # class WordNet::Lexicon

