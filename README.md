# Ruby-WordNet

home
: https://hg.sr.ht/~ged/ruby-wordnet

code
: https://hg.sr.ht/~ged/ruby-wordnet/browse

docs
: http://deveiate.org/code/wordnet

github
: https://github.com/ged/ruby-wordnet


## Description

This library is a Ruby interface to WordNet®[https://wordnet.princeton.edu/].
WordNet® is an online lexical reference system whose design is inspired by
current psycholinguistic theories of human lexical memory. English nouns,
verbs, adjectives and adverbs are organized into synonym sets, each
representing one underlying lexical concept. Different relations link the
synonym sets.

This library uses SqlUNET[http://sqlunet.sourceforge.net/], which is a
conversion of the WordNet (along with a number of other linguistic databases)
lexicon flatfiles into a relational database format. You can either install the
[wordnet-defaultdb](https://rubygems.org/gems/wordnet-defaultdb) gem, which
packages up the SQLite3 version of SqlUNet, or install your own and point the
lexicon at it by passing [Sequel connection
parameters](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)
to the constructor.

## Usage

There are three major parts to this library:

WordNet::Lexicon
: the interface to the dictionary, used to connect to the
database and look up Words and Synsets.

WordNet::Word
: the English word entries in the Lexicon that are mapped
to Synsets via one or more Senses.

WordNet::Synset
: the main artifact of WordNet: a "synonym set". These
: are connected to one or more Words through a Sense,
and are connected to each other via SemanticLinks.

The other object classes exist mostly as a way of representing relationships
between the main three:

WordNet::Sense
: represents a link between one or more Words and
one or more Synsets for one meaning of the word.

WordNet::SemanticLink
: represents a link between Synsets

WordNet::LexicalLink
: represents a link between Words in Synsets

WordNet::Morph
: an interface to a lookup table of irregular word
forms mapped to their base form (lemma)


The last class (WordNet::Model) is the abstract superclass for all the others,
and inherits most of its functionality from Sequel::Model, the ORM layer
of the Sequel toolkit. It's mostly just a container for the database
connection, with some convenience methods to allow the database connection
to be deferred until runtime instead of when the library loads.

The library also comes with the beginnings of support for the SUMO-WordNet
mapping:

WordNet::SumoTerm
: [Suggested Upper Merged Ontology](http://www.ontologyportal.org/) terms,
with associations back to related Synsets.

As mentioned above, SqlUNet has done an amazing job of linking up a number of
other useful linguistic lexicons via WordNet synsets. I plan on adding support
for at minimum VerbNet, FrameNet, and PropBank.


## Requirements

* Ruby >= 3.0
* Sequel >= 5.0


## Contributing

You can check out the current development source with Mercurial via its
[project page](https://hg.sr.ht/~ged/ruby-wordnet). Or if you prefer
Git, via [its Github mirror](https://github.com/ged/ruby-wordnet).

After checking out the source, run:

    $ gem install -Ng
    $ rake setup

This will do any necessary development environment set up.


## Authors

* Michael Granger <ged@FaerieMUD.org>


## License

Copyright (c) 2002-2023, Michael Granger
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
