#!/usr/bin/ruby
# = Name
#
# WordNet - A Ruby interface to the WordNet lexicon
#
# = Synopsis
# 
#   require "WordNet"
# 
#   # Create a new lexicon object, and unlock it so we can write to it
#   wn = WordNet::Lexicon.new( "/usr/share/wordnet" )
#   wn.unlock
# 
#   # Look up the synsets for "language" and "computer program"
#   languageSynset = wn.lookupSynset( "language", NOUN, 3 )
#   programSynset = wn.lookupSynset( "program", NOUN, 3 )
# 
#   # Create a new synset for programming languages, set its gloss, link it to its
#   # hypernym and holonym, and save everything to the database.
#   progLangSynset = wn.createSynset( "programming language", NOUN )
#   progLangSynset.gloss = "a system of human-readable symbols and words for encoding instructions for a computer"
#   progLangSynset.hypernyms += languageSynset ; languageSynset.hyponyms += progLangSynset
#   progLangSynset.holonyms += programSynset ; programSynset.meronyms += progLangSynset
#   for (progLangSynset, programSynset, languageSynset ) do |synset|
# 	  synset.send( "write" )
#   end
# 
#   # Create a new synset for Ruby, link it, and save it
#   rubySynset = wn.createSynset( "Ruby", NOUN )
#   rubySynset.gloss = "an interpreted scripting language for quick and easy object-oriented programming"
#   rubySynset.hypernyms += languageSyn ; languageSynset.hyponyms += rubySyn
#   rubySynset.write ; languageSynset.write
# 
#   # Now lock the lexicon to prevent further writes
#   wn.close
# 
# = Description
#
# This is a Ruby interface to the WordNet lexicon. It's mostly a port of Dan
# Brian's Lingua::Wordnet Perl module, modified a bit to be more Ruby-ish.
#
# = Author
#
# The Lingua::Wordnet module by Dan Brian, on which this code is based, falls under
# the following license:
#
#   Copyright 1999,2000,2001 by Dan Brian.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself.
#
# Port and miscellaneous mistakes by Michael Granger <ged@FaerieMUD.org>
#
# Copyright (c) 2002 The FaerieMUD Consortium. All rights reserved.
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
#
# = Version
#
#  $Id: wordnet.rb,v 1.1 2002/01/04 21:52:22 deveiant Exp $
#

##
# Root namespace for WordNet classes
module WordNet

	### Globals
	Version = /([\d\.]+)/.match( %q$Revision: 1.1 $ )[1]
	Rcsid = %q$Id: wordnet.rb,v 1.1 2002/01/04 21:52:22 deveiant Exp $

	### Constants

	##
	# Default path to the WordNet databases (this should be modified by the
	# configuration process.
	DICTDIR = '/usr/local/wordnet1.7/lingua-wordnet'

	##
	# Record-part delimiter
	DELIM = '||'

	##
	# Record-subpart delimiter
	SUBDELIM = '|'

	##
	# Synset syntactic-category types
	NOUN		= "n"
	VERB		= "v"
	ADJECTIVE	= "a"
	ADVERB		= "r"
	OTHER		= "s"

	##
	# Synset pointer types
	ANTONYM		= '!'
	HYPERNYM	= '@'
	ENTAILMENT	= '*'
	HYPONYM		= '~'
	MERONYM		= '%'
	HOLONYM		= '#'
	CAUSE		= '>'
	VERBGROUP	= %{$}
	SIMILARTO	= '&'
	PARTICIPLE	= '<'
	PERTAINYM	= '\\'
	ATTRIBUTE	= '='
	DERIVEDFROM	= '\\' # Is this really supposed to be the same as with PERTAINYM?
	SEEALSO		= '^'
	FUNCTION	= '+'

	##
	# Meronym synset pointer types
	MEMBER_MERONYM		= '%m'
	STUFF_MERONYM		= '%s'
	PORTION_MERONYM		= '%o'
	COMPONENT_MERONYM	= '%p'
	FEATURE_MERONYM		= '%f'
	PHASE_MERONYM		= '%a'
	PLACE_MERONYM		= '%l'
	
	##
	# Holonym synset pointer types
	MEMBER_HOLONYM		= '#m'
	STUFF_HOLONYM		= '#s'
	PORTION_HOLONYM		= '#o'
	COMPONENT_HOLONYM	= '#p'
	FEATURE_HOLONYM		= '#f'
	PHASE_HOLONYM		= '#a'
	PLACE_HOLONYM		= '#l'
	
	##
	# Lexicographer file index
	Lexfiles = [
		"adj.all",
		"adj.pert",         
		"adv.all",          
		"noun.Tops",        
		"noun.act",         
		"noun.animal",      
		"noun.artifact",        
		"noun.attribute",       
		"noun.body",        
		"noun.cognition",       
		"noun.communication",   
		"noun.event",       
		"noun.feeling",     
		"noun.food",        
		"noun.group",       
		"noun.location",        
		"noun.motive",      
		"noun.object",      
		"noun.person",      
		"noun.phenomenon",      
		"noun.plant",       
		"noun.possession",      
		"noun.process",     
		"noun.quantity",        
		"noun.relation",        
		"noun.shape",       
		"noun.state",       
		"noun.substance",       
		"noun.time",        
		"verb.body",        
		"verb.change",      
		"verb.cognition",       
		"verb.communication",   
		"verb.competition",     
		"verb.consumption",     
		"verb.contact",     
		"verb.creation",        
		"verb.emotion",     
		"verb.motion",      
		"verb.perception",      
		"verb.possession",      
		"verb.social",      
		"verb.stative",     
		"verb.weather",     
		"adj.ppl"
	]

	##
	# Verb sentences (?) -- used in building verb frames.
	VerbSents = [
		"",
		"Something ----s",
		"Somebody ----s",
		"It is ----ing",
		"Something is ----ing PP",
		"Something ----s something Adjective/Noun",
		"Something ----s Adjective/Noun",
		"Somebody ----s Adjective",
		"Somebody ----s something",
		"Somebody ----s somebody",
		"Something ----s somebody",
		"Something ----s something",
		"Something ----s to somebody",
		"Somebody ----s on something",
		"Somebody ----s somebody something",
		"Somebody ----s something to somebody",
		"Somebody ----s something from somebody",
		"Somebody ----s somebody with something",
		"Somebody ----s somebody of something",
		"Somebody ----s something on somebody",
		"Somebody ----s somebody PP",
		"Somebody ----s something PP",
		"Somebody ----s PP",
		"Somebody's (body part) ----s",
		"Somebody ----s somebody to INFINITIVE",
		"Somebody ----s somebody INFINITIVE",
		"Somebody ----s that CLAUSE",
		"Somebody ----s to somebody",
		"Somebody ----s to INFINITIVE",
		"Somebody ----s whether INFINITIVE",
		"Somebody ----s somebody into V-ing something",
		"Somebody ----s something with something",
		"Somebody ----s INFINITIVE",
		"Somebody ----s VERB-ing",
		"It ----s that CLAUSE",
		"Something ----s INFINITIVE"
	]
end # module WordNet

require "wn/Lexicon"
require "wn/Synset"
#require "wn/Analysis"
