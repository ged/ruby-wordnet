#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/mixins'
require 'wordnet/model'


# WordNet synonym-set object class
# 
# Instances of this class encapsulate the data for a synonym set ('synset') in a
# WordNet lexical database. A synonym set is a set of words that are
# interchangeable in some context.
# 
#   ss = WordNet::Synset[ 106286395 ]
#   # => #<WordNet::Synset @values={:synsetid=>106286395, :pos=>"n", 
#       :lexdomainid=>10, 
#       :definition=>"a unit of language that native speakers can identify"}>
#
#   ss.words.map( &:lemma )
#   # => ["word"]
#
#   ss.hypernyms
#   # => [#<WordNet::Synset @values={:synsetid=>106284225, :pos=>"n", 
#       :lexdomainid=>10, 
#       :definition=>"one of the natural units into which [...]"}>]
#
#   ss.hyponyms
#   # => [#<WordNet::Synset @values={:synsetid=>106287620, :pos=>"n", 
#       :lexdomainid=>10, 
#       :definition=>"a word or phrase spelled by rearranging [...]"}>, 
#     #<WordNet::Synset @values={:synsetid=>106287859, :pos=>"n", 
#       :lexdomainid=>10, 
#       :definition=>"a word (such as a pronoun) used to avoid [...]"}>, 
#     #<WordNet::Synset @values={:synsetid=>106288024, :pos=>"n", 
#       :lexdomainid=>10, 
#       :definition=>"a word that expresses a meaning opposed [...]"}>,
#     ...
#    ]
# 
class WordNet::Synset < WordNet::Model( :synsets )
	include WordNet::Constants

	require 'wordnet/lexicallink'
	require 'wordnet/semanticlink'

	set_primary_key :synsetid

	##
	# The WordNet::Words associated with the receiver
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

	##
	# The WordNet::Senses associated with the receiver
	one_to_many :senses,
		:key         => :synsetid,
		:primary_key => :synsetid

	##
	# The WordNet::SemanticLinks indicating a relationship with other 
	# WordNet::Synsets
	one_to_many :semlinks,
		:class       => :"WordNet::SemanticLink",
		:key         => :synset1id,
		:primary_key => :synsetid,
		:eager       => :target

	##
	# The WordNet::SemanticLinks pointing *to* this Synset
	many_to_one :semlinks_to,
		:class       => :"WordNet::SemanticLink",
		:key         => :synsetid,
		:primary_key => :synset2id


	#
	# Suggested Upper Merged Ontology (SUMO) extensions
	#

	##
	# Terms from the Suggested Upper Merged Ontology
	# :section: SUMO WordNet Extension
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
		@postypes ||= self.db[:postypes].inject({}) do |hash, row|
			hash[ row[:pos].untaint.to_sym ] = row[:posname]
			hash
		end
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
			self.class.filter( :synsetid => ssids ).all
		end
		WordNet.log.debug "  method body is: %p" % [ method_body ]

		define_method( type, &method_body )
	end


	######
	public
	######

	### Return the name of the Synset's part of speech (#pos).
	def part_of_speech
		return self.class.postypes[ self.pos.to_sym ]
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


	# :section: Semantic Links

	##
	# "See Also" synsets
	semantic_link :also_see, :also

	##
	# Attribute synsets
	semantic_link :attributes

	##
	# Cause synsets
	semantic_link :causes

	##
	# Domain category synsets
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


	### With a block, yield a WordNet::Synset related to the receiver via a link of
	### the specified +type+, recursing depth first into each of its links, as well.
	### If no block is given, return an Enumerator that will do the same thing instead.
	def traverse( type, &block )
		enum = self.traversal_enum( type )
		return enum unless block
		return enum.each( &block )
	end

end # class WordNet::Synset

