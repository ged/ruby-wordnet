#!/usr/bin/env ruby

BEGIN {
	require 'pathname'

	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'wordnet'
require 'wordnet/word'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Word, :requires_database => true do
	include WordNet::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
		@lexicon = WordNet::Lexicon.new
	end

	before( :each ) do
		# 'run'
		@word = @lexicon[ 113377 ]
	end

	after( :all ) do
		reset_logging()
	end


	it "knows what senses it has" do
		senses = @word.senses
		senses.should be_an( Array )
		senses.should have( 57 ).members
		senses.first.should be_a( WordNet::Sense )
	end

	it "knows what synsets it has" do
		senses = @word.senses
		synsets = @word.synsets

		synsets.should have( senses.length ).members
		synsets.first.senses.should include( senses.first )
	end

end


