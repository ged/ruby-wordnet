#!/usr/bin/env ruby

#
#	Find least general hypernymial synsets between all noun senses of two words.
#

$LOAD_PATH.unshift "lib"

require 'wordnet'
require 'loggability'

raise RuntimeError, "You must specify two words." if ARGV.length != 2

lex = WordNet::Lexicon.new

word1_syns = lex.lookup_synsets( ARGV[0], :noun )
word2_syns = lex.lookup_synsets( ARGV[1], :noun )

logger = Loggability[ WordNet ]

# Use the analyzer to traverse hypernyms of the synset, adding a string for each
# one with indentation for the level
word1_syns.each do |syn|
	logger.debug ">>> Searching with #{syn.wordlist.join(', ')} as the origin."

	word2_syns.each do |syn2|
		logger.debug "  Comparing #{syn2.wordlist.join(', ')} to the origin."

		# The intersection of the two synsets is the most-specific hypernym they
		# share in common.
		common_syn = (syn | syn2)

		# Skip common synsets that are too abstract
		if common_syn && common_syn.lexical_domain != 'noun.tops'
			puts syn, syn2, '  ' + common_syn.to_s, ''
		else
			logger.debug "    No synsets in common."
		end
	end

	logger.debug "  done with #{syn.wordlist}"
end

