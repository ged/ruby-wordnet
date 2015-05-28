#!/usr/bin/env rspec
require_relative 'helpers'

require 'rspec'
require 'wordnet/lexicon'


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet do

	it "returns a version string if asked" do
		expect( WordNet.version_string ).to match( /\w+ [\d.]+/ )
	end


	it "returns a version string with a build number if asked" do
		expect( WordNet.version_string(true) ).to match( /\w+ [\d.]+ \(build [[:xdigit:]]+\)/ )
	end


end

