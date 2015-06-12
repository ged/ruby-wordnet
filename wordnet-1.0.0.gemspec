# -*- encoding: utf-8 -*-
# stub: wordnet 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wordnet"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger"]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDLDCCAhSgAwIBAgIBADANBgkqhkiG9w0BAQUFADA8MQwwCgYDVQQDDANnZWQx\nFzAVBgoJkiaJk/IsZAEZFgdfYWVyaWVfMRMwEQYKCZImiZPyLGQBGRYDb3JnMB4X\nDTEwMDkxNjE0NDg1MVoXDTExMDkxNjE0NDg1MVowPDEMMAoGA1UEAwwDZ2VkMRcw\nFQYKCZImiZPyLGQBGRYHX2FlcmllXzETMBEGCgmSJomT8ixkARkWA29yZzCCASIw\nDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALy//BFxC1f/cPSnwtJBWoFiFrir\nh7RicI+joq/ocVXQqI4TDWPyF/8tqkvt+rD99X9qs2YeR8CU/YiIpLWrQOYST70J\nvDn7Uvhb2muFVqq6+vobeTkILBEO6pionWDG8jSbo3qKm1RjKJDwg9p4wNKhPuu8\nKGue/BFb67KflqyApPmPeb3Vdd9clspzqeFqp7cUBMEpFS6LWxy4Gk+qvFFJBJLB\nBUHE/LZVJMVzfpC5Uq+QmY7B+FH/QqNndn3tOHgsPadLTNimuB1sCuL1a4z3Pepd\nTeLBEFmEao5Dk3K/Q8o8vlbIB/jBDTUx6Djbgxw77909x6gI9doU4LD5XMcCAwEA\nAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFJeoGkOr9l4B\n+saMkW/ZXT4UeSvVMA0GCSqGSIb3DQEBBQUAA4IBAQBG2KObvYI2eHyyBUJSJ3jN\nvEnU3d60znAXbrSd2qb3r1lY1EPDD3bcy0MggCfGdg3Xu54z21oqyIdk8uGtWBPL\nHIa9EgfFGSUEgvcIvaYqiN4jTUtidfEFw+Ltjs8AP9gWgSIYS6Gr38V0WGFFNzIH\naOD2wmu9oo/RffW4hS/8GuvfMzcw7CQ355wFR4KB/nyze+EsZ1Y5DerCAagMVuDQ\nU0BLmWDFzPGGWlPeQCrYHCr+AcJz+NRnaHCKLZdSKj/RHuTOt+gblRex8FAh8NeA\ncmlhXe46pZNJgWKbxZah85jIjx95hR8vOI+NAM5iH9kOqK13DrxacTKPhqj5PjwF\n-----END CERTIFICATE-----\n"]
  s.date = "2012-10-01"
  s.description = "This library is a Ruby interface to WordNet\u{ae}[http://wordnet.princeton.edu/].\nWordNet\u{ae} is an online lexical reference system whose design is inspired\nby current psycholinguistic theories of human lexical memory. English\nnouns, verbs, adjectives and adverbs are organized into synonym sets, each\nrepresenting one underlying lexical concept. Different relations link\nthe synonym sets.\n\nThis library uses WordNet-SQL[http://wnsql.sourceforge.net/], which is a\nconversion of the lexicon flatfiles into a relational database format. You\ncan either install the 'wordnet-defaultdb' gem, which packages up the\nSQLite3 version of WordNet-SQL, or install your own and point the lexicon\nat it by passing \n{Sequel connection parameters}[http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html]\nto the constructor."
  s.email = ["ged@FaerieMUD.org"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "WordNet30-license.txt"]
  s.files = ["History.rdoc", "Manifest.txt", "README.rdoc", "WordNet30-license.txt"]
  s.homepage = "http://deveiate.org/projects/Ruby-WordNet"
  s.licenses = ["BSD"]
  s.post_install_message = "\nIf you don't already have a WordNet database installed somewhere,\nyou'll need to either download and install one from:\n\n   http://wnsql.sourceforge.net/\n\nor just install the 'wordnet-defaultdb' gem, which will install\nthe SQLite version for you.\n\n"
  s.rdoc_options = ["-f", "fivefish", "-t", "Ruby WordNet"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.rubyforge_project = "wordnet"
  s.rubygems_version = "2.4.7"
  s.summary = "This library is a Ruby interface to WordNet\u{ae}[http://wordnet.princeton.edu/]"

  s.installed_by_version = "2.4.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sequel>, ["~> 4"])
      s.add_runtime_dependency(%q<loggability>, ["~> 0.5"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4.0"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.1.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.7"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.6"])
      s.add_development_dependency(%q<hoe>, ["~> 3.0"])
    else
      s.add_dependency(%q<sequel>, ["~> 3.38"])
      s.add_dependency(%q<loggability>, ["~> 0.5"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4.0"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.1.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3"])
      s.add_dependency(%q<rspec>, ["~> 2.7"])
      s.add_dependency(%q<simplecov>, ["~> 0.6"])
      s.add_dependency(%q<hoe>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<sequel>, ["~> 3.38"])
    s.add_dependency(%q<loggability>, ["~> 0.5"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4.0"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.1.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3"])
    s.add_dependency(%q<rspec>, ["~> 2.7"])
    s.add_dependency(%q<simplecov>, ["~> 0.6"])
    s.add_dependency(%q<hoe>, ["~> 3.0"])
  end
end
