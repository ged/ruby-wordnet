#!/usr/bin/ruby -*- ruby -*-

BEGIN {
	require 'pathname'
	$stderr.puts "__FILE__ is: #{__FILE__}"
	basedir = Pathname.new( __FILE__ ).dirname.expand_path
	libdir = basedir + 'lib'
	dblibdir = basedir + 'wordnet-defaultdb/lib'

	puts ">>> Adding #{libdir} to load path..."
	$LOAD_PATH.unshift( libdir.to_s )

	puts ">>> Adding #{dblibdir} to load path..."
	$LOAD_PATH.unshift( dblibdir.to_s )
}

begin
	$stderr.puts "Loading WordNet..."
	require 'loggability'
	require 'wordnet'
rescue Exception => e
	$stderr.puts "Ack! WordNet failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end

Loggability.level = :debug if $DEBUG

if Gem::Specification.find_all_by_name( 'pg' ).any?
	begin
		puts "Instantiating the lexicon against the PostgreSQL (wordnet31) DB as $lex"
		$lex = WordNet::Lexicon.new( 'postgres:/wordnet31' )
	rescue => err
		puts "That didn't work."
	end
end

unless $lex
	puts "Instantiating the lexicon against the default DB as $lex"
	$lex = WordNet::Lexicon.new
end


