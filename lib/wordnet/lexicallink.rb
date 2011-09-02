#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/mixins'
require 'wordnet/model'

# WordNet lexical link (pointer) model class
class WordNet::LexicalLink < WordNet::Model( :lexlinks )
	include WordNet::Constants

	set_primary_key [:word1id, :synset1id, :word2id, :synset2id, :linkid]

	many_to_one :origin,
		:class       => :"WordNet::Sense",
		:key         => :synset1id,
		:primary_key => :synsetid

	one_to_many :target,
		:class       => :"WordNet::Synset",
		:key         => :synsetid,
		:primary_key => :synset2id


	######
	public
	######

	### Return the type of link this is as a Symbol.
	def type
		return WordNet::Synset.linktypes[ self.linkid ][ :type ]
	end

end # class WordNet::SemanticLink

