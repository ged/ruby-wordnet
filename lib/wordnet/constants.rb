#!/usr/bin/ruby
# 
# This is a module containing constants used in the WordNet interface for
# Ruby. They are contained in a module to facilitate their easy inclusion in
# other namespaces. All constants in this module are also contained in the
# WordNet namespace itself.
#
# E.g.,
#
#	WordNet::Adjective == WordNet::Constants::Adjective
#
# If you do:
#	include WordNet::Constants
#
# then:
#	Adjective == WordNet::Adjective
# 
# == Synopsis
# 
#   require 'wordnet'
#	include WordNet::Constants
#
#	lex = WordNet::Lexicon::new
#	origins = lex.lookupSynsets( "shoe", Noun )
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# == Copyright
#
# Copyright (c) 2003 The FaerieMUD Consortium. All rights reserved.
# 
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
# 
# == Version
#
#  $Id: constants.rb,v 1.1 2003/08/06 08:05:18 deveiant Exp $
# 


module WordNet

	### Constant-container module
	module Constants

		### Record-part delimiter
		Delim = '||'
		DelimRe = Regexp::new( Regexp::quote(Delim) )

		### Record-subpart delimiter
		SubDelim = '|'
		SubDelimRe = Regexp::new( Regexp::quote(SubDelim) )

		### Synset syntactic-category types
		Noun		= "n"
		Verb		= "v"
		Adjective	= "a"
		Adverb		= "r"
		Other		= "s"

		### Synset pointer types
		Antonym		= '!'
		Hypernym	= '@'
		Entailment	= '*'
		Hyponym		= '~'
		Meronym		= '%'
		Holonym		= '#'
		Cause		= '>'
		VerbGroup	= %{$}
		SimilarTo	= '&'
		Participle	= '<'
		Pertainym	= '\\'
		Attribute	= '='
		DerivedFrom	= '\\' # Is this really supposed to be the same as PERTAINYM?
		SeeAlso		= '^'
		Function	= '+'

		### Meronym synset pointer types
		MemberMeronym		= '%m'
		StuffMeronym		= '%s'
		PortionMeronym		= '%o'
		ComponentMeronym	= '%p'
		FeatureMeronym		= '%f'
		PhaseMeronym		= '%a'
		PlaceMeronym		= '%l'

		### Holonym synset pointer types
		MemberHolonym		= '#m'
		StuffHolonym		= '#s'
		PortionHolonym		= '#o'
		ComponentHolonym	= '#p'
		FeatureHolonym		= '#f'
		PhaseHolonym		= '#a'
		PlaceHolonym		= '#l'

		### Lexicographer file index
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

		### Verb sentences (?) -- used in building verb frames.
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


	end # module Constants

	# Make the constants available under the WordNet namespace, too.
	include Constants

end # module WordNet
