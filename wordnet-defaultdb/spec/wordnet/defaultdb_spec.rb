#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'rspec'

require 'wordnet'
require 'wordnet/defaultdb'


RSpec.describe WordNet::DefaultDB do

	it "knows what the URL of its database is" do
		expect( described_class.uri ).to start_with( 'sqlite:' ).and( end_with('wordnet31.sqlite') )
	end


	it "returns nil if its data file does not exist" do
		expect( FileTest ).to receive( :exist? ).with( a_string_ending_with('wordnet31.sqlite') ).
			and_return( false )
		expect( described_class.uri ).to be_nil
	end

end

