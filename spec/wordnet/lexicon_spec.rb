#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'sequel'

require 'spec/lib/helpers'
require 'wordnet'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Lexicon do

	before( :all ) do
		setup_logging()
		@devdb = Pathname( 'wordnet-defaultdb/data/wordnet-defaultdb/wordnet30.sqlite' ).
			expand_path
	end

	after( :all ) do
		reset_logging()
	end


	context "the default_db_uri method" do

		it "uses the wordnet-defaultdb database gem (if available)" do
			Gem.should_receive( :datadir ).with( 'wordnet-defaultdb' ).at_least( :once ).
				and_return( '/tmp/foo' )
			FileTest.should_receive( :exist? ).with( '/tmp/foo/wordnet30.sqlite' ).
				and_return( true )

			WordNet::Lexicon.default_db_uri.should == "sqlite:/tmp/foo/wordnet30.sqlite"
		end

		it "uses the development version of the wordnet-defaultdb database gem if it's " +
		   "not installed" do
			Gem.should_receive( :datadir ).with( 'wordnet-defaultdb' ).
				and_return( nil )
			FileTest.should_receive( :exist? ).with( @devdb.to_s ).
				and_return( true )

			WordNet::Lexicon.default_db_uri.should == "sqlite:#{@devdb}"
		end

		it "returns nil if there is no default database" do
			Gem.should_receive( :datadir ).with( 'wordnet-defaultdb' ).
				and_return( nil )
			FileTest.should_receive( :exist? ).with( @devdb.to_s ).
				and_return( false )

			WordNet::Lexicon.default_db_uri.should be_nil()
		end

	end


	it "raises an exception if created with no arguments and no defaultdb is available" do
		Gem.should_receive( :datadir ).with( 'wordnet-defaultdb' ).at_least( :once ).
			and_return( nil )
		FileTest.should_receive( :exist? ).with( @devdb.to_s ).
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
				rval.should be_a( WordNet::Synset )
				rval.words.map( &:to_s ).should include( 'carrot' )
			end

			it "can look up a Word by ID" do
				rval = lexicon[ 21338 ]
				rval.should be_a( WordNet::Word )
				rval.lemma.should == 'carrot'
			end

			it "can look up the synset for a word and a sense" do
				ss = lexicon[ :boot, 3 ]
				ss.should be_a( WordNet::Synset )
				ss.definition.should == 'footwear that covers the whole foot and lower leg'
			end

			it "can look up all synsets for a particular word" do
				sss = lexicon.lookup_synsets( :tree )
				sss.should have( 7 ).members
				sss.all? {|ss| ss.should be_a(WordNet::Synset) }
			end

			it "can constrain fetched synsets to a certain range of results" do
				sss = lexicon.lookup_synsets( :tree, 1..4 )
				sss.should have( 4 ).members
			end

			it "can constrain fetched synsets to a certain (exclusive) range of results" do
				sss = lexicon.lookup_synsets( :tree, 1...4 )
				sss.should have( 3 ).members
			end

		end

	end

	context "with a PostgreSQL database", :requires_pg do

		let( :lexicon ) { WordNet::Lexicon.new('postgres:/wordnet30') }

		context "via its index operator" do

			it "can look up a Synset by ID" do
				rval = lexicon[ 101219722 ]
				rval.should be_a( WordNet::Synset )
				rval.words.map( &:to_s ).should include( 'carrot' )
			end

			it "can look up a Word by ID" do
				rval = lexicon[ 21338 ]
				rval.should be_a( WordNet::Word )
				rval.lemma.should == 'carrot'
			end

			it "can look up the synset for a word and a sense" do
				ss = lexicon[ :boot, 3 ]
				ss.should be_a( WordNet::Synset )
				ss.definition.should == 'footwear that covers the whole foot and lower leg'
			end

			it "can look up a synset for a word and a substring of its definition" do
				ss = lexicon[ :boot, 'kick' ]
				ss.should be_a( WordNet::Synset )
				ss.definition.should =~ /kick/i
			end

			it "can look up a synset for a word and a part of speech" do
				ss = lexicon[ :boot, :verb ]
				ss.should be_a( WordNet::Synset )
				ss.definition.should =~ /cause to load/i
			end

			it "can look up a synset for a word and an abbreviated part of speech" do
				ss = lexicon[ :boot, :n ]
				ss.should be_a( WordNet::Synset )
				ss.definition.should =~ /act of delivering/i
			end

			it "can constrain fetched synsets with a Regexp match against its definition" do
				sss = lexicon.lookup_synsets( :tree, /plant/ )
				sss.should have( 2 ).members
			end

			it "can constrain fetched synsets via lexical domain" do
				sss = lexicon.lookup_synsets( :tree, 'noun.shape' )
				sss.should have( 1 ).member
				sss.first.should == WordNet::Synset[ 113912260 ]
			end

			it "can constrain fetched synsets via part of speech as a single-letter Symbol" do
				sss = lexicon.lookup_synsets( :tree, :n )
				sss.should have( 3 ).members
				sss.should include(
					WordNet::Synset[ 113912260 ],
					WordNet::Synset[ 111348160 ],
					WordNet::Synset[ 113104059 ]
				)
			end

			it "can constrain fetched synsets via part of speech as a Symbol word" do
				sss = lexicon.lookup_synsets( :tree, :verb )
				sss.should have( 4 ).members
				sss.should include(
					WordNet::Synset[ 200319111 ],
					WordNet::Synset[ 201145163 ],
					WordNet::Synset[ 201616293 ],
					WordNet::Synset[ 201934205 ]
				)
			end

			it "includes the database adapter name in its inspect output" do
				lexicon.inspect.should include( "postgres" )
			end

		end
	end

end

