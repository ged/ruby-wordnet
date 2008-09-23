#!/usr/bin/ruby
# 

require 'wordnet'
require 'wordnet/constants'
require 'wordnet/synset'


# WordNet synonym-set pointer class -- the "pointer" type that encapsulates
# relationships between one synset and another.
# 
# == Authors
#
# * Michael Granger <ged@FaerieMUD.org>
# 
# Copyright (c) 2002-2008 The FaerieMUD Consortium. All rights reserved.
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
class Pointer
	include WordNet::Constants


	#########################################################
	###	C L A S S   M E T H O D S
	#########################################################

	### Make an Array of WordNet::Synset::Pointer objects out of the
	### given +pointer_string+. The pointer_string is a string of pointers
	### delimited by WordNet::Constants::SUB_DELIM. Pointers are in the form:
	###   "<pointer_symbol> <synset_offset>%<pos> <source/target>"
	def self::parse( pointer_string )
		type, offset_pos, ptr_nums = pointer_string.split(/\s+/)
		offset, pos = offset_pos.split( /%/, 2 )
		return new( type, offset, pos, ptr_nums[0,2], ptr_nums[2,2] )
	end


	#########################################################
	###	I N S T A N C E   M E T H O D S
	#########################################################

	### Create a new synset pointer with the given arguments. The
	### +type+ is the type of the link between synsets, and must be
	### either a key or a value of WordNet::Constants::POINTER_TYPES. The
	### +offset+ is the unique identifier of the target synset, and
	### +pos+ is its part-of-speech, which must be either a key or value
	### of WordNet::Constants::SYNTACTIC_CATEGORIES. The +source_wn+ and
	### +target_wn+ are numerical values which distinguish lexical and
	### semantic pointers. +source_wn+ indicates the word number in the
	### current (source) synset, and +target_wn+ indicates the word
	### number in the target synset. If both are 0 (the default) it
	### means that the pointer type of the pointer represents a semantic
	### relation between the current (source) synset and the target
	### synset indicated by +offset+.
	def initialize( type, offset, pos=Noun, source_wn=0, target_wn=0 )
		@type = @subtype = nil

		@type, @subtype = self.normalize_type( type )
		@part_of_speech = self.normalize_part_of_speech( pos )

		# Other attributes
		@offset		= offset
		@source_wn	= source_wn
		@target_wn	= target_wn
	end


	######
	public
	######

	# The type of the pointer. Will be one of the keys of
	# WordNet::POINTER_TYPES (e.g., :meronym).
	attr_accessor :type

	# The subtype of the pointer, if any. Will be one of the keys of one
	# of the hashes in POINTER_SUBTYPES (e.g., :portion).
	attr_accessor :subtype

	# The offset of the target synset
	attr_accessor :offset

	# The part-of-speech of the target synset. Will be one of the keys
	# of WordNet::SYNTACTIC_CATEGORIES.
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
		return SYNTACTIC_CATEGORIES[ @part_of_speech ]
	end


	### Return the pointer type symbol for this pointer
	def type_symbol
		unless @subtype
			return POINTER_TYPES[ @type ]
		else
			return POINTER_SUBTYPES[ @type ][ @subtype ]
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

	
	#########
	protected
	#########

	### Given a type description, normalize it into one of the WordNet pointer types (and
	### subtype, if applicable)
	def normalize_type( typedesc )
		type = subtype = nil

		# Allow type = '!', 'antonym', or :antonym. Also handle
		# splitting of compound pointers (e.g., :member_meronym / '%m')
		# into their correct type/subtype parts.
		case typedesc.to_s.length
		when 1
			type = POINTER_SYMBOLS[ typedesc.to_s[0,1] ]

		when 2
			type = POINTER_SYMBOLS[ typedesc.to_s[0,1] ]
			raise "No known subtypes for '%s'" % [@type] unless
				POINTER_SUBTYPES.key?( type )

			subtype = POINTER_SUBTYPES[ type ].index( typedesc ) or
				raise "Unknown subtype '%s' for '%s'" % [ typedesc, @type ]

		else
			if POINTER_TYPES.key?( typedesc.to_sym )
				type = typedesc.to_sym

			elsif /([a-z]+)([A-Z][a-z]+)/ =~ typedesc.to_s
				subtype, maintype = $1, $2.downcase

				type = maintype.to_sym if
					POINTER_TYPES.key?( maintype.to_sym )

				subtype = subtype.to_sym
			end
		end

		raise ArgumentError, "No such pointer type %p" % [ typedesc ] if type.nil?
			
		return type, subtype
	end


	### Given a part of speech description, normalize it into one of the WordNet parts of speech
	### types.
	def normalize_part_of_speech( pos )
		if pos.to_s.length == 1
			return SYNTACTIC_SYMBOLS[ pos ]
		elsif SYNTACTIC_CATEGORIES.key?( pos.to_sym )
			return pos.to_sym
		end

		raise ArgumentError, "No such part of speech %p" % [ pos ]
	end

end # class WordNet::Pointer


