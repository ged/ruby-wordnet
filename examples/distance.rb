#!/usr/bin/ruby -w
#
#	Find the distance between the first senses of two nouns
#

$LOAD_PATH.unshift "lib"
require "wordnet"

raise RuntimeError, "You must specify two nouns." if ARGV.length < 2

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the synsets for the two words
word1 = lex.lookup_synsets( ARGV[0], WordNet::Noun, 1 )
unless word1
	puts "Couldn't find a synset for #{ARGV[0]}."
	exit
end
word2 = lex.lookup_synsets( ARGV[1], WordNet::Noun, 1 )
unless word2
	puts "Couldn't find a synset for #{ARGV[1]}."
	exit
end

# Analyze the distance
distance = word1.distance( :hypernyms, word2 )

# If we got a distance, display it.
if distance
	puts "The hypernym distance between #{word1.words[0]} and #{word2.words[0]} is: #{distance}"

# If we didn't get a distance, the second word isn't a hypernym of the first
else
	puts "#{word1.words[0]} is not a kind of #{word2.words[0]}, apparently."
end

