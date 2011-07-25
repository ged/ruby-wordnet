#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/mixins'
require 'wordnet/model'

# WordNet word model class
class WordNet::Word < WordNet::Model( :words )
	include WordNet::Constants

	set_primary_key :wordid

	#                 Table "public.words"
	#  Column |         Type          |     Modifiers      
	# --------+-----------------------+--------------------
	#  wordid | integer               | not null default 0
	#  lemma  | character varying(80) | not null
	# Indexes:
	#     "pk_words" PRIMARY KEY, btree (wordid)
	#     "unq_words_lemma" UNIQUE, btree (lemma)
	# Referenced by:
	#     TABLE "adjpositions" CONSTRAINT "fk_adjpositions_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "bncconvtasks" CONSTRAINT "fk_bncconvtasks_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "bncimaginfs" CONSTRAINT "fk_bncimaginfs_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "bncs" CONSTRAINT "fk_bncs_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "bncspwrs" CONSTRAINT "fk_bncspwrs_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "casedwords" CONSTRAINT "fk_casedwords_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "lexlinks" CONSTRAINT "fk_lexlinks_word1id" 
	# 		FOREIGN KEY (word1id) REFERENCES words(wordid)
	#     TABLE "lexlinks" CONSTRAINT "fk_lexlinks_word2id" 
	# 		FOREIGN KEY (word2id) REFERENCES words(wordid)
	#     TABLE "morphmaps" CONSTRAINT "fk_morphmaps_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "sensemaps2021" CONSTRAINT "fk_sensemaps2021_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "sensemaps2130" CONSTRAINT "fk_sensemaps2130_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "senses20" CONSTRAINT "fk_senses20_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "senses21" CONSTRAINT "fk_senses21_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "senses" CONSTRAINT "fk_senses_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "vframemaps" CONSTRAINT "fk_vframemaps_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "vframesentencemaps" CONSTRAINT "fk_vframesentencemaps_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "vnclassmembers" CONSTRAINT "fk_vnclassmembers_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "vnframemaps" CONSTRAINT "fk_vnframemaps_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)
	#     TABLE "vnrolemaps" CONSTRAINT "fk_vnrolemaps_wordid" 
	# 		FOREIGN KEY (wordid) REFERENCES words(wordid)


	##
	# The WordNet::Sense objects that relate the word with its Synsets
	one_to_many :senses,
		:key => :wordid,
		:primary_key => :wordid

	##
	# The WordNet::Synsets related to the word via its senses
	many_to_many :synsets,
		:join_table => :senses,
		:left_key => :wordid,
		:right_key => :synsetid

	##
	# The WordNet::Morphs related to the word
	many_to_many :morphs,
		:join_table => :morphmaps,
		:left_key => :wordid,
		:right_key => :morphid


	### Return the stringified word; alias for #lemma.
	def to_s
		return self.lemma
	end

end # class WordNet::Word

