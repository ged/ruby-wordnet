#!/usr/bin/env rspec
require_relative '../helpers'

require 'rspec'
require 'sequel'

require 'wordnet'
require 'wordnet/model'


#####################################################################
###	C O N T E X T S
#####################################################################

DB = Sequel.connect( 'mock://postgres' )

describe WordNet::Model do

	it "propagates database handle changes to all of its subclasses" do
		subclass = WordNet::Model( :tests )
		newdb = Sequel.mock
		WordNet::Model.db = newdb
		expect( subclass.db ).to equal( newdb )
	end

end

