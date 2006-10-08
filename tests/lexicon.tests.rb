#!/usr/bin/ruby

require "wntestcase"
require "bdb"
require 'tmpdir'
require 'fileutils'


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


	def setup
		super
		GC.disable
	end
	
	def teardown
		GC.enable
		super
	end


	#################################################################
	###	T E S T S
	#################################################################


	def test_default_open_with_new_dir_should_fail
		printTestHeader "Lexicon: ':readonly' creation with new dir"
		
		make_testing_directory do |path|
			assert_raises( BDB::Fatal ) do
				WordNet::Lexicon::new( path )
			end
		end
	end


	def test_writable_open_with_new_dir_should_succeed
		printTestHeader "Lexicon: ':writable' creation with new dir"

		make_testing_directory do |path|
			assert_nothing_raised do
				WordNet::Lexicon::new( path, :writable )
			end
		end
	end


	def test_readwrite_open_with_new_dir_should_succeed
		printTestHeader "Lexicon: ':readwrite' creation with new dir"

		make_testing_directory do |path|
			assert_nothing_raised do
				WordNet::Lexicon::new( path, :readwrite )
			end
		end
	end


	def test_default_open_with_existing_dir_should_succeed
		make_testing_directory do |path|
			WordNet::Lexicon::new( path, :readwrite ).checkpoint

			assert_nothing_raised do
				WordNet::Lexicon::new( path )
			end
		end
	end


	def test_familiarity_for_testwords_should_all_return_a_fixnum
		printTestHeader "Lexicon: Familiarity for testwords should all return a Fixnum"
		res = nil

		TestWords.each do |word, pos|
			assert_nothing_raised( "Familiarity for #{word}(#{pos})" ) do
				res = @lexicon.familiarity( word, pos )
			end
			assert_instance_of Fixnum, res
		end
	end


	def test_morphology_of_dictionary_word_should_return_root_word
		printTestHeader "Lexicon: Morphology should "
		res = nil

		assert_nothing_raised do
			res = @lexicon.morph( "angriest", WordNet::Adjective )
		end
		assert_equal "angry", res
	end


	def test_morphology_of_nondictionary_word_should_return_nil
		printTestHeader "Lexicon: Morphology should "
		res = nil

		assert_nothing_raised do
			res = @lexicon.morph( "Passomoquoddy", WordNet::Noun )
		end
		assert_equal nil, res
	end


	def test_reverse_morphology_should_return_inverse
		printTestHeader "Lexicon: Reverse morphology"
		res = nil

		assert_nothing_raised do
			res = @lexicon.reverseMorph( "angry" )
		end

		# Don't want this to fail if WordNet data changes, so just match the
		# beginning
		assert_match( /^angr/, res )
	end


	def test_grep_finds_compound_words
		printTestHeader "Lexicon: Grep"
		words = []

		assert_nothing_raised do
			words = @lexicon.grep( "thing" )
		end
		words.each do |word|
			assert_match( /^thing/, word )
		end
	end


	### Test synset lookup (which also tests synset-by-offset lookup)
	def test_lookup_synsets
		printTestHeader "Lexicon: Lookup synsets"
		rval = nil

		TestWords.each {|word,pos|
			assert_nothing_raised do
				rval, rest = @lexicon.lookupSynsets( word, pos )
			end

			assert_instance_of WordNet::Synset, rval

			# :TODO: Should test synsets for content, but I've yet to condense a
			# test dataset for it from the WordNet sources.
		}
	end


	### Test synset creation via factory method
	def test_lexicon_create_synset_should_create_a_new_synset
		synset = nil

		assert_nothing_raised do
			synset = @lexicon.createSynset( "Ruby", WordNet::Noun )
		end
		assert_instance_of WordNet::Synset, synset
	end


	# :TODO: Test storeSynset()?


	#######
	private
	#######

	### Create a temporary directory for testing, call the supplied +block+ with
	### the name of the new directory, then remove it.
	def make_testing_directory
		rndstuff = Process::pid
		path = File::join( Dir::tmpdir, "test.#{rndstuff}" )
		Dir::mkdir( path ) unless File.directory?( path )

		yield( path )
	ensure
		FileUtils::rm_rf( path, :verbose => $VERBOSE ) if defined?( path )
	end


end

