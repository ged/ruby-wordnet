#
# WordNet - A Ruby interface to the WordNet lexical database
#
# == Synopsis
# 
#   require "WordNet"
# 
#   # Create a new lexicon object
#   lex = WordNet::Lexicon::new
# 
#   # Look up the synsets for "language" and "computer program"
#   languageSynset = lex.lookup_synsets( "language", WordNet::Noun, 3 )
#   programSynset = lex.lookup_synsets( "program", WordNet::Noun, 3 )
# 
#   # Create a new synset for programming languages, set its gloss, link it to its
#   # hypernym and holonym, and save everything to the database.
#   progLangSynset = lex.create_synset( "programming language", WordNet::Noun )
#   progLangSynset.gloss = "a system of human-readable symbols and words "\
#		"for encoding instructions for a computer"
#   progLangSynset.hypernyms += languageSynset
#   languageSynset.hyponyms += progLangSynset
#   progLangSynset.holonyms += programSynset
#	programSynset.stuff_meronyms += progLangSynset
#   [ progLangSynset, programSynset, languageSynset ].each do |synset|
# 	  synset.store
#   end
# 
#   # Create a new synset for Ruby, link it, and save it
#   rubySynset = lex.create_synset( "Ruby", Wordnet::Noun )
#   rubySynset.gloss = "an interpreted scripting language for quick and easy object-oriented programming"
#   rubySynset.hypernyms += languageSyn ; languageSynset.hyponyms += rubySyn
#   rubySynset.write ; languageSynset.write
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
# Copyright (c) 2002,2003,2005 The FaerieMUD Consortium. All rights reserved.
#
# This module is free software. You may use, modify, and/or redistribute this
# software under the terms of the Perl Artistic License. (See
# http://language.perl.com/misc/Artistic.html)
#
# == Version
#
#  $Id$
#

# Try to provide underbarred alternatives for camelCased methods. Requires the
# 'CrossCase' module.
begin
	require 'crosscase'
rescue LoadError
end

### The main namespace for WordNet classes
module WordNet

	# Revision tag
	SvnRev = %q$Rev$

	# Id tag
	SvnId = %q$Id$

	# Release version
	VERSION = '1.0.0'

	require 'wordnet/constants'
	require 'wordnet/lexicon'
	require 'wordnet/synset'

end # module WordNet

