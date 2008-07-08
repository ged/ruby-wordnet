#!/usr/bin/ruby
#
#	Test::Unit test suite for Ruby-WordNet
#
#

BEGIN {
	$:.unshift "lib", "tests"

	require './utils'
	include UtilityFunctions
}

verbose_off {
	require 'tests/wntestcase'
	require 'find'
	require 'test/unit'
	require 'test/unit/testsuite'
	require 'test/unit/ui/console/testrunner'
	require 'optparse'
}

# Turn off output buffering
$stderr.sync = $stdout.sync = true

# Initialize variables
patterns = []
requires = []

# Parse command-line switches
ARGV.options {|oparser|
	oparser.banner = "Usage: #$0 [options] [TARGETS]\n"

	oparser.on( "--debug", "-d", TrueClass, "Turn debugging on" ) {
		$DEBUG = true
		debug_msg "Turned debugging on."
	}

	oparser.on( "--verbose", "-v", TrueClass, "Make progress verbose" ) {
		$VERBOSE = true
		debug_msg "Turned verbose on."
	}

	# Handle the 'help' option
	oparser.on( "--help", "-h", "Display this text." ) {
		$stderr.puts oparser
		exit!(0)
	}

	oparser.parse!
}

# Parse test patterns
ARGV.each {|pat| patterns << Regexp::new( pat, Regexp::IGNORECASE )}
$stderr.puts "#{patterns.length} patterns given on the command line"

### Load all the tests from the tests dir
Find.find("tests") {|file|
	Find.prune if /\/\./ =~ file or /~$/ =~ file
	Find.prune if /TEMPLATE/ =~ file
	next if File.stat( file ).directory?

 	unless patterns.empty?
 		Find.prune unless patterns.find {|pat| pat =~ file}
 	end

	debug_msg "Considering '%s': " % file
	next unless file =~ /\.tests.rb$/
	debug_msg "Requiring '%s'..." % file
	require "#{file}"
	requires << file
}

$stderr.puts "Required #{requires.length} files."
unless patterns.empty?
	$stderr.puts "[" + requires.sort.join( ", " ) + "]"
end

# Build the test suite
class WordNetTests
	class << self
		def suite
			suite = Test::Unit::TestSuite.new( "WordNet" )

			if suite.respond_to?( :add )
				ObjectSpace.each_object( Class ) {|klass|
					suite.add( klass.suite ) if klass < WordNet::TestCase
				}
			else
				ObjectSpace.each_object( Class ) {|klass|
					suite << klass.suite if klass < WordNet::TestCase
				}			
			end

			return suite
		end
	end
end

# Run tests
Test::Unit::UI::Console::TestRunner.new( WordNetTests ).start




