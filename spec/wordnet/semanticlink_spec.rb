#!/usr/bin/env ruby

BEGIN {
	require 'pathname'

	basedir = Pathname.new( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'wordnet/semanticlink'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::SemanticLink, :requires_database => true do
	include WordNet::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
		@lexicon = WordNet::Lexicon.new
	end

	before( :each ) do
		@word   = @lexicon[ :parody ]
		@synset = @word.synsets.first
	end

	after( :all ) do
		reset_logging()
	end


end


