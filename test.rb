#!/usr/bin/ruby
#
#	Test suite for Ruby-WordNet
#
#

require "walkit/cli_script"
require "find"

$: << "lib"

### Load all the tests from the tests dir
puts "Finding test files..."
Find.find("t") {|file|
	Find.prune if file =~ %r{^\.\.|.*/\.}
	next if File.stat( file ).directory?
	next unless file =~ /.*_tests\.rb$/
	puts "  Requiring #{file}..."
	require( file )
}

### Find all the loaded test classes
testClasses = []
ObjectSpace.each_object( Class ) {|klass|
	next unless klass < Walkit::Testclass
	testClasses << klass
}

### Run 'em, or run the ones that match Regexp.new(ARGV[0]), if specified.
Walkit::Cli_script.new.select( testClasses.sort, $*.shift )

