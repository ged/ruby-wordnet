# Ruby-WordNet

* http://deveiate.org/projects/Ruby-WordNet

## Description

This library is a Ruby interface to WordNet®. WordNet® is an online lexical
reference system whose design is inspired by current psycholinguistic theories
of human lexical memory. English nouns, verbs, adjectives and adverbs are
organized into synonym sets, each representing one underlying lexical
concept. Different relations link the synonym sets.

It uses WordNet-SQL, which is a conversion of the lexicon flatfiles into a
relational database format. You can either install the 'wordnet-defaultdb' gem,
which packges up the SQLite3 version of WordNet-SQL, or install your own and
point the lexicon at it by passing a Sequel URL to the constructor.

TO-DO: More details and better writing later.


## Requirements

* Ruby 1.8.7 or 1.9.2
* Sequel >= 3.19.0


## Authors

* Michael Granger <ged@FaerieMUD.org>


## License

Copyright (c) 2010-2011, The FaerieMUD Consortium
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
