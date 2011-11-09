#!/usr/bin/ruby -w

BEGIN {
	require 'pathname'

	basedir = Pathname.new( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'wordnet'

#
# Add a synset for laced boots
#

lex = WordNet::Lexicon.new

boot = lex[ :boot ]
laced_boot = WordNet::Synset.create( "laced boot", "n" )
tongue = lex.lookup_synsets( "tongue", "n", 6 )

laced_boot.add_hypernyms( boot )
laced_boot.add_component_meronyms( tongue )

lex.unlock {
	laced_boot.write
	boot.write
	tongue.write
}





