#!/usr/bin/ruby -w
#
#	Find all articles of clothing that have tongues (From the synopsis of
#	Lingua::Wordnet::Analysis)
#

$: << "lib"
require "WordNet"

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the clothes synset as the origin
clothes = lex.lookupSynsets( "clothes", WordNet::NOUN, 1 )
puts clothes

# Now look up the second sense of tongue (not the anatomical part)
tongue = lex.lookupSynsets( "tongue", WordNet::NOUN, 7 )
puts tongue

# Now traverse all hyponyms of the clothes synset, and check for "tongue" among
# each one's meronyms. We print any that we find.
clothes.traverse( :hyponyms ) {|syn,depth|
	if syn.search( :allMeronyms, tongue )
		puts "Has a tongue: #{syn}"
	else
		puts "Doesn't have a tongue: #{syn}"
	end
}

