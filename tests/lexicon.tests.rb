#!/usr/bin/ruby

require "wntestcase"
require "bdb"

class LexiconTests < WordNet::TestCase

	TestWords = {
		'activity'		=> WordNet::Noun,
		'sword'			=> WordNet::Noun,
		'density'		=> WordNet::Noun,
		'burly'			=> WordNet::Adjective,
		'wispy'			=> WordNet::Adjective,
		'traditional'	=> WordNet::Adjective,
		'sit'			=> WordNet::Verb,
		'take'			=> WordNet::Verb,
		'joust'			=> WordNet::Verb,
	}


	#################################################################
	###	T E S T S
	#################################################################

	### Class + constructor
	def test_00_constructor
		printTestHeader "Lexicon: Constructor"
		rval = nil

		assert_instance_of Module, WordNet
		assert_instance_of Class, WordNet::Lexicon
		assert_instance_of Class, WordNet::Synset

		assert_nothing_raised {
			# This can't be a per-test instance var because bdb segfaults for
			# some reason if you destroy and re-create it for each test...
			$lexicon ||= WordNet::Lexicon::new
		}

		assert_instance_of WordNet::Lexicon, $lexicon
	end

	### Database methods
	def test_10_DbMethods
		printTestHeader "Lexicon: Database methods"
		rval = nil

		# DB handles
		assert_nothing_raised { rval = $lexicon.env }
		assert_instance_of BDB::Env, rval

		[ :indexDb, :morphDb, :dataDb ].each {|db|
			assert_nothing_raised {
				rval = $lexicon.send( db )
			}
			assert_instance_of BDB::Btree, rval
		}

		# Checkpoint the DB
		assert_nothing_raised {
			$lexicon.checkpoint
		}

		# Fetch the list of archival logs
		assert_nothing_raised {
			rval = $lexicon.archlogs
		}
		assert_instance_of Array, rval

		# Delete old logs
		assert_nothing_raised {
			$lexicon.cleanLogs
		}
	end


	### Test familiarity
	def test_20_Familiarity
		printTestHeader "Lexicon: Familiarity"
		res = nil

		TestWords.each {|word, pos|
			assert_nothing_raised( "Familiarity for #{word}(#{pos})" ) {
				res = $lexicon.familiarity( word, pos )
			}
			assert_instance_of Fixnum, res
		}
	end


	### Test morphology
	def test_25_Morph
		printTestHeader "Lexicon: Morphology"
		res = nil

		assert_nothing_raised {
			res = $lexicon.morph("angriest", WordNet::Adjective)
		}
		assert_equal "angry", res

		assert_nothing_raised {
			res = $lexicon.morph("Passomoquoddy", WordNet::Noun )
		}
		assert_nil res
	end


	### Test reverse morph
	def test_30_ReverseMorph
		printTestHeader "Lexicon: Reverse morphology"
		res = nil

		assert_nothing_raised {
			res = $lexicon.reverseMorph("angry")
		}
		assert_match( /^angr/, res )
	end


	### Test grep
	def test_35_Grep
		printTestHeader "Lexicon: Grep"
		words = []

		assert_nothing_raised {
			words = $lexicon.grep( "thing" )
		}
		words.each {|word|
			assert_match( /^thing/, word )
		}
	end


	### Test synset lookup (which also tests synset-by-offset lookup)
	def test_40_LookupSynsets
		printTestHeader "Lexicon: Lookup synsets"
		rval = nil

		TestWords.each {|word,pos|
			assert_nothing_raised {
				rval, rest = $lexicon.lookupSynsets( word, pos )
			}

			assert_instance_of WordNet::Synset, rval

			# :TODO: Should test synsets for content, but I've yet to condense a
			# test dataset for it from the WordNet sources.
		}
	end


	### Test synset creation via factory method
	def test_45_CreateSynset
		printTestHeader "Lexicon: Create Synset via Factory Method"
		synset = nil

		assert_nothing_raised {
			synset = $lexicon.createSynset( "Ruby", WordNet::Noun )
		}
		assert_instance_of WordNet::Synset, synset
	end


	# :TODO: Test storeSynset()?

end

