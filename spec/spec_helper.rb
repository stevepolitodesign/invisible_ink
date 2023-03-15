# frozen_string_literal: true

require "invisible_ink"

module InvisibleInkHelpers
  def invoke_executable
    system("exe/invisible_ink")
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include InvisibleInkHelpers
end
