# frozen_string_literal: true

RSpec.describe InvisibleInk do
  it "has a version number" do
    expect(InvisibleInk::VERSION).not_to be nil
  end

  describe "invisible_ink executable" do
    before do
      backup_file(".gitignore")
    end

    after do
      delete_key
      delete_file("file.txt")
      restore_file(".gitignore")
    end

    it "requires a command" do
      system_output = invoke_executable(nil)

      expect(system_output).to be_falsey
      expect($?).to_not be_success
    end

    it "requires a valid command" do
      system_output = invoke_executable("invalid_command")

      expect(system_output).to be_falsey
      expect($?).to_not be_success
    end

    describe "write command" do
      it "exits with a 0 status code" do
        create_key

        switch_env("EDITOR", "cat") do
          system_output = invoke_executable("--write", file: "file.txt")

          expect(system_output).to be_truthy
          expect($?).to be_success
        end
      end

      it "creates an encrypted file" do
        create_key

        invoke_write_command("file.txt", "expected content", editor: %(ruby -e "File.write ARGV[0], ENV['CONTENT']"))

        encrypted_file = ActiveSupport::EncryptedFile.new(
          content_path: "file.txt",
          key_path: "invisible_ink.key",
          env_key: "",
          raise_if_missing_key: true
        )
        expect(encrypted_file.read).to eq "expected content"
      end

      context "when the invisible_ink.key is missing" do
        it "exits with a 1 status code" do
          switch_env("INVISIBLE_INK_KEY", "") do
            output = `exe/invisible_ink --write "file.txt"`

            expect($?).to_not be_success
            expect(output).to match(/INVISIBLE_INK_KEY/)
            expect(output).to match(/invisible_ink\.key/)
            expect(output).to match(/missin/i)
            expect(output).to match(/invisible_ink setup/)
          end
        end

        context "but the environment variable is set" do
          it "creates an encrypted file" do
            key = ActiveSupport::EncryptedFile.generate_key

            switch_env("INVISIBLE_INK_KEY", key) do
              encrypted_file = ActiveSupport::EncryptedFile.new(
                content_path: "file.txt",
                key_path: "",
                env_key: "INVISIBLE_INK_KEY",
                raise_if_missing_key: true
              )

              invoke_write_command("file.txt", "expected content", editor: %(ruby -e "File.write ARGV[0], ENV['CONTENT']"))

              expect(encrypted_file.read).to eq "expected content"
            end
          end
        end
      end

      context "when the message is interrupted" do
        it "does not save the changes" do
          create_encrypted_file("file.txt", content: "existing content")

          invoke_write_command("file.txt", "new content", editor: %(ruby -e "Process.kill 'INT', Process.ppid"))

          encrypted_file = ActiveSupport::EncryptedFile.new(
            content_path: "file.txt",
            key_path: "invisible_ink.key",
            env_key: "",
            raise_if_missing_key: true
          )
          expect(encrypted_file.read).to eq "existing content"
        end
      end

      context "when there is no system editor" do
        it "exits with a 1 status code" do
          switch_env("EDITOR", "") do
            create_key

            system_output = invoke_executable("write", file: "file.txt")

            expect(system_output).to be_falsey
            expect($?).to_not be_success
          end
        end
      end

      context "when no content is added" do
        it "creates an empty file" do
          create_key

          invoke_write_command("file.txt", nil, editor: %(ruby -e "File.write ARGV[0], ENV['CONTENT']"))

          encrypted_file = ActiveSupport::EncryptedFile.new(
            content_path: "file.txt",
            key_path: "invisible_ink.key",
            env_key: "",
            raise_if_missing_key: true
          )
          expect(encrypted_file.read).to be_empty
        end
      end

      context "when there is an existing file" do
        it "does not wipe the file clean before opening the editor" do
          create_encrypted_file("file.txt", content: "existing content")

          invoke_write_command("file.txt", "existing content", editor: "cat")

          encrypted_file = ActiveSupport::EncryptedFile.new(
            content_path: "file.txt",
            key_path: "invisible_ink.key",
            env_key: "",
            raise_if_missing_key: true
          )
          expect(encrypted_file.read).to_not be_empty
        end
      end

      context "when a file is not passed" do
        it "exits with a 1 status code" do
          system_output = invoke_executable("read")

          expect(system_output).to be_falsey
          expect($?).to_not be_success
        end
      end
    end

    describe "read command" do
      it "exits with a 0 status code" do
        create_encrypted_file("file.txt", content: "content")
        system_output = invoke_executable("--read", file: "file.txt")

        expect(system_output).to be_truthy
        expect($?).to be_success
      end

      it "returns the decrypted contents of the file" do
        create_encrypted_file("file.txt", content: "content")

        output = `exe/invisible_ink --read file.txt`
        expect(output).to eq "content\n"
      end

      context "when the invisible_ink.key is missing" do
        it "exits with a 1 status code" do
          switch_env("INVISIBLE_INK_KEY", "") do
            create_file("file.txt", content: "content")

            output = `exe/invisible_ink --read "file.txt"`

            expect($?).to_not be_success
            expect(output).to match(/INVISIBLE_INK_KEY/)
            expect(output).to match(/invisible_ink\.key/)
            expect(output).to match(/missin/i)
            expect(output).to match(/invisible_ink setup/)
          end
        end

        context "but the environment variable is set" do
          it "returns the decrypted contents of the file" do
            key = ActiveSupport::EncryptedFile.generate_key

            switch_env("INVISIBLE_INK_KEY", key) do
              create_encrypted_file("file.txt", content: "content", env_key: "INVISIBLE_INK_KEY")

              output = `exe/invisible_ink --read file.txt`
              expect(output).to eq "content\n"
            end
          end
        end
      end

      context "when a file is not passed" do
        it "exits with a 1 status code" do
          system_output = invoke_executable("write")

          expect(system_output).to be_falsey
          expect($?).to_not be_success
        end
      end
    end

    describe "setup command" do
      it "exits with a 0 status code" do
        system_output = invoke_executable("--setup")

        expect(system_output).to be_truthy
        expect($?).to be_success
      end

      it "creates a key with 32 characters" do
        expect(File.exist?("invisible_ink.key")).to be false

        invoke_executable("--setup")

        key = File.open("invisible_ink.key")
        expect(key.size).to eq 32
      end

      it "ignores the key file" do
        File.write(".gitignore", "first_line")

        invoke_executable("--setup")

        gitignore = File.read(".gitignore")
        expect(gitignore).to eq "first_line\ninvisible_ink.key\n"
      end

      context "when there is no .gitignore file" do
        it "ignores the key file" do
          expect(File.exist?(".gitignore")).to be false

          invoke_executable("--setup")

          gitignore = File.read(".gitignore")
          expect(gitignore).to eq "invisible_ink.key\n"
        end
      end

      context "when the key exists" do
        it "does not override the key" do
          File.write("invisible_ink.key", "original")

          invoke_executable("setup")

          key = File.read("invisible_ink.key")
          expect(key).to eq "original"
        end

        it "exits with a 1 status code" do
          File.write("invisible_ink.key", "original")

          system_output = invoke_executable("setup")

          expect(system_output).to be_falsey
          expect($?).to_not be_success
        end
      end
    end
  end
end
