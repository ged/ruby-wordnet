# -*- ruby -*-

puts ">>> Adding 'lib' to library path."
$: << "lib"
puts ">>> Requiring 'WordNet'."
begin
	require "WordNet"
rescue => e
	puts "   Error: While requiring 'WordNet': #{e.message}"
end



