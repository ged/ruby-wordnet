#!/usr/bin/ruby -w
#
#	Find least general hypernymial synsets between all noun senses of two words.
#

$LOAD_PATH.unshift "lib"
require "wordnet"

raise RuntimeError, "You must specify two words." if ARGV.length != 2

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the synsets for the specified word
word1Syns = lex.lookup_synsets( ARGV[0], WordNet::Noun )
word2Syns = lex.lookup_synsets( ARGV[1], WordNet::Noun )

def debugMsg( message )
	return unless $DEBUG
	$stderr.puts message
end

# Use the analyzer to traverse hypernyms of the synset, adding a string for each
# one with indentation for the level
word1Syns.each {|syn|
	debugMsg( ">>> Searching with #{syn.wordlist} as the origin." )

	word2Syns.each {|secondSyn|
		debugMsg( "  Comparing #{secondSyn.wordlist} to the origin." )

		# The intersection of the two syns is the most-specific hypernym they
		# share in common.
		commonSyn = (syn | secondSyn)

		if commonSyn
			puts <<-"EOF".gsub( /^\t{3}/, '' )
			----
			  #{syn.words.join(', ')}
			  #{syn.gloss}
			and
			  #{secondSyn.words.join(', ')}
			  #{secondSyn.gloss}
			are both instances of
			  #{commonSyn.words.join(', ')}
			  #{commonSyn.gloss}.
			----
			EOF
		else
			debugMsg( "    No synsets in common." )
		end
	}

	debugMsg( "  done with #{syn.wordlist}" )
}
