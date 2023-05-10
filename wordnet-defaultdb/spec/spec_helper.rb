#!/usr/bin/env rspec

BEGIN {
	require 'pathname'
	$LOAD_PATH << Pathname( __FILE__ ).dirname.parent + 'lib'
}

require 'rspec'
require 'wordnet/defaultdb'


RSpec.configure do |config|
	config.expect_with :rspec do |expectations|
		expectations.include_chain_clauses_in_custom_matcher_descriptions = true
	end

	config.mock_with :rspec do |mocks|
		mocks.verify_partial_doubles = true
	end

	config.disable_monkey_patching!
	config.example_status_persistence_file_path = "spec/.state"
	config.filter_run :focus
	config.filter_run_when_matching :focus
	config.order = :random
	config.profile_examples = 5
	config.run_all_when_everything_filtered = true
	config.shared_context_metadata_behavior = :apply_to_host_groups
	config.warnings = true

	Kernel.srand( config.seed )
end

