#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/mixins'
require 'wordnet/word'
require 'wordnet/model'


# WordNet synonym-set object class
class WordNet::Synset < WordNet::Model( :synsets )
	include WordNet::Constants

	set_primary_key :synsetid

	# Synset -> [ Sense ]
	one_to_many :senses,
		:key => :synsetid,
		:primary_key => :synsetid

	# Synset -> [ Sense ] -> [ Word ]
	many_to_many :words,
		:join_table => :senses,
		:left_key => :synsetid,
		:right_key => :wordid

end # class WordNet::Synset

