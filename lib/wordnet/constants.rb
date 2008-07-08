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
#	origins = lex.lookup_synsets( "shoe", Noun )
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# == Copyright
#
# Copyright (c) 2003-2008 The FaerieMUD Consortium. All rights reserved.
# 
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
# 
# == Version
#
#  $Id$
# 


module WordNet

	### Constant-container module
	module Constants

		# Synset syntactic-category names -> indicators
		SYNTACTIC_CATEGORIES = {
			:noun		=> "n",
			:verb		=> "v",
			:adjective	=> "a",
			:adverb		=> "r",
			:other		=> "s",
		}
		# Syntactic-category indicators -> names
		SYNTACTIC_SYMBOLS = SYNTACTIC_CATEGORIES.invert

		# Map the categories into their own constants (eg., Noun)
		SYNTACTIC_CATEGORIES.each do |sym,val|
			cname = sym.to_s.capitalize
			const_set( cname, val )
		end

        # Information about pointer types is contained in the wninput(5WN)
        # manpage.

		# Synset pointer typenames -> indicators
		POINTER_TYPES = {
			:antonym		=> '!',
			:hypernym		=> '@',
			:entailment		=> '*',
			:hyponym		=> '~',
			:meronym		=> '%',
			:holonym		=> '#',
			:cause			=> '>',
			:verb_group		=> %{$},
			:similar_to		=> '&',
			:participle		=> '<',
			:pertainym		=> '\\',
			:attribute		=> '=',
			:derived_from	=> '\\',
			:see_also		=> '^',
			:derivation		=> '+',
			:domain			=> ';',
			:member			=> '-',
		}

		# Synset pointer indicator -> typename
		POINTER_SYMBOLS = POINTER_TYPES.invert

		# Map the pointer types into their own symbols (eg., :verb_group => VerbGroup)
		POINTER_TYPES.each do |sym,val|
			cname = sym.to_s.gsub( /(?:^|_)(.)/ ) { $1.upcase }
			const_set( cname, val )
		end

        # Hypernym synset pointer types
        HYPERNYM_TYPES = {
            nil             => '@', # Install non-subtype methods, too
            :instance       => '@i',
        }
        
        # Hypernym indicator -> type map
        HYPERNYM_SYMBOLS = HYPERNYM_TYPES.invert

        # Hyponym synset pointer types
        HYPONYM_TYPES = {
            nil             => '~', # Install non-subtype methods, too
            :instance       => '~i',
        }
        
        # Hyponym indicator -> type map
        HYPONYM_SYMBOLS = HYPONYM_TYPES.invert

		# Meronym synset pointer types
		MERONYM_TYPES = {
			:member			=> '%m',
			:stuff			=> '%s',
			:portion		=> '%o',
			:component		=> '%p',
			:feature		=> '%f',
			:phase			=> '%a',
			:place			=> '%l',
		}

		# Meronym indicator -> type map
		MERONYM_SYMBOLS = MERONYM_TYPES.invert

		# Map the meronym types into their own constants (eg., MemberMeronym)
		MERONYM_TYPES.each do |sym,val|
			cname = sym.to_s.capitalize + "Meronym"
			const_set( cname, val )
		end

		# Holonym synset pointer types
		HOLONYM_TYPES = {
			:member			=> '#m',
			:stuff			=> '#s',
			:portion		=> '#o',
			:component		=> '#p',
			:feature		=> '#f',
			:phase			=> '#a',
			:place			=> '#l',
		}

		# Holonym indicator -> type map
		HOLONYM_SYMBOLS = HOLONYM_TYPES.invert

		# Map the holonym types into their own constants (eg., MemberHolonym)
		HOLONYM_TYPES.each do |sym,val|
			cname = sym.to_s.capitalize + "Holonym"
			const_set( cname, val )
		end

		# Domain synset pointer types
		DOMAIN_TYPES = {
			:category		=> ';c',
			:region			=> ';r',
			:usage			=> ';u',
		}

		# Domain indicator -> type map
		DomainSymbols = DOMAIN_TYPES.invert

		# Map the domain types into their own constants (eg., CategoryDomain)
		DOMAIN_TYPES.each do |sym,val|
			cname = sym.to_s.capitalize + "Domain"
			const_set( cname, val )
		end

		# Member synset pointer types
		MEMBER_TYPES = {
			:category		=> '-c',
			:region			=> '-r',
			:usage			=> '-u',
		}

		# Member indicator -> type map
		MEMBER_SYMBOLS = MEMBER_TYPES.invert

		# Map the member types into their own constants (eg., CategoryMember)
		MEMBER_TYPES.each do |sym,val|
			cname = sym.to_s.capitalize + "Member"
			const_set( cname, val )
		end

		# Map of primary types to maps of their subtypes 
		POINTER_SUBTYPES = {
            :hyponym    => HYPONYM_TYPES,
            :hypernym   => HYPERNYM_TYPES,
			:meronym	=> MERONYM_TYPES,
			:holonym	=> HOLONYM_TYPES,
			:member		=> MEMBER_TYPES,
			:domain		=> DOMAIN_TYPES,
		}


		# Record-part delimiter
		DELIM = '||'
		DELIM_RE = Regexp::new( Regexp::quote(DELIM) )

		# Record-subpart delimiter
		SUB_DELIM = '|'
		SUB_DELIM_RE = Regexp::new( Regexp::quote(SUB_DELIM) )

		# Lexicographer file index -- from lexnames(5WN)
		LEXFILES = [
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

		# Verb sentences (?) -- used in building verb frames.
		VERB_SENTS = [
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
