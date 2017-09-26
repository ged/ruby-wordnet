#!/usr/bin/env ruby

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
		VERSION = '1.0.0'

		# Version-control revision constant
		REVISION = %q$Revision$

	end # module DefaultDB
end # module Wordnet

