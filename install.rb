#!/usr/bin/ruby
#
#	Module Install Script
#	$Id$
#
#	Thanks to Masatoshi SEKI for ideas found in his install.rb.
#
#	Copyright (c) 2001-2005 The FaerieMUD Consortium.
#
#	This is free software. You may use, modify, and/or redistribute this
#	software under the terms of the Perl Artistic License. (See
#	http://language.perl.com/misc/Artistic.html)
#

BEGIN {
    basedir = File::dirname( __FILE__ )
    $LOAD_PATH.unshift( "#{basedir}/lib" )
    require 'wordnet'

    require "#{basedir}/utils.rb"
    include UtilityFunctions
}

require './convertdb.rb'

require 'rbconfig'
include Config unless defined?( CONFIG )

require 'find'
require 'ftools'
require 'optparse'

$version	= %q$Revision: 11 $
$rcsId		= %q$Id$

# Define required libraries
RequiredLibraries = [
	# libraryname, nice name, RAA URL, Download URL, e.g.,
	[ 'bdb', "Berkeley-DB", 
		'http://raa.ruby-lang.org/project/bdb',
		'',
	],
]

DataDir = File::join( File::expand_path(File::dirname(__FILE__)), 
    File::basename(WordNet::Lexicon::DefaultDbEnv) )

def main( dryrun, forcedbcreate, *args )

	# Don't do anything if they expect this to be the three-step install script
	# and they aren't doing the 'install' step.
	if args.include?( "config" )
		for lib in RequiredLibraries
			testForRequiredLibrary( *lib )
		end
		puts "Done."
	elsif args.include?( "setup" )
        makeDatabase()
		puts "Done."
	elsif args.empty?
		for lib in RequiredLibraries
			testForRequiredLibrary( *lib )
		end
	end

	if args.empty? || args.include?( "install" )
	    makeDatabase()
		sitelibdir = CONFIG['sitelibdir']
		debugMsg "Sitelibdir = '#{sitelibdir}'"
		sitearchdir = CONFIG['sitearchdir']
		debugMsg "Sitearchdir = '#{sitearchdir}'"
		datadir = WordNet::Lexicon::DefaultDbEnv
		debugMsg "Datadir = '#{datadir}'"

		message "Installing..."
		message "\n" if $VERBOSE

		i = Installer.new( dryrun )
		i.installFiles( DataDir, datadir, 0666 - File::umask, $VERBOSE )
		i.installFiles( "lib", sitelibdir, 0444, $VERBOSE )

		message "done.\n"
	end
end


### If the database hasn't already been built, or +force+ is true, build
### it out of the WordNet data files.
def makeDatabase( force=false )
    return unless force ||
        !File.directory?( DataDir ) || 
        !File.exists?( DataDir + "/index" )
    
    debugMsg( "(Re)-creating the WordNet database" )
    convertdb()
end


class Installer

	@@PrunePatterns = [
		/CVS/,
		/~$/,
		%r:(^|/)\.:,
		/\.tpl$/,
	]

	def initialize( testing=false )
		@ftools = (testing) ? self : File
	end

	### Make the specified dirs (which can be a String or an Array of Strings)
	### with the specified mode.
	def makedirs( dirs, mode=0755, verbose=false )
		dirs = [ dirs ] unless dirs.is_a? Array

		oldumask = File::umask
		File::umask( 0777 - mode )

		for dir in dirs
			if @ftools == File
				File::mkpath( dir, $VERBOSE )
			else
				$stderr.puts "Make path %s with mode %o" % [ dir, mode ]
			end
		end

		File::umask( oldumask )
	end

	def install( srcfile, dstfile, mode=nil, verbose=false )
		dstfile = File.catname(srcfile, dstfile)
		unless FileTest.exist? dstfile and File.cmp srcfile, dstfile
			$stderr.puts "   install #{srcfile} -> #{dstfile}"
		else
			$stderr.puts "   skipping #{dstfile}: unchanged"
		end
	end

	public

	def installFiles( src, dstDir, mode=0444, verbose=false )
		directories = []
		files = []
		
		if File.directory?( src )
			Find.find( src ) do |f|
			    verboseMsg "Examining '#{f}'"
				if pattern = @@PrunePatterns.find {|pat| f =~ pat}
				    debugMsg "Pruning #{f}: Matched pattern #{pattern.inspect}" 
				    Find.prune
			    end

				if f == src
				    debugMsg "Nexting in Find loop on origin directory"
				    next
			    else
			        debugMsg "No next, because %p != %p" %
			            [ f, src ]
			    end

				if FileTest.directory?( f )
				    verboseMsg "Adding directory '#{f}'"
					directories << f.gsub( /^#{src}#{File::Separator}/, '' )
					next 

				elsif FileTest.file?( f )
				    verboseMsg "Adding file '#{f}'"
					files << f.gsub( /^#{src}#{File::Separator}/, '' )

				else
				    verboseMsg "Pruning '#{f}' (not a file or directory)"
					Find.prune
				end
			end
		else
            verboseMsg "Directly adding file '#{f}'"
			files << File.basename( src )
			src = File.dirname( src )
		end

		verboseMsg "Done with file search for '#{src}'"

		dirs = [ dstDir ]
		dirs |= directories.collect {|d| File.join(dstDir,d)}
		makedirs( dirs, 0755, verbose )
		files.each do |f|
			srcfile = File.join(src,f)
			dstfile = File.dirname(File.join( dstDir,f ))

			if verbose
				if mode
					verboseMsg "Install #{srcfile} -> #{dstfile} (mode %o)" % mode
				else
					verboseMsg "Install #{srcfile} -> #{dstfile}"
				end
			end

			@ftools.install( srcfile, dstfile, mode, verbose )
		end
	end

end


if $0 == __FILE__
	dryrun = false
	forcedbcreate = false

	# Parse command-line switches
	ARGV.options {|oparser|
		oparser.banner = "Usage: #$0 [options]\n"

		oparser.on( "--debug", "-d", TrueClass, "Show debugging output" ) do
		    $DEBUG = true
		    debugMsg "Turned debugging on."
	    end

		oparser.on( "--verbose", "-v", TrueClass, "Make progress verbose" ) do
			$VERBOSE = true
			debugMsg "Turned verbose on."
		end
		
		oparser.on( "--dry-run", "-n", TrueClass, "Don't really install anything" ) do
			debugMsg "Turned dry-run on."
			dryrun = true
		end

        oparser.on( "--force-db-create", "-f", FalseClass, "Force creation of the database" ) do
            debugMsg "Will force re-creation of the Ruby-WordNet database"
            forcedbcreate = true
        end

		# Handle the 'help' option
		oparser.on( "--help", "-h", "Display this text." ) do
			$stderr.puts oparser
			exit!(0)
		end

		oparser.parse!
	}

    main( dryrun, forcedbcreate, *ARGV )
end
	



