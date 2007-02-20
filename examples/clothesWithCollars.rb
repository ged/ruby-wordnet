#!/usr/bin/ruby -w
#
#	Find all articles of clothing that have collars (Adapted from the synopsis
#	of Lingua::Wordnet::Analysis)
#

$LOAD_PATH.unshift "lib"
require "wordnet"

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the clothing synset as the origin
clothing = lex.lookup_synsets( "clothing", WordNet::Noun, 1 )

part_word = ARGV.shift || "collar"
part = lex.lookup_synsets( part_word, WordNet::Noun, 1 ) or
	abort( "Couldn't find synset for #{part_word}" )


puts "Looking for instances of:",
	"  #{part}",
	"in the hyponyms of",
	"  #{clothing}",
	""

# Now traverse all hyponyms of the clothing synset, and check for "part" among
# each one's meronyms, printing any we find
clothing.traverse( :hyponyms ) do |syn,depth|
	if syn.search( :meronyms, part )
		puts "Has a #{part_word}: #{syn}"
	else
		puts "Doesn't have a #{part_word}: #{syn}" if $DEBUG
	end
end

