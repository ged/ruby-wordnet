#!/usr/bin/ruby

#
# This is a walkit test suite for the WordNet::Lexicon class.
#

$: << "../lib" if File.directory?( "../lib" )
$: << "lib" if File.directory?( "lib" )

require "walkit/cli_script"
require "WordNet"
require "bdb"

class LexiconTests < Walkit::Testclass

	indexDb	= BDB::Btree.open( "#{WordNet::DICTDIR}/lingua_wordnet.index", nil, BDB::CREATE, 0666 )
	dataDb	= BDB::Btree.open( "#{WordNet::DICTDIR}/lingua_wordnet.data", nil, BDB::CREATE, 0666 )
	morphDb	= BDB::Btree.open( "#{WordNet::DICTDIR}/lingua_wordnet.morph", nil, BDB::CREATE, 0666 )

	TestWords = {
		'activity'	=> { 'pos' => WordNet::NOUN	},
		'sword'		=> { 'pos' => WordNet::NOUN },
		'density'	=> { 'pos' => WordNet::NOUN },
		'burly'		=> { 'pos' => WordNet::ADJECTIVE },
		'wispy'		=> { 'pos' => WordNet::ADJECTIVE },
		'traditional' => { 'pos' => WordNet::ADJECTIVE },
		'sit'		=> { 'pos' => WordNet::VERB },
		'take'		=> { 'pos' => WordNet::VERB },
		'joust'		=> { 'pos' => WordNet::VERB }
	}

	# Now fetch information about each word from the db
	TestWords.each_pair {|word,val|
		# familiarities
		poly, offsets = indexDb[ "#{word}%#{val['pos']}" ].split(/\|\|/)
		val['fam'] = poly.to_i
		val['data'] = {}
		offsets.split(/\|/).collect {|off| "#{off}%#{val['pos']}" }.each {|offset|
			fileno, words, ptrs, frames, gloss = dataDb[offset].split(/\|\|/)
			val['data'][offset] = {
				'fileno'	=> fileno,
				'words'		=> words,
				'ptrs'		=> ptrs,
				'frames'	=> frames,
				'gloss'		=> gloss
			}
		}
	}

	#require "pp"
	#pp TestWords

	def setup
		@lexicon = WordNet::Lexicon.new( "/usr/local/wordnet1.7/lingua-wordnet" )
	end

	def teardown
		@lexicon = nil
	end

	# Make sure the constructor worked
	def test_00_constructor
		vet { assert_instance_of WordNet::Lexicon, @lexicon }
	end

	# Test to be sure closing the lexicon works, and that it makes it inactive
	def test_01_close
		vet { assert @lexicon.active? }
		vet { assert_no_exception { @lexicon.close } }
		vet { assert ! @lexicon.active? }
		vet { assert_exception(WordNet::LexiconError) { @lexicon.familiarity("activity", WordNet::NOUN) } }
	end

	# Test locking
	def test_02_lock
		vet { assert @lexicon.locked? }
		vet { assert_no_exception {@lexicon.unlock} }
		vet { assert ! @lexicon.locked? }
		vet { assert_no_exception {@lexicon.lock} }
		vet { assert @lexicon.locked? }
	end

	# Test familiarity
	def test_03_familiarity
		result = nil

		TestWords.each_pair {|word,attr|
			vet {
				fam = nil
				assert_no_exception { fam = @lexicon.familiarity( word, attr['pos'] ) }
				assert_equals attr['fam'], fam
			}
		}
	end

	# Test morph
	def test_04_morph
		res = nil

		vet {
			assert_no_exception { res = @lexicon.morph("angriest", WordNet::ADJECTIVE) }
			assert_equal "angry", res
		}

		vet {
			assert_no_exception { res = @lexicon.morph("Passomoquoddy", WordNet::NOUN ) }
			assert_nil res
		}
	end

	# Test reverse morph
	def test_05_morph
		res = nil

		vet {
			assert_no_exception { res = @lexicon.reverseMorph("angry") }
			assert_matches res, /^angr/
		}
	end

	# Test grep
	def test_06_grep
		words = []

		vet {
			assert_no_exception { words = @lexicon.grep( "thing" ) }
			words.each {|word|
				assert_matches word, /^thing/
			}
		}
	end

	# Test synset lookup (which also tests synset-by-offset lookup)
	def test_07_lookupSynsets
		synsets = []

		TestWords.each_pair {|word,attr|
			vet {
				assert_no_exception { synsets |= @lexicon.lookupSynsets(word, attr['pos']) }

				attr['data'].each_pair {|offset,data|
					assert_not_nil synsets.detect {|syn| syn.offset == offset}
				}
			}
		}
	end

	# Test synset creation via factory method
	def test_08_createSynset
		synset = nil

		vet {
			assert_no_exception { synset = @lexicon.createSynset("Ruby", WordNet::NOUN) }
			assert_instance_of WordNet::Synset, synset
		}
	end


	# :TODO: Test storeSynset()?

end

if $0 == __FILE__
    Walkit::Cli_script.new.select([LexiconTests], $*.shift)
end

