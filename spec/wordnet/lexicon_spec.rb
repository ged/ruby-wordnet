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

	it "defaults to being in :readonly mode" do
		env = stub( "bdb environment handle", :open_db => nil )
		BDB::Env.should_receive( :new ).
			with( @path.to_s, WordNet::Lexicon::ENV_FLAGS_RO, WordNet::Lexicon::ENV_OPTIONS ).
			and_return( env )

		lex = WordNet::Lexicon.new( @path.to_s )

		lex.should be_readonly()
		lex.should_not be_readwrite()
	end
	
	it "can be created in :writable mode" do
		env = stub( "bdb environment handle", :open_db => nil )
		BDB::Env.should_receive( :new ).
			with( @path.to_s, WordNet::Lexicon::ENV_FLAGS_RW, WordNet::Lexicon::ENV_OPTIONS ).
			and_return( env )

		lex = WordNet::Lexicon.new( @path.to_s, :writable )

		lex.should_not be_readonly()
		lex.should be_readwrite()
	end
	
	it "passes a read/write flagset to BDB when created in :readwrite mode" do
		env = stub( "bdb environment handle", :open_db => nil )
		BDB::Env.should_receive( :new ).
			with( @path.to_s, WordNet::Lexicon::ENV_FLAGS_RW, WordNet::Lexicon::ENV_OPTIONS ).
			and_return( env )

		lex = WordNet::Lexicon.new( @path.to_s, :readwrite )

		lex.should_not be_readonly()
		lex.should be_readwrite()
	end
	

	describe "created in readonly mode" do

		before( :each ) do
			@env = mock( "bdb environment handle" )
			BDB::Env.stub!( :new ).and_return( @env )
			@env.stub!( :open_db )

			@lexicon = WordNet::Lexicon.new( @path.to_s, :readonly )
		end


		it "doesn't try to remove logs" do
			@env.should_not_receive( :log_archive )
			@lexicon.clean_logs
		end
		
		
	end


	describe "created in readwrite mode" do

		before( :each ) do
			@env = mock( "bdb environment handle" )
			BDB::Env.stub!( :new ).and_return( @env )
			@env.stub!( :open_db )

			@lexicon = WordNet::Lexicon.new( @path.to_s, :readwrite )
		end
		

		it "can be closed" do
			@env.should_receive( :close )
			@lexicon.close
		end

		it "provides a delegator for the checkpoint method of the underlying database" do
			@env.should_receive( :checkpoint )
			@lexicon.checkpoint
		end
	
		it "provides an interface to clean up database transaction logs" do
			@env.should_receive( :log_archive ).with( BDB::ARCH_ABS ).
				and_return([ :log1, :log2 ])
			File.should_receive( :chmod ).with( 0777, :log1 )
			File.should_receive( :delete ).with( :log1 )
			File.should_receive( :chmod ).with( 0777, :log2 )
			File.should_receive( :delete ).with( :log2 )
			
			@lexicon.clean_logs
		end
		
	
	end
	

	describe "with a converted WordNet database" do

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
		
		
		it "returns the root word as the morphological conversion of a dictionary word it knows about" do
			@lexicon.morph( "angriest", WordNet::Adjective ).should == 'angry'
		end


		it "returns nil as the morphological conversion of a dictionary word it doesn't know about" do
			@lexicon.morph( "Passomoquoddy", WordNet::Noun ).should be_nil()
		end


		it "returns the 'reverse morph' of dictionary words it knows about" do
			@lexicon.reverse_morph( "angry" ).should == 'angriest%a'
		end


		it "tries looking up a failing via its morphological conversion if the original fails" do
			synsets = @lexicon.lookup_synsets( 'angriest', WordNet::Adjective )
			
			synsets.should_not be_nil()
			synsets.first.should be_an_instance_of( WordNet::Synset )
			synsets.first.words.should include( 'angry' )
		end


		it "returns only the requested sense if a sense is specified" do
			synset = @lexicon.lookup_synsets( 'run', WordNet::Verb, 4 )
			synset.should be_an_instance_of( WordNet::Synset )
			synset.words.first.should =~ /operate/i
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

end

