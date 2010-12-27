#!/usr/bin/env ruby

require 'wordnet'

module WordNet

	# Add logging to a WordNet class. Including classes get #log and #log_debug methods.
	module Loggable

		# Level names to levels
		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }

		### A logging proxy class that wraps calls to the logger into calls that include
		### the name of the calling class.
		### @private
		class ClassNameProxy

			### Create a new proxy for the given +klass+.
			def initialize( klass, force_debug=false )
				@classname   = klass.name
				@force_debug = force_debug
			end

			### Delegate calls the global logger with the class name as the 'progname' 
			### argument.
			def method_missing( sym, msg=nil, &block )
				return super unless LEVEL.key?( sym )
				sym = :debug if @force_debug
				WordNet.logger.add( LEVEL[sym], msg, @classname, &block )
			end
		end # ClassNameProxy

		#########
		protected
		#########

		### Copy constructor -- clear the original's log proxy.
		def initialize_copy( original )
			@log_proxy = @log_debug_proxy = nil
			super
		end

		### Return the proxied logger.
		def log
			@log_proxy ||= ClassNameProxy.new( self.class )
		end

		### Return a proxied "debug" logger that ignores other level specification.
		def log_debug
			@log_debug_proxy ||= ClassNameProxy.new( self.class, true )
		end
	end # module Loggable


	# A mixin module that provides utilities for the other model mixins.
	module ModelMixin

		### Extension callback -- add data structures to the extending +mod+.
		### @param [Module] mod  the mixin module to be extended
		def self::extended( mod )
			super
			mod.instance_variable_set( :@table_name, mod.name.downcase.to_sym )
		end


		### A declarative/reader for the table that the mixin applies to. This
		### also tells the lexicon which table it's supposed to be creating a model
		### class for.
		### @see WordNet::Lexicon.model_class
		### @param [Symbol] newname  the name of the table the mixin applies to
		def table_name( newname=nil )
			@table_name = newname if newname
			return @table_name
		end


		# Class methods to add to the anonymous model classes which include the
		# module that extends ModuleMixin
		module ModelClassMethods

			### Provide a name for the anonymous classes that makes them easier
			### to debug.
			def name
				return "%s(%s)" % [
					self.included_modules.first.name,
					self.dataset.db.uri
				]
			end

		end # module ModelClassMethods

		### Inclusion hook -- add class methods to model classes that include the
		### module that extends ModuleMixin
		def included( mod )
			super
			mod.extend( ModelClassMethods )
		end

	end # module ModelMixin

end # module WordNet

