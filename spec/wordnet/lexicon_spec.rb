#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'fileutils'
	require 'tmpdir'
	require 'bdb'
	require 'spec/runner'
	require 'spec/lib/helpers'

	require 'wordnet/lexicon'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end



#####################################################################
###	C O N T E X T S
#####################################################################

describe WordNet::Lexicon do
	include WordNet::SpecHelpers

	TEST_WORDS = {
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


	before( :each ) do
		@path = make_tempdir()
	end


	after( :each ) do
		FileUtils.rm_rf @path, :verbose => $DEBUG
	end

	

	#################################################################
	###	T E S T S
	#################################################################

	it "passes a read-only flagset to BDB when created in :readonly mode" do
		env = stub( "bdb environment handle", :open_db => nil )
		BDB::Env.should_receive( :new ).
			with( @path.to_s, WordNet::Lexicon::ENV_FLAGS_RO, WordNet::Lexicon::ENV_OPTIONS ).
			and_return( env )

		WordNet::Lexicon.new( @path.to_s )
	end
	
	it "passes a read/write flagset to BDB when created in :writable mode" do
		env = stub( "bdb environment handle", :open_db => nil )
		BDB::Env.should_receive( :new ).
			with( @path.to_s, WordNet::Lexicon::ENV_FLAGS_RW, WordNet::Lexicon::ENV_OPTIONS ).
			and_return( env )

		WordNet::Lexicon.new( @path.to_s, :writable )
	end
	
	it "passes a read/write flagset to BDB when created in :readwrite mode" do
		env = stub( "bdb environment handle", :open_db => nil )
		BDB::Env.should_receive( :new ).
			with( @path.to_s, WordNet::Lexicon::ENV_FLAGS_RW, WordNet::Lexicon::ENV_OPTIONS ).
			and_return( env )

		WordNet::Lexicon.new( @path.to_s, :readwrite )
	end
	

	describe "created in the default configuration" do

		before( :all ) do
			@basedir = Pathname.new( __FILE__ ).dirname.parent.parent
			@datadir = @basedir + 'ruby-wordnet'
		end

		before( :each ) do
			pending "you haven't converted the WordNet datafiles yet -- try 'rake convert'" unless
			 	@datadir.directory?

			@lexicon = WordNet::Lexicon.new( @datadir.to_s )
		end


		TEST_WORDS.each do |word, pos|
			it "returns a Fixnum value for the familiarity of #{word}(#{pos})" do
				@lexicon.familiarity( word, pos ).should be_an_instance_of( Fixnum )
			end
		end
		
		
		it "returns the root word as the morphology of a dictionary word it knows about" do
			@lexicon.morph( "angriest", WordNet::Adjective ).should == 'angry'
		end


		it "returns nil as the morphology of a dictionary word it doesn't know about" do
			@lexicon.morph( "Passomoquoddy", WordNet::Noun ).should be_nil()
		end


		it "returns the 'reverse morph' of dictionary words it knows about" do
			@lexicon.reverse_morph( "angry" ).should == 'angriest%a'
		end
		
		
		it "can find every compound sense of a word in its dictionary" do
			words = @lexicon.grep( 'thing' )

			words.should have(10).members
			words.should include( 'thing%n' )
			words.should include( 'thing-in-itself%n' )
			words.should include( 'thingamabob%n' )
			words.should include( 'thingamajig%n' )
			words.should include( 'thingmabob%n' )
			words.should include( 'thingmajig%n' )
			words.should include( 'things%n' )
			words.should include( 'thingumabob%n' )
			words.should include( 'thingumajig%n' )
			words.should include( 'thingummy%n' )
		end
		
		
		TEST_WORDS.each do |word, pos|
			it "can look up the synset #{word}(#{pos}) by word and part-of-speech" do
				synsets = @lexicon.lookup_synsets( word, pos )

				synsets.should have_at_least(1).members
				synsets.each do |ss|
					ss.should be_an_instance_of( WordNet::Synset )
				end
			end
		end


		it "can act as a factory for new synsets" do
			@lexicon.create_synset( "Ruby", WordNet::Noun ).
				should be_an_instance_of( WordNet::Synset )
		end
		
	end


	### Test synset creation via factory method
	def test_lexicon_create_synset_should_create_a_new_synset
		synset = nil

		assert_nothing_raised do
			synset = @lexicon.create_synset( "Ruby", WordNet::Noun )
		end
		assert_instance_of WordNet::Synset, synset
	end


	def test_lexicon_should_be_readonly_if_opened_in_readonly_mode
		make_testing_directory do |path|
			lex = WordNet::Lexicon::new( path, :readwrite ).checkpoint
			lex = nil
			
			lex = WordNet::Lexicon.new( path, :readonly )
			assert_equal true, lex.readonly?
			assert_equal false, lex.readwrite?
		end
	end


	def test_lexicon_should_be_readwrite_if_opened_in_readwrite_mode
		make_testing_directory do |path|
			lex = WordNet::Lexicon::new( path, :readwrite )

			assert_equal false, lex.readonly?
			assert_equal true, lex.readwrite?
		end
	end



	# :TODO: Test store_synset()?


end

