#!/usr/bin/ruby

require 'wordnet' unless defined?( WordNet )
require 'wordnet/model'
require 'wordnet/constants'


# Experimental support for the WordNet mapping for the {Suggested Upper Merged 
# Ontology}[http://www.ontologyportal.org/] (SUMO).
# This is still a work in progress, and isn't supported by all of the WordNet-SQL
# databases.
class WordNet::SumoTerm < WordNet::Model( :sumoterms )
	include WordNet::Constants

	#                       Table "public.sumoterms"
	#         Column         |          Type          |     Modifiers
	# -----------------------+------------------------+--------------------
	#  sumoid                | integer                | not null default 0
	#  sumoterm              | character varying(128) | not null
	#  ischildofattribute    | boolean                |
	#  ischildoffunction     | boolean                |
	#  ischildofpredicate    | boolean                |
	#  ischildofrelation     | boolean                |
	#  iscomparisonop        | boolean                |
	#  isfunction            | boolean                |
	#  isinstance            | boolean                |
	#  islogical             | boolean                |
	#  ismath                | boolean                |
	#  isquantifier          | boolean                |
	#  isrelationop          | boolean                |
	#  issubclass            | boolean                |
	#  issubclassofattribute | boolean                |
	#  issubclassoffunction  | boolean                |
	#  issubclassofpredicate | boolean                |
	#  issubclassofrelation  | boolean                |
	#  issubrelation         | boolean                |
	#  issuperclass          | boolean                |
	#  issuperrelation       | boolean                |
	# Indexes:
	#     "pk_sumoterms" PRIMARY KEY, btree (sumoid)
	#     "unq_sumoterms_sumoterm" UNIQUE, btree (sumoterm)
	# Referenced by:
	#     TABLE "sumomaps" CONSTRAINT "fk_sumomaps_sumoid" FOREIGN KEY (sumoid) REFERENCES sumoterms(sumoid)
	#     TABLE "sumoparsemaps" CONSTRAINT "fk_sumoparsemaps_sumoid" FOREIGN KEY (sumoid) REFERENCES sumoterms(sumoid)
	set_primary_key :sumoid


	#
	# Associations
	#

	# SUMO Term -> [ SUMO Map ] -> [ Synset ]

	#             Table "public.sumomaps"
	#   Column   |     Type     |     Modifiers
	# -----------+--------------+--------------------
	#  synsetid  | integer      | not null default 0
	#  sumoid    | integer      | not null default 0
	#  sumownrel | character(1) | not null
	# Indexes:
	#     "pk_sumomaps" PRIMARY KEY, btree (synsetid)
	#     "k_sumomaps_sumoid" btree (sumoid)
	#     "k_sumomaps_sumownrel" btree (sumownrel)
	# Foreign-key constraints:
	#     "fk_sumomaps_sumoid" FOREIGN KEY (sumoid) REFERENCES sumoterms(sumoid)
	#     "fk_sumomaps_synsetid" FOREIGN KEY (synsetid) REFERENCES synsets(synsetid)

	##
	# WordNet::Synsets that are related to this term
	many_to_many :synsets,
		:join_table => :sumomaps,
		:left_key   => :sumoid,
		:right_key  => :synsetid

end # class WordNet::SumoTerm

