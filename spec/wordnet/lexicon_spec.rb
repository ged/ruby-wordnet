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

require 'wordnet/lexicon'
require 'wordnet/word'



#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Lexicon do

	TEST_WORDS = {
		'activity'		=> WordNet::Noun,
		'sword'			=> WordNet::Noun,
		'density'		=> WordNet::Noun,
		'burly'			=> WordNet::Adjective,
		'wispy'			=> WordNet::Adjective,
		'traditional'	=> WordNet::Adjective,
		'sit'			=> WordNet::Verb,
		'take'			=> WordNet::Verb,
		'joust'			=> WordNet::Verb,
	}

	TEST_DBDIR = Pathname( __FILE__ ).dirname.parent.parent + 'data/wordnet-defaultdb/'
	TEST_DB = TEST_DBDIR + 'wordnet30.sqlite'


	it "connects to the database on demand" do
		Sequel.should_receive( :connect ).with( WordNet::Constants::DEFAULTDB_URI )
		WordNet::Lexicon.new.db
	end


	context "an instance" do

		before( :each ) do
			@lexicon = WordNet::Lexicon.new
		end

		it "can look up words" do
			result = @lexicon.find_word( 'radish' )

			result.should be_a( WordNet::Word )
			result.to_s.should == 'radish'
		end

	end

end

