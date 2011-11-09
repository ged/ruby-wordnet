#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/model'
require 'wordnet/constants'


# SUMO terms
class WordNet::SumoTerm < WordNet::Model( :sumoterms )
	include WordNet::Constants

	set_primary_key :sumoid

	# SUMO Term -> [ SUMO Map ] -> [ Synset ]
	many_to_many :synsets,
		:join_table => :sumomaps,
		:left_key => :sumoid,
		:right_key => :synsetid

end # class WordNet::SumoTerm

