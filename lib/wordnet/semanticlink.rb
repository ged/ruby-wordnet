#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/model'

# WordNet semantic link (pointer) model class
class WordNet::SemanticLink < WordNet::Model( :semlinks )
	include WordNet::Constants


	set_primary_key [:synset1id, :synset2id, :linkid]

	many_to_one :origin,
		:class       => :"WordNet::Synset",
		:key         => :synset1id,
		:primary_key => :synsetid

	one_to_one :target,
		:class       => :"WordNet::Synset",
		:key         => :synsetid,
		:primary_key => :synset2id,
		:eager       => :words


	######
	public
	######

	### Return a stringified version of the SemanticLink.
	def to_s
		return "%s: %s (%s)" % [
			self.type,
			self.target.words.map( &:to_s ).join( ', ' ),
			self.target.pos,
		]
	end


	### Return the type of link as a Symbol.
	def type
		return WordNet::Synset.linktype_table[ self.linkid ][ :type ]
	end


	### Return the name of the link type as a String.
	def typename
		return WordNet::Synset.linktype_table[ self.linkid ][ :typename ]
	end

end # class WordNet::SemanticLink

