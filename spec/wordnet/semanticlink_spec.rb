#!/usr/bin/env rspec
require_relative '../helpers'

require 'rspec'
require 'wordnet/semanticlink'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::SemanticLink, :requires_database => true do

	let( :lexicon ) { WordNet::Lexicon.new  }
	let( :word )    { lexicon[96814]        } # 'parody'
	let( :synset )  { word.synsets.first    }
	let( :semlink ) { synset.semlinks.first }


	it "links two synsets together" do
		expect( semlink.origin ).to be_a( WordNet::Synset )
		expect( semlink.target ).to be_a( WordNet::Synset )
	end

	it "has a Symbolic type" do
		expect( semlink.type ).to eq( :hypernym )
	end

	it "has a human-readable type name" do
		expect( semlink.typename ).to eq( 'hypernym' )
	end


end


