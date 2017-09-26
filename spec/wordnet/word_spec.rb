#!/usr/bin/env rspec
require_relative '../helpers'

require 'rspec'
require 'wordnet'


#####################################################################
###	C O N T E X T S
#####################################################################

describe 'WordNet::Word', :requires_database do

	let( :described_class ) { WordNet::Word }

	let!( :lexicon ) { WordNet::Lexicon.new($dburi) }


	context "the Word for 'run'" do

		let( :word ) { described_class.by_lemma('run').first }


		it "knows what senses it has" do
			senses = word.senses
			expect( senses ).to be_an( Array )
			expect( senses.count ).to eq( 57 )
			expect( senses.first ).to be_a( WordNet::Sense )
		end


		it "knows what synsets it has" do
			synsets = word.synsets

			# Should have one synset per sense
			expect( synsets.size ).to eq( word.senses.size )
			expect( synsets.first.senses ).to include( word.senses.first )
		end


		it "has a dataset for selecting noun synsets" do
			expect( word.nouns ).to be_a( Sequel::Dataset )
			expect( word.nouns.count ).to eq( 16 )
			ss = word.nouns.all
			expect( ss ).to include(
				lexicon[ :run, 'sequence' ],
				lexicon[ :run, 'baseball' ],
				lexicon[ :run, 'act of running' ],
				lexicon[ :run, 'testing' ]
			)
		end


		it "has a dataset for selecting verb synsets" do
			expect( word.verbs ).to be_a( Sequel::Dataset )
			expect( word.verbs.count ).to eq( 41 )
			ss = word.verbs.all
			expect( ss ).to include(
				lexicon[ :run, 'compete' ],
				lexicon[ :run, 'be diffused' ],
				lexicon[ :run, 'liquid' ],
				lexicon[ :run, 'move fast' ]
			)
		end

	end


	context "the Word for 'light'" do

		let( :word ) { described_class.by_lemma('light').first }


		it "has a dataset for selecting adjective synsets" do
			expect( word.adjectives ).to be_a( Sequel::Dataset )
			expect( word.adjectives.count ).to eq( 8 )
			ss = word.adjectives.all
			expect( ss ).to include(
				lexicon[ :light, 'weight' ],
				lexicon[ :light, 'emit', :adjective ],
				lexicon[ :light, 'color' ]
			)
		end


		it "has a dataset for selecting adjective-satellite synsets" do
			expect( word.adjective_satellites ).to be_a( Sequel::Dataset )
			expect( word.adjective_satellites.count ).to eq( 17 )
			ss = word.adjective_satellites.all
			expect( ss ).to include(
				lexicon[ :light, 'soil' ],
				lexicon[ :light, 'calories' ],
				lexicon[ :light, 'entertainment' ]
			)
		end

	end


	context "the Word for 'lightly'" do

		let( :word ) { described_class.by_lemma('lightly').first }


		it "has a dataset for selecting adverb synsets" do
			expect( word.adverbs ).to be_a( Sequel::Dataset )
			expect( word.adverbs.count ).to eq( 7 )
			ss = word.adverbs.all
			expect( ss ).to include(
				lexicon[ :lightly, 'indifference' ],
				lexicon[ :lightly, 'indulging' ],
				lexicon[ :lightly, 'little weight' ],
				lexicon[ :lightly, 'quantity' ]
			)
		end

	end

end


