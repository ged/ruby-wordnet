#!/usr/bin/env rspec
require_relative '../helpers'

require 'rspec'
require 'wordnet/lexicon'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Lexicon do

	before( :all ) do
		@devdb = Pathname( 'wordnet-defaultdb/data/wordnet-defaultdb/wordnet30.sqlite' ).
			expand_path
	end


	context "the default_db_uri method" do

		it "uses the wordnet-defaultdb database gem (if available)" do
			expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).at_least( :once ).
				and_return( '/tmp/foo' )
			expect( FileTest ).to receive( :exist? ).with( '/tmp/foo/wordnet30.sqlite' ).
				and_return( true )

			expect( WordNet::Lexicon.default_db_uri ).to eq( "sqlite:/tmp/foo/wordnet30.sqlite" )
		end

		it "uses the development version of the wordnet-defaultdb database gem if it's " +
		   "not installed" do
			expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).
				and_return( nil )
			expect( FileTest ).to receive( :exist? ).with( @devdb.to_s ).
				and_return( true )

			expect( WordNet::Lexicon.default_db_uri ).to eq( "sqlite:#{@devdb}" )
		end

		it "returns nil if there is no default database" do
			expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).
				and_return( nil )
			expect( FileTest ).to receive( :exist? ).with( @devdb.to_s ).
				and_return( false )

			expect( WordNet::Lexicon.default_db_uri ).to be_nil()
		end

	end


	it "raises an exception if created with no arguments and no defaultdb is available" do
		expect( Gem ).to receive( :datadir ).with( 'wordnet-defaultdb' ).at_least( :once ).
			and_return( nil )
		expect( FileTest ).to receive( :exist? ).with( @devdb.to_s ).
			and_return( false )

		expect {
			WordNet::Lexicon.new
		}.to raise_error( WordNet::LexiconError, /no default wordnetsql/i )
	end


	context "with the default database", :requires_database => true do

		let( :lexicon ) { WordNet::Lexicon.new }

		context "via its index operator" do

			it "can look up a Synset by ID" do
				rval = lexicon[ 101219722 ]
				expect( rval ).to be_a( WordNet::Synset )
				expect( rval.words.map( &:to_s ) ).to include( 'carrot' )
			end

			it "can look up a Word by ID" do
				rval = lexicon[ 21338 ]
				expect( rval ).to be_a( WordNet::Word )
				expect( rval.lemma ).to eq( 'carrot' )
			end

			it "can look up the synset for a word and a sense" do
				ss = lexicon[ :boot, 3 ]
				expect( ss ).to be_a( WordNet::Synset )
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

		end

	end

	context "with a PostgreSQL database", :requires_pg do

		let( :lexicon ) { WordNet::Lexicon.new('postgres:/wordnet30') }

		context "via its index operator" do

			it "can look up a Synset by ID" do
				rval = lexicon[ 101219722 ]
				expect( rval ).to be_a( WordNet::Synset )
				expect( rval.words.map(&:to_s) ).to include( 'carrot' )
			end

			it "can look up a Word by ID" do
				rval = lexicon[ 21338 ]
				expect( rval ).to be_a( WordNet::Word )
				expect( rval.lemma ).to eq( 'carrot' )
			end

			it "can look up the synset for a word and a sense" do
				ss = lexicon[ :boot, 3 ]
				expect( ss ).to be_a( WordNet::Synset )
				expect( ss.definition ).to eq( 'footwear that covers the whole foot and lower leg' )
			end

			it "can look up a synset for a word and a substring of its definition" do
				ss = lexicon[ :boot, 'kick' ]
				expect( ss ).to be_a( WordNet::Synset )
				expect( ss.definition ).to match( /kick/i )
			end

			it "can look up a synset for a word and a part of speech" do
				ss = lexicon[ :boot, :verb ]
				expect( ss ).to be_a( WordNet::Synset )
				expect( ss.definition ).to match( /cause to load/i )
			end

			it "can look up a synset for a word and an abbreviated part of speech" do
				ss = lexicon[ :boot, :n ]
				expect( ss ).to be_a( WordNet::Synset )
				expect( ss.definition ).to match( /act of delivering/i )
			end

			it "can constrain fetched synsets with a Regexp match against its definition" do
				sss = lexicon.lookup_synsets( :tree, /plant/ )
				expect( sss.size ).to eq( 2 )
			end

			it "can constrain fetched synsets via lexical domain" do
				sss = lexicon.lookup_synsets( :tree, 'noun.shape' )
				expect( sss.size ).to eq( 1 )
				expect( sss.first ).to eq( WordNet::Synset[ 113912260 ] )
			end

			it "can constrain fetched synsets via part of speech as a single-letter Symbol" do
				sss = lexicon.lookup_synsets( :tree, :n )
				expect( sss.size ).to eq( 3 )
				expect( sss ).to include(
					WordNet::Synset[ 113912260 ],
					WordNet::Synset[ 111348160 ],
					WordNet::Synset[ 113104059 ]
				)
			end

			it "can constrain fetched synsets via part of speech as a Symbol word" do
				sss = lexicon.lookup_synsets( :tree, :verb )
				expect( sss.size ).to eq( 4 )
				expect( sss ).to include(
					WordNet::Synset[ 200319111 ],
					WordNet::Synset[ 201145163 ],
					WordNet::Synset[ 201616293 ],
					WordNet::Synset[ 201934205 ]
				)
			end

			it "includes the database adapter name in its inspect output" do
				expect( lexicon.inspect ).to include( "postgres" )
			end

		end
	end

end

