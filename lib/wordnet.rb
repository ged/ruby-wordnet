#
# WordNet - A Ruby interface to the WordNet lexical database
#
# == Synopsis
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
#   progLangSynset.gloss = "a system of human-readable symbols and words "\
#		"for encoding instructions for a computer"
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
# == Description
#
# This is a Ruby interface to the WordNet lexical database. It's mostly a port
# of Dan Brian's Lingua::Wordnet Perl module, modified a bit to be more
# Ruby-ish.
#
# == Author
#
# The Lingua::Wordnet module by Dan Brian, on which this code is based, falls under
# the following license:
#
#   Copyright 1999,2000,2001 by Dan Brian.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself.
#
# Written by Michael Granger <ged@FaerieMUD.org>
#
# Copyright (c) 2002,2003 The FaerieMUD Consortium. All rights reserved.
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
#
# == Version
#
#  $Id: wordnet.rb,v 1.3 2003/08/06 08:04:43 deveiant Exp $
#

module WordNet

	### Class constants
	Version = /([\d\.]+)/.match( %q{$Revision: 1.3 $} )[1]
	Rcsid = %q$Id: wordnet.rb,v 1.3 2003/08/06 08:04:43 deveiant Exp $

end # module WordNet

require 'wordnet/constants'
require 'wordnet/lexicon'
require 'wordnet/synset'

