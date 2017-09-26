#!/usr/bin/env rspec
require_relative '../helpers'

require 'rspec'


#####################################################################
###	C O N T E X T S
#####################################################################

describe 'WordNet::Synset', :requires_database do

	before( :all ) do
		@lexicon = WordNet::Lexicon.new( $dburi )
	end


	let( :described_class ) { WordNet::Synset }


	it "knows what kinds of lexical domains are available" do
		expect( described_class.lexdomains ).to be_a( Hash )
		expect( described_class.lexdomains ).to include( 'noun.cognition' )
		expect( described_class.lexdomains['noun.cognition'] ).to be_a( Hash )
		expect( described_class.lexdomains['noun.cognition'][:pos] ).to eq( 'n' )
	end

	it "knows what kinds of semantic links are available" do
		expect( described_class.linktypes ).to be_a( Hash )
		hypernym = described_class.linktypes[:hypernym]
		expect( hypernym ).to be_a( Hash )
		expect( hypernym[:typename] ).to eq( 'hypernym' )
		expect( hypernym[:recurses] ).to be_truthy()
	end

	it "knows what parts of speech are supported" do
		expect( described_class.postypes ).to be_a( Hash )
		expect( described_class.postypes['noun'] ).to eq( :n )
	end


	context "for 'floor, level, storey, story (noun)' [103365991]" do

		# floor, level, storey, story (noun): [noun.artifact] a structure
		#     consisting of a room or set of rooms at a single position along a
		#     vertical scale (hypernym: 1, hyponym: 5, part meronym: 1)
		let( :synset ) { @lexicon['story', :n] }


		it "knows what lexical domain it's from" do
			expect( synset.lexical_domain ).to eq( 'noun.artifact' )
		end

		it "can make a Sequel dataset for any of its semantic link relationships" do
			ds = synset.semanticlink_dataset( :member_meronyms )
			expect( ds ).to be_a( Sequel::Dataset )
			expect( ds.first_source_table ).to eq( :synsets )
		end

		it "can make an Enumerator for any of its semantic link relationships" do
			enum = synset.semanticlink_enum( :member_meronyms )
			expect( enum ).to be_a( Enumerator )
		end

		it "can return an Enumerator for recursively traversing its semantic links" do
			enum = synset.traverse( :hypernyms )

			expect( enum ).to be_a( Enumerator ).and( contain_exactly(
				@lexicon['artifact', :n],
				@lexicon['unit', :n],
				@lexicon['object', :n],
				@lexicon['physical entity', :n],
				@lexicon['entity', :n],
				@lexicon['structure', :n],
			) )
		end
	end


	context "for 'knight (noun)' [110238375]" do

		let( :synset ) { @lexicon[:knight, "noble"] }

		it "can find the hypernym that it and another synset share in common through the intersection operator" do
			res = synset | @lexicon[ :squire ]
			expect( res ).to eq( @lexicon[:person] )
		end

		it "knows what part of speech it's for" do
			expect( synset.part_of_speech ).to eq( 'noun' )
		end

		it "stringifies as a readable definition" do
			expect(
				synset.to_s
			).to eq( "knight (noun): [noun.person] originally a person of noble birth trained to " +
				"arms and chivalry; today in Great Britain a person honored by the sovereign for personal " +
				"merit (hypernym: 1, hyponym: 6, instance hyponym: 1)" )
		end

	end


	context "for 'congener (noun)' [100003993]" do

		let( :synset ) { @lexicon[:congener] }

		it "can look up its sample sentences" do
			expect( synset.samples.size ).to eq( 2 )
			expect( synset.samples ).to include(
				"lard was also used, though its congener, butter, was more frequently employed",
				"the American shopkeeper differs from his European congener"
			)
		end

	end


end


