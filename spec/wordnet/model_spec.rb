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

require 'spec/lib/helpers'
require 'wordnet'
require 'wordnet/model'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Model do

	before( :all ) do
		setup_logging( :fatal )
	end

	before( :each ) do
		MODEL_DB.reset
	end

	after( :all ) do
		reset_logging()
	end

	it "propagates database handle changes to all of its subclasses" do
		subclass = WordNet::Model( :tests )
		newdb = Sequel.mock
		WordNet::Model.db = newdb
		subclass.db.should equal( newdb )
	end


end

