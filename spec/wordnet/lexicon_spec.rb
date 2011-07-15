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

# Use Sequel's own spec helpers
if Gem::Specification.respond_to?( :find_by_name )
	sequel_spec = Gem::Specification.find_by_name( 'sequel' )
	gem_basedir = sequel_spec.full_gem_path
	$LOAD_PATH.unshift( gem_basedir ) unless $LOAD_PATH.include?( gem_basedir )
else
	gem_basedir = Pathname( Gem.required_location('sequel', 'sequel.rb') ).dirname.parent.to_s
	$LOAD_PATH.unshift( gem_basedir ) unless $LOAD_PATH.include?( gem_basedir )
end
require 'spec/model/spec_helper'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Lexicon do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		MODEL_DB.reset
	end

	after( :all ) do
		reset_logging()
	end


	it "uses the wordnet-defaultdb database gem (if available) when created with no arguments" do
		Gem.should_receive( :datadir ).with( 'wordnet-defaultdb' ).
			and_return( '/tmp/foo' )

		lex = WordNet::Lexicon.new
		lex.db.should be_a( Sequel::Database )
		lex.db.uri.should == 'sqlite://tmp/foo/wordnet30.sqlite'
	end

	it "accepts uri, options for the database connection", :ruby_1_9_only => true do
		WordNet::Lexicon.new( 'postgres://localhost/test', :username => 'test' )
		WordNet::Model.db.uri.should == 'postgres://test@localhost/test'
	end


	context "with the default database", :requires_database => true do

		before( :all ) do
			@lexicon = WordNet::Lexicon.new
		end

		it "can look up a word via its index operator" do
			rval = @lexicon[ :carrot ]
			rval.should be_a( WordNet::Word )
			rval.lemma.should == 'carrot'
		end

	end

end

