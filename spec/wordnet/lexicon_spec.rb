#!/usr/bin/env rspec
require_relative '../helpers'

require 'rspec'
require 'wordnet/lexicon'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Lexicon do

	let( :devdb ) do
		Pathname( 'wordnet-defaultdb/data/wordnet-defaultdb/wordnet31.sqlite' ).expand_path
	end


	context "the default_db_uri method" do

		it "uses the wordnet-defaultdb database gem (if available)" do
			expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).at_least( :once ).
				and_return( '/tmp/foo' )
			expect( FileTest ).to receive( :exist? ).with( '/tmp/foo/wordnet31.sqlite' ).
				and_return( true )

			expect( WordNet::Lexicon.default_db_uri ).to eq( "sqlite:/tmp/foo/wordnet31.sqlite" )
		end

		it "uses the development version of the wordnet-defaultdb database gem if it's " +
		   "not installed" do
			expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).
				and_return( nil )
			expect( FileTest ).to receive( :exist? ).with( devdb.to_s ).
				and_return( true )

			expect( WordNet::Lexicon.default_db_uri ).to eq( "sqlite:#{devdb}" )
		end

		it "returns nil if there is no default database" do
			expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).
				and_return( nil )
			expect( FileTest ).to receive( :exist? ).with( devdb.to_s ).
				and_return( false )

			expect( WordNet::Lexicon.default_db_uri ).to be_nil()
		end

	end


	it "raises an exception if created with no arguments and no defaultdb is available" do
		expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).at_least( :once ).
			and_return( nil )
		expect( FileTest ).to receive( :exist? ).with( devdb.to_s ).
			and_return( false )

		expect {
			WordNet::Lexicon.new
		}.to raise_error( WordNet::LexiconError, /no default wordnetsql/i )
	end


	context "via its index operator" do

		let( :lexicon ) { WordNet::Lexicon.new($dburi) }


		it "can look up a Synset by ID" do
			rval = lexicon[ 101222212 ]
			# Can't use "be_a", as on failure it does Array(WordNet::Synset), which explodes to
			# all synsets in the database
			expect( rval.class ).to eq( WordNet::Synset )
			expect( rval.words.map( &:to_s ) ).to include( 'carrot' )
		end

		it "can look up a Word by ID" do
			rval = lexicon[ 21346 ]
			expect( rval.class ).to eq( WordNet::Word )
			expect( rval.lemma ).to eq( 'carrot' )
		end

		it "can look up the synset for a word and a sense" do
			ss = lexicon[ :boot, 3 ]
			expect( ss.class ).to eq( WordNet::Synset )
			expect( ss.definition ).to eq( 'footwear that covers the whole foot and lower leg' )
		end

		it "can look up all synsets for a particular word" do
			sss = lexicon.lookup_synsets( :tree )
			expect( sss.size ).to eq( 7 )
			expect( sss ).to all( be_a(WordNet::Synset) )
		end

		it "can constrain fetched synsets to a certain range of results" do
			sss = lexicon.lookup_synsets( :tree, 1..4 )
			expect( sss.size ).to eq( 4 )
		end

		it "can constrain fetched synsets to a certain (exclusive) range of results" do
			sss = lexicon.lookup_synsets( :tree, 1...4 )
			expect( sss.size ).to eq( 3 )
		end

		it "can look up a synset for a word and a substring of its definition" do
			ss = lexicon[ :boot, 'kick' ]
			expect( ss.class ).to eq( WordNet::Synset )
			expect( ss.definition ).to match( /kick/i )
		end

		it "can look up a synset for a word and a part of speech" do
			ss = lexicon[ :boot, :verb ]
			expect( ss.class ).to eq( WordNet::Synset )
			expect( ss.definition ).to match( /cause to load/i )
		end

		it "can look up a synset for a word and an abbreviated part of speech" do
			ss = lexicon[ :boot, :n ]
			expect( ss.class ).to eq( WordNet::Synset )
			expect( ss.definition ).to match( /delivering a blow with the foot/i )
		end

		it "can constrain fetched synsets with a Regexp match against its definition", :requires_pg do
			sss = lexicon.lookup_synsets( :tree, /plant/ )
			expect( sss.size ).to eq( 2 )
		end

		it "can constrain fetched synsets via lexical domain" do
			sss = lexicon.lookup_synsets( :tree, 'noun.shape' )
			expect( sss.size ).to eq( 1 )
			expect( sss.first ).to eq( WordNet::Synset[113935275 ] )
		end

		it "can constrain fetched synsets via part of speech as a single-letter Symbol" do
			sss = lexicon.lookup_synsets( :tree, :n )
			expect( sss.size ).to eq( 3 )
			expect( sss ).to include(
				lexicon[ :tree, 'actor' ],
				lexicon[ :tree, 'figure' ],
				lexicon[ :tree, 'plant' ]
			)
		end

		it "can constrain fetched synsets via part of speech as a Symbol word" do
			sss = lexicon.lookup_synsets( :tree, :verb )
			expect( sss.size ).to eq( 4 )
			expect( sss ).to include(
				WordNet::Synset[ 201938064 ],
				WordNet::Synset[ 201147629 ],
				WordNet::Synset[ 201619197 ],
				WordNet::Synset[ 200319912 ]
			)
		end

	end

end

