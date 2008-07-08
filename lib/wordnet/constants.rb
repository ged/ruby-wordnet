#!/usr/bin/ruby
# 
# This is a module containing constants used in the WordNet interface for
# Ruby. They are contained in a module to facilitate their easy inclusion in
# other namespaces. All constants in this module are also contained in the
# WordNet namespace itself.
#
# E.g.,
#
#   WordNet::Adjective == WordNet::Constants::Adjective
#
# If you do:
#   include WordNet::Constants
#
# then:
#   Adjective == WordNet::Adjective
# 
# == Synopsis
# 
#   require 'wordnet'
#   include WordNet::Constants
#
#   lex = WordNet::Lexicon::new
#   origins = lex.lookup_synsets( "shoe", Noun )
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# == Copyright
#
# Copyright (c) 2003, 2005 The FaerieMUD Consortium. All rights reserved.
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
		# From: senseidx(5WN)
        SyntacticCategories = {
            :noun                => "n",
            :verb                => "v",
            :adjective           => "a",
            :adverb              => "r",
            :adjective_satellite => "s",
        }
        # Syntactic-category indicators -> names
        SyntacticSymbols = SyntacticCategories.invert

        # Map the categories into their own constants (eg., Noun)
        SyntacticCategories.each {|sym,val|
            cname = sym.to_s.capitalize
            const_set( cname, val )
        }

        # Information about pointer types is contained in the wninput(5WN)
        # manpage.

        # Synset pointer typenames -> indicators
        PointerTypes = {
            :antonym        => '!',
            :hypernym       => '@',
            :entailment     => '*',
            :hyponym        => '~',
            :meronym        => '%',
            :holonym        => '#',
            :cause          => '>',
            :verb_group     => %{$},
            :similar_to     => '&',
            :participle     => '<',
            :pertainym      => '\\',
            :attribute      => '=',
            :derived_from   => '\\',
            :see_also       => '^',
            :derivation     => '+',
            :domain         => ';',
            :member         => '-',
        }

        # Synset pointer indicator -> typename
        PointerSymbols = PointerTypes.invert

        # Map the pointer types into their own symbols (eg., VerbGroup)
        PointerTypes.each {|sym,val|
            cname = sym.to_s[0,1].upcase + sym.to_s[1..-1]
            const_set( cname, val )
        }

        # Hypernym synset pointer types
        HypernymTypes = {
            nil             => '@', # Install non-subtype methods, too
            :instance       => '@i',
        }
        
        # Hypernym indicator -> type map
        HypernymSymbols = HypernymTypes.invert

        # Hyponym synset pointer types
        HyponymTypes = {
            nil             => '~', # Install non-subtype methods, too
            :instance       => '~i',
        }
        
        # Hyponym indicator -> type map
        HyponymSymbols = HyponymTypes.invert

        # Meronym synset pointer types
        MeronymTypes = {
            :member         => '%m',
            :stuff          => '%s',
            :portion        => '%o',
            :component      => '%p',
            :feature        => '%f',
            :phase          => '%a',
            :place          => '%l',
        }

        # Meronym indicator -> type map
        MeronymSymbols = MeronymTypes.invert

        # Map the meronym types into their own constants (eg., MemberMeronym)
        MeronymTypes.each {|sym,val|
            cname = sym.to_s.capitalize + "Meronym"
            const_set( cname, val )
        }

        # Holonym synset pointer types
        HolonymTypes = {
            :member         => '#m',
            :stuff          => '#s',
            :portion        => '#o',
            :component      => '#p',
            :feature        => '#f',
            :phase          => '#a',
            :place          => '#l',
        }

        # Holonym indicator -> type map
        HolonymSymbols = HolonymTypes.invert

        # Map the holonym types into their own constants (eg., MemberHolonym)
        HolonymTypes.each {|sym,val|
            cname = sym.to_s.capitalize + "Holonym"
            const_set( cname, val )
        }

        # Domain synset pointer types
        DomainTypes = {
            :category       => ';c',
            :region         => ';r',
            :usage          => ';u',
        }

        # Domain indicator -> type map
        DomainSymbols = DomainTypes.invert

        # Map the domain types into their own constants (eg., CategoryDomain)
        DomainTypes.each {|sym,val|
            cname = sym.to_s.capitalize + "Domain"
            const_set( cname, val )
        }

        # Member synset pointer types
        MemberTypes = {
            :category       => '-c',
            :region         => '-r',
            :usage          => '-u',
        }

        # Member indicator -> type map
        MemberSymbols = MemberTypes.invert

        # Map the member types into their own constants (eg., CategoryMember)
        MemberTypes.each {|sym,val|
            cname = sym.to_s.capitalize + "Member"
            const_set( cname, val )
        }

        # Map of primary types to maps of their subtypes 
        PointerSubTypes = {
            :hyponym    => HyponymTypes,
            :hypernym   => HypernymTypes,
            :meronym    => MeronymTypes,
            :holonym    => HolonymTypes,
            :member     => MemberTypes,
            :domain     => DomainTypes,
        }


        # Record-part delimiter
        Delim = '||'
        DelimRe = Regexp::new( Regexp::quote(Delim) )

        # Record-subpart delimiter
        SubDelim = '|'
        SubDelimRe = Regexp::new( Regexp::quote(SubDelim) )

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


    end # module Constants

    # Make the constants available under the WordNet namespace, too.
    include Constants

end # module WordNet
