#!/usr/bin/ruby

require 'wordnet'
require 'wordnet/mixins'
require 'wordnet/model'

# WordNet sense model class
class WordNet::Sense < WordNet::Model
	include WordNet::Constants

	set_dataset :senses
	set_primary_key :senseid

	many_to_one :synset, :key => :synsetid
	many_to_one :word, :key => :wordid

end # class WordNet::Sense

