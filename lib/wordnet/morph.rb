#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/model'

# WordNet morph model class
class WordNet::Morph < WordNet::Model( :morphs )
	include WordNet::Constants

	set_primary_key :morphid

	many_to_one :word,
		:join_table => :morphmaps,
		:left_key => :wordid,
		:right_key => :morphid


	### Return the stringified word; alias for #lemma.
	def to_s
		return "%s (%s)" % [ self.morph, self.pos ]
	end

end # class WordNet::Morph

