#!/usr/bin/ruby

# This is a port of the test.pl script that comes with Lingua::Wordnet. It's
# here to make sure this library is at least functionally compatible.

$: << "../lib" if File.directory?( "../lib" )
$: << "lib" if File.directory?( "lib" )

require "walkit/cli_script"
require "WordNet"

class LinguaWordnetTests < Walkit::Testclass

	def setup
		@lexicon = WordNet::Lexicon.new
	end

	def teardown
		@lexicon = nil
	end

	def test_pl
		synset = nil
		synset2 = nil

		vet {
			assert_no_exception { synset = @lexicon.lookupSynsetByOffset( "00333350%n" ) }
			assert_instance_of WordNet::Synset, synset
		}

		vet {
			words = ''

			synset.hyponyms.each {|bb_synset|
				bb_synset.words += ["ballser"]
				bb_synset.words.each {|word| words += "#{word}, "}
			}

			assert_match words, /hardball/
		}

		vet {
			words = ''
			synset2 = @lexicon.lookupSynsets( "travel", WordNet::VERB, 2 )[0]
			synset2.words.each {|word| words += "#{word}, "}
		
			assert_match words, /journey/
		}

		vet {
			assert_equal @lexicon.familiarity("boy", WordNet::NOUN), 4
		}

		vet {
			assert_equal @lexicon.morph("bluest", WordNet::ADJECTIVE), "blue"
		}

		vet {
			assert_match "#{synset}", /baseball/
		}
	end
end

if $0 == __FILE__
    Walkit::Cli_script.new.select([LinguaWordnetTests], $*.shift)
end

