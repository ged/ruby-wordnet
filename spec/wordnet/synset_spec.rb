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
require 'wordnet/synset'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Synset, :requires_database => true do
	include WordNet::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
		@lexicon = WordNet::Lexicon.new
	end

	before( :each ) do
		@synset = WordNet::Synset[ 103365991 ]
	end

	after( :all ) do
		reset_logging()
	end


	it "knows what lexical domain it's from" do
		@synset.lexical_domain.should == 'noun.artifact'
	end

	it "knows what its synonyms are" do
		syns = @synset.synonyms
		syns.should be_an( Array )
		syns.should have( 4 ).members
		syns.should include(
			@lexicon[ :floor ],
			@lexicon[ :level ],
			@lexicon[ :storey ],
			@lexicon[ :story ]
		)
	end

end


