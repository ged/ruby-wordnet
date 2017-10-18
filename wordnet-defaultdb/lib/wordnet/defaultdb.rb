# -*- ruby -*-
#encoding: utf-8

require 'wordnet'
require 'pathname'

# This gem is a container for the default database files required for the
# 'wordnet' gem. It's mostly just a wrapper around the Sqlite database from
# SQLUNet:
#
#	 http://sqlunet.sourceforge.net/
#
module WordNet::DefaultDB

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
			Pathname( __FILE__ ).dirname.parent.parent + 'data/wordnet-defaultdb'
		end

	# The name of the bundled Sqlite database
	DATABASE_FILENAME = 'wordnet31.sqlite'


	### Return the Sequel URI for the database
	def self::uri
		dbfile = WordNet::DefaultDB::DATA_DIR + DATABASE_FILENAME
		return nil unless dbfile.exist?
		return "sqlite:%s" % [ dbfile ]
	end

end # module WordNet::DefaultDB
