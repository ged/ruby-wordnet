# 
# WordNet synonym-set object class
# 
# = Synopsis
# 
#   ss = lexicon.lookupSynset( "word", WordNet::NOUN, 1 )
# 
# = Description
# 
# Instances of this class encapsulate the data for a synonym set ('synset') in a
# Wordnet lexical database. A synonym set is a set of words that are
# interchangeable in some context.
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
#  $Id: synset.rb,v 1.2 2002/01/14 13:44:09 deveiant Exp $
# 

require "sync"

module WordNet

	##
	# Synset internal error class
	class SynsetError < StandardError ; end

	##
	# "Synonym set" class - encapsulates the data for a set of words in the
	# lexical database that are interchangeable in some context, and provides
	# methods for accessing its relationships.
	class Synset < Object

		##
		# Class constants
		Version = /([\d\.]+)/.match( %q$Revision: 1.2 $ )[1]
		Rcsid = %q$Id: synset.rb,v 1.2 2002/01/14 13:44:09 deveiant Exp $

		#########
		protected
		#########

		##
		# Create a new Synset object in the specified _lexicon_ for the
		# specified _word_ and _partOfSpeech_. If _data_ is specified,
		# initialize the synset's other object data from it. This method
		# shouldn't be called directly: you should use one of the Lexicon
		# class's factory methods: #createSynset, #lookupSynset, or
		# #lookupSynsetByOffset.
		def initialize( lexicon, offset, partOfSpeech, word=nil, data=nil )
			@lexicon		= lexicon
			@partOfSpeech	= partOfSpeech.to_s
			@mutex			= Sync.new

			if data
				@offset = offset
				@filenum, @wordlist, @pointerlist, @frameslist, @gloss = data.split( Regexp.escape WordNet::DELIM )
			else
				@offset = "1%#{partOfSpeech}"
				@wordlist = word ? word : ''
				@filenum, @pointerlist, @frameslist, @gloss = [''] * 4
			end
		end

		### Synset pointer methods

		##
		# Define a group of pointer methods based on _symbol_ that will fetch,
		# add, and delete pointer synsets of the type indicated by
		# _pointerType_. If _fetchOnly_ is true, create only the 'get'
		def Synset.def_pointer_methods( symbol, pointerType, fetchOnly=false )
			name = symbol.id2name
			ubname = name.gsub( /([a-z])([A-Z])/ ) {|match| $1 + '_' + $2.downcase}
			ptype = Regexp.escape( pointerType )

			$stderr.puts( "Autogenerating code for #{name} (#{ptype})" ) if $DEBUG

			# Define a fetch method for the pointer type
			code = %Q{
				def #{name}
					self.fetchSynsetPointers( '#{ptype}' )
				end
			}

			# If the underbar-style name is different than the camelCased one,
			# provide an alias for the underbarred version.
			unless name == ubname
				code << %Q{
					alias :#{ubname} :#{name} 
				}
			end

			# If this isn't a fetch-only method, define =, add*, and delete*
			# methods, too.
			unless fetchOnly
				casename = name.dup
				casename[ 0,1 ] = casename[ 0,1 ].upcase

				code << %Q{
					def #{name}=( *synsets )
						self.setSynsetPointers( '#{ptype}', *synsets )
					end

					def add#{casename}( *synsets )
						self.addSynsetPointers( '#{ptype}', *synsets )
					end

					def delete#{casename}( *synsets )
						self.deleteSynsetPointers( '#{ptype}', *synsets )
					end
				}

				# Provide underbarred aliases if they're needed
				unless name == ubname
					code << %Q{
						alias :#{ubname}= :#{name}=
						alias :add_#{ubname} :add#{casename}
						alias :delete_#{ubname} :delete#{casename}
					}
				end
			end

			$stderr.puts( "Pointer code is: #{code}" ) if $DEBUG
			eval( code )
		end

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
				@pointerlist = newPointers.join( WordNet::SUBDELIM )
			}
		end

		##
		# Add the specified _newPointers_ to this synset's pointerlist.
		def addPointers( *newPointers )
			@mutex.synchronize( Sync::EX ) {
				self.pointers |= newPointers
			}
		end
		alias :add_pointers :addPointers

		##
		# Delete the specified _oldPointers_ from this synset's pointerlist.
		def deletePointers( *oldPointers )
			@mutex.synchronize( Sync::EX ) {
				self.pointers -= oldPointers
			}
		end
		alias :delete_pointers :deletePointers

		##
		# Returns an Array of synset objects for the receiver's pointers of the
		# specified _pointerType_.
		def fetchSynsetPointers( pointerType )
			synsets = []

			# Iterate over this synset's pointers, looking for ones that match
			# the type we're after. When we find one, we extract its offset and
			# use that to look it up.
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
		# the specified _synsets_. (*Not yet implemented*)
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


		######
		public
		######

		##
		# Attribute accessor
		attr_accessor :lexicon,
			:partOfSpeech,
			:offset,
			:filenum,
			:wordlist,
			:pointerlist,
			:frameslist,
			:gloss

		##
		# Returns true if the receiver and otherSyn are identical according to
		# their offsets.
		def ==( otherSyn )
			return false unless otherSyn.kind_of?( WordNet::Synset )
			return self.offset == otherSyn.offset
		end


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
		# lexicon's database.
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
		# Returns an Array of the coordinate sisters of the receiver.
		def coordinates
			self.hypernyms[0].hyponyms
		end

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

		##
		# Traversal iterator: Iterates depth-first over a particular
		# _pointerType_ of the receiver, and all of the pointed-to synset's
		# pointers. If called with a block, the block is called once for each
		# synset with the _foundSyn_ and its _depth_ in relation to the
		# originating synset as arguments. The first call will be the
		# originating synset with a depth of +0+ unless _includeOrigin_ is
		# +false+. If the _callback_ returns +true+, the traversal is halted,
		# and the methods returns immediately. This method returns an Array of
		# the synsets which were traversed if no block is given, or a flag which
		# indicates whether or not the traversal was interrupted if a block is
		# given.
		def traverse( pointerType, includeOrigin=true )
			raise ArgumentError, "Illegal parameter 1: Must be either a String or a Symbol" unless
				pointerType.kind_of?( String ) || pointerType.kind_of?( Symbol )

			raise ArgumentError, "Synset doesn't support the #{pointerType.to_s} pointer type." unless
				self.respond_to?( pointerType )

			foundSyns = []
			depth = 0
			traversalFunc = nil

			# Build a traversal function which we can call recursively. It'll return
			# the synsets it traverses.
			traversalFunc = Proc.new {|syn,newDepth|

				# Flag to continue traversal
				haltFlag = false

				# Call the block if it exists and we're either past the origin or
				# including it
				if block_given? && (newDepth > 0 || includeOrigin)
					res = yield( syn, newDepth )
					haltFlag = true if res.is_a? TrueClass
				end

				# Make an array for holding sub-synsets we see
				subSyns = [ syn ]

				# Iterate over each synset returned by calling the pointer on the
				# current syn. For each one, we call ourselves recursively, and
				# break out of the iterator with a false value if the block has
				# indicated we should abort by returning a false value.
				unless haltFlag
					syn.send( pointerType ).each {|subSyn|
						subSubSyns, haltFlag = traversalFunc.call( subSyn, newDepth + 1 )
						subSyns.push( *subSubSyns ) unless subSubSyns.empty?
						break if haltFlag
					}
				end

				# return
				[ subSyns, haltFlag ]
			}

			# Call the iterator
			traversedSets, haltFlag =  traversalFunc.call( self, depth )
			
			# If a block was given, just return whether or not the block was halted.
			if block_given?
				return haltFlag

			# If no block was given, return the traversed synsets
			else
				return traversedSets
			end
		end


		##
		# Returns the distance in pointers between the receiver and _otherSynset_
		# using _pointerType_ as the search path.
		def distance( pointerType, otherSynset )
			dist = nil
			self.traverse( pointerType ) {|syn,depth|
				if syn == otherSynset
					dist = depth
					true
				end
			}

			return dist
		end


		##
		# Recursively searches all of the receiver's pointers of the specified
		# _pointerType_ for _otherSynset_, returning +true+ if it is found.
		def search( pointerType, otherSynset )
			self.traverse( pointerType ) {|syn,depth|
				syn == otherSynset
			}
		end


		##
		# Union: Return the least general synset that the receiver and
		# _otherSynset_ have in common as a hypernym, or nil if it doesn't share
		# any.
		def |( otherSyn )

			# Find all of this syn's hypernyms
			hyperSyns = self.traverse( :hypernyms )
			commonSyn = nil

			# Now traverse the other synset's hypernyms looking for one of our
			# own hypernyms.
			otherSyn.traverse( :hypernyms ) {|syn,depth|
				if hyperSyns.find {|s| s == syn}
					commonSyn = syn
					true
				end
			}

			return commonSyn
		end


	end # class Synset
end # module WordNet

