# install.rb
#
# $Date: 2003/08/06 08:00:52 $
# Copyright (c) 2000, 2003 Masatoshi SEKI
#
# install.rb is copyrighted free software by Masatoshi SEKI.
# You can redistribute it and/or modify it under the same term as Ruby.

$LOAD_PATH.unshift "."

require 'rbconfig'
require 'find'
require 'ftools'
require 'utils'

include Config, UtilityFunctions

CheckDb = 'lib/wordnet/lexicon'

class Installer
	protected
	def install(from, to, mode = nil, verbose = false)
		str = "install '#{from}' to '#{to}'"
		str += ", mode=#{mode}" if mode
		puts str if verbose
	end

	protected
	def makedirs(*dirs)
		for d in dirs
			puts "mkdir #{d}"
		end
	end

	def initialize(test=false)
		@version = CONFIG["MAJOR"]+"."+CONFIG["MINOR"]
		@libdir = File.join(CONFIG["libdir"], "ruby", @version)
		@sitelib = find_site_libdir
		@ftools = (test) ? self : File
	end
	public
	attr_reader(:libdir, :sitelib)

	private
	def find_site_libdir
		site_libdir = $:.find {|x| x =~ /site_ruby$/}
		if !site_libdir
			site_libdir = File.join(@libdir, "site_ruby")
		elsif site_libdir !~ Regexp.quote(@version)
			site_libdir = File.join(site_libdir, @version)
		end
		site_libdir
	end

	public
	def files_in_dir(dir)
		list = []
		Find.find(dir) do |f|
			list.push(f)
		end
		list
	end

	public
	def install_files(srcdir, files, destdir=@sitelib)
		path = []
		dir = []

		for f in files
			next if (f = f[srcdir.length+1..-1]) == nil
			path.push f if File.ftype(File.join(srcdir, f)) == 'file'
			dir |= [ File.dirname(File.join(destdir, f)) ]
		end
		@ftools.makedirs(*dir)
		for f in path
			@ftools.install(File.join(srcdir, f), File.join(destdir, f), nil, true)
		end
	end

	public
	def install_rb
		install_files('lib', files_in_dir('lib'))
	end
end

inst = Installer.new( ARGV.shift == '-n' )
inst.install_rb

