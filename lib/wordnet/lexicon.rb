#!/usr/bin/ruby
#
# WordNet Lexicon object class
# 
# == Synopsis
# 
#   lexicon = WordNet::Lexicon.new( dictpath )
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
# Copyright (c) 2002, 2003 The FaerieMUD Consortium. All rights reserved.
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
# $Id: lexicon.rb,v 1.3 2003/08/06 08:07:04 deveiant Exp $
# 

require 'bdb'
require 'sync'

require 'wordnet/constants'
require 'wordnet/synset'

module WordNet

	### Lexicon exception - something has gone wrong in the internals of the
	### lexicon.
	class LexiconError < StandardError ; end

	### Lookup error - the object being looked up either doesn't exist or is
	### malformed
	class LookupError < StandardError ; end

	### WordNet lexicon class - abstracts access to the WordNet lexical
	### databases, and provides factory methods for looking up and creating new
	### WordNet::Synset objects.
	class Lexicon

		# Class constants
		Version = /([\d\.]+)/.match( %q{$Revision: 1.3 $} )[1]
		Rcsid = %q$Id: lexicon.rb,v 1.3 2003/08/06 08:07:04 deveiant Exp $

		#############################################################
		###	B E R K E L E Y D B   C O N F I G U R A T I O N
		#############################################################

		# The path to the WordNet BerkeleyDB Env. It lives in the directory that
		# this module is in.
		DbFile = File::join( File::dirname(__FILE__), "lexicon" )

		# Options for the creation of the Env object
		EnvOptions = {
			:set_timeout	=> 50,
			:set_lk_detect	=> 1,
			:set_verbose	=> false,
		}

		# Flags for the creation of the Env object
		EnvFlags = BDB::CREATE|BDB::INIT_TRANSACTION|BDB::RECOVER

		# Table names (actually database names in BerkeleyDB)
		TableNames = {
			:index => "index",
			:data => "data",
			:morph => "morph",
		}



		#############################################################
		###	I N S T A N C E   M E T H O D S
		#############################################################

		### Create a new WordNet::Lexicon object.
		def initialize
			Dir::mkdir( DbFile ) unless File::directory?( DbFile )

			@env = BDB::Env::new( DbFile, EnvFlags, EnvOptions )
			@indexDb = @env.open_db( BDB::BTREE, "index", nil, BDB::CREATE, 0666 )
			@dataDb = @env.open_db( BDB::BTREE, "data", nil, BDB::CREATE, 0666 )
			@morphDb = @env.open_db( BDB::BTREE, "morph", nil, BDB::CREATE, 0666 )
		end


		######
		public
		######

		# The BDB::Env object which contains the wordnet lexicon's databases.
		attr_reader :env

		# The handle to the index table
		attr_reader :indexDb
		alias_method :index_db, :indexDb

		# The handle to the synset data table
		attr_reader :dataDb
		alias_method :data_db, :dataDb

		# The handle to the morph table
		attr_reader :morphDb
		alias_method :morph_db, :morphDb


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
		### +partOfSpeech+. Given a third value +polyCount+, sets the polysemy
		### count for +word+ as a +partOfSpeech+. In this module, this is a
		### value which must be updated by the user, and is not automatically
		### modified. This makes it useful for recording familiarity or
		### frequency counts outside of the Wordnet lexicons. Note that polysemy
		### can be identified for a given word by counting the synsets returned
		### by #lookupSynsets.
		def familiarity( word, partOfSpeech, polyCount=nil )
			ikey = "#{word}%#{partOfSpeech}"
			return nil unless @indexDb.key?( ikey )
			@indexDb[ ikey ].split( WordNet::DelimRe ).first.to_i
		end


		### Look up sysets (Wordnet::Synset objects) matching +text+ as a
		### +partOfSpeech+, where +partOfSpeech+ is one of +WordNet::Noun+,
		### +WordNet::Verb+, +WordNet::Adjective+, or +WordNet::Adverb+. Without
		### +sense+, #lookupSynsets will return all matches that are a
		### +partOfSpeech+. If +sense+ is specified, only the synset object that
		### matches that particular +partOfSpeech+ and +sense+ is returned.
		def lookupSynsets( word, partOfSpeech, sense=nil )
			wordkey = "#{word}%#{partOfSpeech}"
			synsets = []

			# Look up the index entry, trying first the word as given, and if
			# that fails, trying morphological conversion.
			entry = @indexDb[ wordkey ]
			if entry.nil? && (word = self.morph( word, partOfSpeech ))
				entry = @indexDb[ wordkey ]
			end

			# If the lookup failed both ways, just abort
			return nil unless entry

			# Get the offsets from the entry, narrowing it to just the sense
			# requested if one was specified.
			offsets = entry.split( WordNet::DelimRe )[1].
				split( WordNet::SubDelimRe ).
				collect {|off| "#{off}%#{partOfSpeech}" }

			if sense
				return lookupSynsetsByOffset( offsets[sense - 1] )
			else
				return [ lookupSynsetsByOffset(*offsets) ].flatten
			end
		end
		alias_method :lookup_synsets, :lookupSynsets


		### Returns the WordNet::Synset objects corresponding to the +offsets+
		### specified.
		def lookupSynsetsByOffset( *offsets )
			synsets = []

			offsets.each {|offset|
				raise LookupError, "Failed lookup of synset '#{offset}':"\
					"No such synset" unless @dataDb.key?( offset )

				data = @dataDb[ offset ]
				partOfSpeech = offset[-1,1]
				synsets << Synset::new( self, offset, partOfSpeech, nil, data )
			}

			return *synsets
		end
		alias_method :lookup_synsets_by_offset, :lookupSynsetsByOffset


		### Returns a form of +word+ as a part of speech +partOfSpeech+, as
		### found in the WordNet morph files. The #lookupSynsets method perfoms
		### morphological conversion automatically, so a call to #morph is not
		### required.
		def morph( word, partOfSpeech )
			return @morphDb[ "#{word}%#{partOfSpeech}" ]
		end


		### Returns the result of looking up +word+ in the inverse of the WordNet
		### morph files. _(This is undocumented in Lingua::Wordnet)_
		def reverseMorph( word )
			@morphDb.invert[ word ]
		end
		alias_method :reverse_morph, :reverseMorph


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
			return Synset::new( self, '', partOfSpeech, word )
		end
		alias_method :new_synset, :createSynset
		alias_method :newSynset, :createSynset


		### Store the specified +synset+ (a WordNet::Synset object) in the
		### lexicon. Returns the offset of the stored synset.
		def storeSynset( synset )
			strippedOffset = nil
			partOfSpeech = synset.partOfSpeech

			# Start a transaction
			@env.begin( BDB::TXN_COMMIT, @dataDb ) do |txn,datadb|

				# If this is a new synset, generate an offset for it
				if /^1%(\w)$/ =~ synset.offset
					partOfSpeech = $1
					strippedOffset =
						(datadb['offsetcount'] = datadb['offsetcount'].to_i + 1)
					synset.offset = strippedOffset + "%#{partOfSpeech}"
				else
					strippedOffset = synset.offset.gsub( /%\w/, '' )
				end
				
				# Write the data entry
				datadb[ synset.offset ] = synset.serialize
					
				# Write the index entries
				txn.begin( BDB::TXN_COMMIT, @indexDb ) do |txn,indexdb|
					synset.words.collect {|word| word + "%" + partOfSpeech }.
						each {|word|

						# If the index already has this word, but not this
						# synset, add it
						if indexdb.key?( word )
							unless indexdb[ word ].include?( strippedOffset )
								indexdb[ word ] << WordNet::SubDelim <<
									strippedOffset
							end
						else
							indexdb[ word ] = "1" << WordNet::Delim <<
								strippedOffset
						end
					}
				end # transaction on @indexDb
			end # transaction on @dataDB

			return synset.offset
		end
		alias_method :store_synset, :storeSynset

	end # class Lexicon
end # module WordNet

