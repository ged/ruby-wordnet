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
	end

	after( :all ) do
		reset_logging()
	end


	let( :lexicon ) { WordNet::Lexicon.new }


	context "the Word for 'run'" do

		let( :word ) { lexicon[113377] }

		it "knows what senses it has" do
			senses = word.senses
			senses.should be_an( Array )
			senses.should have( 57 ).members
			senses.first.should be_a( WordNet::Sense )
		end

		it "knows what synsets it has" do
			synsets = word.synsets

			# Should have one synset per sense
			synsets.should have( word.senses.length ).members
			synsets.first.senses.should include( word.senses.first )
		end

		it "has a dataset for selecting noun synsets" do
			word.nouns.should be_a( Sequel::Dataset )
			word.nouns.should have( 16 ).members
			ss = word.nouns.all
			ss.should include(
				lexicon[ :run, 'sequence' ],
				lexicon[ :run, 'baseball' ],
				lexicon[ :run, 'act of running' ],
				lexicon[ :run, 'testing' ]
			)
		end

		it "has a dataset for selecting verb synsets" do
			word.verbs.should be_a( Sequel::Dataset )
			word.verbs.should have( 41 ).members
			ss = word.verbs.all
			ss.should include(
				lexicon[ :run, 'compete' ],
				lexicon[ :run, 'be diffused' ],
				lexicon[ :run, 'liquid' ],
				lexicon[ :run, 'move fast' ]
			)
		end

	end


	context "the Word for 'light'" do

		let( :word ) { lexicon[77458] }

		it "has a dataset for selecting adjective synsets" do
			word.adjectives.should be_a( Sequel::Dataset )
			word.adjectives.should have( 8 ).members
			ss = word.adjectives.all
			ss.should include(
				lexicon[ :light, 'weight' ],
				lexicon[ :light, 'emit', :adjective ],
				lexicon[ :light, 'color' ]
			)
		end

		it "has a dataset for selecting adjective-satellite synsets" do
			word.adjective_satellites.should be_a( Sequel::Dataset )
			word.adjective_satellites.should have( 17 ).members
			ss = word.adjective_satellites.all
			ss.should include(
				lexicon[ :light, 'soil' ],
				lexicon[ :light, 'calories' ],
				lexicon[ :light, 'entertainment' ]
			)
		end

	end


	context "the Word for 'lightly'" do

		let( :word ) { lexicon[77549] }

		it "has a dataset for selecting adverb synsets" do
			word.adverbs.should be_a( Sequel::Dataset )
			word.adverbs.should have( 7 ).members
			ss = word.adverbs.all
			ss.should include(
				lexicon[ :lightly, 'indifference' ],
				lexicon[ :lightly, 'indulging' ],
				lexicon[ :lightly, 'little weight' ],
				lexicon[ :lightly, 'quantity' ]
			)
		end

	end

end


