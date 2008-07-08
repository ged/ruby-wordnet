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
#  $Id$
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

		# Subversion ID
		SVNId = %q$Id$

		# Subversion Rev
		SVNRev = %q$Rev$

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
			### of WordNet::Constants::SyntacticCategories. The +source_wn+ and
			### +target_wn+ are numerical values which distinguish lexical and
			### semantic pointers. +source_wn+ indicates the word number in the
			### current (source) synset, and +target_wn+ indicates the word
			### number in the target synset. If both are 0 (the default) it
			### means that the pointer type of the pointer represents a semantic
			### relation between the current (source) synset and the target
			### synset indicated by +offset+.
			def initialize( type, offset, pos=Noun, source_wn=0, target_wn=0 )

				# Allow type = '!', 'antonym', or :antonym. Also handle
				# splitting of compound pointers (e.g., :memberMeronym / '%m')
				# into their correct type/subtype parts.
				@type = @subtype = nil
				if type.to_s.length == 1
					@type = PointerSymbols[ type[0,1] ]
					
				elsif type.to_s.length == 2
					@type = PointerSymbols[ type[0,1] ]
					raise "No known subtypes for '%s'" % [@type] unless
						PointerSubTypes.key?( @type )
					@subtype = PointerSubTypes[ @type ].index( type ) or
						raise "Unknown subtype '%s' for '%s'" %
						[ type, @type ]
						
				else
					if PointerTypes.key?( type.to_sym )
						@type = type.to_sym
					elsif /([a-z]+)([A-Z][a-z]+)/ =~ type.to_s
						subtype, maintype = $1, $2.downcase
						@type = maintype.to_sym if
							PointerTypes.key?( maintype.to_sym )
						@subtype = subtype.to_sym
					end
				end

				raise ArgumentError, "No such pointer type %p" % type if
					@type.nil?

				# Allow pos = 'n', 'noun', or :noun
				@part_of_speech = nil
				if pos.to_s.length == 1
					@part_of_speech = SyntacticSymbols[ pos ]
				else
					@part_of_speech = pos.to_sym if
						SyntacticCategories.key?( pos.to_sym )
				end
				raise ArgumentError, "No such part of speech %p" % pos if
					@part_of_speech.nil?

				# Other attributes
				@offset		= offset
				@source_wn	= source_wn
				@target_wn	= target_wn
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
			attr_accessor :part_of_speech

			# The word number in the source synset
			attr_accessor :source_wn

			# The word number in the target synset
			attr_accessor :target_wn


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
				return SyntacticCategories[ @part_of_speech ]
			end


			### Return the pointer type symbol for this pointer
			def type_symbol
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
					ptr.type_symbol,
					ptr.offset,
					ptr.posSymbol,
					ptr.source_wn,
					ptr.target_wn,
				]
			end
		end # class Pointer


		#############################################################
		###	C L A S S   M E T H O D S
		#############################################################

		### Define a group of pointer methods based on +symbol+ that will fetch,
		### add, and delete pointer synsets of the type indicated. If no pointer
		### type corresponding to the given +symbol+ is found, a variant without
		### a trailing 's' is tried (e.g., 'def_pointer_methods :antonyms' will
		### create methods called #antonyms and #antonyms=, but will fetch
		### pointers of type :antonym). If the pointer type has subtypes
		### (according to WordNet::PointerSubTypes), accessors/mutators for the
		### subtypes will be generated as well.
		def self::def_pointer_methods( symbol ) # :nodoc:
			name = symbol.to_s
			casename = name.dup
			casename[ 0,1 ] = casename[ 0,1 ].upcase
			type = nil
			$stderr.puts '-' * 50, 
				">>> defining pointer methods for %p" % [symbol] if $DEBUG
			
			if PointerTypes.key?( symbol )
                symbol
            elsif PointerTypes.key?( symbol.to_s.sub(/s$/, '').to_sym )
                type = symbol.to_s.sub(/s$/, '').to_sym
            else
                raise ArgumentError, "Unknown pointer type %p" % symbol
            end

			# Define the accessor
			$deferr.puts "Defining reader for #{name}" if $DEBUG
			define_method( name.to_sym ) { self.fetchSynsetPointers(type) }

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
			variants.each do |subtype|
                
				varname = subtype ? subtype.to_s + casename : name
				varcname = subtype ? subtype.to_s.capitalize + casename : casename

                unless subtype.nil?
                    $deferr.puts "Defining reader for #{varname}" if $DEBUG
                    define_method( varname ) {
                        self.fetchSynsetPointers( type, subtype )
                    }
                else
                    $deferr.puts "No subtype for %s (subtype = %p)" %
                        [ varname, subtype ] if $DEBUG
                end
                
                $deferr.puts "Defining mutator for #{varname}" if $DEBUG
				define_method( "#{varname}=" ) {|*synsets|
					self.setSynsetPointers( type, synsets, subtype )
				}
			end
		end


		#############################################################
		###	I N S T A N C E   M E T H O D S
		#############################################################

		### Create a new Synset object in the specified +lexicon+ for the
		### specified +word+ and +part_of_speech+. If +data+ is specified,
		### initialize the synset's other object data from it. This method
		### shouldn't be called directly: you should use one of the Lexicon
		### class's factory methods: #create_synset, #lookup_synsets, or
		### #lookup_synsetsByOffset.
		def initialize( lexicon, offset, pos, word=nil, data=nil )
			@lexicon		= lexicon or
				raise ArgumentError, "%p is not a WordNet::Lexicon" % lexicon
			@part_of_speech	= SyntacticSymbols[ pos ] or
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

		# The syntactic category of this Synset. Will be one of "n" (noun), "v"
		# (verb), "a" (adjective), "r" (adverb), or "s" (other).
		attr_accessor :part_of_speech

		# The original byte offset of the synset in the data file; acts as the
		# unique identifier (when combined with #part_of_speech) of this Synset in
		# the database.
		attr_accessor :offset

		# The number corresponding to the lexicographer file name containing the
		# synset. Calling #lexInfo will return the actual filename. See the
		# "System Description" of wngloss(7WN) for more info about this.
		attr_accessor :filenum

		# The raw list of word/lex_id pairs associated with this synset. Each
		# word and lex_id is separated by a '%' character, and each pair is
		# delimited with a '|'. E.g., the wordlist for "animal" is:
		#   "animal%0|animate_being%0|beast%0|brute%1|creature%0|fauna%1"
		attr_accessor :wordlist

		# The list of raw pointers to related synsets. E.g., the pointerlist for
		# "mourning dove" is:
		#   "@ 01731700%n 0000|#m 01733452%n 0000"
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

			%q{#<%s:0x%08x/%s %s (%s): "%s" (%s)>} % [
				self.class.name,
				self.object_id * 2,
				self.offset,
				self.words.join(", "),
				self.part_of_speech,
				self.gloss,
				pointerCounts,
			]
		end


		### Returns the Synset's unique identifier, made up of its offset and
		### syntactic category catenated together with a '%' symbol.
		def key
			"%d%%%s" % [ self.offset, self.pos ]
		end


		### The symbol which represents this synset's syntactic category. Will
		### be one of :noun, :verb, :adjective, :adverb, or :other.
		def pos
			return SyntacticCategories[ @part_of_speech ]
		end


		### Return each of the sentences of the gloss for this synset as an
		### array. The gloss is a definition of the synset, and optionally one
		### or more example sentences.
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
		def add_words( *newWords )
			@mutex.synchronize( Sync::EX ) {
				self.words |= newWords
			}
		end


		### Delete the specified +oldWords+ from this synset's wordlist. Alias:
		### +delete_words+.
		def delete_words( *oldWords )
			@mutex.synchronize( Sync::EX ) {
				self.words -= oldWords
			}
		end


		### Return the synset as a string. Alias: +overview+.
		def to_s
			@mutex.synchronize( Sync::SH ) {
				wordlist = self.words.join(", ").gsub( /%\d/, '' ).gsub( /_/, ' ' )
				return "#{wordlist} [#{self.part_of_speech}] -- (#{self.gloss})"
			}
		end
		alias_method :overview, :to_s


		### Writes any changes made to the object to the database and updates all
		### affected synset data and indexes. If the object passes out of scope
		### before #write is called, the changes are lost.
		def store
			@mutex.synchronize( Sync::EX ) {
				self.lexicon.store_synset( self )
			}
		end
		alias_method :write, :store


		### Removes this synset from the database.
		def remove
			@mutex.synchronize( Sync::EX ) {
				self.lexicon.remove_synset( self )
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

		# The synsets for the receiver's antonyms (opposites). E.g., 
		#   $lexicon.lookup_synsets( "opaque", :adjective, 1 ).antonyms
		#   ==> [#<WordNet::Synset:0x010a9acc/454927 clear (adjective): "free
		#        from cloudiness; allowing light to pass through; "clear water";
		#        "clear plastic bags"; "clear glass"; "the air is clear and
		#        clean"" (similar_tos: 6, attributes: 1, derivations: 2,
		#        antonyms: 1, see_alsos: 1)>]
		def_pointer_methods :antonyms

		# Synsets for the receiver's entailments (a verb X entails Y if X cannot
		# be done unless Y is or has been done). E.g.,
		#   $lexicon.lookup_synsets( 'rasp', :verb, 1 ).entailment
		#   ==> [#<WordNet::Synset:0x010dc24c rub (verb): "move over something
		#        with pressure; "rub my hands"; "rub oil into her skin""
		#        (derivations: 2, entailments: 1, hypernyms: 1, hyponyms: 13,
		#        see_alsos: 4)>]
		def_pointer_methods :entailment

		# Get/set synsets for the receiver's cause pointers (a verb X causes Y
		# to happen).
		def_pointer_methods :causes

		# Get/set synsets for the receiver's verb groups. Verb groups link verbs
		# with similar senses together.
		def_pointer_methods :verb_groups

		# Get/set list of synsets for the receiver's "similar to" pointers. This
		# type of pointer links together head adjective synsets with its
		# satellite adjective synsets.
		def_pointer_methods :similar_to

		# Get/set synsets for the receiver's participles. Participles are
		# non-finite forms of a verb; used adjectivally and to form compound
		# tenses. For example, the first participle for "working" is:
		#   "function, work, operate, go, run (verb)"
		def_pointer_methods :participles

		# Get/set synsets for the receiver's pertainyms. Pertainyms are
		# relational adjectives. Adjectives that are pertainyms are usually
		# defined by such phrases as "of or pertaining to" and do not have
		# antonyms. A pertainym can point to a noun or another pertainym.
		def_pointer_methods :pertainyms

		# Get/set synsets for the receiver's attributes. 
		def_pointer_methods :attributes

		# Get/set synsets for the receiver's derived_from.
		def_pointer_methods :derived_from

		# Get/set synsets for the receiver's derivations.
		def_pointer_methods :derivations

		# Get/set synsets for the receiver's see_also.
		def_pointer_methods :see_also


		# Auto-generate types with subtypes

		# Synsets for the receiver's hypernyms (more-general terms). E.g.,
		#   $lexicon.lookup_synsets( "cudgel", :noun, 1 ).hypernyms
		#     ==> [#<WordNet::Synset:0x0109a644/3023321 club (noun): "stout
		#          stick that is larger at one end; "he carried a club in self
		#          defense"; "he felt as if he had been hit with a club""
		#          (derivations: 1, hypernyms: 1, hyponyms: 7)>]
		# 
		# Also generates accessors for subtypes:
		# 
		# [instance_hypernyms]
		#   A proper noun that refers to a particular, unique referent (as
        #   distinguished from nouns that refer to classes).
 		def_pointer_methods :hypernyms

		# Get/set synsets for the receiver's hyponyms (more-specific terms). E.g., 

		# [instance_hyponyms]
		#   The specific term used to designate a member of a class. X  is a 
		#   hyponym of Y  if X  is a (kind of) Y.
		def_pointer_methods :hyponyms


		# Get/set synsets for the receiver's meronyms. In addition to the
		# general accessors for all meronyms, there are also accessors for
		# subtypes as well:
		#
		# [member_meronyms]
		#   Get/set synsets for the receiver's "member" meronyms (HAS MEMBER
		#   relation).
		# [stuff_meronyms]
		#   Get/set synsets for the receiver's "stuff" meronyms (IS MADE OUT OF
		#   relation).
		# [portion_meronyms]
		#   Get/set synsets for the receiver's "portion" meronyms (HAS PORTION
		#   relation).
		# [component_meronyms]
		#   Get/set synsets for the receiver's "component" meronyms (HAS
		#   COMPONENT relation).
		# [feature_meronyms]
		#   Get/set synsets for the receiver's "feature" meronyms (HAS FEATURE
		#   relation).
		# [phase_meronyms]
		#   Get/set synsets for the receiver's "phase" meronyms (HAS PHASE
		#   relation).
		# [place_meronyms]
		#   Get/set synsets for the receiver's "place" meronyms (HAS PLACE
		#   relation).
		def_pointer_methods :meronyms

		# Get/set synsets for the receiver's holonyms. In addition to the
		# general accessors for all holonyms, there are also accessors for
		# subtypes as well:
		#
		# [member_holonyms]
		#   Get/set synsets for the receiver's "member" holonyms (IS A MEMBER OF
		#   relation).
		# [stuff_holonyms]
		#   Get/set synsets for the receiver's "stuff" holonyms (IS MATERIAL OF
		#   relation).
		# [portion_holonyms]
		#   Get/set synsets for the receiver's "portion" holonyms (IS A PORTION
		#   OF relation).
		# [component_holonyms]
		#   Get/set synsets for the receiver's "component" holonyms (IS A
		#   COMPONENT OF relation).
		# [feature_holonyms]
		#   Get/set synsets for the receiver's "feature" holonyms (IS A FEATURE
		#   OF relation).
		# [phase_holonyms]
		#   Get/set synsets for the receiver's "phase" holonyms (IS A PHASE OF
		#   relation).
		# [place_holonyms]
		#   Get/set synsets for the receiver's "place" holonyms (IS A PLACE IN
		#   relation).
		def_pointer_methods :holonyms

		# Get/set synsets for the receiver's topical domain members. In addition
		# to the general members accessor, there are also accessors for
		# membership subtypes:
		#
		# [category_members]
		#   Get/set synsets for the receiver's
		# "category" topical domain members.
		# [region_members]
		#   Get/set synsets for the receiver's "region"
		# topical domain members.
		# [usage_members]
		#   Get/set synsets for the receiver's "usage"
		# topical domain members.
		def_pointer_methods :members

		# Get/set synsets for the receiver's topical domain domains. In addition
		# to the general domains accessor, there are also accessors for
		# domainship subtypes:
		#
		# [category_domains]
		#   Get/set synsets for the receiver's
		#   "category" topical domain domains.
		# [region_domains]
		#   Get/set synsets for the receiver's "region"
		#   topical domain domains.
		# [usage_domains]
		#   Get/set synsets for the receiver's "usage"
		#   topical domain domains.
		def_pointer_methods :domains


		### Returns an Array of the coordinate sisters of the receiver.
		def coordinates
			self.hypernyms.collect {|syn|
				syn.hyponyms
			}.flatten
		end


		### Return the name of the "lexicographer's file" associated with this
		### synset.
		def lex_info
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
					collect {|key| @lexicon.lookup_synsets_by_key( key )}
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

