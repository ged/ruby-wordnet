#!/usr/bin/env rake

require 'pathname'

begin
	require 'hoe'
rescue LoadError => err
	$stderr.puts "Couldn't load hoe: %p: %s" % [ err.class, err.message ] if
		Rake.application.options.trace
	abort "This Rakefile requires hoe (gem install hoe)"
end

Hoe.plugin :mercurial
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

BASEDIR = Pathname( __FILE__ ).dirname
LIBDIR = BASEDIR + 'lib'
DATADIR = BASEDIR + 'data'

hoespec = Hoe.spec( 'wordnet' ) do
	self.name = 'wordnet'
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = FileList[ '*.rdoc' ]
	self.spec_extras[:rdoc_options] = ['-f', 'fivefish', '-t', 'Ruby WordNet']

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'sequel',      '~> 3.38'
	self.dependency 'loggability', '~> 0.5'
	self.dependency 'sqlite3',     '~> 1.3', :developer
	self.dependency 'rspec',       '~> 2.7', :developer
	self.dependency 'simplecov',   '~> 0.6', :developer

	self.spec_extras[:licenses] = ["BSD"]
	self.spec_extras[:post_install_message] = %{
	If you don't already have a WordNet database installed somewhere,
	you'll need to either download and install one from:

	   http://wnsql.sourceforge.net/

	or just install the 'wordnet-defaultdb' gem, which will install
	the SQLite version for you.

	}.gsub( /^\t/, '' )

	self.require_ruby_version( '>=1.9.2' )

	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

task 'hg:precheckin' => [ :check_history, :spec ]

### Make the ChangeLog update if the repo has changed since it was last built
file '.hg/branch'
file 'ChangeLog' => '.hg/branch' do |task|
	$stderr.puts "Updating the changelog..."
	begin
		content = make_changelog()
	rescue NoMethodError
		abort "This task requires hoe-mercurial (gem install hoe-mercurial)"
	end
	File.open( task.name, 'w', 0644 ) do |fh|
		fh.print( content )
	end
end

# Rebuild the ChangeLog immediately before release
task :prerelease => 'ChangeLog'

# Simplecov
desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end
