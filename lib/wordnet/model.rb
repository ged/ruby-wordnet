#!/usr/bin/ruby

require 'loggability'
require 'sequel'

# Use a mock database until the real one is provided by the user
Sequel::Model.db = Sequel.mock if Sequel::DATABASES.empty?

require 'wordnet' unless defined?( WordNet )

module WordNet

	# The base WordNet database-backed domain class. It's a subclass of Sequel::Model, so
	# you'll first need to be familiar with Sequel (http://sequel.rubyforge.org/) and
	# especially its Sequel::Model ORM.
	class Model < Sequel::Model
		extend Loggability

		# Loggability API -- log to the WordNet module's logger
		log_to :wordnet

		# Sequel plugins
		plugin :validation_helpers
		plugin :schema
		plugin :subclasses


		### Execute a block after removing all loggers from the current database handle, then
		### restore them before returning.
		def self::without_sql_logging( logged_db=nil )
			logged_db ||= self.db

			loggers_to_restore = logged_db.loggers.dup
			logged_db.loggers.clear
			yield
		ensure
			logged_db.loggers.replace( loggers_to_restore )
		end


		### Reset the database connection that all model objects will use.
		### @param [Sequel::Database] newdb  the new database object.
		def self::db=( newdb )
			self.without_sql_logging( newdb ) do
				super
			end

			self.descendents.each do |subclass|
				self.log.debug "Resetting database connection for: %p to: %p" % [ subclass, newdb ]
				subclass.db = newdb
			end
		end

	end # class Model


	### Overridden version of Sequel.Model() that creates subclasses of WordNet::Model instead
	### of Sequel::Model.
	### @see Sequel.Model()
	def self::Model( source )
		unless Sequel::Model::ANONYMOUS_MODEL_CLASSES.key?( source )
			anonclass = nil
			WordNet::Model.without_sql_logging do
				if source.is_a?( Sequel::Database )
					anonclass = Class.new( WordNet::Model )
					anonclass.db = source
				else
					anonclass = Class.new( WordNet::Model ).set_dataset( source )
				end
			end

			Sequel::Model::ANONYMOUS_MODEL_CLASSES[ source ] = anonclass
		end

		return Sequel::Model::ANONYMOUS_MODEL_CLASSES[ source ]
	end

end # module WordNet
