#!/usr/bin/ruby
#
#	Test suite for Ruby-WordNet
#
#

require "runit/testsuite"
require "runit/cui/testrunner"
require "parsearg"
require "find"

# RUNIT::CUI::TestRunner.quiet_mode = true

$: << "lib"

### Run 'em, or run the ones that match Regexp.new(ARGV[0]), if specified.
class TestAll
	def TestAll.suite

		# Load all the tests from the tests dir
		puts "Finding test files..."
		Find.find("t") {|file|
			Find.prune if file =~ %r{^\.\.|.*/\.}
			next if File.stat( file ).directory?
			next unless file =~ /.*\.rb$/
			puts "  Requiring #{file}..."
			require( file )
		}
		# Find all the loaded test classes
		testClasses = []
		ObjectSpace.each_object( Class ) {|klass|
			next unless klass < RUNIT::TestCase
			testClasses << klass
		}

		# Define a test suite made up of all the RUNIT::TestCase suites
		suite = RUNIT::TestSuite.new
		testClasses.sort.each {|klass|
			suite.add(klass.suite)
		}
		return suite
	end
end

RUNIT::CUI::TestRunner.run( TestAll.suite )


