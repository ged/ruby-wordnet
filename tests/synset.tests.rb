#!/usr/bin/ruby

#
# This is a walkit test suite for the WordNet::Synset class
#

$: << "../lib" if File.directory?( "../lib" )
$: << "lib" if File.directory?( "lib" )

require "runit/cui/testrunner"
require "runit/testcase"

require "WordNet"
require "bdb"

class SynsetTests < RUNIT::TestCase

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

	# Look up data for a synset for testing words: "thing" sense 8
	TestSyns = {
		'words'		=> {
			'offset'	=> "04778617%n",
			'data'		=> dataDb[ "04778617%n" ].split(/\|\|/)[1],
		},

		'antonyms'	=> {
		},
	}


	#require "pp"
	#pp TestWords

	def setup
		@lexicon = WordNet::Lexicon.new( "/usr/local/wordnet1.7/lingua-wordnet" )
	end

	def teardown
		@lexicon = nil
	end

	# Make sure the synset factory method on the lexicon object works
	def test_00_factory
		synset = nil

		assert_no_exception { synset = @lexicon.createSynset("Ruby", WordNet::NOUN) }
		assert_instance_of WordNet::Synset, synset
	end

	# Test various static attribute accessors, and by extension the data-parsing
	# code behind them
	def test_01_attrAccessors
		synsets = nil

		TestWords.each_pair {|word,hash|
			assert_no_exception		{synsets = @lexicon.lookupSynsets( word, hash['pos'] )}
			assert_instance_of		Array, synsets
			assert_equal			hash['data'].length, synsets.length

			synsets.each {|syn|
				assert_matches		syn.offset, /\d+%\w/

				data = hash['data'][syn.offset]

				assert_equal		data['fileno'], syn.filenum
				assert_equal		data['words'], syn.wordlist
				assert_equal		data['ptrs'], syn.pointerlist
				assert_equal		data['frames'], syn.frameslist
				assert_equal		data['gloss'], syn.gloss
			}
		}
	end

	# Test wordlist manipulation methods
	def test_02_wordMethods

		# Get the entry for 'thing, matter, affair'
		synset = @lexicon.lookupSynsetByOffset( TestSyns['words']['offset'] ) or raise RuntimeError
		words = []

		assert_equals TestSyns['words']['data'], synset.wordlist

		assert_no_exception { words = synset.words }
		dataWords = TestSyns['words']['data'].split(/\|/)
			
		assert_equal dataWords, words
	end

	# :TODO: Write tests for pointers (perhaps automate by scanning dataDb for
	# pointer-characters?)

end

if $0 == __FILE__
    RUNIT::CUI::TestRunner.run(SynsetTests.suite)
end

