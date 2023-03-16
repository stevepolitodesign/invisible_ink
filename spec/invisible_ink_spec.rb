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
        system_output = invoke_executable("write", file: "file.txt")

        expect(system_output).to be_truthy
        expect($?).to be_success
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
        system_output = invoke_executable("read", file: "file.txt")

        expect(system_output).to be_truthy
        expect($?).to be_success
      end

      it "returns the decrypted contents of the file" do
        create_encrypted_file("file.txt", content: "content")

        output = `exe/invisible_ink read file.txt`
        expect(output).to eq "content\n"
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
        system_output = invoke_executable("setup")

        expect(system_output).to be_truthy
        expect($?).to be_success
      end

      it "creates a key with 32 characters" do
        expect(File.exist?("invisible_ink.key")).to be false

        invoke_executable("setup")

        key = File.open("invisible_ink.key")
        expect(key.size).to eq 32
      end

      it "ignores the key file" do
        File.write(".gitignore", "first_line")

        invoke_executable("setup")

        gitignore = File.read(".gitignore")
        expect(gitignore).to eq "first_line\ninvisible_ink.key\n"
      end

      context "when there is no .gitignore file" do
        it "ignores the key file" do
          expect(File.exist?(".gitignore")).to be false

          invoke_executable("setup")

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
