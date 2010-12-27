#!/usr/bin/ruby

require 'wordnet'
require 'wordnet/mixins'

require 'sequel/model'

# WordNet word model class mixin -- adds WordNet-specific functionality to
# the Sequel::Model subclass created by the Lexicon.
module WordNet::Word
	include WordNet::Constants
	extend WordNet::ModelMixin

	table_name :words

	def self::included( mod )
		super
		mod.module_eval do
			one_to_many :synsets
		end
	end

end # module WordNet::Word

