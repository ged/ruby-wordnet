#!/usr/bin/env rake

require 'hoe'

Hoe.plugin :hg
Hoe.plugin :yard
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec( 'wordnet' ) do
	self.name = 'wordnet'
	self.readme_file = 'README.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.extra_deps <<
		['sequel', '~> 3.18.0']
	self.extra_dev_deps <<
		['rspec', '~> 2.2.0']

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

# :TODO: Tasks for packaging up the database gem.

