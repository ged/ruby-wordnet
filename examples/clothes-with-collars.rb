#!/usr/bin/env ruby

BEGIN {
	require 'pathname'

	basedir = Pathname.new( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'wordnet'

#
#	Find all articles of clothing that have collars (Adapted from the synopsis
#	of Lingua::Wordnet::Analysis)
#

# Create the lexicon
lex = WordNet::Lexicon.new

# Look up the clothing synset as the origin
clothing = lex[:clothing].synsets_dataset.nouns.
	filter { :definition.like('%a covering%') }.first
collar = lex[:collar].synsets_dataset.nouns.
	filter { :definition.like('%band that fits around the neck%') }.first

puts "Looking for instances of:",
	"  #{collar}",
	"in the hyponyms of",
	"  #{clothing}",
	""

# Now traverse all hyponyms of the clothing synset, and check for "collar" among
# each one's "member" meronyms, printing any we find
clothing.traverse( :hyponyms ) do |syn|
	if syn.search( :member_meronyms, collar )
		puts "Has a collar: #{syn}"
	else
		puts "Doesn't have a collar: #{syn}" if $VERBOSE
	end
end

