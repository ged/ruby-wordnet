# -*- ruby -*-
#encoding: utf-8

require 'loggability'
require 'sequel'

require 'wordnet' unless defined?( WordNet )


module WordNet

	Model = Class.new( Sequel::Model )
	Model.def_Model( WordNet )

	Model.require_valid_table = false


	# The base WordNet database-backed domain class. It's a subclass of Sequel::Model, so
	# you'll first need to be familiar with Sequel (http://sequel.jeremyevans.net/) and
	# especially its Sequel::Model ORM.
	class Model
		extend Loggability

		# Loggability API -- log to the WordNet module's logger
		log_to :wordnet

		# Sequel plugins
		plugin :validation_helpers
		plugin :subclasses


		# Allow registration of subclasses to load once the db is connected
		class << self
			attr_reader :registered_models
		end
		@registered_models = []


		### Reset the database connection that all model objects will use.
		### @param [Sequel::Database] newdb  the new database object.
		def self::db=( newdb )
			Loggability.with_level( :fatal ) do
				super
			end

			self.load_registered_models if self == WordNet::Model
		end


		### Register a model subclass path to load when the database is connected. If
		### there's already a database connection, just `require` it immediately.
		def self::register_model( name )
			if @db
				require( name )
			else
				self.registered_models << name
			end
		end


		### Load any models which have been registered.
		def self::load_registered_models
			self.registered_models.each do |path|
				require( path )
			end
		end

	end # class Model


end # module WordNet
