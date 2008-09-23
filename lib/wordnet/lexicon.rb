#!/usr/bin/ruby
#
# WordNet Lexicon object class
# 
# == Synopsis
# 
#	lexicon = WordNet::Lexicon.new( dictpath )
# 
# == Description
# 
# Instances of this class abstract access to the various databases of the
# WordNet lexicon. It can be used to look up and search for WordNet::Synsets.
# 
# == Author
# 
# Michael Granger <ged@FaerieMUD.org>
# 
# Copyright (c) 2002, 2003, 2005 The FaerieMUD Consortium. All rights reserved.
# 
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
# 
# Much of this code was inspired by/ported from the Lingua::Wordnet Perl module
# by Dan Brian.
# 
# == Version
#
# $Id$
# 

require 'rbconfig'
require 'pathname'
require 'bdb'
require 'sync'

require 'wordnet/constants'
require 'wordnet/synset'

### Lexicon exception - something has gone wrong in the internals of the
### lexicon.
class WordNet::LexiconError < StandardError ; end

### Lookup error - the object being looked up either doesn't exist or is
### malformed
class WordNet::LookupError < StandardError ; end

### WordNet lexicon class - abstracts access to the WordNet lexical
### databases, and provides factory methods for looking up and creating new
### WordNet::Synset objects.
class WordNet::Lexicon
	include WordNet::Constants
	include CrossCase if defined?( CrossCase )

	# Subversion Id
	SvnId = %q$Id$

	# Subversion revision
	SvnRev = %q$Rev$


	#############################################################
	### B E R K E L E Y D B	  C O N F I G U R A T I O N
	#############################################################

	# The path to the WordNet BerkeleyDB Env. It lives in the directory that
	# this module is in.
	DEFAULT_DB_ENV = File::join( Config::CONFIG['datadir'], "ruby-wordnet" )

	# Options for the creation of the Env object
	ENV_OPTIONS = {
		:set_timeout	=> 50,
		:set_lk_detect	=> 1,
		:set_verbose	=> false,
		:set_lk_max     => 3000,
	}

	# Flags for the creation of the Env object (read-write and read-only)
	ENV_FLAGS_RW = BDB::CREATE|BDB::INIT_TRANSACTION|BDB::RECOVER|BDB::INIT_MPOOL
	ENV_FLAGS_RO = BDB::INIT_MPOOL


	#############################################################
	### I N S T A N C E	  M E T H O D S
	#############################################################

	### Create a new WordNet::Lexicon object that will read its data from
	### the given +dbenv+ (a BerkeleyDB env directory). The database will be
	### opened with the specified +mode+, which can either be a numeric 
	### octal mode (e.g., 0444) or one of (:readonly, :readwrite).
	def initialize( dbenv=DEFAULT_DB_ENV, mode=:readonly )
		@mode = normalize_mode( mode )
		debug_msg "Mode is: %04o" % [ @mode ]

		envflags = 0
		dbflags  = 0

		unless self.readonly?
			debug_msg "Using read/write flags"
			envflags = ENV_FLAGS_RW
			dbflags = BDB::CREATE
		else
			debug_msg "Using readonly flags"
			envflags = ENV_FLAGS_RO
			dbflags = 0
		end

		debug_msg "Env flags are: %0s, dbflags are %0s" %
			[ envflags.to_s(2), dbflags.to_s(2) ]

		begin
			@env = BDB::Env.new( dbenv, envflags, ENV_OPTIONS )
			@index_db = @env.open_db( BDB::BTREE, "index", nil, dbflags, @mode )
			@data_db = @env.open_db( BDB::BTREE, "data", nil, dbflags, @mode )
			@morph_db = @env.open_db( BDB::BTREE, "morph", nil, dbflags, @mode )
		rescue StandardError => err
			msg = "Error while opening Ruby-WordNet data files: #{dbenv}: %s" % 
				[ err.message ]
			raise err, msg, err.backtrace
		end
	end



	######
	public
	######

	# The BDB::Env object which contains the wordnet lexicon's databases.
	attr_reader :env

	# The handle to the index table
	attr_reader :index_db

	# The handle to the synset data table
	attr_reader :data_db

	# The handle to the morph table
	attr_reader :morph_db


	### Returns +true+ if the lexicon was opened in read-only mode.
	def readonly?
		( @mode & 0200 ).nonzero? ? false : true
	end
	
	
	### Returns +true+ if the lexicon was opened in read-write mode.
	def readwrite?
		! self.readonly?
	end
	

	### Close the lexicon's database environment
	def close
		@env.close if @env
	end


	### Checkpoint the database. (BerkeleyDB-specific)
	def checkpoint( bytes=0, minutes=0 )
		@env.checkpoint
	end


	### Remove any archival logfiles for the lexicon's database
	### environment. (BerkeleyDB-specific).
	def clean_logs
		return unless self.readwrite?
		self.archlogs.each do |logfile|
			File::chmod( 0777, logfile )
			File::delete( logfile )
		end
	end


	### Returns an integer of the familiarity/polysemy count for +word+ as a
	### +part_of_speech+. Note that polysemy can be identified for a given
	### word by counting the synsets returned by #lookup_synsets.
	def familiarity( word, part_of_speech, polyCount=nil )
		wordkey = self.make_word_key( word, part_of_speech )
		return nil unless @index_db.key?( wordkey )
		@index_db[ wordkey ].split( WordNet::SUB_DELIM_RE ).length
	end


	### Look up synsets (Wordnet::Synset objects) matching +text+ as a
	### +part_of_speech+, where +part_of_speech+ is one of +WordNet::Noun+,
	### +WordNet::Verb+, +WordNet::Adjective+, or +WordNet::Adverb+. Without
	### +sense+, #lookup_synsets will return all matches that are a
	### +part_of_speech+. If +sense+ is specified, only the synset object that
	### matches that particular +part_of_speech+ and +sense+ is returned.
	def lookup_synsets( word, part_of_speech, sense=nil )
		wordkey = self.make_word_key( word, part_of_speech )
		pos = self.make_pos( part_of_speech )
		synsets = []

		# Look up the index entry, trying first the word as given, and if
		# that fails, trying morphological conversion.
		entry = @index_db[ wordkey ]

		if entry.nil? && (word = self.morph( word, part_of_speech ))
			wordkey = self.make_word_key( word, part_of_speech )
			entry = @index_db[ wordkey ]
		end

		# If the lookup failed both ways, just abort
		return nil unless entry

		# Make synset keys from the entry, narrowing it to just the sense
		# requested if one was specified.
		synkeys = entry.split( SUB_DELIM_RE ).collect {|off| "#{off}%#{pos}" }
		if sense
			return lookup_synsets_by_key( synkeys[sense - 1] )
		else
			return [ lookup_synsets_by_key(*synkeys) ].flatten
		end
	end


	### Returns the WordNet::Synset objects corresponding to the +keys+
	### specified. The +keys+ are made up of the target synset's "offset"
	### and syntactic category catenated together with a '%' character.
	def lookup_synsets_by_key( *keys )
		synsets = []

		keys.each {|key|
			raise WordNet::LookupError, "Failed lookup of synset '#{key}':"\
				"No such synset" unless @data_db.key?( key )

			data = @data_db[ key ]
			offset, part_of_speech = key.split( /%/, 2 )
			synsets << WordNet::Synset.new( self, offset, part_of_speech, nil, data )
		}

		return *synsets
	end
	alias_method :lookup_synsetsByOffset, :lookup_synsets_by_key


	### Returns a form of +word+ as a part of speech +part_of_speech+, as
	### found in the WordNet morph files. The #lookup_synsets method perfoms
	### morphological conversion automatically, so a call to #morph is not
	### required.
	def morph( word, part_of_speech )
		return @morph_db[ self.make_word_key(word, part_of_speech) ]
	end


	### Returns the result of looking up +word+ in the inverse of the WordNet
	### morph files. _(This is undocumented in Lingua::Wordnet)_
	def reverse_morph( word )
		@morph_db.invert[ word ]
	end


	### Returns an array of compound words matching +text+.
	def grep( text )
		return [] if text.empty?
		
		words = []
		
		# Grab a cursor into the database and fetch while the key matches
		# the target text
		cursor = @index_db.cursor
		rec = cursor.set_range( text )
		while /^#{text}/ =~ rec[0]
			words.push rec[0]
			rec = cursor.next
		end
		cursor.close

		return *words
	end


	### Factory method: Creates and returns a new WordNet::Synset object in
	### this lexicon for the specified +word+ and +part_of_speech+.
	def create_synset( word, part_of_speech )
		return WordNet::Synset.new( self, '', part_of_speech, word )
	end
	alias_method :new_synset, :create_synset


	### Store the specified +synset+ (a WordNet::Synset object) in the
	### lexicon. Returns the key of the stored synset.
	def store_synset( synset )
		strippedOffset = nil
		pos = nil

		# Start a transaction
		@env.begin( BDB::TXN_COMMIT, @data_db ) do |txn,datadb|

			# If this is a new synset, generate an offset for it
			if synset.offset == 1
				synset.offset =
					(datadb['offsetcount'] = datadb['offsetcount'].to_i + 1)
			end
			
			# Write the data entry
			datadb[ synset.key ] = synset.serialize
				
			# Write the index entries
			txn.begin( BDB::TXN_COMMIT, @index_db ) do |txn,indexdb|

				# Make word/part-of-speech pairs from the words in the synset
				synset.words.collect {|word| word + "%" + pos }.each {|word|

					# If the index already has this word, but not this
					# synset, add it
					if indexdb.key?( word )
						indexdb[ word ] << SUB_DELIM << synset.offset unless
							indexdb[ word ].include?( synset.offset )
					else
						indexdb[ word ] = synset.offset
					end
				}
			end # transaction on @index_db
		end # transaction on @dataDB

		return synset.offset
	end


	### Remove the specified +synset+ (a WordNet::Synset object) in the
	### lexicon. Returns the offset of the stored synset.
	def remove_synset( synset )
		# If it's not in the database (ie., doesn't have a real offset),
		# just return.
		return nil if synset.offset == 1

		# Start a transaction on the data table
		@env.begin( BDB::TXN_COMMIT, @data_db ) do |txn,datadb|

			# First remove the index entries for this synset by iterating
			# over each of its words
			txn.begin( BDB::TXN_COMMIT, @index_db ) do |txn,indexdb|
				synset.words.collect {|word| word + "%" + pos }.each {|word|

					# If the index contains an entry for this word, either
					# splice out the offset for the synset being deleted if
					# there are more than one, or just delete the whole
					# entry if it's the only one.
					if indexdb.key?( word )
						offsets = indexdb[ word ].
							split( SUB_DELIM_RE ).
							reject {|offset| offset == synset.offset}

						unless offsets.empty?
							index_db[ word ] = newoffsets.join( SUB_DELIM )
						else
							index_db.delete( word )
						end
					end
				}
			end

			# :TODO: Delete synset from pointers of related synsets

			# Delete the synset from the main db
			datadb.delete( synset.offset )
		end

		return true
	end


	#########
	protected
	#########

	### Normalize various ways of specifying a part of speech into the
	### WordNet part of speech indicator from the +original+ representation,
	### which may be the name (e.g., "noun"); +nil+, in which case it
	### defaults to the indicator for a noun; or the indicator character
	### itself, in which case it is returned unmodified.
	def make_pos( original )
		return WordNet::Noun if original.nil?
		osym = original.to_s.intern
		return WordNet::SYNTACTIC_CATEGORIES[ osym ] if
			WordNet::SYNTACTIC_CATEGORIES.key?( osym )
		return original if SYNTACTIC_SYMBOLS.key?( original )
		return nil
	end


	### Make a lexicon key out of the given +word+ and part of speech
	### (+pos+).
	def make_word_key( word, pos )
		pos = self.make_pos( pos )
		word = word.gsub( /\s+/, '_' )
		return "#{word}%#{pos}"
	end


	### Return a list of archival logfiles that can be removed
	### safely. (BerkeleyDB-specific).
	def archlogs
		return @env.log_archive( BDB::ARCH_ABS )
	end


	#######
	private
	#######
	
	### Turn the given +origmode+ into an octal file mode such as that 
	### given to File.open.
	def normalize_mode( origmode )
		case origmode
		when :readonly
			0444 & ~File.umask
		when :readwrite, :writable
			0666 & ~File.umask
		when Fixnum
			origmode
		else
			raise ArgumentError, "unrecognized mode %p" % [origmode]
		end
	end

	### Output the given +msg+ to STDERR if $DEBUG is turned on.
	def debug_msg( *msg )
		return unless $DEBUG
		$deferr.puts msg
	end
	

end # class WordNet::Lexicon

