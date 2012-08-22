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
require 'wordnet/semanticlink'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::SemanticLink, :requires_database => true do
	include WordNet::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	let( :lexicon ) { WordNet::Lexicon.new  }
	let( :word )    { lexicon[96814]        } # 'parody'
	let( :synset )  { word.synsets.first    }
	let( :semlink ) { synset.semlinks.first }


	it "links two synsets together" do
		semlink.origin.should be_a( WordNet::Synset )
		semlink.target.should be_a( WordNet::Synset )
	end

	it "has a Symbolic type" do
		semlink.type.should == :hypernym
	end

	it "has a human-readable type name" do
		semlink.typename.should == 'hypernym'
	end


end


