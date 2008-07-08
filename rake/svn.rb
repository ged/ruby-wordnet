#####################################################################
###	S U B V E R S I O N   T A S K S   A N D   H E L P E R S
#####################################################################

require 'pp'
require 'yaml'
require 'English'

# Strftime format for tags/releases
TAG_TIMESTAMP_FORMAT = '%Y%m%d-%H%M%S'
TAG_TIMESTAMP_PATTERN = /\d{4}\d{2}\d{2}-\d{6}/

RELEASE_VERSION_PATTERN = /\d+\.\d+\.\d+/

DEFAULT_EDITOR = 'vi'
DEFAULT_KEYWORDS = %w[Date Rev Author URL Id]
KEYWORDED_FILEDIRS = %w[applets bin etc lib misc]
KEYWORDED_FILEPATTERN = /^(?:Rakefile|.*\.(?:rb|js|html|template))$/i

COMMIT_MSG_FILE = 'commit-msg.txt'

###
### Subversion-specific Helpers
###

### Return a new tag for the given time
def make_new_tag( time=Time.now )
	return time.strftime( TAG_TIMESTAMP_FORMAT )
end


### Get the subversion information for the current working directory as
### a hash.
def get_svn_info( dir='.' )
	info = IO.read( '|-' ) or exec 'svn', 'info', dir
	return YAML.load( info ) # 'svn info' outputs valid YAML! Yay!
end


### Get a list of the objects registered with subversion under the specified directory and
### return them as an Array of Pathame objects.
def get_svn_filelist( dir='.' )
	list = IO.read( '|-' ) or exec 'svn', 'st', '-v', '--ignore-externals', dir

	# Split into lines, filter out the unknowns, and grab the filenames as Pathnames
	# :FIXME: This will break if we ever put in a file with spaces in its name. This
	# will likely be the least of our worries if we do so, however, so it's not worth
	# the additional complexity to make it handle that case. If we do need that, there's
	# always the --xml output for 'svn st'...
	return list.split( $/ ).
		reject {|line| line =~ /^\?/ }.
		collect {|fn| Pathname(fn[/\S+$/]) }
end

### Return the URL to the repository root for the specified +dir+.
def get_svn_repo_root( dir='.' )
	info = get_svn_info( dir )
	return info['Repository Root'] + '/thingfish'
end


### Return the Subversion URL to the given +dir+.
def get_svn_url( dir='.' )
	info = get_svn_info( dir )
	return info['URL']
end


### Return the path of the specified +dir+ under the svn root of the 
### checkout.
def get_svn_path( dir='.' )
	root = get_svn_repo_root( dir )
	url = get_svn_url( dir )
	
	return url.sub( root + '/', '' )
end


### Return the keywords for the specified array of +files+ as a Hash keyed by filename.
def get_svn_keyword_map( files )
	cmd = ['svn', 'pg', 'svn:keywords', *files]

	# trace "Executing: svn pg svn:keywords " + files.join(' ')
	output = IO.read( '|-' ) or exec( 'svn', 'pg', 'svn:keywords', *files )
	
	kwmap = {}
	output.split( "\n" ).each do |line|
		next if line !~ /\s+-\s+/
		path, keywords = line.split( /\s+-\s+/, 2 )
		kwmap[ path ] = keywords.split
	end
	
	return kwmap
end


### Return the latest revision number of the specified +dir+ as an Integer.
def get_svn_rev( dir='.' )
	info = get_svn_info( dir )
	return info['Revision']
end


### Return a list of the entries at the specified Subversion url. If
### no +url+ is specified, it will default to the list in the URL
### corresponding to the current working directory.
def svn_ls( url=nil )
	url ||= get_svn_url()
	list = IO.read( '|-' ) or exec 'svn', 'ls', url

	trace 'svn ls of %s: %p' % [url, list] if $trace
	
	return [] if list.nil? || list.empty?
	return list.split( $INPUT_RECORD_SEPARATOR )
end


### Return the URL of the latest timestamp in the tags directory.
def get_latest_svn_timestamp_tag
	rooturl = get_svn_repo_root()
	tagsurl = rooturl + '/tags'
	
	tags = svn_ls( tagsurl ).grep( TAG_TIMESTAMP_PATTERN ).sort
	return nil if tags.nil? || tags.empty?
	return tagsurl + '/' + tags.last
end


### Get a subversion diff of the specified targets and return it. If no targets are
### specified, the current directory will be diffed instead.
def get_svn_diff( *targets )
	targets << BASEDIR if targets.empty?
	trace "Getting svn diff for targets: %p" % [targets]
	log = IO.read( '|-' ) or exec 'svn', 'diff', *(targets.flatten)

	return log
end


### Return the URL of the latest timestamp in the tags directory.
def get_latest_release_tag
	rooturl    = get_svn_repo_root()
	releaseurl = rooturl + '/releases'
	
	tags = svn_ls( releaseurl ).grep( RELEASE_VERSION_PATTERN ).sort_by do |tag|
		tag.split('.').collect {|i| Integer(i) }
	end
	return nil if tags.empty?

	return releaseurl + '/' + tags.last
end


### Extract a diff from the specified subversion working +dir+, rewrite its
### file lines as Trac links, and return it.
def make_svn_commit_log( dir='.' )
	editor_prog = ENV['EDITOR'] || ENV['VISUAL'] || DEFAULT_EDITOR
	
	diff = IO.read( '|-' ) or exec 'svn', 'diff'
	fail "No differences." if diff.empty?

	return diff
end



###
### Tasks
###

desc "Subversion tasks"
namespace :svn do

	desc "Copy the HEAD revision of the current trunk/ to tags/ with a " +
		 "current timestamp."
	task :tag do
		svninfo   = get_svn_info()
		tag       = make_new_tag()
		svntrunk  = svninfo['Repository Root'] + '/thingfish/trunk'
		svntagdir = svninfo['Repository Root'] + '/thingfish/tags'
		svntag    = svntagdir + '/' + tag

		desc = "Tagging trunk as #{svntag}"
		ask_for_confirmation( desc ) do
			msg = prompt_with_default( "Commit log: ", "Tagging for code push" )
			run 'svn', 'cp', '-m', msg, svntrunk, svntag
		end
	end


	desc "Copy the most recent tag to releases/#{PKG_VERSION}"
	task :release do
		last_tag    = get_latest_svn_timestamp_tag()
		svninfo     = get_svn_info()
		release     = PKG_VERSION
		svnrel      = svninfo['Repository Root'] + '/thingfish/releases'
		svnrelease  = svnrel + '/' + release

		if last_tag.nil?
			error "There are no tags in the repository"
			fail
		end

		releases = svn_ls( svnrel )
		trace "Releases: %p" % [releases]
		if releases.include?( release )
			error "Version #{release} already has a branch (#{svnrelease}). Did you mean" +
				"to increment the version in thingfish.rb?"
			fail
		else
			trace "No #{svnrel} version currently exists"
		end
		
		desc = "Release tag\n  #{last_tag}\nto\n  #{svnrelease}"
		ask_for_confirmation( desc ) do
			msg = prompt_with_default( "Commit log: ", "Branching for release" )
			run 'svn', 'cp', '-m', msg, last_tag, svnrelease
		end
	end

	### Task for debugging the #get_target_args helper
	task :show_targets do
		$stdout.puts "Targets from ARGV (%p): %p" % [ARGV, get_target_args()]
	end


	desc "Generate a commit log"
	task :commitlog => [COMMIT_MSG_FILE]
	
	desc "Show the (pre-edited) commit log for the current directory"
	task :show_commitlog => [COMMIT_MSG_FILE] do
		ask_for_confirmation( "Confirm? " ) do
			args = get_target_args()
			puts get_svn_diff( *args )
		end
	end
	

	file COMMIT_MSG_FILE do
		args = get_target_args()
		diff = get_svn_diff( *args )
		
		File.open( COMMIT_MSG_FILE, File::WRONLY|File::EXCL|File::CREAT ) do |fh|
			fh.print( diff )
		end

		editor = ENV['EDITOR'] || ENV['VISUAL'] || DEFAULT_EDITOR
		system editor, COMMIT_MSG_FILE
		unless $?.success?
			fail "Editor exited uncleanly."
		end
	end


	desc "Update from Subversion"
	task :update do
		run 'svn', 'up', '--ignore-externals'
	end


	desc "Check in all the changes in your current working copy"
	task :checkin => ['svn:update', 'coverage:verify', 'svn:fix_keywords', COMMIT_MSG_FILE] do
		targets = get_target_args()
		$deferr.puts '---', File.read( COMMIT_MSG_FILE ), '---'
		ask_for_confirmation( "Continue with checkin?" ) do
			run 'svn', 'ci', '-F', COMMIT_MSG_FILE, targets
			rm_f COMMIT_MSG_FILE
		end
	end
	task :commit => :checkin
	task :ci => :checkin
		
	
	task :clean do
		rm_f COMMIT_MSG_FILE
	end


	desc "Check and fix any missing keywords for any files in the project which need them"
	task :fix_keywords do
		log "Checking subversion keywords..."
		paths = get_svn_filelist( BASEDIR ).
			select {|path| path.file? && path.to_s =~ KEYWORDED_FILEPATTERN }

		trace "Looking at %d paths for keywords:\n  %p" % [paths.length, paths]
		kwmap = get_svn_keyword_map( paths )

		buf = ''
		PP.pp( kwmap, buf, 132 )
		trace "keyword map is: %s" % [buf]
		
		files_needing_fixups = paths.find_all do |path|
			(kwmap[path.to_s] & DEFAULT_KEYWORDS) != DEFAULT_KEYWORDS
		end
		
		unless files_needing_fixups.empty?
			$deferr.puts "Files needing keyword fixes: ",
				files_needing_fixups.collect {|f|
					"  %s: %s" % [f, kwmap[f] ? kwmap[f].join(' ') : "(no keywords)"]
				}
			ask_for_confirmation( "Will add default keywords to these files." ) do
				run 'svn', 'ps', 'svn:keywords', DEFAULT_KEYWORDS.join(' '), *files_needing_fixups
			end
		else
			log "Keywords are all up to date."
		end
	end

	
	task :debug_helpers do
		methods = [
			:make_new_tag,
			:get_svn_info,
			:get_svn_repo_root,
			:get_svn_url,
			:get_svn_path,
			:svn_ls,
			:get_latest_svn_timestamp_tag,
		]
		maxlen = methods.collect {|sym| sym.to_s.length }.max
		
		methods.each do |meth|
			res = send( meth )
			puts "%*s => %p" % [ maxlen, colorize(meth.to_s, :cyan), res ]
		end
	end
end

