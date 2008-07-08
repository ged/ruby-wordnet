#####################################################################
###	G L O B A L   H E L P E R   F U N C T I O N S
#####################################################################

require 'pathname'
require 'readline'


# Set some ANSI escape code constants (Shamelessly stolen from Perl's
# Term::ANSIColor by Russ Allbery <rra@stanford.edu> and Zenin <zenin@best.com>
ANSI_ATTRIBUTES = {
	'clear'      => 0,
	'reset'      => 0,
	'bold'       => 1,
	'dark'       => 2,
	'underline'  => 4,
	'underscore' => 4,
	'blink'      => 5,
	'reverse'    => 7,
	'concealed'  => 8,

	'black'      => 30,   'on_black'   => 40, 
	'red'        => 31,   'on_red'     => 41, 
	'green'      => 32,   'on_green'   => 42, 
	'yellow'     => 33,   'on_yellow'  => 43, 
	'blue'       => 34,   'on_blue'    => 44, 
	'magenta'    => 35,   'on_magenta' => 45, 
	'cyan'       => 36,   'on_cyan'    => 46, 
	'white'      => 37,   'on_white'   => 47
}


CLEAR_TO_EOL       = "\e[K"
CLEAR_CURRENT_LINE = "\e[2K"


### Output a logging message
def log( *msg )
	output = colorize( msg.flatten.join(' '), 'cyan' )
	$deferr.puts( output )
end


### Output a logging message if tracing is on
def trace( *msg )
	return unless $trace
	output = colorize( msg.flatten.join(' '), 'yellow' )
	$deferr.puts( output )
end


### Run the specified command +cmd+ with system(), failing if the execution
### fails.
def run( *cmd )
	cmd.flatten!

	log( cmd.collect {|part| part =~ /\s/ ? part.inspect : part} ) 
	if $dryrun
		$deferr.puts "(dry run mode)"
	else
		system( *cmd )
		unless $?.success?
			fail "Command failed: [%s]" % [cmd.join(' ')]
		end
	end
end


### Open a pipe to a process running the given +cmd+ and call the given block with it.
def pipeto( *cmd )
	$DEBUG = true

	cmd.flatten!
	log( "Opening a pipe to: ", cmd.collect {|part| part =~ /\s/ ? part.inspect : part} ) 
	if $dryrun
		$deferr.puts "(dry run mode)"
	else
		open( '|-', 'w+' ) do |io|
		
			# Parent
			if io
				yield( io )

			# Child
			else
				exec( *cmd )
				fail "Command failed: [%s]" % [cmd.join(' ')]
			end
		end
	end
end


### Download the file at +sourceuri+ via HTTP and write it to +targetfile+.
def download( sourceuri, targetfile )
	oldsync = $defout.sync
	$defout.sync = true
	require 'net/http'
	require 'uri'

	targetpath = Pathname.new( targetfile )

	log "Downloading %s to %s" % [sourceuri, targetfile]
	targetpath.open( File::WRONLY|File::TRUNC|File::CREAT, 0644 ) do |ofh|
	
		url = URI.parse( sourceuri )
		downloaded = false
		limit = 5
		
		until downloaded or limit.zero?
			Net::HTTP.start( url.host, url.port ) do |http|
				req = Net::HTTP::Get.new( url.path )

				http.request( req ) do |res|
					if res.is_a?( Net::HTTPSuccess )
						log "Downloading..."
						res.read_body do |buf|
							ofh.print( buf )
						end
						downloaded = true
						puts "done."
		
					elsif res.is_a?( Net::HTTPRedirection )
						url = URI.parse( res['location'] )
						log "...following redirection to: %s" % [ url ]
						limit -= 1
						sleep 0.2
						next
				
					else
						res.error!
					end
				end
			end
		end
	end
	
	return targetpath
ensure
	$defout.sync = oldsync
end


### Return the fully-qualified path to the specified +program+ in the PATH.
def which( program )
	ENV['PATH'].split(/:/).
		collect {|dir| Pathname.new(dir) + program }.
		find {|path| path.exist? && path.executable? }
end


### Create a string that contains the ANSI codes specified and return it
def ansi_code( *attributes )
	attributes.flatten!
	attributes.collect! {|at| at.to_s }
	# $deferr.puts "Returning ansicode for TERM = %p: %p" %
	# 	[ ENV['TERM'], attributes ]
	return '' unless /(?:vt10[03]|xterm(?:-color)?|linux|screen)/i =~ ENV['TERM']
	attributes = ANSI_ATTRIBUTES.values_at( *attributes ).compact.join(';')

	# $deferr.puts "  attr is: %p" % [attributes]
	if attributes.empty? 
		return ''
	else
		return "\e[%sm" % attributes
	end
end


### Colorize the given +string+ with the specified +attributes+ and return it, handling 
### line-endings, color reset, etc.
def colorize( *args )
	string = ''
	
	if block_given?
		string = yield
	else
		string = args.shift
	end
	
	ending = string[/(\s)$/] || ''
	string = string.rstrip

	return ansi_code( args.flatten ) + string + ansi_code( 'reset' ) + ending
end


### Output the specified <tt>msg</tt> as an ANSI-colored error message
### (white on red).
def error_message( msg, details='' )
	$deferr.puts colorize( 'bold', 'white', 'on_red' ) { msg } + details
end
alias :error :error_message


### Highlight and embed a prompt control character in the given +string+ and return it.
def make_prompt_string( string )
	return CLEAR_CURRENT_LINE + colorize( 'bold', 'green' ) { string + ' ' }
end


### Output the specified <tt>prompt_string</tt> as a prompt (in green) and
### return the user's input with leading and trailing spaces removed.  If a
### test is provided, the prompt will repeat until the test returns true.
### An optional failure message can also be passed in.
def prompt( prompt_string, failure_msg="Try again." ) # :yields: response
	prompt_string.chomp!
	prompt_string << ":" unless /\W$/.match( prompt_string )
	response = nil

	begin
		prompt = make_prompt_string( prompt_string )
		response = Readline.readline( prompt ) || ''
		response.strip!
		if block_given? && ! yield( response ) 
			error_message( failure_msg + "\n\n" )
			response = nil
		end
	end while response.nil?

	return response
end


### Prompt the user with the given <tt>prompt_string</tt> via #prompt,
### substituting the given <tt>default</tt> if the user doesn't input
### anything.  If a test is provided, the prompt will repeat until the test
### returns true.  An optional failure message can also be passed in.
def prompt_with_default( prompt_string, default, failure_msg="Try again." )
	response = nil

	begin
		response = prompt( "%s [%s]" % [ prompt_string, default ] )
		response = default if response.empty?

		if block_given? && ! yield( response ) 
			error_message( failure_msg + "\n\n" )
			response = nil
		end
	end while response.nil?

	return response
end


### Display a description of a potentially-dangerous task, and prompt
### for confirmation. If the user answers with anything that begins
### with 'y', yield to the block, else raise with an error.
def ask_for_confirmation( description )
	puts description

	answer = prompt_with_default( "Continue?", 'n' ) do |input|
		input =~ /^[yn]/i
	end

	case answer
	when /^y/i
		yield
	else
		error "Aborted."
		fail
	end
end


### Search line-by-line in the specified +file+ for the given +regexp+, returning the
### first match, or nil if no match was found. If the +regexp+ has any capture groups,
### those will be returned in an Array, else the whole matching line is returned.
def find_pattern_in_file( regexp, file )
	rval = nil
	
	File.open( file, 'r' ).each do |line|
		if (( match = regexp.match(line) ))
			rval = match.captures.empty? ? match[0] : match.captures
			break
		end
	end

	return rval
end


### Get a list of the file or files to run rspec on.
def rspec_files
	if ENV['class']
		classname = ENV['class']
		spec_file = SPECSDIR + "#{classname}_spec.rb"
		raise "Can't find the spec file for the class '#{classname}'" unless spec_file.exist?
		return [ spec_file ]
	else
		return SPEC_FILES
	end
end


### Extract all the non Rake-target arguments from ARGV and return them.
def get_target_args
	args = ARGV.reject {|arg| Rake::Task.task_defined?(arg) }
	return args
end



