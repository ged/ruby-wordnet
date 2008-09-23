#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'fileutils'
	require 'tmpdir'
	require 'bdb'
	require 'spec/runner'
	require 'spec/lib/helpers'

	require 'wordnet/lexicon'
	require 'wordnet/synset'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Synset do

end


