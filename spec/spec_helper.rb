# frozen_string_literal: true

require "invisible_ink"
require "fileutils"

module InvisibleInkHelpers
  def invoke_executable(command, file: nil)
    system("exe/invisible_ink #{command} #{file}")
  end

  def invoke_write_command(file, content, editor:)
    switch_env("CONTENT", content) do
      switch_env("EDITOR", editor) do
        invoke_executable("--write", file: file)
      end
    end
  end

  def switch_env(key, value)
    old, ENV[key] = ENV[key], value
    yield
  ensure
    ENV[key] = old
  end

  def create_key
    key = ActiveSupport::EncryptedFile.generate_key

    create_file("invisible_ink.key", content: key) unless File.exist?("invisible_ink.key")
  end

  def delete_key
    delete_file("invisible_ink.key")
  end

  def create_file(file, content: "")
    File.write(file, content)
  end

  def create_encrypted_file(file, content: "", env_key: "")
    create_key unless env_key.present?

    encrypted_file = ActiveSupport::EncryptedFile.new(
      content_path: file,
      key_path: "invisible_ink.key",
      env_key: env_key,
      raise_if_missing_key: true
    )

    encrypted_file.write(content)
  end

  def backup_file(file)
    FileUtils.mv(file, "#{file}.bak")
  end

  def delete_file(file)
    File.delete(file) if File.exist?(file)
  end

  def restore_file(file)
    FileUtils.mv("#{file}.bak", file)
  end

  def read_file(file)
    File.read(file)
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
