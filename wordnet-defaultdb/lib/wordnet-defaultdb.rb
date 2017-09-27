#!/usr/bin/env ruby

require 'pathname'

# This gem is a container for the default WordNetSQL database files required for
# the 'wordnet' gem. It's mostly just a wrapper around the Sqlite database from:
#
#   http://sqlunet.sourceforge.net/
#
# == Author/s
#
# * Michael Granger <ged@FaerieMUD.org>
#
module WordNet
	module DefaultDB

		# Library version constant
		VERSION = '2.0.0'

		# Version-control revision constant
		REVISION = %q$Revision$

		# The data directory which contains the database file
		DATA_DIR = if ENV['WORDNET_DEFAULTDB_DATADIR']
				Pathname( ENV['WORDNET_DEFAULTDB_DATADIR'] )
			elsif Gem.datadir( 'wordnet-defaultdb' ) && File.directory?( Gem.datadir('wordnet-defaultdb') )
				Pathname( Gem.datadir('wordnet-defaultdb') )
			else
				Pathname( __FILE__ ).dirname.parent + 'data/wordnet-defaultdb'
			end


		### The Sequel URI for the database
		def self::uri
			
		end

	end # module DefaultDB
end # module Wordnet

