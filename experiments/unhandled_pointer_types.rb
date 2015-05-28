# -*- ruby -*-
#encoding: utf-8
#
# Trying to find a minimal testcase for reproducing the error that happens with
# the new '~i' and '@i' synset pointer types.
#
# Time-stamp: <12-Nov-2005 13:11:04 ged>
#

BEGIN {
	base = File::dirname( File::dirname(File::expand_path(__FILE__)) )
	$LOAD_PATH.unshift "#{base}/lib"

	require "#{base}/utils.rb"
	include UtilityFunctions
}

require 'wordnet'

lex = WordNet::Lexicon.new
syn = lex.lookup_synsets_by_offset( "04456674%n" )

try( %{syn.pointerlist} )
try( %{syn.pointers} )

