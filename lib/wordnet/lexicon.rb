#
# WordNet lexicon object class
# 
# = Synopsis
# 
#   lexicon = WordNet::Lexicon.new( dictpath )
# 
# = Description
# 
# Instances of this class abstract access to the various databases of the
# WordNet lexicon. It can be used to look up and search for +WordNet::Synset+s.
# 
# = Author
# 
# Michael Granger <ged@FaerieMUD.org>
# 
# Copyright (c) 2002 The FaerieMUD Consortium. All rights reserved.
# 
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
# 
# Much of this code was inspired by/ported from the Lingua::Wordnet Perl module
# by Dan Brian.
# 
# = Version
#
# $Id: lexicon.rb,v 1.2 2002/01/14 13:41:27 deveiant Exp $
# 

require "bdb"
require "sync"

module WordNet

	##
	# Lexicon exception - something has gone wrong in the internals of the
	# lexicon.
	class LexiconError < StandardError ; end

	##
	# Lookup error - the object being looked up either doesn't exist or is
	# malformed
	class LookupError < StandardError ; end

	##
	# Locking error - An attempt was made to write to a lexicon without first
	# unlocking it.
	class LockError < StandardError ; end

	##
	# WordNet lexicon class - abstracts access to the WordNet lexical databases,
	# and provides factory methods for looking up and creating new
	# WordNet::Synset objects.
	class Lexicon < Object

		##
		# Class constants
		Version = /([\d\.]+)/.match( %q$Revision: 1.2 $ )[1]
		Rcsid = %q$Id: lexicon.rb,v 1.2 2002/01/14 13:41:27 deveiant Exp $

		### Public methods
		public

		##
		# Create a new WordNet::Lexicon object which will use the databases
		# in the directory specified by _dictPath_.
		def initialize( dictPath=WordNet::DICTDIR )
			@dictPath	= dictPath
			@locked		= true
			@mutex		= Sync.new

			@indexDb	= BDB::Btree.open( "#{@dictPath}/lingua_wordnet.index", nil, BDB::CREATE, 0666 ) or
				raise RuntimeError, "Unable to load #{@dictPath}/lingua_wordnet.index: Unknown error."
			@dataDb		= BDB::Btree.open( "#{@dictPath}/lingua_wordnet.data", nil, BDB::CREATE, 0666 ) or
				raise RuntimeError, "Unable to load #{@dictPath}/lingua_wordnet.data: Unknown error."
			@morphDb	= BDB::Btree.open( "#{@dictPath}/lingua_wordnet.morph", nil, BDB::CREATE, 0666 ) or
				raise RuntimeError, "Unable to load #{@dictPath}/lingua_wordnet.morph: Unknown error."

			@active = true
		end

		##
		# Close the databases if they're currently opened.
		def close
			return false unless @active
			@mutex.synchronize( Sync::EX ) {
				@indexDb.close
				@dataDb.close
				@morphDb.close
				@active = false
			}
		end

		##
		# Returns +true+ if the receiver is active (ie., still has open database
		# connections)
		def active?
			@active
		end

		##
		# Lock the lexicon to prohibit changes (default).
		def lock
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			@mutex.synchronize( Sync::EX ) {
				@locked = true
			}
		end

		##
		# Unlock the lexicon to allow files to be written when data is
		# added/edited/deleted. If a block is given, it will be called with the
		# lexicon unlocked, and then be locked again when the block exits.
		def unlock
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			if block_given?
				@mutex.synchronize( Sync::EX ) {
					@locked = false
					yield
					@locked = true
				}
			else
				@mutex.synchronize( Sync::EX ) {
					@locked = false
				}
			end
		end

		##
		# Returns true if the lexicon is currently preventing writes.
		def locked?
			@locked
		end

		##
		# Returns an integer of the familiarity/polysemy count for _word_ as a
		# _partOfSpeech_. Given a third value _polyCount_, sets the polysemy count for
		# _word_ as a _partOfSpeech_. In this module, this is a value which must be
		# updated by the user, and is not automatically modified. This makes it
		# useful for recording familiarity or frequency counts outside of the
		# Wordnet lexicons. Note that polysemy can be identified for a given
		# word by counting the synsets returned by #lookupSynsets.
		def familiarity( word, partOfSpeech, polyCount=nil )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			@mutex.synchronize( Sync::SH ) {
				@indexDb[ "#{word}%#{partOfSpeech}" ].split(Regexp.escape WordNet::DELIM)[0].to_i
			}
		end


		##
		# Look up sysets (Wordnet::Synset objects) matching _text_ as a
		# _partOfSpeech_, where _partOfSpeech_ is one of +WordNet::NOUN+,
		# +WordNet::VERB+, +WordNet::ADJECTIVE+, or +WordNet::ADVERB+. Without
		# _sense_, #lookupSynsets will return all matches that are a
		# _partOfSpeech_ as an Array object. If _sense_ is specified, only the
		# synset object that matches that particular _partOfSpeech_ and _sense_
		# is returned.
		def lookupSynsets( word, partOfSpeech, sense=nil )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			poly, offsets = nil, nil

			test = :test

			# Serialize access to the database
			@mutex.synchronize( Sync::SH ) {

				# If the database doesn't have the specified word, try to morph
				# it and look it up again.
				if ! @indexDb.has_key?( "#{word}%#{partOfSpeech}" )
					word = self.morph( word, partOfSpeech )
					if ! word || ! @indexDb.has_key?( "#{word}%#{partOfSpeech}" )
						return sense ? nil : []
					end
				end

				poly, offsets = @indexDb[ "#{word}%#{partOfSpeech}" ].split( Regexp.escape WordNet::DELIM )
			}

			# If we got a sense, just return that particular synset
			if sense
				offset = offsets.split( Regexp.escape WordNet::SUBDELIM )[ sense - 1 ] + "%#{partOfSpeech}"
				return lookupSynsetByOffset( offset )

			# Otherwise, return all of 'em
			else
				synsets = []
				offsets.split( Regexp.escape WordNet::SUBDELIM ).each {|off|
					synsets.push lookupSynsetByOffset( "#{off}%#{partOfSpeech}" )
				}
				return synsets
			end
		end
		alias :lookup_synset :lookupSynsets
		alias :lookupSynset :lookupSynsets

		##
		# Returns a WordNet::Synset object with the _offset_ specified.
		def lookupSynsetByOffset( offset )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			@mutex.synchronize( Sync::SH ) {
				raise LookupError, "Failed lookup of synset '#{offset}': No such synset" unless
					@dataDb.has_key?( offset )

				data = @dataDb[ offset ]
				partOfSpeech = offset[-1,1]
				return WordNet::Synset::new( self, offset, partOfSpeech, nil, data )
			}
		end
		alias :lookup_synset_offset :lookupSynsetByOffset
		alias :lookupSynsetOffset :lookupSynsetByOffset

		##
		# Returns a form of _word_ as a part of speech _partOfSpeech_, as found in the
		# WordNet morph files. The #lookupSynsets method perfoms morphological
		# conversion automatically, so a call to #morph is not required.
		def morph( word, partOfSpeech )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			@mutex.synchronize( Sync::SH ) {
				return @morphDb[ "#{word}%#{partOfSpeech}" ]
			}
		end

		##
		# Returns the result of looking up _word_ in the inverse of the WordNet
		# morph files. _(This is undocumented in Lingua::Wordnet)_
		def reverseMorph( word )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			@mutex.synchronize( Sync::SH ) {
				return @morphDb.invert[ word ]
			}
		end
		alias :reverse_morph :reverseMorph

		##
		# Returns an array of compound words matching _text_.
		def grep( text )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			return [] if text.empty?
			
			words = []
			
			# Grab a cursor into the database and fetch while the key matches
			# the target text
			@mutex.synchronize( Sync::SH ) {
				cursor = @indexDb.cursor
				rec = cursor.set_range( text )
				while rec[0] =~ /^#{text}/
					words.push rec[0]
					rec = cursor.next
				end
			}

			return words
		end

		##
		# Factory method: Creates and returns a new WordNet::Synset object in
		# this lexicon for the specified _word_ and _partOfSpeech_.
		def createSynset( word, partOfSpeech )
			raise LexiconError, "Can't reuse inactive lexicon object" unless @active
			return WordNet::Synset::new( self, '', partOfSpeech, word )
		end
		alias :new_synset :createSynset
		alias :newSynset :createSynset

		##
		# Store the specified WordNet::Synset object in the lexicon. Returns the
		# offset of the stored synset.
		def storeSynset( synset )
			raise LockError, "Cannot write to a locked lexicon." if @locked

			strippedOffset = nil
			partOfSpeech = synset.partOfSpeech

			@mutex.synchronize( Sync::EX ) {
			
				# If this is a new synset, generate an offset for it
				if synset.offset =~ /^1%(\w)$/
					partOfSpeech = $1
					@dataDb['offsetcount'] = @dataDb['offsetcount'].to_i + 1
					strippedOffset = @dataDb['offsetcount']
					synset.offset = strippedOffset + "%#{partOfSpeech}"
				else
					strippedOffset = synset.offset.gsub( /%\w/, '' )
				end
				
				# Write the data entry
				@dataDb[ synset.offset ] = synset.serialize
					
				# Write the index entries
				synset.words.collect {|word| word + "%" + partOfSpeech }.each {|word|

					# If the index already has this word, but not this synset, add it
					if @indexDb.has_key?( word )
						unless @indexDb[ word ] =~ strippedOffset
							@indexDb[ word ] << WordNet::SUBDELIM << strippedOffset
						end
					else
						@indexDb[ word ] = "1" << WordNet::DELIM << strippedOffset
					end
				}
			}

			return synset.offset
		end


	end # class Lexicon
end # module WordNet

