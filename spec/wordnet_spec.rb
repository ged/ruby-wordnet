#!/usr/bin/env ruby

BEGIN {
	require 'pathname'

	basedir = Pathname.new( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'spec/lib/helpers'
require 'wordnet/lexicon'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet do
	include WordNet::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	it "returns a version string if asked" do
		WordNet.version_string.should =~ /\w+ [\d.]+/
	end


	it "returns a version string with a build number if asked" do
		WordNet.version_string(true).should =~ /\w+ [\d.]+ \(build [[:xdigit:]]+\)/
	end


end

