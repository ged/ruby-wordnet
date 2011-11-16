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
require 'wordnet/synset'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Synset, :requires_database => true do
	include WordNet::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
		@lexicon = WordNet::Lexicon.new
	end

	before( :each ) do
		# floor, level, storey, story (noun): [noun.artifact] a structure
		#     consisting of a room or set of rooms at a single position along a
		#     vertical scale (hypernym: 1, hyponym: 5, part meronym: 1)
		@synset = WordNet::Synset[ 103365991 ]
	end

	after( :all ) do
		reset_logging()
	end


	it "knows what lexical domain it's from" do
		@synset.lexical_domain.should == 'noun.artifact'
	end

	it "can make a Sequel dataset for any of its semantic link relationships" do
		ds = @synset.semanticlink_dataset( :member_meronyms )
		ds.should be_a( Sequel::Dataset )
		ds.first_source_table.should == :synsets
	end

	it "can make an Enumerator for any of its semantic link relationships" do
		enum = @synset.semanticlink_enum( :member_meronyms )
		enum.should be_a( Enumerator )
	end

end


