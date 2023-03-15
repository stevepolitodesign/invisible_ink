# frozen_string_literal: true

RSpec.describe InvisibleInk do
  it "has a version number" do
    expect(InvisibleInk::VERSION).not_to be nil
  end

  describe "invisible_ink executable" do
    it "requires a command" do
      system_output = invoke_executable(nil)

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
        system_output = invoke_executable("read", file: "file.txt")

        expect(system_output).to be_truthy
        expect($?).to be_success
      end

      context "when a file is not passed" do
        it "exits with a 1 status code" do
          system_output = invoke_executable("write")

          expect(system_output).to be_falsey
          expect($?).to_not be_success
        end
      end
    end
  end
end
