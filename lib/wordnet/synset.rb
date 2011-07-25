#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/mixins'
require 'wordnet/model'


# WordNet synonym-set object class
class WordNet::Synset < WordNet::Model( :synsets )
	include WordNet::Constants

	require 'wordnet/lexicallink'
	require 'wordnet/semanticlink'

	set_primary_key :synsetid

	# Synset -> [ Sense ] -> [ Word ]
	many_to_many :words,
		:join_table  => :senses,
		:left_key    => :synsetid,
		:right_key   => :wordid

	# many_to_many :synonyms,
	# 	:join_table  => :senses,
	# 	:left_key    => :synsetid,
	# 	:right_key   => :wordid,
	# 	:conditions  => 
	alias_method :synonyms, :words

	# Synset -> [ Sense ]
	one_to_many :senses,
		:key         => :synsetid,
		:primary_key => :synsetid

	# Synset -> [ SemanticLinks ] -> [ Synsets ]
	one_to_many :semlinks,
		:class       => :"WordNet::SemanticLink",
		:key         => :synset1id,
		:primary_key => :synsetid,
		:eager       => :target

	# Synset -> [ SemanticLinks ] -> [ Synsets ]
	many_to_one :semlinks_to,
		:class       => :"WordNet::SemanticLink",
		:key         => :synsetid,
		:primary_key => :synset2id


	#
	# Suggested Upper Merged Ontology (SUMO) extensions
	#

	# Synset -> [ SumoMaps ] -> [ SumoTerm ]
	many_to_many :sumo_terms,
		:join_table  => :sumomaps,
		:left_key    => :synsetid,
		:right_key   => :sumoid


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	# Cached lookup tables (lazy-loaded)
	@lexdomains      = nil
	@lexdomain_names = nil
	@linktypes       = nil
	@linktype_names  = nil
	@postypes        = nil
	@postype_names   = nil


	### Overridden to reset any lookup tables that may have been loaded from the previous
	### database.
	def self::db=( newdb )
		self.reset_lookup_tables
		super
	end


	### Unload all of the cached lookup tables that have been loaded.
	def self::reset_lookup_tables
		@lexdomains      = nil
		@lexdomain_names = nil
		@linktypes       = nil
		@linktype_names  = nil
		@postypes        = nil
		@postype_names   = nil
	end


	### Return the table of lexical domains, keyed by id.
	def self::lexdomains
		@lexdomains ||= self.db[:lexdomains].to_hash( :lexdomainid )
	end


	### (Undocumented)
	def self::lexdomain_names
		@lexdomain_names ||= self.lexdomains.inject({}) do |hash,(id,domain)|
			hash[ domain[:lexdomainname] ] = domain
			hash
		end
	end


	### Return the table of link types, keyed by linkid
	def self::linktypes
		@linktypes ||= self.db[:linktypes].inject({}) do |hash,row|
			hash[ row[:linkid] ] = {
				:id       => row[:linkid],
				:typename => row[:link],
				:type     => row[:link].gsub( /\s+/, '_' ).to_sym,
				:recurses => row[:recurses].nonzero? ? true : false,
			}
			hash
		end
	end


	### Return the table of link types, keyed by name.
	def self::linktype_names
		@linktype_names ||= self.linktypes.inject({}) do |hash,(id,link)|
			hash[ link[:type] ] = link
			hash
		end
	end


	### Return the table of part-of-speech types, keyed by letter identifier.
	def self::postypes
		@postypes ||= self.db[:postypes].to_hash( :pos, :posname )
	end


	### Return the table of part-of-speech types, keyed by name.
	def self::postype_names
		@postype_names ||= self.postypes.invert
	end


	### Generate a method that will return Synsets related by the given semantic pointer
	### +type+.
	def self::semantic_link( type, typekey=nil )
		typekey ||= type.to_s.chomp( 's' ).to_sym

		WordNet.log.debug "Generating a %p method for %p links" % [ type, typekey ]

		method_body = Proc.new do
			linkinfo = self.class.linktype_names[ typekey ] or
				raise ScriptError, "no such link type %p" % [ typekey ]
			ssids = self.semlinks_dataset.filter( :linkid => linkinfo[:id] ).select( :synset2id )
			self.class.filter( :synsetid => ssids )
		end
		WordNet.log.debug "  method body is: %p" % [ method_body ]

		define_method( type, &method_body )
	end


	######
	public
	######

	### Return the name of the Synset's part of speech (#pos).
	def part_of_speech
		return self.class.postypes[ self.pos ]
	end


	### Stringify the synset.
	def to_s

		# Make a sorted list of the semantic link types from this synset
		semlink_list = self.semlinks_dataset.
			group_and_count( :linkid ).
			to_hash( :linkid, :count ).
			collect do |linkid, count|
				'%s: %d' % [ self.class.linktypes[linkid][:typename], count ]
			end.
			sort.
			join( ', ' )

		return "%s (%s): [%s] %s (%s)" % [
			self.words.map( &:to_s ).join(', '),
			self.part_of_speech,
			self.lexical_domain,
			self.definition,
			semlink_list
		]
	end


	### Return the name of the lexical domain the synset belongs to; this also
	### corresponds to the lexicographer's file the synset was originally loaded from.
	def lexical_domain
		return self.class.lexdomains[ self.lexdomainid ][ :lexdomainname ]
	end


	semantic_link :also_see, :also
	semantic_link :attributes
	semantic_link :causes
	semantic_link :domain_categories, :domain_category
	semantic_link :domain_member_categories, :domain_member_category
	semantic_link :domain_member_regions
	semantic_link :domain_member_usages
	semantic_link :domain_regions
	semantic_link :domain_usages
	semantic_link :entailments, :entail
	semantic_link :hypernyms
	semantic_link :hyponyms
	semantic_link :instance_hypernyms
	semantic_link :instance_hyponyms
	semantic_link :member_holonyms
	semantic_link :member_meronyms
	semantic_link :part_holonyms
	semantic_link :part_meronyms
	semantic_link :similar_words, :similar
	semantic_link :substance_holonyms
	semantic_link :substance_meronyms
	semantic_link :verb_groups

end # class WordNet::Synset

