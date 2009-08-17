#!rake
#
# Ruby-WordNet rakefile
#
# Based on various other Rakefiles, especially one by Ben Bleything
#
# Copyright (c) 2007-2009 The FaerieMUD Consortium
#
# Authors:
#  * Michael Granger <ged@FaerieMUD.org>
#

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname

	libdir = basedir + "lib"
	extdir = basedir + "ext"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
	$LOAD_PATH.unshift( extdir.to_s ) unless $LOAD_PATH.include?( extdir.to_s )
}

begin
	require 'readline'
	include Readline
rescue LoadError
	# Fall back to a plain prompt
	def readline( text )
		$stderr.print( text.chomp )
		return $stdin.gets
	end
end

require 'rbconfig'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/clean'
# require 'rake/191_compat.rb'

$dryrun = false

### Config constants
BASEDIR       = Pathname.new( __FILE__ ).dirname.relative_path_from( Pathname.getwd )
BINDIR        = BASEDIR + 'bin'
LIBDIR        = BASEDIR + 'lib'
EXTDIR        = BASEDIR + 'ext'
DOCSDIR       = BASEDIR + 'docs'
PKGDIR        = BASEDIR + 'pkg'
DATADIR       = BASEDIR + 'data'

MANUALDIR     = DOCSDIR + 'manual'

PROJECT_NAME  = 'Ruby-WordNet'
PKG_NAME      = PROJECT_NAME.downcase
PKG_SUMMARY   = 'a Ruby interface to the WordNet Lexical Database'

# Cruisecontrol stuff
CC_BUILD_LABEL     = ENV['CC_BUILD_LABEL']
CC_BUILD_ARTIFACTS = ENV['CC_BUILD_ARTIFACTS'] || 'artifacts'

VERSION_FILE  = LIBDIR + 'wordnet.rb'
if VERSION_FILE.exist? && buildrev = ENV['CC_BUILD_LABEL']
	PKG_VERSION = VERSION_FILE.read[ /VERSION\s*=\s*['"](\d+\.\d+\.\d+)['"]/, 1 ] + '.' + buildrev
elsif VERSION_FILE.exist?
	PKG_VERSION = VERSION_FILE.read[ /VERSION\s*=\s*['"](\d+\.\d+\.\d+)['"]/, 1 ]
else
	PKG_VERSION = '0.0.0'
end

PKG_FILE_NAME = "#{PKG_NAME.downcase}-#{PKG_VERSION}"
GEM_FILE_NAME = "#{PKG_FILE_NAME}.gem"

# Universal VCS constants
DEFAULT_EDITOR  = 'vi'
COMMIT_MSG_FILE = 'commit-msg.txt'
FILE_INDENT     = " " * 12
LOG_INDENT      = " " * 3

EXTCONF       = EXTDIR + 'extconf.rb'

ARTIFACTS_DIR = Pathname.new( CC_BUILD_ARTIFACTS )

TEXT_FILES    = Rake::FileList.new( %w[Rakefile ChangeLog README LICENSE] )
BIN_FILES     = Rake::FileList.new( "#{BINDIR}/*" )
LIB_FILES     = Rake::FileList.new( "#{LIBDIR}/**/*.rb" )
EXT_FILES     = Rake::FileList.new( "#{EXTDIR}/**/*.{c,h,rb}" )
DATA_FILES    = Rake::FileList.new( "#{DATADIR}/**/*" )

SPECDIR       = BASEDIR + 'spec'
SPECLIBDIR    = SPECDIR + 'lib'
SPEC_FILES    = Rake::FileList.new( "#{SPECDIR}/**/*_spec.rb", "#{SPECLIBDIR}/**/*.rb" )

TESTDIR       = BASEDIR + 'tests'
TEST_FILES    = Rake::FileList.new( "#{TESTDIR}/**/*.tests.rb" )

RAKE_TASKDIR  = BASEDIR + 'rake'
RAKE_TASKLIBS = Rake::FileList.new( "#{RAKE_TASKDIR}/*.rb" )
PKG_TASKLIBS  = Rake::FileList.new( "#{RAKE_TASKDIR}/{191_compat,helpers,packaging,rdoc,testing}.rb" )
PKG_TASKLIBS.include( "#{RAKE_TASKDIR}/manual.rb" ) if MANUALDIR.exist?

RAKE_TASKLIBS_URL = 'http://repo.deveiate.org/rake-tasklibs'

LOCAL_RAKEFILE = BASEDIR + 'Rakefile.local'

EXTRA_PKGFILES = Rake::FileList.new
EXTRA_PKGFILES.include( "#{BASEDIR}/convertdb.rb" )
EXTRA_PKGFILES.include( "#{BASEDIR}/utils.rb" )
EXTRA_PKGFILES.include( "#{BASEDIR}/examples/*.rb" )

RELEASE_FILES = TEXT_FILES + 
	SPEC_FILES + 
	TEST_FILES + 
	BIN_FILES +
	LIB_FILES + 
	EXT_FILES + 
	DATA_FILES + 
	RAKE_TASKLIBS +
	EXTRA_PKGFILES


RELEASE_FILES << LOCAL_RAKEFILE.to_s if LOCAL_RAKEFILE.exist?

COVERAGE_MINIMUM = ENV['COVERAGE_MINIMUM'] ? Float( ENV['COVERAGE_MINIMUM'] ) : 85.0
RCOV_EXCLUDES = 'spec,tests,/Library/Ruby,/var/lib,/usr/local/lib'
RCOV_OPTS = [
	'--exclude', RCOV_EXCLUDES,
	'--xrefs',
	'--save',
	'--callsites',
	#'--aggregate', 'coverage.data' # <- doesn't work as of 0.8.1.2.0
  ]


### Load some task libraries that need to be loaded early
if !RAKE_TASKDIR.exist?
	$stderr.puts "It seems you don't have the build task directory. Shall I fetch it "
	ans = readline( "for you? [y]" )
	ans = 'y' if !ans.nil? && ans.empty?

	if ans =~ /^y/i
		$stderr.puts "Okay, fetching #{RAKE_TASKLIBS_URL} into #{RAKE_TASKDIR}..."
		system 'hg', 'clone', RAKE_TASKLIBS_URL, RAKE_TASKDIR
		if ! $?.success?
			fail "Damn. That didn't work. Giving up; maybe try manually fetching?"
		end
	else
		$stderr.puts "Then I'm afraid I can't continue. Best of luck."
		fail "Rake tasklibs not present."
	end

	RAKE_TASKLIBS.include( "#{RAKE_TASKDIR}/*.rb" )
end

require RAKE_TASKDIR + 'helpers.rb'

# Define some constants that depend on the 'svn' tasklib
if hg = which( 'hg' )
	id = IO.read('|-') or exec hg, 'id', '-q'
	PKG_BUILD = id.chomp
else
	PKG_BUILD = 0
end
SNAPSHOT_PKG_NAME = "#{PKG_FILE_NAME}.#{PKG_BUILD}"
SNAPSHOT_GEM_NAME = "#{SNAPSHOT_PKG_NAME}.gem"

# Documentation constants
RDOCDIR = DOCSDIR + 'api'
RDOC_OPTIONS = [
	'-w', '4',
	'-HN',
	'-i', '.',
	'-m', 'README',
	'-t', PKG_NAME,
	'-W', 'http://deveiate.org/projects/Ruby-WordNet/browser/'
  ]

# Release constants
SMTP_HOST = 'mail.faeriemud.org'
SMTP_PORT = 465 # SMTP + SSL

# Project constants
PROJECT_HOST = 'deveiate'
PROJECT_PUBDIR = '/usr/local/www/public/code'
PROJECT_DOCDIR = "#{PROJECT_PUBDIR}/#{PKG_NAME}"
PROJECT_SCPPUBURL = "#{PROJECT_HOST}:#{PROJECT_PUBDIR}"
PROJECT_SCPDOCURL = "#{PROJECT_HOST}:#{PROJECT_DOCDIR}"

# Rubyforge stuff
RUBYFORGE_GROUP = 'deveiate'
RUBYFORGE_PROJECT = 'wordnet'

# Gem dependencies: gemname => version
DEPENDENCIES = {
	'sequel' => '>= 2.11.0',
}

# Developer Gem dependencies: gemname => version
DEVELOPMENT_DEPENDENCIES = {
	'amatch'      => '>= 0.2.3',
	'rake'        => '>= 0.8.1',
	'rcodetools'  => '>= 0.7.0.0',
	'rcov'        => '>= 0',
	'RedCloth'    => '>= 4.0.3',
	'rspec'       => '>= 0',
	'rubyforge'   => '>= 0',
	'termios'     => '>= 0',
	'text-format' => '>= 1.0.0',
	'tmail'       => '>= 1.2.3.1',
	'ultraviolet' => '>= 0.10.2',
	'libxml-ruby' => '>= 0.8.3',
	'rdoc'        => '>= 2.4.3',
}

# Non-gem requirements: packagename => version
REQUIREMENTS = {
	'bdb' => '>= 0.6.5',
}

# RubyGem specification
GEMSPEC   = Gem::Specification.new do |gem|
	gem.name              = PKG_NAME.downcase
	gem.version           = PKG_VERSION

	gem.summary           = PKG_SUMMARY
	gem.description       = [
		"A Ruby implementation of the WordNet lexical dictionary an online lexical reference system whose",
		"design is inspired by current psycholinguistic theories of human lexical memory.",
  	  ].join( "\n" )

	gem.authors           = "Michael Granger"
	gem.email             = ["ged@FaerieMUD.org"]
	gem.homepage          = 'http://deveiate.org/projects/Ruby-WordNet'
	gem.rubyforge_project = RUBYFORGE_PROJECT

	gem.has_rdoc          = true
	gem.rdoc_options      = RDOC_OPTIONS
	gem.extra_rdoc_files  = %w[ChangeLog README LICENSE]

	gem.bindir            = BINDIR.relative_path_from(BASEDIR).to_s
	gem.executables       = BIN_FILES.select {|pn| File.executable?(pn) }.
	                            collect {|pn| File.basename(pn) }
	gem.require_paths << EXTDIR.relative_path_from( BASEDIR ).to_s if EXTDIR.exist?

	if EXTCONF.exist?
		gem.extensions << EXTCONF.relative_path_from( BASEDIR ).to_s
	end

	gem.files             = RELEASE_FILES
	gem.test_files        = SPEC_FILES

	DEPENDENCIES.each do |name, version|
		version = '>= 0' if version.length.zero?
		gem.add_runtime_dependency( name, version )
	end

	# Developmental dependencies don't work as of RubyGems 1.2.0
	unless Gem::Version.new( Gem::RubyGemsVersion ) <= Gem::Version.new( "1.2.0" )
		DEVELOPMENT_DEPENDENCIES.each do |name, version|
			version = '>= 0' if version.length.zero?
			gem.add_development_dependency( name, version )
		end
	end

	REQUIREMENTS.each do |name, version|
		gem.requirements << [ name, version ].compact.join(' ')
	end
end

$trace = Rake.application.options.trace ? true : false
$dryrun = Rake.application.options.dryrun ? true : false


# Load any remaining task libraries
RAKE_TASKLIBS.each do |tasklib|
	next if tasklib.to_s =~ %r{/helpers\.rb$}
	begin
		trace "  loading tasklib %s" % [ tasklib ]
		import tasklib
	rescue ScriptError => err
		fail "Task library '%s' failed to load: %s: %s" %
			[ tasklib, err.class.name, err.message ]
		trace "Backtrace: \n  " + err.backtrace.join( "\n  " )
	rescue => err
		log "Task library '%s' failed to load: %s: %s. Some tasks may not be available." %
			[ tasklib, err.class.name, err.message ]
		trace "Backtrace: \n  " + err.backtrace.join( "\n  " )
	end
end

# Load any project-specific rules defined in 'Rakefile.local' if it exists
import LOCAL_RAKEFILE if LOCAL_RAKEFILE.exist?


#####################################################################
###	T A S K S 	
#####################################################################

### Default task
task :default  => [:clean, :local, :spec, :rdoc, :package]

### Task the local Rakefile can append to -- no-op by default
task :local


### Task: clean
CLEAN.include 'coverage'
CLOBBER.include 'artifacts', 'coverage.info', PKGDIR

### Task: changelog
file 'ChangeLog' do |task|
	log "Updating #{task.name}"

	changelog = make_changelog()
	File.open( task.name, 'w' ) do |fh|
		fh.print( changelog )
	end
end


### Task: cruise (Cruisecontrol task)
desc "Cruisecontrol build"
task :cruise => [:clean, 'spec:quiet', :package] do |task|
	raise "Artifacts dir not set." if ARTIFACTS_DIR.to_s.empty?
	artifact_dir = ARTIFACTS_DIR.cleanpath + (CC_BUILD_LABEL || Time.now.strftime('%Y%m%d-%T'))
	artifact_dir.mkpath

	coverage = BASEDIR + 'coverage'
	if coverage.exist? && coverage.directory?
		$stderr.puts "Copying coverage stats..."
		FileUtils.cp_r( 'coverage', artifact_dir )
	end

	$stderr.puts "Copying packages..."
	FileUtils.cp_r( FileList['pkg/*'].to_a, artifact_dir )
end


desc "Update the build system to the latest version"
task :update_build do
	log "Updating the build system"
	run 'hg', '-R', RAKE_TASKDIR, 'pull', '-u'
	log "Updating the Rakefile"
	sh 'rake', '-f', RAKE_TASKDIR + 'Metarakefile'
end

