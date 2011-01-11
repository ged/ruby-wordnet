#!/usr/bin/ruby

require 'sequel/model'

require 'wordnet'
require 'wordnet/mixins'

# WordNet word model class mixin -- adds WordNet-specific functionality to
# the Sequel::Model subclass created by the Lexicon.
class WordNet::Model < Sequel::Model
	include WordNet::Constants

	# The list of model subclasses
	@subclasses = []
	class << self; attr_reader :subclasses; end


	### Inheritance callback -- add the inheriting class to the list of known
	### subclasses.
	def self::inherited( subclass )
		self.subclasses << subclass
		super
	end


	### Override Sequel::Model#db= to propagate the change to all subclasses.
	def self::db=( newdb )
		if self == WordNet::Model
			super
			self.subclasses.each {|subclass| subclass.db = newdb }
		else
			super
			set_dataset( self.dataset.opts[:from].first )
		end
	end

end # class WordNet::Model

