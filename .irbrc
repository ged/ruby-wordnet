# -*- ruby -*-

puts ">>> Adding 'lib' to load path..."
$LOAD_PATH.unshift( "lib" )

#puts ">>> Turning on $VERBOSE and $DEBUG..."
# $VERBOSE = $DEBUG = true

require './utils'
include UtilityFunctions

def colored( prompt, *args )
	return ansi_code( *(args.flatten) ) + prompt + ansi_code( 'reset' )
end


# Modify prompt to do highlighting
IRB.conf[:PROMPT][:MUES] = { # name of prompt mode
 	:PROMPT_I => colored( "%N(%m):%03n:%i>", %w{bold white on_blue} ) + " ",
 	:PROMPT_S => colored( "%N(%m):%03n:%i%l", %w{white on_blue} ) + " ",
 	:PROMPT_C => colored( "%N(%m):%03n:%i*", %w{white on_blue} ) + " ",
    :RETURN => "    ==> %s\n\n"      # format to return value
}
IRB.conf[:PROMPT_MODE] = :MUES

# Try to require the 'wordnet' library
begin
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname
	datadir = basedir + 'ruby-wordnet'
	
	puts "Requiring 'wordnet'..."
	require 'wordnet'

    puts "Instantiating the lexicon as $lex"
    $lex = WordNet::Lexicon.new( datadir )
rescue => e
	$stderr.puts "Ack! WordNet failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end
