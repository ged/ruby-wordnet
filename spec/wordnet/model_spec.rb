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

end

