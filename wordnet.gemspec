# -*- encoding: utf-8 -*-
# stub: wordnet 1.3.0.pre.20230510160526 ruby lib

Gem::Specification.new do |s|
  s.name = "wordnet".freeze
  s.version = "1.3.0.pre.20230510160526"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://todo.sr.ht/~ged/ruby-wordnet/browse", "changelog_uri" => "http://deveiate.org/code/wordnet/History_md.html", "documentation_uri" => "http://deveiate.org/code/wordnet", "homepage_uri" => "https://hg.sr.ht/~ged/ruby-wordnet", "source_uri" => "https://hg.sr.ht/~ged/ruby-wordnet/browse" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2023-05-10"
  s.description = "This library is a Ruby interface to WordNet\u00AE. WordNet\u00AE is an online lexical reference system whose design is inspired by current psycholinguistic theories of human lexical memory. English nouns, verbs, adjectives and adverbs are organized into synonym sets, each representing one underlying lexical concept. Different relations link the synonym sets.".freeze
  s.email = ["ged@FaerieMUD.org".freeze]
  s.files = ["History.md".freeze, "README.md".freeze, "WordNet30-license.txt".freeze, "lib/wordnet.rb".freeze, "lib/wordnet/constants.rb".freeze, "lib/wordnet/lexicallink.rb".freeze, "lib/wordnet/lexicon.rb".freeze, "lib/wordnet/model.rb".freeze, "lib/wordnet/morph.rb".freeze, "lib/wordnet/semanticlink.rb".freeze, "lib/wordnet/sense.rb".freeze, "lib/wordnet/sumoterm.rb".freeze, "lib/wordnet/synset.rb".freeze, "lib/wordnet/word.rb".freeze, "spec/helpers.rb".freeze, "spec/wordnet/lexicon_spec.rb".freeze, "spec/wordnet/model_spec.rb".freeze, "spec/wordnet/semanticlink_spec.rb".freeze, "spec/wordnet/sense_spec.rb".freeze, "spec/wordnet/synset_spec.rb".freeze, "spec/wordnet/word_spec.rb".freeze, "spec/wordnet_spec.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/ruby-wordnet".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.post_install_message = "If you don't already have a WordNet database installed somewhere,\nyou'll need to either download and install one from:\n\n   http://wnsql.sourceforge.net/\n\nor just install the 'wordnet-defaultdb' gem, which will install\nthe SQLite version for you.\n".freeze
  s.required_ruby_version = Gem::Requirement.new("~> 3.0".freeze)
  s.rubygems_version = "3.4.12".freeze
  s.summary = "This library is a Ruby interface to WordNet\u00AE.".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.18"])
  s.add_runtime_dependency(%q<pg>.freeze, ["~> 1.4"])
  s.add_runtime_dependency(%q<sequel>.freeze, ["~> 5.64"])
  s.add_runtime_dependency(%q<sqlite3>.freeze, ["~> 1.5"])
  s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.22"])
  s.add_development_dependency(%q<rdoc-generator-sixfish>.freeze, ["~> 0.3"])
end
