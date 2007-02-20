#!/usr/bin/ruby -w
#
# Add a synset for laced boots
#

$: << "lib"
require "WordNet"

lex = WordNet::Lexicon.new( "ruby-wordnet" )

boot = lex.lookup_synsets( "boot", "n", 1 )
laced_boot = lex.create_synset( "laced boot", "n" )
tongue = lex.lookup_synsets( "tongue", "n", 6 )

laced_boot.add_hypernyms( boot )
laced_boot.add_component_meronyms( tongue )

lex.unlock {
	laced_boot.write
	boot.write
	tongue.write
}





