#!/usr/bin/env ruby

require 'wordnet' unless defined?( WordNet )

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


end # module WordNet

