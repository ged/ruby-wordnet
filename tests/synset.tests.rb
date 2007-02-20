#!/usr/bin/ruby

require "wntestcase"
require "bdb"

class SynsetTests < WordNet::TestCase

	Accessors = [
		:part_of_speech,
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
		:verb_groups,
		:similar_to,
		:participles,
		:pertainyms,
		:attributes,
		:derived_from,
		:derivations,
		:see_also,

        :instance_hyponyms,

        :instance_hypernyms,

		:member_meronyms,
		:stuff_meronyms,
		:portion_meronyms,
		:component_meronyms,
		:feature_meronyms,
		:phase_meronyms,
		:place_meronyms,

		:member_holonyms,
		:stuff_holonyms,
		:portion_holonyms,
		:component_holonyms,
		:feature_holonyms,
		:phase_holonyms,
		:place_holonyms,

		:category_domains,
		:region_domains,
		:usage_domains,

		:category_members,
		:region_members,
		:usage_members,
	]

	AggregateRelationMethods = [
		:meronyms,
		:holonyms,
		:domains,
		:members,
	]
		

	### Make sure the Lexicon's loaded
	def setup
        super

		@blankSyn = WordNet::Synset::new( @lexicon, "1%n", WordNet::Noun )
		@traversalSyn = @lexicon.lookup_synsets( 'linguistics', :noun, 1 )
	end


	#################################################################
	###	T E S T S
	#################################################################

	### Accessors
	def test_accessors
		printTestHeader "Synset: Accessors"
		rval = nil

		assert_respond_to @blankSyn, :lexicon
		
		Accessors.each do |meth|
			assert_respond_to @blankSyn, meth
			assert_respond_to @blankSyn, "#{meth}="

			assert_nothing_raised do
				rval = @blankSyn.send( meth )
			end
		end
	end

	### Relations
	def test_relations
		printTestHeader "Synset: Relation methods"
		rval = nil
		
		RelationMethods.each do |meth|
			casemeth = meth.to_s.sub( /^(\w)/ ) {|char| char.upcase }.intern

			assert_respond_to @blankSyn, meth
			assert_respond_to @blankSyn, "#{meth}="

			assert_nothing_raised {
				rval = @blankSyn.send( meth )
			}

			assert_instance_of Array, rval
		end
	end

	### Aggregate relation methods
	def test_aggregate_relations
		printTestHeader "Synset: Aggregate relations"
		rval = nil
		
		AggregateRelationMethods.each {|meth|
			assert_respond_to @blankSyn, meth

			assert_nothing_raised {
				rval = @blankSyn.send( meth )
			}

			assert_instance_of Array, rval
		}
	end

	### Traversal method
	def test_synset_should_respond_to_traverse_method
		printTestHeader "Synset: Traversal method"
		assert_respond_to @traversalSyn, :traverse
	end

    ### :TODO: This should really be split into two tests.
	### Traversal: include origin, break loop
	def test_traversal_with_true_second_arg_should_include_origin
		printTestHeader "Synset: Traversal, including origin, break"
		rval = nil
		count = depth = 0
		sets = []

		assert_nothing_raised {
			rval = @traversalSyn.traverse( :hyponyms, true ) {|tsyn,tdepth|
				sets << tsyn
				depth = tdepth
				count += 1
				return true
			}
		}
		assert_equal true, rval
		assert_equal 1, sets.length
		assert_equal @traversalSyn, sets[0]
		assert_equal 0, depth
		assert_equal 1, count
	end

    ### :TODO: This should really be split into two tests.
	### Traversal: exclude origin, break loop
	def test_traversal_with_false_second_arg_should_not_include_origin
		printTestHeader "Synset: Traversal, excluding origin, break"
		rval = nil
		count = depth = 0
		sets = []

		assert_nothing_raised {
			rval = @traversalSyn.traverse( :hyponyms, false ) {|tsyn,tdepth|
				sets << tsyn
				depth = tdepth
				count += 1
				return true
			}
		}
		assert_equal true, rval
		assert_equal 1, sets.length
		assert_not_equal @traversalSyn, sets[0]
		assert_equal 1, depth
		assert_equal 1, count
	end

	### Traversal: include origin, nobreak, noblock
	def test_hyponym_traversal_with_no_block_should_return_appropriate_hyponyms
		printTestHeader "Synset: Traversal, include origin, nobreak, noblock"
		sets = []

		assert_nothing_raised {
			sets = @traversalSyn.traverse( :hyponyms )
		}
		assert_block { sets.length > 1 }
		assert_equal @traversalSyn, sets[0]
		assert_block { sets.find {|hsyn| hsyn.words.include?( "grammar" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "syntax" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "computational linguistics" )} }
	end
	

	### Traversal: exclude origin, nobreak, noblock
	def test_hyponym_traversal_with_no_block_and_false_second_arg_should_return_holonyms_but_not_the_origin
		printTestHeader "Synset: Traversal, exclude origin, nobreak, noblock"
		sets = []

		assert_nothing_raised {
			sets = @traversalSyn.traverse( :hyponyms, false )
		}
		assert_block { sets.length > 1 }
		assert_not_equal @traversalSyn, sets[0]
		assert_block { sets.find {|hsyn| hsyn.words.include?( "grammar" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "syntax" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "computational linguistics" )} }
	end
	

	### Traversal: include origin, nobreak, noblock
	def test_traversal_break_after_3_should_include_three_sets_plus_origin
		printTestHeader "Synset: Traversal, break after 3"
		rval = nil
		sets = Hash::new {|hsh,key| hsh[key] = []}

		assert_nothing_raised {
			rval = @traversalSyn.traverse( :hyponyms ) {|tsyn,tdepth|
				sets[tdepth] << tsyn
				tdepth == 3
			}
		}
		assert_equal 4, sets.keys.length
		assert_equal [0,1,2,3], sets.keys.sort
		assert_equal 1, sets[3].length
		assert rval, "Break early flag expected to be set"
	end


	### Part of speech: part_of_speech
	def test_part_of_speech_should_return_the_symbol_part_of_speech
		printTestHeader "Synset: part_of_speech"
		rval = nil

		assert_nothing_raised { rval = @traversalSyn.part_of_speech }
		assert_equal :noun, rval
	end


	### Part of speech: pos
	def test_pos_should_return_the_synsets_singlechar_part_of_speech
		printTestHeader "Synset: pos"
		rval = nil

		assert_nothing_raised { rval = @traversalSyn.pos }
		assert_equal "n", rval
	end


	### :TODO: Test traversal, content, storing, higher-order functions


end


