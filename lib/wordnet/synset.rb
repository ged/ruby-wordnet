#!/usr/bin/ruby
# 
# WordNet synonym-set object class
# 
# == Synopsis
# 
#   ss = lexicon.lookupSynset( "word", WordNet::Noun, 1 )
#	puts "Definition: %s" % ss.gloss
#   coords = ss.coordinates
#
# == Description
# 
# Instances of this class encapsulate the data for a synonym set ('synset') in a
# Wordnet lexical database. A synonym set is a set of words that are
# interchangeable in some context.
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
#  $Id: synset.rb,v 1.4 2003/09/03 06:41:39 deveiant Exp $
# 

require 'sync'
require 'wordnet/constants'

module WordNet

	### Synset internal error class
	class SynsetError < StandardError ; end

	### "Synonym set" class - encapsulates the data for a set of words in the
	### lexical database that are interchangeable in some context, and provides
	### methods for accessing its relationships.
	class Synset
		include WordNet::Constants
		include CrossCase if defined?( CrossCase )

		# CVS version tag
		Version = /([\d\.]+)/.match( %q{$Revision: 1.4 $} )[1]

		# CVS id tag
		Rcsid = %q$Id: synset.rb,v 1.4 2003/09/03 06:41:39 deveiant Exp $

		# The "pointer" type that encapsulates relationships between one synset
		# and another.
		class Pointer
			include WordNet::Constants
			include CrossCase if defined?( CrossCase )

			#########################################################
			###	C L A S S   M E T H O D S
			#########################################################

			### Make an Array of WordNet::Synset::Pointer objects out of the
			### given +pointerList+. The pointerlist is a string of pointers
			### delimited by Constants::SubDelim. Pointers are in the form:
			###   "<pointer_symbol> <synset_offset>%<pos> <source/target>"
			def self::parse( pointerString )
				type, offsetPos, ptrNums = pointerString.split(/\s+/)
				offset, pos = offsetPos.split( /%/, 2 )
				new( type, offset, pos, ptrNums[0,2], ptrNums[2,2] )
			end


			#########################################################
			###	I N S T A N C E   M E T H O D S
			#########################################################

			### Create a new synset pointer with the given arguments. The
			### +ptrType+ is the type of the link between synsets, and must be
			### either a key or a value of WordNet::Constants::PointerTypes. The
			### +offset+ is the unique identifier of the target synset, and
			### +pos+ is its part-of-speech, which must be either a key or value
			### of WordNet::Constants::SyntacticCategories. The +sourceWn+ and
			### +targetWn+ are numerical values which distinguish lexical and
			### semantic pointers. +sourceWn+ indicates the word number in the
			### current (source) synset, and +targetWn+ indicates the word
			### number in the target synset. If both are 0 (the default) it
			### means that the pointer type of the pointer represents a semantic
			### relation between the current (source) synset and the target
			### synset indicated by +offset+.
			def initialize( type, offset, pos=Noun, sourceWn=0, targetWn=0 )

				# Allow type = '!', 'antonym', or :antonym. Also handle
				# splitting of :memberMeronym and '%m' into their correct
				# type/subtype parts.
				@type = @subtype = nil
				if type.to_s.length == 1
					@type = PointerSymbols[ type[0,1] ]
				elsif type.to_s.length == 2
					@type = PointerSymbols[ type[0,1] ]
					@subtype = PointerSubTypes[ @type ].index( type )
				else
					if PointerTypes.key?( type.to_s.intern )
						@type = type.to_s.intern
					elsif /([a-z]+)([A-Z][a-z]+)/ =~ type.to_s
						subtype, maintype = $1, $2.downcase
						@type = maintype.intern if
							PointerTypes.key?( maintype.intern )
						@subtype = subtype.intern
					end
				end
				raise ArgumentError, "No such pointer type %p" % type if
					@type.nil?

				# Allow pos = 'n', 'noun', or :noun
				@partOfSpeech = nil
				if pos.to_s.length == 1
					@partOfSpeech = SyntacticSymbols[ pos ]
				else
					@partOfSpeech = pos.to_s.intern if
						SyntacticCategories.key?( pos.to_s.intern )
				end
				raise ArgumentError, "No such part of speech %p" % pos if
					@partOfSpeech.nil?

				# Other attributes
				@offset		= offset
				@sourceWn	= sourceWn
				@targetWn	= targetWn
			end


			######
			public
			######

			# The type of the pointer. Will be one of the keys of
			# WordNet::PointerTypes (e.g., :meronym).
			attr_accessor :type

			# The subtype of the pointer, if any. Will be one of the keys of one
			# of the hashes in PointerSubTypes (e.g., :portion).
			attr_accessor :subtype

			# The offset of the target synset
			attr_accessor :offset

			# The part-of-speech of the target synset. Will be one of the keys
			# of WordNet::SyntacticCategories.
			attr_accessor :partOfSpeech

			# The word number in the source synset
			attr_accessor :sourceWn

			# The word number in the target synset
			attr_accessor :targetWn


			### Return the Pointer as a human-readable String suitable for
			### debugging.
			def inspect
				"#<%s:0x%08x %s %s>" % [
					self.class.name,
					self.object_id,
					@subtype ? "#@type(#@subtype)" : @type,
					self.synset,
				]
			end


			### Return the synset key of the target synset (i.e.,
			### <offset>%<pos symbol>).
			def synset
				self.offset + "%" + self.pos
			end


			### Return the syntactic category symbol for this pointer
			def pos
				return SyntacticCategories[ @partOfSpeech ]
			end


			### Return the pointer type symbol for this pointer
			def typeSymbol
				unless @subtype
					return PointerTypes[ @type ]
				else
					return PointerSubTypes[ @type ][ @subtype ]
				end
			end


			### Comparison operator. Pointer are equivalent if they point at the
			### same synset and are of the same type.
			def ==( other )
				return false unless other.is_a?( self.class )
				other.offset == self.offset &&
					other.type == self.type
			end


			### Return the pointer in its stringified form.
			def to_s
				"%s %d%%%s %02x%02x" % [ 
					ptr.typeSymbol,
					ptr.offset,
					ptr.posSymbol,
					ptr.sourceWn,
					ptr.targetWn,
				]
			end
		end # class Pointer


		#############################################################
		###	C L A S S   M E T H O D S
		#############################################################

		### Define a group of pointer methods based on +symbol+ that will fetch,
		### add, and delete pointer synsets of the type indicated by +type+. If
		### the given +type+ has subtypes (according to
		### WordNet::PointerSubTypes), accessors/mutators for the subtypes will
		### be generated as well.
		def self::def_pointer_methods( symbol, type ) # :nodoc:
			name = symbol.id2name
			casename = name.dup
			casename[ 0,1 ] = casename[ 0,1 ].upcase

			# Define the accessor
			define_method( name.intern ) {
				self.fetchSynsetPointers( type )
			}

			# If the pointer is one that has subtypes, make the variants list
			# out of the subtypes. If it doesn't have subtypes, make the only
			# variant nil, which will cause the mutators to be defined for the
			# main pointer type.
			if PointerSubTypes.key?( type )
				variants = PointerSubTypes[ type ].keys
			else
				variants = [nil]
			end

			# Define a set of methods for each variant, or for the main method
			# if the variant is nil.
			variants.each {|var|
				varname = var ? var.to_s + casename : name
				varcname = var ? var.to_s.capitalize + casename : casename

				define_method( varname ) {
					self.fetchSynsetPointers( type, var )
				} unless var.nil?
				define_method( "#{varname}=" ) {|*synsets|
					self.setSynsetPointers( type, synsets, var )
				}
			}
		end


		#############################################################
		###	I N S T A N C E   M E T H O D S
		#############################################################

		### Create a new Synset object in the specified +lexicon+ for the
		### specified +word+ and +partOfSpeech+. If +data+ is specified,
		### initialize the synset's other object data from it. This method
		### shouldn't be called directly: you should use one of the Lexicon
		### class's factory methods: #createSynset, #lookupSynsets, or
		### #lookupSynsetsByOffset.
		def initialize( lexicon, offset, pos, word=nil, data=nil )
			@lexicon		= lexicon or
				raise ArgumentError, "%p is not a WordNet::Lexicon" % lexicon
			@partOfSpeech	= SyntacticSymbols[ pos ] or
				raise ArgumentError, "No such part of speech %p" % pos
			@mutex			= Sync::new
			@pointers		= []

			if data
				@offset = offset.to_i
				@filenum, @wordlist, @pointerlist,
					@frameslist, @gloss = data.split( DelimRe )
			else
				@offset = 1
				@wordlist = word ? word : ''
				@filenum, @pointerlist, @frameslist, @gloss = [''] * 4
			end
		end


		######
		public
		######

		# The WordNet::Lexicon that was used to look up this synset
		attr_reader :lexicon

		# The syntactic category of this Synset. Will be one of the keys of
		# WordNet::SyntacticCategories.
		attr_accessor :partOfSpeech

		# The original byte offset of the synset in the data file; acts as the
		# unique identifier (when combined with #partOfSpeech) of this Synset in
		# the database.
		attr_accessor :offset

		# The number corresponding to the lexicographer file name containing the
		# synset. Calling #lexInfo will return the actual filename.
		attr_accessor :filenum

		# The raw list of word/lex_id pairs associated with this synset
		attr_accessor :wordlist

		# The list of raw pointers to related synsets
		attr_accessor :pointerlist

		# The list of raw verb sentence frames for this synset.
		attr_accessor :frameslist
		
		# Definition and/or example sentences for the Synset.
		attr_accessor :gloss


		### Return a human-readable representation of the Synset suitable for
		### debugging.
		def inspect
			pointerCounts = self.pointerMap.collect {|type,ptrs|
				"#{type}s: #{ptrs.length}"
			}.join( ", " )

			%q{#<%s:0x%08x %s (%s): "%s" (%s)>} % [
				self.class.name,
				self.object_id * 2,
				self.words.join(", "),
				self.partOfSpeech,
				self.gloss,
				pointerCounts,
			]
		end


		### Returns the Synset's unique identifier, made up of its offset and
		### syntactic category catenated together with a '%' symbol.
		def key
			"%d%%%s" % [ self.offset, self.pos ]
		end


		### The symbol which represents this synset's syntactic category
		def pos
			return SyntacticCategories[ @partOfSpeech ]
		end


		### Return each of the sentences of the gloss for this synset as an
		### array.
		def glosses
			return self.gloss.split( /\s*;\s*/ )
		end


		### Returns true if the receiver and otherSyn are identical according to
		### their offsets.
		def ==( otherSyn )
			return false unless otherSyn.kind_of?( WordNet::Synset )
			return self.offset == otherSyn.offset
		end



		### Returns an Array of words and/or collocations associated with this
		### synset.
		def words
			@mutex.synchronize( Sync::SH ) {
				self.wordlist.split( SubDelimRe ).collect do |word|
					word.gsub( /_/, ' ' ).sub( /%.*$/, '' )
				end
			}
		end
		alias_method :synonyms, :words


		### Set the words in this synset's wordlist to +newWords+
		def words=( *newWords )
			@mutex.synchronize( Sync::EX ) {
				@wordlist = newWords.join( SubDelim )
			}
		end


		### Add the specified +newWords+ to this synset's wordlist. Alias:
		### +add_words+.
		def addWords( *newWords )
			@mutex.synchronize( Sync::EX ) {
				self.words |= newWords
			}
		end
		alias_method :add_words, :addWords


		### Delete the specified +oldWords+ from this synset's wordlist. Alias:
		### +delete_words+.
		def deleteWords( *oldWords )
			@mutex.synchronize( Sync::EX ) {
				self.words -= oldWords
			}
		end
		alias_method :delete_words, :deleteWords


		### Return the synset as a string. Alias: +overview+.
		def to_s
			@mutex.synchronize( Sync::SH ) {
				wordlist = self.words.join(", ").gsub( /%\d/, '' ).gsub( /_/, ' ' )
				return "#{wordlist} [#{self.partOfSpeech}] -- (#{self.gloss})"
			}
		end
		alias_method :overview, :to_s


		### Writes any changes made to the object to the database and updates all
		### affected synset data and indexes. If the object passes out of scope
		### before #write is called, the changes are lost.
		def store
			@mutex.synchronize( Sync::EX ) {
				self.lexicon.storeSynset( self )
			}
		end
		alias_method :write, :store


		### Removes this synset from the database.
		def remove
			@mutex.synchronize( Sync::EX ) {
				self.lexicon.removeSynset( self )
			}
		end


		### Returns the synset's data in a form suitable for storage in the
		### lexicon's database.
		def serialize
			@mutex.synchronize( Sync::SH ) {
				return [
					@filenum,
					@wordlist,
					@pointerlist,
					@frameslist,
					@gloss
				].join( WordNet::Delim )
			}
		end


		### Auto-generate synset pointer methods for the various types

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :antonyms,		:antonym

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :hypernyms,		:hypernym

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :entailment,	:entailment

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :hyponyms,		:hyponym

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :causes,		:cause

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :verbgroups,	:verbGroup

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :similarTo,		:similarTo

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :participles,	:participle

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :pertainyms,	:pertainym

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :attributes,	:attribute

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :derivedFrom,	:derivedFrom

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :seeAlso,		:seeAlso

		# :def: antonyms() - Returns synsets for the receiver's antonyms.
		# :def: antonyms=( *synsets ) - Set the receiver's antonyms to the given
		# +synsets+.
		def_pointer_methods :functions,		:function

		# Auto-generate types with subtypes


		# :def: meronyms() - Returns synsets for the receiver's meronyms.
		# :def: memberMeronyms() - Returns synsets for the receiver's "member"
		# meronyms (HAS MEMBER relation).
		# :def: memberMeronyms=( *synsets ) - Set the receiver's member meronyms
		# to the given +synsets+.
		# :def: stuffMeronyms() - Returns synsets for the receiver's "stuff"
		# meronyms (IS MADE OUT OF relation).
		# :def: stuffMeronyms=( *synsets ) - Set the receiver's stuff meronyms
		# to the given +synsets+.
		# :def: portionMeronyms() - Returns synsets for the receiver's "portion"
		# meronyms (HAS PORTION relation).
		# :def: portionMeronyms=( *synsets ) - Set the receiver's portion meronyms
		# to the given +synsets+.
		# :def: componentMeronyms() - Returns synsets for the receiver's "component"
		# meronyms (HAS COMPONENT relation).
		# :def: componentMeronyms=( *synsets ) - Set the receiver's component meronyms
		# to the given +synsets+.
		# :def: featureMeronyms() - Returns synsets for the receiver's "feature"
		# meronyms (HAS FEATURE relation).
		# :def: featureMeronyms=( *synsets ) - Set the receiver's feature meronyms
		# to the given +synsets+.
		# :def: phaseMeronyms() - Returns synsets for the receiver's "phase"
		# meronyms (HAS PHASE relation).
		# :def: phaseMeronyms=( *synsets ) - Set the receiver's phase meronyms
		# to the given +synsets+.
		# :def: placeMeronyms() - Returns synsets for the receiver's "place"
		# meronyms (HAS PLACE relation).
		# :def: placeMeronyms=( *synsets ) - Set the receiver's place meronyms
		# to the given +synsets+.
		def_pointer_methods :meronyms,		:meronym

		# :def: holonyms() - Returns synsets for the receiver's holonyms.
		# :def: memberHolonyms() - Returns synsets for the receiver's "member"
		# holonyms (IS A MEMBER OF relation).
		# :def: memberHolonyms=( *synsets ) - Set the receiver's member holonyms
		# to the given +synsets+.
		# :def: stuffHolonyms() - Returns synsets for the receiver's "stuff"
		# holonyms (IS MATERIAL OF relation).
		# :def: stuffHolonyms=( *synsets ) - Set the receiver's stuff holonyms
		# to the given +synsets+.
		# :def: portionHolonyms() - Returns synsets for the receiver's "portion"
		# holonyms (IS A PORTION OF relation).
		# :def: portionHolonyms=( *synsets ) - Set the receiver's portion holonyms
		# to the given +synsets+.
		# :def: componentHolonyms() - Returns synsets for the receiver's "component"
		# holonyms (IS A COMPONENT OF relation).
		# :def: componentHolonyms=( *synsets ) - Set the receiver's component holonyms
		# to the given +synsets+.
		# :def: featureHolonyms() - Returns synsets for the receiver's "feature"
		# holonyms (IS A FEATURE OF relation).
		# :def: featureHolonyms=( *synsets ) - Set the receiver's feature holonyms
		# to the given +synsets+.
		# :def: phaseHolonyms() - Returns synsets for the receiver's "phase"
		# holonyms (IS A PHASE OF relation).
		# :def: phaseHolonyms=( *synsets ) - Set the receiver's phase holonyms
		# to the given +synsets+.
		# :def: placeHolonyms() - Returns synsets for the receiver's "place"
		# holonyms (IS A PLACE IN relation).
		# :def: placeHolonyms=( *synsets ) - Set the receiver's place holonyms
		# to the given +synsets+.
		def_pointer_methods :holonyms,		:holonym

		# :def: members() - Returns synsets for the receiver's topical domain
		# members.
		# :def: categoryMembers() - Returns synsets for the receiver's
		# "category" topical domain members.
		# :def: categoryMembers=( *synsets ) - Set the receiver's category
		# domain members to the given +synsets+.
		# :def: regionMembers() - Returns synsets for the receiver's "region"
		# topical domain members.
		# :def: regionMembers=( *synsets ) - Set the receiver's region domain
		# members to the given +synsets+.
		# :def: usageMembers() - Returns synsets for the receiver's "usage"
		# topical domain members.
		# :def: usageMembers=( *synsets ) - Set the receiver's usage domain
		# members to the given +synsets+.
		def_pointer_methods :members,		:member

		# :def: domains() - Returns synsets for the receiver's topical domains.
		# :def: categoryDomains() - Returns synsets for the receiver's "category"
		# topical domains.
		# :def: categoryDomains=( *synsets ) - Set the receiver's category domains
		# to the given +synsets+.
		# :def: regionDomains() - Returns synsets for the receiver's "region"
		# topical domains.
		# :def: regionDomains=( *synsets ) - Set the receiver's region domains
		# to the given +synsets+.
		# :def: usageDomains() - Returns synsets for the receiver's "usage"
		# topical domains.
		# :def: usageDomains=( *synsets ) - Set the receiver's usage domains
		# to the given +synsets+.
		def_pointer_methods :domains,		:domain


		### Returns an Array of the coordinate sisters of the receiver.
		def coordinates
			self.hypernyms.collect {|syn|
				syn.hyponyms
			}.flatten
		end


		### Return the name of the "lexicographer's file" associated with this
		### synset.
		def lexInfo
			@mutex.synchronize( Sync::SH ) {
				return Lexfiles[ self.filenum.to_i ]
			}
		end


		### Sets the "lexicographer's file" association for this synset to
		### +id+. The value in +id+ should correspond to one of the values in
		### #WordNet::Lexfiles
		def lexInfo=( id )
			raise ArgumentError, "Bad index: Lexinfo id must be within Lexfiles" unless
				Lexfiles[id]
			@mutex.synchronize( Sync::EX ) {
				self.filenum = id
			}
		end


		### Returns an +Array+ of verb frame +String+s for the synset.
		def frames
			frarray = self.frameslist.split( WordNet::SubDelimRe )
			verbFrames = []

			@mutex.synchronize( Sync::SH ) {
				frarray.each {|fr|
					fnum, wnum = fr.split
					if wnum > 0
						wordtext = " (" + self.words[wnum] + ")"
						verbFrames.push VerbSents[ fnum ] + wordtext
					else
						verbFrames.push VerbSents[ fnum ]
					end
				}
			}

			return verbFrames
		end


		### Traversal iterator: Iterates depth-first over a particular
		### +type+ of the receiver, and all of the pointed-to synset's
		### pointers. If called with a block, the block is called once for each
		### synset with the +foundSyn+ and its +depth+ in relation to the
		### originating synset as arguments. The first call will be the
		### originating synset with a depth of +0+ unless +includeOrigin+ is
		### +false+. If the +callback+ returns +true+, the traversal is halted,
		### and the method returns immediately. This method returns an Array of
		### the synsets which were traversed if no block is given, or a flag
		### which indicates whether or not the traversal was interrupted if a
		### block is given.
		def traverse( type, includeOrigin=true )
			raise ArgumentError, "Illegal parameter 1: Must be either a String or a Symbol" unless
				type.kind_of?( String ) || type.kind_of?( Symbol )

			raise ArgumentError, "Synset doesn't support the #{type.to_s} pointer type." unless
				self.respond_to?( type )

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
				subSyns = []
				subSyns.push( syn ) unless newDepth == 0 && !includeOrigin

				# Iterate over each synset returned by calling the pointer on the
				# current syn. For each one, we call ourselves recursively, and
				# break out of the iterator with a false value if the block has
				# indicated we should abort by returning a false value.
				unless haltFlag
					syn.send( type ).each {|subSyn|
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


		### Returns the distance in pointers between the receiver and +otherSynset+
		### using +type+ as the search path.
		def distance( type, otherSynset )
			dist = nil
			self.traverse( type ) {|syn,depth|
				if syn == otherSynset
					dist = depth
					true
				end
			}

			return dist
		end


		### Recursively searches all of the receiver's pointers of the specified
		### +type+ for +otherSynset+, returning +true+ if it is found.
		def search( type, otherSynset )
			self.traverse( type ) {|syn,depth|
				syn == otherSynset
			}
		end


		### Union: Return the least general synset that the receiver and
		### +otherSynset+ have in common as a hypernym, or nil if it doesn't share
		### any.
		def |( otherSyn )

			# Find all of this syn's hypernyms
			hyperSyns = self.traverse( :hypernyms )
			commonSyn = nil

			# Now traverse the other synset's hypernyms looking for one of our
			# own hypernyms.
			otherSyn.traverse( :hypernyms ) {|syn,depth|
				if hyperSyns.include?( syn )
					commonSyn = syn
					true
				end
			}

			return commonSyn
		end


		### Returns the pointers in this synset's pointerlist as an +Array+
		def pointers
			@mutex.synchronize( Sync::SH ) {
				@mutex.synchronize( Sync::EX ) {
					@pointers = @pointerlist.split(SubDelimRe).collect {|pstr|
						Pointer::parse( pstr )
					}
				} if @pointers.empty?
				@pointers
			}
		end


		### Set the pointers in this synset's pointerlist to +newPointers+
		def pointers=( *newPointers )
			@mutex.synchronize( Sync::EX ) {
				@pointerlist = newPointers.collect {|ptr| ptr.to_s}.join( SubDelim )
				@pointers = newPointers
			}
		end


		### Returns the synset's pointers in a Hash keyed by their type.
		def pointerMap
			return self.pointers.inject( {} ) do |hsh,ptr|
				hsh[ ptr.type ] ||= []
				hsh[ ptr.type ] << ptr
				hsh
			end
		end



		#########
		protected
		#########

		### Returns an Array of synset objects for the receiver's pointers of the
		### specified +type+.
		def fetchSynsetPointers( type, subtype=nil )
			synsets = nil

			# Iterate over this synset's pointers, looking for ones that match
			# the type we're after. When we find one, we extract its offset and
			# use that to look it up.
			@mutex.synchronize( Sync::SH ) do
				synsets = self.pointers.
					find_all {|ptr|
						ptr.type == type and
							subtype.nil? || ptr.subtype == subtype
					}.
					collect {|ptr| ptr.synset }.
					collect {|key| @lexicon.lookupSynsetsByKey( key )}
			end

			return synsets.flatten
		end


		### Sets the receiver's synset pointers for the specified +type+ to
		### the specified +synsets+.
		def setSynsetPointers( type, synsets, subtype=nil )
			synsets = [ synsets ] unless synsets.is_a?( Array )
			pmap = self.pointerMap
			pmap[ type ] = synsets
			self.pointers = pmap.values
		end


	end # class Synset
end # module WordNet

