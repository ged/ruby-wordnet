#!/usr/bin/env rake

require 'hoe'

Hoe.plugin :mercurial
Hoe.plugin :yard
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec( 'wordnet' ) do
	self.name = 'wordnet'
	self.readme_file = 'README.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.extra_deps.push *{
		'sequel'       => '~> 3.18.0',
		'sqlite3-ruby' => '~> 1.3.2',
	}
	self.extra_dev_deps.push *{
		'rspec' => '~> 2.2.0',
	}

	self.spec_extras[:licenses] = ["BSD"]
	self.spec_extras[:post_install_message] = %{
	If you don't already have a WordNet database installed somewhere, 
	you'll need to either download and install one from:

	   http://wnsql.sourceforge.net/

	or just install the 'wordnet-defaultdb' gem, which will install
	the SQLite version for you.

	}.gsub( /^\t/, '' )

	self.require_ruby_version( '>=1.8.7' )

	self.yard_title = 'WordNet for Ruby'
	self.yard_opts = [ '--use-cache', '--protected', '--verbose' ]

	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags )
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

begin
	include Hoe::MercurialHelpers

	### Task: prerelease
	desc "Append the package build number to package versions"
	task :pre do
		rev = get_numeric_rev()
		trace "Current rev is: %p" % [ rev ]
		hoespec.spec.version.version << "pre#{rev}"
		Rake::Task[:gem].clear

		Gem::PackageTask.new( hoespec.spec ) do |pkg|
			pkg.need_zip = true
			pkg.need_tar = true
		end
	end

	### Make the ChangeLog update if the repo has changed since it was last built
	file '.hg/branch'
	file 'ChangeLog' => '.hg/branch' do |task|
		$stderr.puts "Updating the changelog..."
		content = make_changelog()
		File.open( task.name, 'w', 0644 ) do |fh|
			fh.print( content )
		end
	end

	# Rebuild the ChangeLog immediately before release
	task :prerelease => 'ChangeLog'

rescue NameError => err
	task :no_hg_helpers do
		fail "Couldn't define the :pre task: %s: %s" % [ err.class.name, err.message ]
	end

	task :pre => :no_hg_helpers
	task 'ChangeLog' => :no_hg_helpers

end


# :TODO: Tasks for packaging up the database gem.

