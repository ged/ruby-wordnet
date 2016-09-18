# -*- encoding: utf-8 -*-
# stub: wordnet 1.1.0.pre20160918161825 ruby lib

Gem::Specification.new do |s|
  s.name = "wordnet"
  s.version = "1.1.0.pre20160918161825"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger"]
  s.cert_chain = ["certs/ged.pem"]
  s.date = "2016-09-18"
  s.description = "This library is a Ruby interface to WordNet\u{ae}[http://wordnet.princeton.edu/].\nWordNet\u{ae} is an online lexical reference system whose design is inspired\nby current psycholinguistic theories of human lexical memory. English\nnouns, verbs, adjectives and adverbs are organized into synonym sets, each\nrepresenting one underlying lexical concept. Different relations link\nthe synonym sets.\n\nThis library uses WordNet-SQL[http://wnsql.sourceforge.net/], which is a\nconversion of the lexicon flatfiles into a relational database format. You\ncan either install the 'wordnet-defaultdb' gem, which packages up the\nSQLite3 version of WordNet-SQL, or install your own and point the lexicon\nat it by passing \n{Sequel connection parameters}[http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html]\nto the constructor."
  s.email = ["ged@FaerieMUD.org"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "WordNet30-license.txt", "History.rdoc", "README.rdoc"]
  s.files = [".simplecov", "ChangeLog", "History.rdoc", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "TODO", "WordNet30-license.txt", "examples/gcs.rb", "examples/hypernym_tree.rb", "lib/wordnet.rb", "lib/wordnet/constants.rb", "lib/wordnet/lexicallink.rb", "lib/wordnet/lexicon.rb", "lib/wordnet/model.rb", "lib/wordnet/morph.rb", "lib/wordnet/semanticlink.rb", "lib/wordnet/sense.rb", "lib/wordnet/sumoterm.rb", "lib/wordnet/synset.rb", "lib/wordnet/word.rb", "spec/helpers.rb", "spec/wordnet/lexicon_spec.rb", "spec/wordnet/model_spec.rb", "spec/wordnet/semanticlink_spec.rb", "spec/wordnet/synset_spec.rb", "spec/wordnet/word_spec.rb", "spec/wordnet_spec.rb"]
  s.homepage = "http://deveiate.org/projects/Ruby-WordNet"
  s.licenses = ["BSD-3-Clause"]
  s.post_install_message = "\nIf you don't already have a WordNet database installed somewhere,\nyou'll need to either download and install one from:\n\n   http://wnsql.sourceforge.net/\n\nor just install the 'wordnet-defaultdb' gem, which will install\nthe SQLite version for you.\n\n"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0")
  s.rubygems_version = "2.5.1"
  s.summary = "This library is a Ruby interface to WordNet\u{ae}[http://wordnet.princeton.edu/]"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel>, ["~> 4.38"])
      s.add_runtime_dependency(%q<loggability>, ["~> 0.11"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.8"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1.3"])
      s.add_development_dependency(%q<rspec>, ["~> 3.5"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.12"])
      s.add_development_dependency(%q<hoe>, ["~> 3.15"])
    else
      s.add_dependency(%q<sequel>, ["~> 4.38"])
      s.add_dependency(%q<loggability>, ["~> 0.11"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.8"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3"])
      s.add_dependency(%q<rspec>, ["~> 3.5"])
      s.add_dependency(%q<simplecov>, ["~> 0.12"])
      s.add_dependency(%q<hoe>, ["~> 3.15"])
    end
  else
    s.add_dependency(%q<sequel>, ["~> 4.38"])
    s.add_dependency(%q<loggability>, ["~> 0.11"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.8"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3"])
    s.add_dependency(%q<rspec>, ["~> 3.5"])
    s.add_dependency(%q<simplecov>, ["~> 0.12"])
    s.add_dependency(%q<hoe>, ["~> 3.15"])
  end
end
