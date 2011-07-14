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


	it "accepts uri, options for the database connection" do
		uri = 'postgres://localhost/test'
		options = { :username => 'test' }

		db = double( "database object" )
		Sequel.should_receive( :connect ).with( uri, options ).
			and_return( db )

		WordNet::Lexicon.new( uri, options )
		WordNet::Model.db.should equal( db )
	end

end

