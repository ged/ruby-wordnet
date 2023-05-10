# -*- ruby -*-

require 'rake/deveiate'


Rake::DevEiate.setup( 'wordnet' ) do |project|
	project.publish_to = 'deveiate:/usr/local/www/public/code'
	project.required_ruby_version = '~> 3.0'
	project.rdoc_generator = :sixfish
	project.post_install_message = <<~END_MESSAGE
	If you don't already have a WordNet database installed somewhere,
	you'll need to either download and install one from:

	   http://wnsql.sourceforge.net/

	or just install the 'wordnet-defaultdb' gem, which will install
	the SQLite version for you.
	END_MESSAGE
end
