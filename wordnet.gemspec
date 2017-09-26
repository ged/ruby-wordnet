# -*- encoding: utf-8 -*-
# stub: wordnet 1.1.0.pre20170926144654 ruby lib

Gem::Specification.new do |s|
  s.name = "wordnet".freeze
  s.version = "1.1.0.pre20170926144654"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.cert_chain = ["certs/ged.pem".freeze]
  s.date = "2017-09-26"
  s.description = "This library is a Ruby interface to WordNet\u00AE[http://wordnet.princeton.edu/].\nWordNet\u00AE is an online lexical reference system whose design is inspired\nby current psycholinguistic theories of human lexical memory. English\nnouns, verbs, adjectives and adverbs are organized into synonym sets, each\nrepresenting one underlying lexical concept. Different relations link\nthe synonym sets.\n\nThis library uses WordNet-SQL[http://wnsql.sourceforge.net/], which is a\nconversion of the lexicon flatfiles into a relational database format. You\ncan either install the 'wordnet-defaultdb' gem, which packages up the\nSQLite3 version of WordNet-SQL, or install your own and point the lexicon\nat it by passing \n{Sequel connection parameters}[http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html]\nto the constructor.".freeze
  s.email = ["ged@FaerieMUD.org".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.md".freeze, "README.rdoc".freeze, "WordNet30-license.txt".freeze, "History.rdoc".freeze, "README.rdoc".freeze]
  s.files = [".gems".freeze, ".ruby-gemset".freeze, ".ruby-version".freeze, ".simplecov".freeze, "ChangeLog".freeze, "Gemfile".freeze, "History.rdoc".freeze, "LICENSE".freeze, "Manifest.txt".freeze, "README.md".freeze, "README.rdoc".freeze, "Rakefile".freeze, "TODO".freeze, "WordNet30-license.txt".freeze, "certs/ged.pem".freeze, "examples/gcs.rb".freeze, "examples/hypernym_tree.rb".freeze, "lib/wordnet.rb".freeze, "lib/wordnet/constants.rb".freeze, "lib/wordnet/lexicallink.rb".freeze, "lib/wordnet/lexicon.rb".freeze, "lib/wordnet/model.rb".freeze, "lib/wordnet/morph.rb".freeze, "lib/wordnet/semanticlink.rb".freeze, "lib/wordnet/sense.rb".freeze, "lib/wordnet/sumoterm.rb".freeze, "lib/wordnet/synset.rb".freeze, "lib/wordnet/word.rb".freeze, "spec/helpers.rb".freeze, "spec/wordnet/lexicon_spec.rb".freeze, "spec/wordnet/model_spec.rb".freeze, "spec/wordnet/semanticlink_spec.rb".freeze, "spec/wordnet/sense_spec.rb".freeze, "spec/wordnet/synset_spec.rb".freeze, "spec/wordnet/word_spec.rb".freeze, "spec/wordnet_spec.rb".freeze, "wordnet.gemspec".freeze]
  s.homepage = "http://deveiate.org/projects/Ruby-WordNet".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.post_install_message = "\nIf you don't already have a WordNet database installed somewhere,\nyou'll need to either download and install one from:\n\n   http://wnsql.sourceforge.net/\n\nor just install the 'wordnet-defaultdb' gem, which will install\nthe SQLite version for you.\n\n".freeze
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "2.6.13".freeze
  s.summary = "This library is a Ruby interface to WordNet\u00AE[http://wordnet.princeton.edu/]".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel>.freeze, ["~> 5.0"])
      s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.11"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.12"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.16"])
    else
      s.add_dependency(%q<sequel>.freeze, ["~> 5.0"])
      s.add_dependency(%q<loggability>.freeze, ["~> 0.11"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<sequel>.freeze, ["~> 5.0"])
    s.add_dependency(%q<loggability>.freeze, ["~> 0.11"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
  end
end
