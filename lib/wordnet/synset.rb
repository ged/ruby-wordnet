#!/usr/bin/ruby
# = Name
# 
# Synset - WordNet synonym-set object class
# 
# = Synopsis
# 
#   ss = lexicon.createSynset( "word", WordNet::NOUN )
# 
# = Description
# 
# Instances of this class encapsulate the data for a synonym set ('synset') in a
# Wordnet lexical database. A synonym set is a set of words that are
# interchangeable in some context.
# 
# = Author
#
# This is a port of the Lingua::Wordnet Perl module by Dan Brians. 
# 
# Rubyification by Michael Granger <ged@FaerieMUD.org>
# 
# Copyright (c) 2002 The FaerieMUD Consortium. All rights reserved.
# 
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
# 
# = Version
#
#  $Id: synset.rb,v 1.1 2002/01/04 21:52:22 deveiant Exp $
# 

require "sync"

module WordNet

	##
	# "Synonym set" class - encapsulates the data for a set of words in the
	# lexical database that are interchangeable in some context, and provides
	# methods for accessing its relationships.
	class Synset < Object

		##
		# Class constants
		Version = /([\d\.]+)/.match( %q$Revision: 1.1 $ )[1]
		Rcsid = %q$Id: synset.rb,v 1.1 2002/01/04 21:52:22 deveiant Exp $

		### Protected methods
		protected

		##
		# Create a new Synset object in the specified _lexicon_ for the
		# specified _word_ and part of speech _pos_. If _data_ is specified,
		# initialize the synset's other object data from it. This method
		# shouldn't be called directly: you should use one of the Lexicon
		# object's factory methods: #createSynset, #lookupSynset, or
		# #lookupSynsetByOffset.
		def initialize( lexicon, offset, pos, word=nil, data=nil )
			@lexicon	= lexicon
			@pos		= pos
			@mutex		= Sync.new

			if data
				@offset = offset
				@filenum, @wordlist, @pointerlist, @frameslist, @gloss = data.split( Regexp.escape WordNet::DELIM )
			else
				@offset = "1%#{pos}"
				@wordlist = word ? word : ''
				@filenum, @pointerlist, @frameslist, @gloss = [''] * 4
			end
		end

		##
		# Define a group of pointer methods based on _symbol_ that will fetch,
		# add, and delete pointer synsets of the type indicated by
		# pointerTypeConst.
		def Synset.def_pointer_methods( symbol, pointerType, fetchOnly=false )
			name = symbol.id2name
			ptype = Regexp.escape( pointerType )

			# $stderr.puts( "Autogenerating code for #{name} (#{ptype})" )

			# Define a fetch method for the pointer type
			code = %Q{
				def #{name}
					self.fetchSynsetPointers( '#{ptype}' )
				end
			}

			# $stderr.puts( "Fetch code is: #{code}." )
			eval( code )

			# If this isn't a fetch-only method, define an add* and delete*
			# method, too.
			unless fetchOnly
				name[ 0,1 ] = name[ 0,1 ].upcase

				code = %Q{
					def #{name}=( *synsets )
						self.setSynsetPointers( '#{ptype}', *synsets )
					end

					def add#{name}( *synsets )
						self.addSynsetPointers( '#{ptype}', *synsets )
					end

					def delete#{name}( *synsets )
						self.deleteSynsetPointers( '#{ptype}', *synsets )
					end
				}
				# $stderr.puts( "Add/delete code is: #{code}" )
				eval( code )
			end
		end


		### Public methods
		public

		##
		# Accessor for raw synset data member
		attr_accessor :lexicon, :pos, :offset, :filenum, :wordlist, :pointerlist, :frameslist, :gloss

		##
		# Returns the words in this synset's wordlist as an +Array+
		def words
			@mutex.synchronize( Sync::SH ) {
				@wordlist.split( Regexp.escape WordNet::SUBDELIM )
			}
		end

		##
		# Set the words in this synset's wordlist to _newWords_
		def words=( *newWords )
			@mutex.synchronize( Sync::EX ) {
				@wordlist = newWords.join( WordNet::SUBDELIM )
			}
		end

		##
		# Add the specified _newWords_ to this synset's wordlist. Alias:
		# +add_words+.
		def addWords( *newWords )
			@mutex.synchronize( Sync::EX ) {
				self.words |= newWords
			}
		end
		alias :add_words :addWords

		##
		# Delete the specified _oldWords_ from this synset's wordlist. Alias:
		# +delete_words+.
		def deleteWords( *oldWords )
			@mutex.synchronize( Sync::EX ) {
				self.words -= oldWords
			}
		end
		alias :delete_words :deleteWords

		##
		# Returns the pointers in this synset's pointerlist as an +Array+
		def pointers
			@mutex.synchronize( Sync::SH ) {
				@pointerlist.split( Regexp.escape WordNet::SUBDELIM )
			}
		end

		##
		# Set the pointers in this synset's pointerlist to _newPointers_
		def pointers=( *newPointers )
			@mutex.synchronize( Sync::EX ) {
				@pointerlist = newPointers.join( WordNew::SUBDELIM )
			}
		end

		##
		# Add the specified _newPointers_ to this synset's pointerlist.
		def addPointers( *newPointers )
			@mutex.synchronize( Sync::EX ) {
				self.pointers |= newPointers
			}
		end
		alias :add_words :addWords

		##
		# Delete the specified _oldPointers_ from this synset's pointerlist.
		def deletePointers( *oldPointers )
			@mutex.synchronize( Sync::EX ) {
				self.pointers -= oldPointers
			}
		end

		##
		# Return the synset as a string. Alias: +overview+.
		def to_s
			@mutex.synchronize( Sync::SH ) {
				wordlist = self.words.join(", ").gsub( /%\d/, '' ).gsub( /_/, ' ' )
				return "#{wordlist} -- (#{self.gloss})"
			}
		end
		alias :overview :to_s

		##
		# Writes any changes made to the object to the database and updates all
		# affected synset data and indexes. If the object passes out of scope
		# before #write is called, the changes are lost.
		def write
			@mutex.synchronize( Sync::EX ) {
				self.lexicon.storeSynset( self )
			}
		end

		##
		# Returns the synset's data in a form suitable for storage in the
		# lexicon's database. Raises an exception if the synset hasn't yet been
		# assigned an offset.
		def serialize
			@mutex.synchronize( Sync::SH ) {
				return [
					@filenum,
					@wordlist,
					@pointerlist,
					@frameslist,
					@gloss
				].join( WordNet::DELIM )
			}
		end


		##
		# Auto-generate synset pointer methods for the various types
		def_pointer_methods :antonyms,		WordNet::ANTONYM
		def_pointer_methods :hypernyms,		WordNet::HYPERNYM
		def_pointer_methods :entailment,	WordNet::ENTAILMENT
		def_pointer_methods :hyponyms,		WordNet::HYPONYM
		def_pointer_methods :causes,		WordNet::CAUSE
		def_pointer_methods :verbgroups,	WordNet::VERBGROUP
		def_pointer_methods :similarTo,		WordNet::SIMILARTO
		def_pointer_methods :participles,	WordNet::PARTICIPLE
		def_pointer_methods :pertainyms,	WordNet::PERTAINYM
		def_pointer_methods :attributes,	WordNet::ATTRIBUTE
		def_pointer_methods :derivedFrom,	WordNet::DERIVEDFROM
		def_pointer_methods :seeAlso,		WordNet::SEEALSO
		def_pointer_methods :functions,		WordNet::FUNCTION

		##
		# Meronym synset pointers
		def_pointer_methods :allMeronyms,		WordNet::MERONYM, true # Fetch-only
		alias :meronyms :allMeronyms
		def_pointer_methods :memberMeronyms,	WordNet::MEMBER_MERONYM
		def_pointer_methods :stuffMeronyms,		WordNet::STUFF_MERONYM
		def_pointer_methods :potionMeronyms,	WordNet::PORTION_MERONYM
		def_pointer_methods :componentMeronyms,	WordNet::COMPONENT_MERONYM
		def_pointer_methods :featureMeronyms,	WordNet::FEATURE_MERONYM
		def_pointer_methods :phaseMeronyms,		WordNet::PHASE_MERONYM
		def_pointer_methods :placeMeronyms,		WordNet::PLACE_MERONYM
		
		##
		# Holonym synset pointers
		def_pointer_methods :allHolonyms,		WordNet::HOLONYM, true # Fetch-only
		alias :holonyms :allHolonyms
		def_pointer_methods :memberHolonyms,	WordNet::MEMBER_HOLONYM
		def_pointer_methods :stuffHolonyms,		WordNet::STUFF_HOLONYM
		def_pointer_methods :portionHolonyms,	WordNet::PORTION_HOLONYM
		def_pointer_methods :componentHolonyms,	WordNet::COMPONENT_HOLONYM
		def_pointer_methods :featureHolonyms,	WordNet::FEATURE_HOLONYM
		def_pointer_methods :phaseHolonyms,		WordNet::PHASE_HOLONYM
		def_pointer_methods :placeHolonyms,		WordNet::PLACE_HOLONYM


		##
		# Return the name of the "lexicographer's file" associated with this
		# synset.
		def lexInfo
			@mutex.synchronize( Sync::SH ) {
				return WordNet::Lexfiles[ self.filenum ]
			}
		end

		##
		# Sets the "lexicographer's file" association for this synset to
		# _id_. The value in _id_ should correspond to one of the values in
		# #WordNet::Lexfiles
		def lexInfo=( id )
			raise ArgumentError "Bad index: Lexinfo id must be within Lexfiles" unless
				WordNet::Lexfiles[id]
			@mutex.synchronize( Sync::EX ) {
				self.filenum = id
			}
		end

		##
		# Returns an +Array+ of verb frame +String+s for the synset.
		def frames
			frarray = self.framelist.split( Regexp.escape WordNet::SUBDELIM )
			verbFrames = []

			@mutex.synchronize( Sync::SH ) {
				frarray.each {|fr|
					fnum, wnum = fr.split(/ /)
					if wnum > 0
						wordtext = " (" + self.words[wnum] + ")"
						verbFrames.push WordNet::VerbSents[ fnum ] + wordtext
					else
						verbFrames.push WordNet::VerbSents[ fnum ]
					end
				}
			}

			return verbFrames
		end



		### Protected methods
		protected

		# Synset pointer functions
		
		##
		# Returns an Array of synset objects for the receiver's pointers of the
		# specified _pointerType_.
		def fetchSynsetPointers( pointerType )
			synsets = []

			@mutex.synchronize( Sync::SH ) {
				self.pointers.each {|ptr|
					if ptr =~ /^#{pointerType}\w*\s(\d+)\%(\w)\s(\d{4})/
						synsets.push @lexicon.lookupSynsetByOffset( "#{$1}%#{$2}" )
					end
				}
			}

			return synsets
		end

		##
		# Sets the receiver's synset pointers for the specified _pointerType_ to
		# the specified _synsets_.
		def setSynsetPointers( pointerType, *synsets )
			raise :UnimplementedError, "This method is not yet implemented."
			# :TODO: Implementation
		end

		##
		# Add the specified _synsets_ (WordNet::Synset objects) to the receiver
		# as _pointerType_ pointers.
		def addSynsetPointers( pointerType, *synsets )
			raise ArgumentError, "No synsets to delete" if synsets.empty?

			@mutex.synchronize( Sync::EX ) {
				newPointers = synsets.collect {|syn| "#{pointerType} #{syn.offset} 0000" }
				self.pointers |= newPointers
			}
		end

		##
		# Remove the specified _synsets_ (WordNet::Synset objects) from the
		# receiver's pointers. If no _synsets_ are specified, removes all
		# pointers of the specified _pointerType_. If no _pointerType_ is
		# specified, removes all pointers.
		def deleteSynsetPointers( pointerType=nil, *synsets )
			oldPointers = []

			@mutex.synchronize( Sync::EX ) {
				if pointerType
					if synsets.empty?
						oldPointers |= self.pointers.find_all {|ptr|
							ptr =~ /^#{pointerType}\s/
						}
					else
						synsets.each {|syn|
							oldPointers |= self.pointers.find_all {|ptr|
								ptr =~ /#{pointerType}\s#{syn.offset}\s\d{4}/
							}
						}
					end

				else
					oldPointers = self.pointers
				end

				self.pointers -= oldPointers
			}
		end
	

	end # class Synset
end # module WordNet

