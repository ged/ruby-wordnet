#!/usr/bin/ruby

require 'pathname'
require 'singleton'
require 'sequel'

require 'wordnet'
require 'wordnet/mixins'


# WordNet lexicon class - abstracts access to the WordNet lexical
# database, and provides factory methods for looking up words and synsets.
class WordNet::Lexicon
	include Singleton,
	        WordNet::Constants,
	        WordNet::Loggable


	#############################################################
	### I N S T A N C E	  M E T H O D S
	#############################################################

	### Create a new WordNet::Lexicon object that will read its data from
	### the given +database+.
	def initialize( uri=DEFAULTDB_URI )
		@uri = uri
		@db = Sequel.connect( self.uri, :logger => [WordNet.logger] )
		WordNet::Model.db = @db
	end


	######
	public
	######

	# The database URI the lexicon will use to look up WordNet data
	attr_reader :uri

	# The Sequel::Database object that model tables read from
	attr_reader :db


	### Find a word in the WordNet database and return it.
	### @param [String, #to_s] word  the word to look up
	### @return [WordNet::Word, nil] the word object if it was found, nil if it wasn't.
	def find_word( word )
		return WordNet::Word.filter( :lemma => word ).first
	end

end # class WordNet::Lexicon

__END__

	### Returns an integer of the familiarity/polysemy count for +word+ as a
	### +part_of_speech+. Note that polysemy can be identified for a given
	### word by counting the synsets returned by #lookup_synsets.
	def familiarity( word, part_of_speech )
		wordkey = self.make_word_key( word, part_of_speech )
		return nil unless @index_db.key?( wordkey )
		@index_db[ wordkey ].split( WordNet::SUB_DELIM_RE ).length
	end


	### Look up synsets (Wordnet::Synset objects) matching +text+ as a
	### +part_of_speech+, where +part_of_speech+ is one of +WordNet::Noun+,
	### +WordNet::Verb+, +WordNet::Adjective+, or +WordNet::Adverb+. Without
	### +sense+, #lookup_synsets will return all matches that are a
	### +part_of_speech+. If +sense+ is specified, only the synset object that
	### matches that particular +part_of_speech+ and +sense+ is returned.
	def lookup_synsets( word, part_of_speech, sense=nil )
		wordkey = self.make_word_key( word, part_of_speech )
		pos = self.make_pos( part_of_speech )
		synsets = []

		# Look up the index entry, trying first the word as given, and if
		# that fails, trying morphological conversion.
		entry = @index_db[ wordkey ]

		if entry.nil? && (word = self.morph( word, part_of_speech ))
			wordkey = self.make_word_key( word, part_of_speech )
			entry = @index_db[ wordkey ]
		end

		# If the lookup failed both ways, just abort
		return nil unless entry

		# Make synset keys from the entry, narrowing it to just the sense
		# requested if one was specified.
		synkeys = entry.split( SUB_DELIM_RE ).collect {|off| "#{off}%#{pos}" }
		if sense
			return lookup_synsets_by_key( synkeys[sense - 1] )
		else
			return [ lookup_synsets_by_key(*synkeys) ].flatten
		end
	end


	### Returns the WordNet::Synset objects corresponding to the +keys+
	### specified. The +keys+ are made up of the target synset's "offset"
	### and syntactic category catenated together with a '%' character.
	def lookup_synsets_by_key( *keys )
		synsets = []

		keys.each {|key|
			raise WordNet::LookupError, "Failed lookup of synset '#{key}':"\
				"No such synset" unless @data_db.key?( key )

			data = @data_db[ key ]
			offset, part_of_speech = key.split( /%/, 2 )
			synsets << WordNet::Synset.new( self, offset, part_of_speech, nil, data )
		}

		return *synsets
	end
	alias_method :lookup_synsetsByOffset, :lookup_synsets_by_key


	### Returns a form of +word+ as a part of speech +part_of_speech+, as
	### found in the WordNet morph files. The #lookup_synsets method perfoms
	### morphological conversion automatically, so a call to #morph is not
	### required.
	def morph( word, part_of_speech )
		return @morph_db[ self.make_word_key(word, part_of_speech) ]
	end


	### Returns the result of looking up +word+ in the inverse of the WordNet
	### morph files. _(This is undocumented in Lingua::Wordnet)_
	def reverse_morph( word )
		@morph_db.invert[ word ]
	end


	### Returns an array of compound words matching +text+.
	def grep( text )
		return [] if text.empty?

		words = []

		# Grab a cursor into the database and fetch while the key matches
		# the target text
		cursor = @index_db.cursor
		rec = cursor.set_range( text )
		while /^#{text}/ =~ rec[0]
			words.push rec[0]
			rec = cursor.next
		end
		cursor.close

		return *words
	end


	### Factory method: Creates and returns a new WordNet::Synset object in
	### this lexicon for the specified +word+ and +part_of_speech+.
	def create_synset( word, part_of_speech )
		return WordNet::Synset.new( self, '', part_of_speech, word )
	end
	alias_method :new_synset, :create_synset


	### Store the specified +synset+ (a WordNet::Synset object) in the
	### lexicon. Returns the key of the stored synset.
	def store_synset( synset )
		strippedOffset = nil
		pos = nil

		# Start a transaction
		@env.begin( BDB::TXN_COMMIT, @data_db ) do |txn,datadb|

			# If this is a new synset, generate an offset for it
			if synset.offset == 1
				synset.offset =
					(datadb['offsetcount'] = datadb['offsetcount'].to_i + 1)
			end

			# Write the data entry
			datadb[ synset.key ] = synset.serialize

			# Write the index entries
			txn.begin( BDB::TXN_COMMIT, @index_db ) do |txn,indexdb|

				# Make word/part-of-speech pairs from the words in the synset
				synset.words.collect {|word| word + "%" + pos }.each {|word|

					# If the index already has this word, but not this
					# synset, add it
					if indexdb.key?( word )
						indexdb[ word ] << SUB_DELIM << synset.offset unless
							indexdb[ word ].include?( synset.offset )
					else
						indexdb[ word ] = synset.offset
					end
				}
			end # transaction on @index_db
		end # transaction on @dataDB

		return synset.offset
	end


	### Remove the specified +synset+ (a WordNet::Synset object) in the
	### lexicon. Returns the offset of the stored synset.
	def remove_synset( synset )
		# If it's not in the database (ie., doesn't have a real offset),
		# just return.
		return nil if synset.offset == 1

		# Start a transaction on the data table
		@env.begin( BDB::TXN_COMMIT, @data_db ) do |txn,datadb|

			# First remove the index entries for this synset by iterating
			# over each of its words
			txn.begin( BDB::TXN_COMMIT, @index_db ) do |txn,indexdb|
				synset.words.collect {|word| word + "%" + pos }.each {|word|

					# If the index contains an entry for this word, either
					# splice out the offset for the synset being deleted if
					# there are more than one, or just delete the whole
					# entry if it's the only one.
					if indexdb.key?( word )
						offsets = indexdb[ word ].
							split( SUB_DELIM_RE ).
							reject {|offset| offset == synset.offset}

						unless offsets.empty?
							index_db[ word ] = newoffsets.join( SUB_DELIM )
						else
							index_db.delete( word )
						end
					end
				}
			end

			# :TODO: Delete synset from pointers of related synsets

			# Delete the synset from the main db
			datadb.delete( synset.offset )
		end

		return true
	end


	#########
	protected
	#########

	### Normalize various ways of specifying a part of speech into the
	### WordNet part of speech indicator from the +original+ representation,
	### which may be the name (e.g., "noun"); +nil+, in which case it
	### defaults to the indicator for a noun; or the indicator character
	### itself, in which case it is returned unmodified.
	def make_pos( original )
		return WordNet::Noun if original.nil?
		osym = original.to_s.intern
		return WordNet::SYNTACTIC_CATEGORIES[ osym ] if
			WordNet::SYNTACTIC_CATEGORIES.key?( osym )
		return original if SYNTACTIC_SYMBOLS.key?( original )
		return nil
	end


	### Make a lexicon key out of the given +word+ and part of speech
	### (+pos+).
	def make_word_key( word, pos )
		pos = self.make_pos( pos )
		word = word.gsub( /\s+/, '_' )
		return "#{word}%#{pos}"
	end


	### Return a list of archival logfiles that can be removed
	### safely. (BerkeleyDB-specific).
	def archlogs
		return @env.log_archive( BDB::ARCH_ABS )
	end


	#######
	private
	#######

	### Turn the given +origmode+ into an octal file mode such as that
	### given to File.open.
	def normalize_mode( origmode )
		case origmode
		when :readonly
			0444 & ~File.umask
		when :readwrite, :writable
			0666 & ~File.umask
		when Fixnum
			origmode
		else
			raise ArgumentError, "unrecognized mode %p" % [origmode]
		end
	end

	### Output the given +msg+ to STDERR if $DEBUG is turned on.
	def debug_msg( *msg )
		return unless $DEBUG
		$deferr.puts msg
	end


end # class WordNet::Lexicon

