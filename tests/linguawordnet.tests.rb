#!/usr/bin/ruby

require "wntestcase"

class LexiconTests < WordNet::TestCase

	$lexicon ||= WordNet::Lexicon::new

	BaseballOffset = '00447188%n'

	def test_00_PerlTests
		synset = nil
		synset2 = nil

		assert_nothing_raised {
			synset = $lexicon.lookupSynsetsByKey( BaseballOffset )
		}
		assert_instance_of WordNet::Synset, synset

		words = ''
		synset.hyponyms.each {|bb_synset|
			bb_synset.words += ["ballser"]
			bb_synset.words.each {|word| words += "#{word}, "}
		}
		assert_match( /hardball/, words )

		words = ''
		synset2 = $lexicon.lookupSynsets( "travel", WordNet::Verb, 2 )
		synset2.words.each {|word| words += "#{word}, "}
		assert_match( /journey/, words )

		assert_equal 4, $lexicon.familiarity( "boy", WordNet::Noun )
		assert_equal "blue", $lexicon.morph( "bluest", WordNet::Adjective ) 
		assert_match( /baseball/, "#{synset}" )
	end
end
