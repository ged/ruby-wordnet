#!/usr/bin/ruby

# This is a port of the test.pl script that comes with Lingua::Wordnet. It's
# here to make sure this library is at least functionally compatible.

$: << "../lib" if File.directory?( "../lib" )
$: << "lib" if File.directory?( "lib" )

require "runit/cui/testrunner"
require "runit/testcase"

require "WordNet"

class LinguaWordnetTests < RUNIT::TestCase

	def setup
		@lexicon = WordNet::Lexicon.new
	end

	def teardown
		@lexicon = nil
	end

	def test_pl
		synset = nil
		synset2 = nil

		assert_no_exception { synset = @lexicon.lookupSynsetByOffset( "00333350%n" ) }
		assert_instance_of WordNet::Synset, synset

		words = ''

		synset.hyponyms.each {|bb_synset|
			bb_synset.words += ["ballser"]
			bb_synset.words.each {|word| words += "#{word}, "}
		}

		assert_match words, /hardball/

		words = ''
		synset2 = @lexicon.lookupSynsets( "travel", WordNet::VERB, 2 )
		synset2.words.each {|word| words += "#{word}, "}
		
		assert_match words, /journey/
		assert_equal @lexicon.familiarity("boy", WordNet::NOUN), 4
		assert_equal @lexicon.morph("bluest", WordNet::ADJECTIVE), "blue"
		assert_match "#{synset}", /baseball/
	end
end

if $0 == __FILE__
    RUNIT::CUI::TestRunner.run(LinguaWordnetTests.suite)
end

