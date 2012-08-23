#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/synset' unless defined?( WordNet::Synset )
require 'wordnet/model'

# WordNet lexical link (pointer) model class
class WordNet::LexicalLink < WordNet::Model( :lexlinks )
	include WordNet::Constants

	set_primary_key [:word1id, :synset1id, :word2id, :synset2id, :linkid]

	##
	# The WordNet::Sense the link is pointing *from*.
	many_to_one :origin,
		:class       => :"WordNet::Sense",
		:key         => :synset1id,
		:primary_key => :synsetid

	##
	# The WordNet::Synset the link is pointing *to*.
	one_to_many :target,
		:class       => :"WordNet::Synset",
		:key         => :synsetid,
		:primary_key => :synset2id


	######
	public
	######

	### Return the type of link this is as a Symbol.
	def type
		return WordNet::Synset.linktype_table[ self.linkid ][ :type ]
	end

end # class WordNet::SemanticLink

