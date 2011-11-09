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
	require 'logger'
	require 'wordnet'

	WordNet.logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

    puts "Instantiating the lexicon as $lex"
    $lex = WordNet::Lexicon.new
rescue Exception => e
	$stderr.puts "Ack! WordNet failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end


