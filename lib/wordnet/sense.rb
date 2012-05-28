#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/model'

# WordNet sense model class
class WordNet::Sense < WordNet::Model( :senses )
	include WordNet::Constants

	set_primary_key :senseid

	many_to_one :synset, :key => :synsetid
	many_to_one :word, :key => :wordid

	# Sense -> [ LexicalLinks ] -> [ Synsets ]
	one_to_many :lexlinks,
		:class       => :"WordNet::LexicalLink",
		:key         => [ :synset1id, :word1id ],
		:primary_key => [ :synsetid, :wordid ]


	### Generate a method that will return Synsets related by the given lexical pointer
	### +type+.
	def self::lexical_link( type, typekey=nil )
		typekey ||= type.to_s.chomp( 's' ).to_sym

		self.log.debug "Generating a %p method for %p links" % [ type, typekey ]

		method_body = Proc.new do
			linkinfo = WordNet::Synset.linktype_names[ typekey ] or
				raise ScriptError, "no such link type %p" % [ typekey ]
			ssids = self.lexlinks_dataset.filter( :linkid => linkinfo[:id] ).select( :synset2id )
			self.class.filter( :synsetid => ssids )
		end
		self.log.debug "  method body is: %p" % [ method_body ]

		define_method( type, &method_body )
	end


	lexical_link :also_see, :also
	lexical_link :antonym
	lexical_link :derivation
	lexical_link :domain_categories, :domain_category
	lexical_link :domain_member_categories, :domain_member_category
	lexical_link :domain_member_region
	lexical_link :domain_member_usage
	lexical_link :domain_region
	lexical_link :domain_usage
	lexical_link :participle
	lexical_link :pertainym
	lexical_link :verb_group

end # class WordNet::Sense

