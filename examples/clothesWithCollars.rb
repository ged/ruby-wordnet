#!/usr/bin/ruby -w
#
#	Find all articles of clothing that have collars (Adapted from the synopsis
#	of Lingua::Wordnet::Analysis)
#

$LOAD_PATH.unshift "lib"
require "wordnet"

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the clothes synset as the origin
clothes = lex.lookupSynsets( "clothes", WordNet::Noun, 1 )
puts clothes

# Now look up the second sense of tongue (not the anatomical part)
collar = lex.lookupSynsets( "collar", WordNet::Noun, 1 )
puts collar

# Now traverse all hyponyms of the clothes synset, and check for "tongue" among
# each one's meronyms. We print any that we find.
clothes.traverse( :hyponyms ) {|syn,depth|
	if syn.search( :allMeronyms, collar )
		puts "Has a collar: #{syn}"
	end
}

