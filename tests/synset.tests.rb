#!/usr/bin/ruby

require "wntestcase"
require "bdb"

class SynsetTests < WordNet::TestCase

	Accessors = [
		:lexicon,
		:partOfSpeech,
		:offset,
		:filenum,
		:wordlist,
		:pointerlist,
		:frameslist,
		:gloss,
	]

	RelationMethods = [
		:antonyms,
		:hypernyms,
		:entailment,
		:hyponyms,
		:causes,
		:verbgroups,
		:similarTo,
		:participles,
		:pertainyms,
		:attributes,
		:derivedFrom,
		:seeAlso,
		:functions,
		:memberMeronyms,
		:stuffMeronyms,
		:portionMeronyms,
		:componentMeronyms,
		:featureMeronyms,
		:phaseMeronyms,
		:placeMeronyms,
		:memberHolonyms,
		:stuffHolonyms,
		:portionHolonyms,
		:componentHolonyms,
		:featureHolonyms,
		:phaseHolonyms,
		:placeHolonyms,
	]
		
	AggregateRelationMethods = [
		:allMeronyms,
		:allHolonyms,
	]


	### Make sure the Lexicon's loaded
	def setup
		$lexicon ||= WordNet::Lexicon::new
		super
	end


	#################################################################
	###	T E S T S
	#################################################################

	### Class + constructor
	def test_00_constructor
		printTestHeader "Synset: Constructor"
		rval = nil

		assert_instance_of Class, WordNet::Synset
		assert_raises( ArgumentError ) {
			rval = WordNet::Synset::new
		}
		assert_raises( ArgumentError ) {
			rval = WordNet::Synset::new( $lexicon )
		}
		assert_raises( ArgumentError ) {
			rval = WordNet::Synset::new( $lexicon, "1%n" )
		}


		assert_nothing_raised {
			rval = WordNet::Synset::new( $lexicon, "1%n", WordNet::Noun )
		}
		assert_instance_of WordNet::Synset, rval

		self.class.addSetupBlock {
			@blankSyn = WordNet::Synset::new( $lexicon, "1%n", WordNet::Noun )
		}
		self.class.addTeardownBlock {
			@blankSyn = nil
		}
	end


	### Accessors
	def test_10_accessors
		printTestHeader "Synset: Accessors"
		rval = nil
		
		Accessors.each {|meth|
			assert_respond_to @blankSyn, meth
			assert_respond_to @blankSyn, "#{meth}="
		}
	end


	### Relations
	def test_20_relations
		printTestHeader "Synset: Relation methods"
		rval = nil
		
		RelationMethods.each {|meth|
			casemeth = meth.to_s.sub( /^(\w)/ ) {|char| char.upcase }.intern

			assert_respond_to @blankSyn, meth
			assert_respond_to @blankSyn, "#{meth}="
			assert_respond_to @blankSyn, "add#{casemeth}"
			assert_respond_to @blankSyn, "delete#{casemeth}"
		}
	end


	### Aggregate relation methods
	def test_30_aggregateRelations
		printTestHeader "Synset: Aggregate relations"
		rval = nil
		
		AggregateRelationMethods.each {|meth|
			assert_respond_to @blankSyn, meth
		}
	end


	### :TODO: Test traversal, content, storing, higher-order functions

end


