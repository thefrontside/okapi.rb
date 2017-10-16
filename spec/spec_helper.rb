require "bundler/setup"
require "okapi"
require "vcr"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  original_env = ENV.to_h

  config.before(:each) do
    sandbox_home = Pathname(__FILE__).dirname.join('sandbox/home').to_s
    FileUtils.rm_rf sandbox_home
    FileUtils.mkdir_p sandbox_home
    ENV['HOME'] = sandbox_home
  end

  config.after(:each) do
    original_env.each_pair do |k, v|
      ENV[k] = v
    end
    ENV.each_pair do |k,v|
      unless original_env.has_key? k
        ENV.delete(k)
      end
    end
  end
end


VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :new_episodes }
end
