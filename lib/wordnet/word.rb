#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/mixins'
require 'wordnet/model'

# WordNet word model class
class WordNet::Word < WordNet::Model( :words )
	include WordNet::Constants

	set_primary_key :wordid

	one_to_many :senses,
		:key => :wordid,
		:primary_key => :wordid

	many_to_many :synsets,
		:join_table => :senses,
		:left_key => :wordid,
		:right_key => :synsetid

end # class WordNet::Word

