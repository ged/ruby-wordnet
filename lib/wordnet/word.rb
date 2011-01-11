#!/usr/bin/ruby

require 'wordnet'
require 'wordnet/mixins'
require 'wordnet/model'

# WordNet word model class
class WordNet::Word < WordNet::Model
	include WordNet::Constants

	set_dataset :words
	set_primary_key :wordid

	one_to_many :senses,
		:key => :wordid,
		:primary_key => :wordid

	many_to_many :synsets,
		:join_table => :senses,
		:left_key => :wordid,
		:right_key => :synsetid

end # class WordNet::Word

