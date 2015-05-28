#!/usr/bin/env ruby
#encoding: utf-8

#
#	Find all the hypernyms of all senses of a given noun and display them in a
#	heirarchy
#

$LOAD_PATH.unshift "lib"
require 'wordnet'

raise RuntimeError, "No word specified." if ARGV.empty?

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the synsets for the specified word
origins = lex.lookup_synsets( *ARGV )


# Iterate over the synsets for the different senses of the word
origins.each.with_index do |syn, i|
	hypernyms = []

	# Traverse the hypernyms
	syn.traverse( :hypernyms ).with_depth.each do |hyper_syn, depth|
		indent = '  ' * depth
		hypernyms << "%s%s" % [ indent, hyper_syn ]
	end

	puts "\nHypernym tree for #{syn} (sense #{i + 1}):", *hypernyms
	puts "Tree has #{hypernyms.length} synsets."
end

