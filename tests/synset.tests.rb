#!/usr/bin/ruby

require "wntestcase"
require "bdb"

class SynsetTests < WordNet::TestCase

	Accessors = [
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

		:categoryDomains,
		:regionDomains,
		:usageDomains,

		:categoryMembers,
		:regionMembers,
		:usageMembers,
	]

	AggregateRelationMethods = [
		:meronyms,
		:holonyms,
		:domains,
		:members,
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

		assert_respond_to @blankSyn, :lexicon
		
		Accessors.each {|meth|
			assert_respond_to @blankSyn, meth
			assert_respond_to @blankSyn, "#{meth}="

			assert_nothing_raised {
				rval = @blankSyn.send( meth )
			}
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

			assert_nothing_raised {
				rval = @blankSyn.send( meth )
			}

			assert_instance_of Array, rval
		}
	end

	### Aggregate relation methods
	def test_30_aggregateRelations
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
	def test_40_traversal_method
		printTestHeader "Synset: Traversal method"
		syn = rval = depth = count = nil
		sets = []

		syn = $lexicon.lookupSynsets( 'linguistics', :noun, 1 )

		assert_respond_to syn, :traverse
		self.class.addSetupBlock {
			@syn = $lexicon.lookupSynsets( 'linguistics', :noun, 1 )
		}
		self.class.addTeardownBlock {
			@syn = nil
		}
	end

	### Traversal: include origin, break loop
	def test_41_traversal_break_includeOrigin
		printTestHeader "Synset: Traversal, including origin, break"
		rval = nil
		count = depth = 0
		sets = []

		assert_nothing_raised {
			rval = @syn.traverse( :hyponyms, true ) {|tsyn,tdepth|
				sets << tsyn
				depth = tdepth
				count += 1
				return true
			}
		}
		assert_equal true, rval
		assert_equal 1, sets.length
		assert_equal @syn, sets[0]
		assert_equal 0, depth
		assert_equal 1, count
	end

	### Traversal: exclude origin, break loop
	def test_42_traversal_break_excludeOrigin
		printTestHeader "Synset: Traversal, excluding origin, break"
		rval = nil
		count = depth = 0
		sets = []

		assert_nothing_raised {
			rval = @syn.traverse( :hyponyms, false ) {|tsyn,tdepth|
				sets << tsyn
				depth = tdepth
				count += 1
				return true
			}
		}
		assert_equal true, rval
		assert_equal 1, sets.length
		assert_not_equal @syn, sets[0]
		assert_equal 1, depth
		assert_equal 1, count
	end

	### Traversal: include origin, nobreak, noblock
	def test_43_traversal_includeOrigin_noblock_nobreak
		printTestHeader "Synset: Traversal, include origin, nobreak, noblock"
		sets = []

		assert_nothing_raised {
			sets = @syn.traverse( :hyponyms )
		}
		assert_block { sets.length > 1 }
		assert_equal @syn, sets[0]
		assert_block { sets.find {|hsyn| hsyn.words.include?( "grammar" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "syntax" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "computational linguistics" )} }
	end
	

	### Traversal: include origin, nobreak, noblock
	def test_44_traversal_excludeOrigin_noblock_nobreak
		printTestHeader "Synset: Traversal, exclude origin, nobreak, noblock"
		sets = []

		assert_nothing_raised {
			sets = @syn.traverse( :hyponyms, false )
		}
		assert_block { sets.length > 1 }
		assert_not_equal @syn, sets[0]
		assert_block { sets.find {|hsyn| hsyn.words.include?( "grammar" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "syntax" )} }
		assert_block { sets.find {|hsyn| hsyn.words.include?( "computational linguistics" )} }
	end
	

	### Traversal: include origin, nobreak, noblock
	def test_45_traversal_break_after_3
		printTestHeader "Synset: Traversal, break after 3"
		rval = nil
		sets = Hash::new {|hsh,key| hsh[key] = []}

		assert_nothing_raised {
			rval = @syn.traverse( :hyponyms ) {|tsyn,tdepth|
				sets[tdepth] << tsyn
				tdepth == 3
			}
		}
		assert_equal 4, sets.keys.length
		assert_equal [0,1,2,3], sets.keys.sort
		assert_equal 1, sets[3].length
		assert rval, "Break early flag expected to be set"
	end


	### Part of speech: partOfSpeech
	def test_50_part_of_speech
		printTestHeader "Synset: partOfSpeech"
		rval = nil

		assert_nothing_raised { rval = @syn.partOfSpeech }
		assert_equal :noun, rval
	end


	### Part of speech: pos
	def test_51_pos
		printTestHeader "Synset: pos"
		rval = nil

		assert_nothing_raised { rval = @syn.pos }
		assert_equal "n", rval
	end


	### :TODO: Test traversal, content, storing, higher-order functions


end


