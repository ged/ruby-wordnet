# -*- ruby -*-
#encoding: utf-8

require 'wordnet' unless defined?( WordNet )
require 'wordnet/model'

# WordNet sense model class
class WordNet::Sense < WordNet::Model( :senses )
	include WordNet::Constants

	set_primary_key :senseid

	##
	# The Synset this is a Sense for
	many_to_one :synset, key: :synsetid

	##
	# The Word this is a Sense for
	many_to_one :word, key: :wordid

	##
	# The lexical links between this sense and its related Synsets.
	# Sense -> [ LexicalLinks ] -> [ Synsets ]
	one_to_many :lexlinks,
		class: 'WordNet::LexicalLink',
		key: [ :synset1id, :word1id ],
		primary_key: [ :synsetid, :wordid ]


	### Generate a method that will return Synsets related by the given lexical pointer
	### +type+.
	def self::lexical_link( type, typekey=nil ) # :nodoc:
		typekey ||= type.to_s.chomp( 's' ).to_sym

		self.log.debug "Generating a %p method for %p links" % [ type, typekey ]

		method_body = Proc.new do
			linkinfo = WordNet::Synset.linktypes[ typekey ] or
				raise ScriptError, "no such link type %p" % [ typekey ]
			ssids = self.lexlinks_dataset.filter( linkid: linkinfo[:id] ).select( :synset2id )
			self.class.filter( synsetid: ssids )
		end

		define_method( type, &method_body )
	end


	##
	# Return the synsets that are lexically linked to this sense via an "also see" link.
	lexical_link :also_see, :also

	##
	# Return the synsets that are lexically linked to this sense via an "antonym" link.
	lexical_link :antonym

	##
	# Return the synsets that are lexically linked to this sense via a "derivation" link.
	lexical_link :derivation

	##
	# Return the synsets that are lexically linked to this sense via a "domain category" link.
	lexical_link :domain_categories, :domain_category

	##
	# Return the synsets that are lexically linked to this sense via a "domain member
	# category" link.
	lexical_link :domain_member_categories, :domain_member_category

	##
	# Return the synsets that are lexically linked to this sense via a "domain member region" link.
	lexical_link :domain_member_region

	##
	# Return the synsets that are lexically linked to this sense via a "domain member usage" link.
	lexical_link :domain_member_usage

	##
	# Return the synsets that are lexically linked to this sense via a "domain region" link.
	lexical_link :domain_region

	##
	# Return the synsets that are lexically linked to this sense via a "domain usage" link.
	lexical_link :domain_usage

	##
	# Return the synsets that are lexically linked to this sense via a "participle" link.
	lexical_link :participle

	##
	# Return the synsets that are lexically linked to this sense via a "pertainym" link.
	lexical_link :pertainym

	##
	# Return the synsets that are lexically linked to this sense via a "verb group" link.
	lexical_link :verb_group


end # class WordNet::Sense

