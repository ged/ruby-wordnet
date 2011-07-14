#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/mixins'
require 'wordnet/model'

# WordNet sense model class
class WordNet::Sense < WordNet::Model( :senses )
	include WordNet::Constants

	set_primary_key :senseid

	many_to_one :synset, :key => :synsetid
	many_to_one :word, :key => :wordid

end # class WordNet::Sense

