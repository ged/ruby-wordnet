#!/usr/bin/ruby

require "wntestcase"

class LexiconTests < WordNet::TestCase

	OldBaseballOffset = '00466621%n'
	BaseballOffset = '00471613%n'

	def test_perl_tests
		synset = nil
		synset2 = nil

		begin
			synset = @lexicon.lookup_synsets_by_key( BaseballOffset )
		rescue WordNet::LookupError
			synset = @lexicon.lookup_synsets_by_key( OldBaseballOffset )
		end

		assert_instance_of WordNet::Synset, synset

		words = ''
		synset.hyponyms.each do |bb_synset|
			bb_synset.words += ["ballser"]
			bb_synset.words.each {|word| words += "#{word}, "}
		end
		assert_match( /hardball/, words )

		words = ''
		synset2 = @lexicon.lookup_synsets( "travel", WordNet::Verb, 2 )
		synset2.words.each {|word| words += "#{word}, "}
		assert_match( /journey/, words )

		assert_equal 4, @lexicon.familiarity( "boy", WordNet::Noun )
		assert_equal "blue", @lexicon.morph( "bluest", WordNet::Adjective ) 
		assert_match( /baseball/, "#{synset}" )
	end
end
