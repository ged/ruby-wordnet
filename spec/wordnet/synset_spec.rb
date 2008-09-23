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
	require 'wordnet/synset'
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

describe WordNet::Synset do

	TEST_SYNSET_OFFSET = 6172789

	TEST_SYNSET_POS = :noun
	
	TEST_SYNSET_DATA = "09||linguistics%0||@ 05999797%n 0000|#p 06142861%n 0000|+ " +
		"02843218%a 0101|+ 10264437%n 0101|-c 00111415%a 0000|-c 00111856%a 0000|-c 00120252%a " +
		"0000|-c 00120411%a 0000|-c 00201802%a 0000|-c 00699651%a 0000|-c 00699876%a 0000|-c " +
		"00819852%a 0000|-c 00820219%a 0000|-c 00820458%a 0000|-c 00820721%a 0000|-c 00820975%a " +
		"0000|-c 00821208%a 0000|-c 01973823%a 0000|-c 02297664%a 0000|-c 02297966%a 0000|-c " +
		"02298285%a 0000|-c 02298642%a 0000|-c 02298766%a 0000|-c 02478052%a 0000|-c 02482790%a " +
		"0000|-c 02593124%a 0000|-c 02593578%a 0000|-c 02836479%a 0000|-c 02856124%a 0000|-c " +
		"02993853%a 0000|-c 03041636%a 0000|-c 03045196%a 0000|-c 03102278%a 0000|-c 03129490%a " +
		"0000|-c 00098051%n 0000|-c 04986883%n 0000|-c 05087664%n 0000|-c 05153897%n 0000|-c " +
		"05850212%n 0000|~ 06168552%n 0000|~ 06168703%n 0000|~ 06168855%n 0000|~ 06169050%n 0000|-c " +
		"06174404%n 0000|-c 06175829%n 0000|-c 06175967%n 0000|-c 06176107%n 0000|-c 06176322%n " +
		"0000|-c 06176519%n 0000|-c 06177450%n 0000|~ 06179290%n 0000|~ 06179492%n 0000|~ 06179792%n " +
		"0000|~ 06181123%n 0000|~ 06181284%n 0000|~ 06181448%n 0000|~ 06181584%n 0000|~ 06181893%n " +
		"0000|-c 06249910%n 0000|-c 06250444%n 0000|-c 06290051%n 0000|-c 06290637%n 0000|-c " +
		"06300193%n 0000|-c 06331803%n 0000|-c 06483702%n 0000|-c 06483992%n 0000|-c 06484279%n " +
		"0000|-c 07111510%n 0000|-c 07111711%n 0000|-c 07111933%n 0000|-c 07259772%n 0000|-c " +
		"07259984%n 0000|-c 07276018%n 0000|-c 08103635%n 0000|-c 13433061%n 0000|-c 13508333%n " +
		"0000|-c 13802920%n 0000|-c 00587390%v 0000|-c 00587522%v 0000|-c 00634286%v 0000|-c " +
		"01013856%v 0000|-c 01735556%v 0000||||the scientific study of language"

	RELATION_METHODS = [
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

	AGGREGATE_RELATION_METHODS = [
		:meronyms,
		:holonyms,
		:domains,
		:members,
	]
	
	
	it "provides defaults for instances created with just a lexicon, offset, and part of speech" do
		syn = WordNet::Synset.new( :lexicon, TEST_SYNSET_OFFSET, TEST_SYNSET_POS )
		syn.filenum.should be_nil()
		syn.wordlist.should == ''
		syn.pointerlist.should == ''
		syn.frameslist.should == ''
		syn.gloss.should == ''
	end
	
	it "has (generated) methods for each type of WordNet relation" do
		RELATION_METHODS.each do |relation|
			WordNet::Synset.instance_method( relation ).should be_an_instance_of( UnboundMethod )
		end
	end

	
	describe "instance created from synset data" do

		before( :each ) do
			@lexicon = mock( "lexicon" )
			@synset = WordNet::Synset.new( @lexicon,
			 	TEST_SYNSET_OFFSET, TEST_SYNSET_POS, 'linguistics', TEST_SYNSET_DATA )
		end
	

		it "knows what part_of_speech it is" do
			@synset.part_of_speech.should == TEST_SYNSET_POS
		end
	
		it "knows what offset it is" do
			@synset.offset.should == TEST_SYNSET_OFFSET
		end
	
		it "knows what filenum it is" do
			@synset.filenum.should == '09'
		end
	
		it "knows what its wordlist is" do
			@synset.wordlist.should == 'linguistics%0'
		end
	
		POINTER_PATTERN = /(\S{2} \d+%[nvars] \d{4})/
		LIST_OF_POINTERS = /#{POINTER_PATTERN}(\|#{POINTER_PATTERN})*/
		it "knows what its pointerlist is" do
			@synset.pointerlist.should =~ LIST_OF_POINTERS
		end
	
		it "knows what frameslist it is" do
			@synset.frameslist.should == ''
		end
	
		it "knows what its gloss is" do
			@synset.gloss.should =~ /study of language/i
		end
	

		### :TODO: Test traversal, content, storing, higher-order functions
		describe "traversal" do

			it "can traverse its relationships and return the resulting synsets" do
				hypernym1 = mock( "hypernym of linguistics" )
				hypernym2 = mock( "super-hypernym of linguistics" )
			
				@lexicon.should_receive( :lookup_synsets_by_key ).with( /\d+%[nvars]/ ).
					and_return( hypernym1 )
				hypernym1.should_receive( :hypernyms ).and_return([ hypernym2 ])
				hypernym2.should_receive( :hypernyms ).and_return([])

				synsets = @synset.traverse( :hypernyms )
			
				synsets.should have(3).members
				synsets.should include( @synset, hypernym1, hypernym2 )
			end


			it "can exclude its origin term from a traversal set" do
				hypernym1 = mock( "hypernym of linguistics" )
				hypernym2 = mock( "super-hypernym of linguistics" )
			
				@lexicon.should_receive( :lookup_synsets_by_key ).with( /\d+%[nvars]/ ).
					and_return( hypernym1 )
				hypernym1.should_receive( :hypernyms ).and_return([ hypernym2 ])
				hypernym2.should_receive( :hypernyms ).and_return([])

				synsets = @synset.traverse( :hypernyms, false )
			
				synsets.should have(2).members
				synsets.should include( hypernym1, hypernym2 )
			end

		end # "traversal"

	end # "instance"

end


