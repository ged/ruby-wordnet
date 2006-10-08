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
	DefaultDbEnv = File::join( Config::CONFIG['datadir'], "ruby-wordnet" )

	# Options for the creation of the Env object
	EnvOptions = {
		:set_timeout	=> 50,
		:set_lk_detect	=> 1,
		:set_verbose	=> false,
	}

	# Flags for the creation of the Env object (read-write and read-only)
	EnvFlagsRW = BDB::CREATE|BDB::INIT_TRANSACTION|BDB::RECOVER|BDB::INIT_MPOOL
	EnvFlagsRO = BDB::INIT_MPOOL

	# Table names (actually database names in BerkeleyDB)
	TableNames = {
		:index => "index",
		:data => "data",
		:morph => "morph",
	}



	#############################################################
	### I N S T A N C E	  M E T H O D S
	#############################################################

	### Create a new WordNet::Lexicon object that will read its data from
	### the given +dbenv+ (a BerkeleyDB env directory). The database will be
	### opened with the specified +mode+, which can either be a numeric 
	### octal mode (e.g., 0444) or one of (:readonly, :readwrite).
	def initialize( dbenv=DefaultDbEnv, mode=:readonly )
		raise ArgumentError, "Cannot find data directory '#{dbenv}'" unless
			File::directory?( dbenv )

		mode = normalize_mode( mode )
		debug_msg "Mode is: %04o" % [ mode ] if $DEBUG

		if (mode & 0200).nonzero?
			debug_msg "Using read/write flags"
			envflags = EnvFlagsRW
			dbflags = BDB::CREATE
		else
			debug_msg "Using readonly flags"
			envflags = EnvFlagsRO
			dbflags = 0
		end

		debug_msg "Env flags are: %0s, dbflags are %0s" %
			[ envflags.to_s(2), dbflags.to_s(2) ]

		begin
			@env = BDB::Env::new( dbenv, envflags, EnvOptions )
			@indexDb = @env.open_db( BDB::BTREE, "index", nil, dbflags, mode )
			@dataDb = @env.open_db( BDB::BTREE, "data", nil, dbflags, mode )
			@morphDb = @env.open_db( BDB::BTREE, "morph", nil, dbflags, mode )
		rescue StandardError => err
			msg = "Error while opening Ruby-WordNet data files: %s" % 
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
	attr_reader :indexDb

	# The handle to the synset data table
	attr_reader :dataDb

	# The handle to the morph table
	attr_reader :morphDb


	### Close the lexicon's database environment
	def close
		@env.close if @env
	end


	### Checkpoint the database. (BerkeleyDB-specific)
	def checkpoint( bytes=0, minutes=0 )
		@env.checkpoint
	end


	### Return a list of archival logfiles that can be removed
	### safely. (BerkeleyDB-specific).
	def archlogs
		return @env.log_archive( BDB::ARCH_ABS )
	end


	### Remove any archival logfiles for the lexicon's database
	### environment. (BerkeleyDB-specific).
	def cleanLogs
		self.archlogs.each {|logfile|
			File::chmod( 0777, logfile )
			File::delete( logfile )
		}
	end


	### Returns an integer of the familiarity/polysemy count for +word+ as a
	### +partOfSpeech+. Note that polysemy can be identified for a given
	### word by counting the synsets returned by #lookupSynsets.
	def familiarity( word, partOfSpeech, polyCount=nil )
		wordkey = self.makeWordKey( word, partOfSpeech )
		return nil unless @indexDb.key?( wordkey )
		@indexDb[ wordkey ].split( WordNet::SubDelimRe ).length
	end


	### Look up sysets (Wordnet::Synset objects) matching +text+ as a
	### +partOfSpeech+, where +partOfSpeech+ is one of +WordNet::Noun+,
	### +WordNet::Verb+, +WordNet::Adjective+, or +WordNet::Adverb+. Without
	### +sense+, #lookupSynsets will return all matches that are a
	### +partOfSpeech+. If +sense+ is specified, only the synset object that
	### matches that particular +partOfSpeech+ and +sense+ is returned.
	def lookupSynsets( word, partOfSpeech, sense=nil )
		wordkey = self.makeWordKey( word, partOfSpeech )
		pos = self.makePos( partOfSpeech )
		synsets = []

		# Look up the index entry, trying first the word as given, and if
		# that fails, trying morphological conversion.
		entry = @indexDb[ wordkey ]
		if entry.nil? && (word = self.morph( word, partOfSpeech ))
			entry = @indexDb[ wordkey ]
		end

		# If the lookup failed both ways, just abort
		return nil unless entry

		# Make synset keys from the entry, narrowing it to just the sense
		# requested if one was specified.
		synkeys = entry.split( SubDelimRe ).collect {|off| "#{off}%#{pos}" }
		if sense
			return lookupSynsetsByKey( synkeys[sense - 1] )
		else
			return [ lookupSynsetsByKey(*synkeys) ].flatten
		end
	end


	### Returns the WordNet::Synset objects corresponding to the +keys+
	### specified. The +keys+ are made up of the target synset's "offset"
	### and syntactic category catenated together with a '%' character.
	def lookupSynsetsByKey( *keys )
		synsets = []

		keys.each {|key|
			raise LookupError, "Failed lookup of synset '#{key}':"\
				"No such synset" unless @dataDb.key?( key )

			data = @dataDb[ key ]
			offset, partOfSpeech = key.split( /%/, 2 )
			synsets << WordNet::Synset::new( self, offset, partOfSpeech, nil, data )
		}

		return *synsets
	end
	alias_method :lookupSynsetsByOffset, :lookupSynsetsByKey


	### Returns a form of +word+ as a part of speech +partOfSpeech+, as
	### found in the WordNet morph files. The #lookupSynsets method perfoms
	### morphological conversion automatically, so a call to #morph is not
	### required.
	def morph( word, partOfSpeech )
		return @morphDb[ self.makeWordKey(word, partOfSpeech) ]
	end


	### Returns the result of looking up +word+ in the inverse of the WordNet
	### morph files. _(This is undocumented in Lingua::Wordnet)_
	def reverseMorph( word )
		@morphDb.invert[ word ]
	end


	### Returns an array of compound words matching +text+.
	def grep( text )
		return [] if text.empty?
		
		words = []
		
		# Grab a cursor into the database and fetch while the key matches
		# the target text
		cursor = @indexDb.cursor
		rec = cursor.set_range( text )
		while /^#{text}/ =~ rec[0]
			words.push rec[0]
			rec = cursor.next
		end
		cursor.close

		return *words
	end


	### Factory method: Creates and returns a new WordNet::Synset object in
	### this lexicon for the specified +word+ and +partOfSpeech+.
	def createSynset( word, partOfSpeech )
		return WordNet::Synset::new( self, '', partOfSpeech, word )
	end
	alias_method :newSynset, :createSynset


	### Store the specified +synset+ (a WordNet::Synset object) in the
	### lexicon. Returns the key of the stored synset.
	def storeSynset( synset )
		strippedOffset = nil
		pos = nil

		# Start a transaction
		@env.begin( BDB::TXN_COMMIT, @dataDb ) do |txn,datadb|

			# If this is a new synset, generate an offset for it
			if synset.offset == 1
				synset.offset =
					(datadb['offsetcount'] = datadb['offsetcount'].to_i + 1)
			end
			
			# Write the data entry
			datadb[ synset.key ] = synset.serialize
				
			# Write the index entries
			txn.begin( BDB::TXN_COMMIT, @indexDb ) do |txn,indexdb|

				# Make word/part-of-speech pairs from the words in the synset
				synset.words.collect {|word| word + "%" + pos }.each {|word|

					# If the index already has this word, but not this
					# synset, add it
					if indexdb.key?( word )
						indexdb[ word ] << SubDelim << synset.offset unless
							indexdb[ word ].include?( synset.offset )
					else
						indexdb[ word ] = synset.offset
					end
				}
			end # transaction on @indexDb
		end # transaction on @dataDB

		return synset.offset
	end


	### Remove the specified +synset+ (a WordNet::Synset object) in the
	### lexicon. Returns the offset of the stored synset.
	def removeSynset( synset )
		# If it's not in the database (ie., doesn't have a real offset),
		# just return.
		return nil if synset.offset == 1

		# Start a transaction on the data table
		@env.begin( BDB::TXN_COMMIT, @dataDb ) do |txn,datadb|

			# First remove the index entries for this synset by iterating
			# over each of its words
			txn.begin( BDB::TXN_COMMIT, @indexDb ) do |txn,indexdb|
				synset.words.collect {|word| word + "%" + pos }.each {|word|

					# If the index contains an entry for this word, either
					# splice out the offset for the synset being deleted if
					# there are more than one, or just delete the whole
					# entry if it's the only one.
					if indexdb.key?( word )
						offsets = indexdb[ word ].
							split( SubDelimRe ).
							reject {|offset| offset == synset.offset}

						unless offsets.empty?
							indexDb[ word ] = newoffsets.join( SubDelim )
						else
							indexDb.delete( word )
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
	def makePos( original )
		return WordNet::Noun if original.nil?
		osym = original.to_s.intern
		return WordNet::SyntacticCategories[ osym ] if
			WordNet::SyntacticCategories.key?( osym )
		return original if SyntacticSymbols.key?( original )
		return nil
	end


	### Make a lexicon key out of the given +word+ and part of speech
	### (+pos+).
	def makeWordKey( word, pos )
		pos = self.makePos( pos )
		word = word.gsub( /\s+/, '_' )
		return "#{word}%#{pos}"
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

