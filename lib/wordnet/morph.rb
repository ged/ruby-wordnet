#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/model'

# WordNet morph model class
class WordNet::Morph < WordNet::Model( :morphs )
	include WordNet::Constants

	#                 Table "public.morphs"
	#  Column  |         Type          |     Modifiers
	# ---------+-----------------------+--------------------
	#  morphid | integer               | not null default 0
	#  morph   | character varying(70) | not null
	# Indexes:
	#     "pk_morphs" PRIMARY KEY, btree (morphid)
	#     "unq_morphs_morph" UNIQUE, btree (morph)
	# Referenced by:
	#     TABLE "morphmaps" CONSTRAINT "fk_morphmaps_morphid" FOREIGN KEY (morphid) REFERENCES morphs(morphid)
	#

	set_primary_key :morphid

	#                 Table "public.morphmaps"
	#  Column  |     Type     |           Modifiers
	# ---------+--------------+-------------------------------
	#  wordid  | integer      | not null default 0
	#  pos     | character(1) | not null default NULL::bpchar
	#  morphid | integer      | not null default 0
	# Indexes:
	#     "pk_morphmaps" PRIMARY KEY, btree (morphid, pos, wordid)
	#     "k_morphmaps_morphid" btree (morphid)
	#     "k_morphmaps_wordid" btree (wordid)
	# Foreign-key constraints:
	#     "fk_morphmaps_morphid" FOREIGN KEY (morphid) REFERENCES morphs(morphid)
	#     "fk_morphmaps_wordid" FOREIGN KEY (wordid) REFERENCES words(wordid)
	many_to_many :words,
		:join_table => :morphmaps,
		:right_key  => :wordid,
		:left_key   => :morphid


	### Return the stringified word; alias for #lemma.
	def to_s
		return "%s (%s)" % [ self.morph, self.pos ]
	end

end # class WordNet::Morph

