#!/usr/bin/ruby -w
#
# Add a synset for laced boots
#

$: << "lib"
require "WordNet"

lex = WordNet::Lexicon.new

boot = lex.lookupSynset( "boot", "n", 1 )
lacedBoot = lex.createSynset( "laced boot", "n" )
tongue = lex.lookupSynset( "tongue", "n", 6 )

lacedBoot.addHypernyms( boot )
lacedBoot.addComponentMeronyms( tongue )

lex.unlock {
	lacedBoot.write
	boot.write
	tongue.write
}





