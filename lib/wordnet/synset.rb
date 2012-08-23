#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/constants'
require 'wordnet/model'


# WordNet synonym-set object class
#
# Instances of this class encapsulate the data for a synonym set ('synset') in a
# WordNet lexical database. A synonym set is a set of words that are
# interchangeable in some context.
#
# We can either fetch the synset from a connected Lexicon:
#
#    lexicon = WordNet::Lexicon.new( 'postgres://localhost/wordnet30' )
#    ss = lexicon[ :first, 'time' ]
#    # => #<WordNet::Synset:0x7ffbf2643bb0 {115265518} 'commencement, first,
#    #       get-go, offset, outset, start, starting time, beginning, kickoff,
#    #       showtime' (noun): [noun.time] the time at which something is
#    #       supposed to begin>
#
# or if you've already created a Lexicon, use its connection indirectly to
# look up a Synset by its ID:
#
#    ss = WordNet::Synset[ 115265518 ]
#    # => #<WordNet::Synset:0x7ffbf257e928 {115265518} 'commencement, first,
#    #       get-go, offset, outset, start, starting time, beginning, kickoff,
#    #       showtime' (noun): [noun.time] the time at which something is
#    #       supposed to begin>
#
# You can fetch a list of the lemmas (base forms) of the words included in the
# synset:
#
#    ss.words.map( &:lemma )
#    # => ["commencement", "first", "get-go", "offset", "outset", "start",
#    #     "starting time", "beginning", "kickoff", "showtime"]
#
# But the primary reason for a synset is its lexical and semantic links to
# other words and synsets. For instance, its *hypernym* is the equivalent
# of its superclass: it's the class of things of which the receiving
# synset is a member.
#
#    ss.hypernyms
#    # => [#<WordNet::Synset:0x7ffbf25c76c8 {115180528} 'point, point in
#    #        time' (noun): [noun.time] an instant of time>]
#
# The synset's *hypernyms*, on the other hand, are kind of like its
# subclasses:
#
#    ss.hyponyms
#    # => [#<WordNet::Synset:0x7ffbf25d83b0 {115142167} 'birth' (noun):
#    #       [noun.time] the time when something begins (especially life)>,
#    #     #<WordNet::Synset:0x7ffbf25d8298 {115268993} 'threshold' (noun):
#    #       [noun.time] the starting point for a new state or experience>,
#    #     #<WordNet::Synset:0x7ffbf25d8180 {115143012} 'incipiency,
#    #       incipience' (noun): [noun.time] beginning to exist or to be
#    #       apparent>,
#    #     #<WordNet::Synset:0x7ffbf25d8068 {115266164} 'starting point,
#    #       terminus a quo' (noun): [noun.time] earliest limiting point>]
#
class WordNet::Synset < WordNet::Model( :synsets )
	include WordNet::Constants

	require 'wordnet/lexicallink'
	require 'wordnet/semanticlink'

	# Semantic link type keys; maps what the API calls them to what
	# they are in the DB.
	SEMANTIC_TYPEKEYS = Hash.new {|h,type| h[type] = type.to_s.chomp('s').to_sym }

	# Now set the ones that aren't just the API name with
	# the 's' at the end removed.
	SEMANTIC_TYPEKEYS.merge!(
		also_see:                 :also,
		domain_categories:        :domain_category,
		domain_member_categories: :domain_member_category,
		entailments:              :entail,
		similar_words:            :similar,
	)


	set_primary_key :synsetid

	##
	# :singleton-method:
	# The WordNet::Words associated with the receiver
	many_to_many :words,
		:join_table  => :senses,
		:left_key    => :synsetid,
		:right_key   => :wordid


	##
	# :singleton-method:
	# The WordNet::Senses associated with the receiver
	one_to_many :senses,
		:key         => :synsetid,
		:primary_key => :synsetid


	##
	# :singleton-method:
	# The WordNet::SemanticLinks indicating a relationship with other
	# WordNet::Synsets
	one_to_many :semlinks,
		:class       => :"WordNet::SemanticLink",
		:key         => :synset1id,
		:primary_key => :synsetid,
		:eager       => :target


	##
	# :singleton-method:
	# The WordNet::SemanticLinks pointing *to* this Synset
	many_to_one :semlinks_to,
		:class       => :"WordNet::SemanticLink",
		:key         => :synsetid,
		:primary_key => :synset2id


	##
	# :singleton-method:
	# Terms from the Suggested Upper Merged Ontology
	many_to_many :sumo_terms,
		:join_table  => :sumomaps,
		:left_key    => :synsetid,
		:right_key   => :sumoid


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	# Cached lookup tables (lazy-loaded)
	@lexdomain_table = nil
	@lexdomains      = nil
	@linktype_table  = nil
	@linktypes       = nil
	@postype_table   = nil
	@postypes        = nil


	#
	# :section: Dataset Methods
	# This is a set of methods that return a Sequel::Dataset for Synsets pre-filtered
	# by a certain criteria. They can be used to do stuff like:
	#
	#   lexicon[ :language ].synsets_dataset.nouns
	#

	##
	# :singleton-method: nouns
	# Dataset method: filtered by part of speech: nouns.
	def_dataset_method( :nouns ) { filter(pos: 'n') }

	##
	# :singleton-method: verbs
	# Dataset method: filtered by part of speech: verbs.
	def_dataset_method( :verbs ) { filter(pos: 'v') }

	##
	# :singleton-method: adjectives
	# Dataset method: filtered by part of speech: adjectives.
	def_dataset_method( :adjectives ) { filter(pos: 'a') }

	##
	# :singleton-method: adverbs
	# Dataset method: filtered by part of speech: adverbs.
	def_dataset_method( :adverbs ) { filter(pos: 'r') }

	##
	# :singleton-method: adjective_satellites
	# Dataset method: filtered by part of speech: adjective satellites.
	def_dataset_method( :adjective_satellites ) { filter(pos: 's') }


	# :section:

	### Overridden to reset any lookup tables that may have been loaded from the previous
	### database.
	def self::db=( newdb )
		self.reset_lookup_tables
		super
	end


	### Unload all of the cached lookup tables that have been loaded.
	def self::reset_lookup_tables
		@lexdomain_table = nil
		@lexdomains      = nil
		@linktype_table  = nil
		@linktypes       = nil
		@postype_table   = nil
		@postypes        = nil
	end


	### Return the table of lexical domains, keyed by id.
	def self::lexdomain_table
		@lexdomain_table ||= self.db[:lexdomains].to_hash( :lexdomainid )
	end


	### Lexical domains, keyed by name as a String (e.g., "verb.cognition")
	def self::lexdomains
		@lexdomains ||= self.lexdomain_table.inject({}) do |hash,(id,domain)|
			hash[ domain[:lexdomainname] ] = domain
			hash
		end
	end


	### Return the table of link types, keyed by linkid
	def self::linktype_table
		@linktype_table ||= self.db[:linktypes].inject({}) do |hash,row|
			hash[ row[:linkid] ] = {
				:id       => row[:linkid],
				:typename => row[:link],
				:type     => row[:link].gsub( /\s+/, '_' ).to_sym,
				:recurses => row[:recurses] && row[:recurses] != 0,
			}
			hash
		end
	end


	### Return the table of link types, keyed by name.
	def self::linktypes
		@linktypes ||= self.linktype_table.inject({}) do |hash,(id,link)|
			hash[ link[:type] ] = link
			hash
		end
	end


	### Return the table of part-of-speech types, keyed by letter identifier.
	def self::postype_table
		@postype_table ||= self.db[:postypes].inject({}) do |hash, row|
			hash[ row[:pos].untaint.to_sym ] = row[:posname]
			hash
		end
	end


	### Return the table of part-of-speech names to letter identifiers (both Symbols).
	def self::postypes
		@postypes ||= self.postype_table.invert
	end


	##
	# :singleton-method: semantic_link_methods
	# An Array of semantic link methods
	class << self; attr_reader :semantic_link_methods ; end
	@semantic_link_methods = []


	### Generate methods that will return Synsets related by the given semantic pointer
	### +type+.
	def self::semantic_link( type )
		self.log.debug "Generating a %p method" % [ type ]

		ds_method_body = Proc.new do
			self.semanticlink_dataset( type )
		end
		define_method( "#{type}_dataset", &ds_method_body )

		ss_method_body = Proc.new do
			self.semanticlink_dataset( type ).all
		end
		define_method( type, &ss_method_body )

		self.semantic_link_methods << type.to_sym
	end


	######
	public
	######

	### Return a Sequel::Dataset for synsets related to the receiver via the semantic
	### link of the specified +type+.
	def semanticlink_dataset( type )
		typekey  = SEMANTIC_TYPEKEYS[ type ]
		linkinfo = self.class.linktypes[ typekey ] or
			raise ArgumentError, "no such link type %p" % [ typekey ]
		ssids    = self.semlinks_dataset.filter( :linkid => linkinfo[:id] ).select( :synset2id )

		return self.class.filter( :synsetid => ssids )
	end


	### Return an Enumerator that will iterate over the Synsets related to the receiver
	### via the semantic links of the specified +linktype+.
	def semanticlink_enum( linktype )
		return self.semanticlink_dataset( linktype ).to_enum
	end


	### Return the name of the Synset's part of speech (#pos).
	def part_of_speech
		return self.class.postype_table[ self.pos.to_sym ]
	end


	### Stringify the synset.
	def to_s

		# Make a sorted list of the semantic link types from this synset
		semlink_list = self.semlinks_dataset.
			group_and_count( :linkid ).
			to_hash( :linkid, :count ).
			collect do |linkid, count|
				'%s: %d' % [ self.class.linktype_table[linkid][:typename], count ]
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
		return self.class.lexdomain_table[ self.lexdomainid ][ :lexdomainname ]
	end


	### Return any sample sentences.
	def samples
		return self.db[:samples].
			filter( synsetid: self.synsetid ).
			order( :sampleid ).
			map( :sample )
	end


	#
	# :section: Semantic Links
	#

	##
	# "See Also" synsets
	semantic_link :also_see

	##
	# Attribute synsets
	semantic_link :attributes

	##
	# Cause synsets
	semantic_link :causes

	##
	# Domain category synsets
	semantic_link :domain_categories

	##
	# Domain member category synsets
	semantic_link :domain_member_categories

	##
	# Domain member region synsets
	semantic_link :domain_member_regions

	##
	# Domain member usage synsets
	semantic_link :domain_member_usages

	##
	# Domain region synsets
	semantic_link :domain_regions

	##
	# Domain usage synsets
	semantic_link :domain_usages

	##
	# Verb entailment synsets
	semantic_link :entailments

	##
	# Hypernym sunsets
	semantic_link :hypernyms

	##
	# Hyponym synsets
	semantic_link :hyponyms

	##
	# Instance hypernym synsets
	semantic_link :instance_hypernyms

	##
	# Instance hyponym synsets
	semantic_link :instance_hyponyms

	##
	# Member holonym synsets
	semantic_link :member_holonyms

	##
	# Member meronym synsets
	semantic_link :member_meronyms

	##
	# Part holonym synsets
	semantic_link :part_holonyms

	##
	# Part meronym synsets
	semantic_link :part_meronyms

	##
	# Similar word synsets
	semantic_link :similar_words

	##
	# Substance holonym synsets
	semantic_link :substance_holonyms

	##
	# Substance meronym synsets
	semantic_link :substance_meronyms

	##
	# Verb group synsets
	semantic_link :verb_groups


	#
	# :section: Traversal Methods
	#

	### Union: Return the least general synset that the receiver and
	### +othersyn+ have in common as a hypernym, or nil if it doesn't share
	### any.
	def |( othersyn )

		# Find all of this syn's hypernyms
		hypersyns = self.traverse( :hypernyms ).to_a
		commonsyn = nil

		# Now traverse the other synset's hypernyms looking for one of our
		# own hypernyms.
		othersyn.traverse( :hypernyms ) do |syn|
			if hypersyns.include?( syn )
				commonsyn = syn
				throw :stop_traversal
			end
		end

		return commonsyn
	end


	### With a block, yield a WordNet::Synset related to the receiver via a link of
	### the specified +type+, recursing depth first into each of its links if the link
	### type is recursive. To exit from the traversal at any depth, throw :stop_traversal.
	###
	### If no block is given, return an Enumerator that will do the same thing instead.
	###
	###   # Print all the parts of a boot
	###   puts lexicon[:boot].traverse( :member_meronyms ).all
	###
	###
	def traverse( type, &block )
		enum = Enumerator.new do |yielder|
			traversals = [ self.semanticlink_enum(type) ]
			syn        = nil
			typekey    = SEMANTIC_TYPEKEYS[ type ]
			recurses   = self.class.linktypes[ typekey ][:recurses]

			self.log.debug "Traversing %s semlinks%s" % [ type, recurses ? " (recursive)" : ''  ]

			catch( :stop_traversal ) do
				until traversals.empty?
					begin
						self.log.debug "  %d traversal/s left" % [ traversals.length ]
						syn = traversals.last.next
						yielder.yield( syn )
						traversals << syn.semanticlink_enum( type ) if recurses
					rescue StopIteration
						traversals.pop
					end
				end
			end
		end

		return enum.each( &block ) if block
		return enum
	end


	### Search for the specified +synset+ in the semantic links of the given +type+ of
	### the receiver, returning the depth it was found at if it's found, or nil if it
	### wasn't found.
	def search( type, synset )
		found, depth = self.traverse( type ).find {|ss,depth| synset == ss }
		return depth
	end


	### Return a human-readable representation of the objects, suitable for debugging.
	def inspect
		return "#<%p:%0#x {%d} '%s' (%s): [%s] %s>" % [
			self.class,
			self.object_id * 2,
			self.synsetid,
			self.words.map(&:to_s).join(', '),
			self.part_of_speech,
			self.lexical_domain,
			self.definition,
		]
	end

end # class WordNet::Synset

