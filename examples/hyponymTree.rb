#!/usr/bin/ruby -w
#
#	Find all the hyponyms of all senses of a given noun and display them in a
#	heirarchy
#

$: << "lib"
require "WordNet"
require "pp"

raise RuntimeError, "No word specified." if ARGV.empty?

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the synsets for the specified word
origins = lex.lookupSynsets( ARGV[0], WordNet::NOUN )

# Use the analyzer to traverse hyponyms of the synset, adding a string for each
# one with indentation for the level
origins.each_index {|i|
	treeComponents = []
	origins[i].traverse( :hyponyms ) {|syn,depth|
		treeComponents << "  #{'  ' * depth}#{syn.words[0]} -- #{syn.gloss.split(/;/)[0]}"
	}

	puts "\nHyponym tree for sense #{i} of #{ARGV[0]}:\n" + treeComponents.join( "\n" )
	puts "Tree has #{treeComponents.length} synsets."
}
