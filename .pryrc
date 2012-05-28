#!/usr/bin/ruby -*- ruby -*-

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.expand_path
	libdir = basedir + "lib"

	puts ">>> Adding #{libdir} to load path..."
	$LOAD_PATH.unshift( libdir.to_s )
}

begin
	$stderr.puts "Loading WordNet..."
	require 'loggability'
	require 'wordnet'

	Loggability.level = :debug if $DEBUG

    puts "Instantiating the lexicon as $lex"
    $lex = WordNet::Lexicon.new
rescue Exception => e
	$stderr.puts "Ack! WordNet failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end


