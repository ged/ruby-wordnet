#!/usr/bin/env rspec -cfd

require_relative '../helpers'

require 'wordnet/sense'


describe WordNet::Sense, :requires_database => true do

	before( :all ) do
		@lexicon = WordNet::Lexicon.new
	end


	let( :sense ) do
		WordNet::Word[ 79712 ].senses.first
	end


	it "has a dataset for its 'also_see' lexical links" do
		expect( sense.also_see ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'antonym' lexical links" do
		expect( sense.antonym ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'derivation' lexical links" do
		expect( sense.derivation ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'domain_categories' lexical links" do
		expect( sense.domain_categories ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'domain_member_categories' lexical links" do
		expect( sense.domain_member_categories ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'domain_member_region' lexical links" do
		expect( sense.domain_member_region ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'domain_member_usage' lexical links" do
		expect( sense.domain_member_usage ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'domain_region' lexical links" do
		expect( sense.domain_region ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'domain_usage' lexical links" do
		expect( sense.domain_usage ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'participle' lexical links" do
		expect( sense.participle ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'pertainym' lexical links" do
		expect( sense.pertainym ).to be_a( Sequel::Dataset )
	end


	it "has a dataset for its 'verb_group' lexical links" do
		expect( sense.verb_group ).to be_a( Sequel::Dataset )
	end

end

