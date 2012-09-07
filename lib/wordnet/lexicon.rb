#!/usr/bin/ruby

require 'pathname'
require 'loggability'
require 'rubygems'

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/synset'
require 'wordnet/word'


# WordNet lexicon class - provides access to the WordNet lexical
# database, and provides factory methods for looking up words[rdoc-ref:WordNet::Word]
# and synsets[rdoc-ref:WordNet::Synset].
#
# == Creating a Lexicon
#
# To create a Lexicon, point it at a database using [Sequel database connection
# criteria]{http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html}:
#
#     lex = WordNet::Lexicon.new( 'postgres://localhost/wordnet30' )
#     # => #<WordNet::Lexicon:0x7fd192a76668 postgres://localhost/wordnet30>
#
#     # Another way of doing the same thing:
#     lex = WordNet::Lexicon.new( adapter: 'postgres', database: 'wordnet30', host: 'localhost' )
#     # => #<WordNet::Lexicon:0x7fd192d374b0 postgres>
#
# Alternatively, if you have the 'wordnet-defaultdb' gem (which includes an
# embedded copy of the SQLite WordNET-SQL database) installed, just call ::new
# without any arguments:
#
#     lex = WordNet::Lexicon.new
#     # => #<WordNet::Lexicon:0x7fdbfac1a358 sqlite:[...]/gems/wordnet-defaultdb-1.0.1
#     #     /data/wordnet-defaultdb/wordnet30.sqlite>
#
# == Looking Up Synsets
#
# Once you have a Lexicon created, the main lookup method for Synsets is
# #[], which will return the first of any Synsets that are found:
#
#    synset = lex[ :language ]
#    # => #<WordNet::Synset:0x7fdbfaa987a0 {105650820} 'language, speech' (noun):
#    #      [noun.cognition] the mental faculty or power of vocal communication>
#
# If you want to look up *all* matching Synsets, use the #lookup_synsets
# method:
#
#    synsets = lex.lookup_synsets( :language )
#    # => [#<WordNet::Synset:0x7fdbfaac46c0 {105650820} 'language, speech' (noun):
#    #       [noun.cognition] the mental faculty or power of vocal
#    #       communication>,
#    #     #<WordNet::Synset:0x7fdbfaac45a8 {105808557} 'language, linguistic process'
#    #       (noun): [noun.cognition] the cognitive processes involved
#    #       in producing and understanding linguistic communication>,
#    #     #<WordNet::Synset:0x7fdbfaac4490 {106282651} 'language, linguistic
#    #       communication' (noun): [noun.communication] a systematic means of
#    #       communicating by the use of sounds or conventional symbols>,
#    #     #<WordNet::Synset:0x7fdbfaac4378 {106304059} 'language, nomenclature,
#    #       terminology' (noun): [noun.communication] a system of words used to
#    #       name things in a particular discipline>,
#    #     #<WordNet::Synset:0x7fdbfaac4260 {107051975} 'language, lyric, words'
#    #       (noun): [noun.communication] the text of a popular song or musical-comedy
#    #       number>,
#    #     #<WordNet::Synset:0x7fdbfaac4120 {107109196} 'language, oral communication,
#    #       speech, speech communication, spoken communication, spoken language,
#    #       voice communication' (noun): [noun.communication] (language)
#    #       communication by word of mouth>]
#
# Sometime, the first Synset isn't necessarily what you want; you want to look up
# a particular one. Both #[] and #lookup_synsets also provide several
# ways of filtering or selecting synsets.
#
# The first is the ability to select one based on its offset:
#
#    lex[ :language, 2 ]
#    # => #<WordNet::Synset:0x7ffa78e74d78 {105808557} 'language, linguistic
#    #       process' (noun): [noun.cognition] the cognitive processes involved in
#    #       producing and understanding linguistic communication>
#
# You can also select one with a particular word in its definition:
#
#    lex[ :language, 'sounds' ]
#    # => #<WordNet::Synset:0x7ffa78ee01b8 {106282651} 'linguistic communication,
#    #       language' (noun): [noun.communication] a systematic means of
#    #       communicating by the use of sounds or conventional symbols>
#
# If you're using a database that supports using regular expressions (e.g.,
# PostgreSQL), you can use that to select one with a matching definition:
#
#    lex[ :language, %r:name.*discipline: ]
#    # => #<WordNet::Synset:0x7ffa78f235a8 {106304059} 'language, nomenclature,
#    #       terminology' (noun): [noun.communication] a system of words used
#    #       to name things in a particular discipline>
#
# You can also select certain parts of speech:
#
#    lex[ :right, :noun ]
#    # => #<WordNet::Synset:0x7ffa78f30b68 {100351000} 'right' (noun):
#    #       [noun.act] a turn toward the side of the body that is on the south
#    #       when the person is facing east>
#    lex[ :right, :verb ]
#    # => #<WordNet::Synset:0x7ffa78f09590 {200199659} 'correct, right, rectify'
#    #       (verb): [verb.change] make right or correct>
#    lex[ :right, :adjective ]
#    # => #<WordNet::Synset:0x7ffa78ea8060 {300631391} 'correct, right'
#    #       (adjective): [adj.all] free from error; especially conforming to
#    #       fact or truth>
#    lex[ :right, :adverb ]
#    # => #<WordNet::Synset:0x7ffa78e5b2d8 {400032299} 'powerful, mightily,
#    #       mighty, right' (adverb): [adv.all] (Southern regional intensive)
#    #       very; to a great degree>
#
# or by lexical domain, which is a more-specific part of speech (see
# <tt>WordNet::Synset.lexdomains.keys</tt> for the list of valid ones):
#
#    lex.lookup_synsets( :right, 'verb.social' )
#    # => [#<WordNet::Synset:0x7ffa78d817e0 {202519991} 'redress, compensate,
#    #       correct, right' (verb): [verb.social] make reparations or amends
#    #       for>]
#
class WordNet::Lexicon
	extend Loggability
	include WordNet::Constants

	# Loggability API -- log to the WordNet module's logger
	log_to :wordnet


	# Add the logger device to the default options after it's been loaded
	WordNet::DEFAULT_DB_OPTIONS.merge!( :logger => [Loggability[WordNet]] )


	### Get the Sequel URI of the default database, if it's installed.
	def self::default_db_uri
		self.log.debug "Fetching the default db URI"

		# Try to load the default database gem, ignoring it if it's not installed.
		begin
			gem 'wordnet-defaultdb'
		rescue Gem::LoadError
		end

		# Now try the gem datadir first, and fall back to a local installation of the
		# default db
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
		if args.empty?
			self.initialize_with_defaultdb( args.shift )
		elsif args.first.is_a?( String )
			self.initialize_with_uri( *args )
		else
			self.initialize_with_opthash( args.shift )
		end

		@db.sql_log_level = :debug
		WordNet::Model.db = @db
	end


	### Connect to the WordNet DB using an optional options hash.
	def initialize_with_defaultdb( options )
		uri = WordNet::Lexicon.default_db_uri or raise WordNet::LexiconError,
			"No default WordNetSQL database! You can install it via the " +
			"wordnet-defaultdb gem, or download a version yourself from " +
			"http://sourceforge.net/projects/wnsql/"
		@db = self.connect( uri, options )
	end


	### Connect to the WordNet DB using a URI and an optional options hash.
	def initialize_with_uri( uri, options={} )
		@db = self.connect( uri, options )
	end


	### Connect to the WordNet DB using a connection options hash.
	def initialize_with_opthash( options )
		@db = self.connect( nil, options )
	end


	### Connect to the WordNet DB and return a Sequel::Database object.
	def connect( uri, options )
		options = WordNet::DEFAULT_DB_OPTIONS.merge( options || {} )

		if uri
			self.log.debug "Connecting using uri + options style: uri = %s, options = %p" %
				[ uri, options ]
			return Sequel.connect( uri, options )
		else
			self.log.debug "Connecting using hash style connect: options = %p" % [ options ]
			return Sequel.connect( options )
		end
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
				dataset = dataset.limit( arg.entries.length, arg.begin - 1 )

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


	### Return a human-readable string representation of the Lexicon, suitable for
	### debugging.
	def inspect
		return "#<%p:%0#x %s>" % [
			self.class,
			self.object_id * 2,
			self.db.url || self.db.adapter_scheme
		]
	end


end # class WordNet::Lexicon

