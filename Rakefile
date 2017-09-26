#!/usr/bin/env rake

require 'pathname'

begin
	require 'hoe'
rescue LoadError => err
	$stderr.puts "Couldn't load hoe: %p: %s" % [ err.class, err.message ] if
		Rake.application.options.trace
	abort "This Rakefile requires hoe (gem install hoe)"
end

GEMSPEC = 'wordnet.gemspec'

Hoe.plugin :mercurial
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

BASEDIR = Pathname( __FILE__ ).dirname
LIBDIR = BASEDIR + 'lib'
DATADIR = BASEDIR + 'data'

hoespec = Hoe.spec( 'wordnet' ) do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = FileList[ '*.rdoc' ]
	self.license 'BSD-3-Clause'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'sequel',               '~> 5.0'
	self.dependency 'loggability',          '~> 0.11'

	self.dependency 'sqlite3',              '~> 1.3', :developer
	self.dependency 'rspec',                '~> 3.5', :developer
	self.dependency 'simplecov',            '~> 0.12', :developer

	self.spec_extras[:post_install_message] = %{
	If you don't already have a WordNet database installed somewhere,
	you'll need to either download and install one from:

	   http://wnsql.sourceforge.net/

	or just install the 'wordnet-defaultdb' gem, which will install
	the SQLite version for you.

	}.gsub( /^\t/, '' )

	self.require_ruby_version( '>=2.2.0' )

	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/ruby-#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Run the tests before checking in
task 'hg:precheckin' => [ :check_history, :check_manifest, :gemspec, :spec ]

# Rebuild the ChangeLog immediately before release
task :prerelease => 'ChangeLog'
CLOBBER.include( 'ChangeLog' )

desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end


# Use the fivefish formatter for docs generated from development checkout
if File.directory?( '.hg' )
	require 'rdoc/task'

	Rake::Task[ 'docs' ].clear
	RDoc::Task.new( 'docs' ) do |rdoc|
	    rdoc.main = "README.rdoc"
	    rdoc.rdoc_files.include( "*.rdoc", "*.md", "ChangeLog", "lib/**/*.rb" )
	    rdoc.generator = :fivefish
		rdoc.title = 'Ruby WordNet'
	    rdoc.rdoc_dir = 'doc'
	end
end

task :gemspec => [ 'ChangeLog', GEMSPEC ]
file GEMSPEC => __FILE__ do |task|
	spec = $hoespec.spec
	spec.files.delete( '.gemtest' )
	spec.signing_key = nil
	spec.version = "#{spec.version.bump}.0.pre#{Time.now.strftime("%Y%m%d%H%M%S")}"
	spec.cert_chain = [ 'certs/ged.pem' ]
	File.open( task.name, 'w' ) do |fh|
		fh.write( spec.to_ruby )
	end
end
CLOBBER.include( GEMSPEC )

task :default => :gemspec

