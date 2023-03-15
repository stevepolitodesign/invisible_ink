# frozen_string_literal: true

RSpec.describe InvisibleInk do
  it "has a version number" do
    expect(InvisibleInk::VERSION).not_to be nil
  end

  describe "invisible_ink executable" do
    it "exits with a 0 status code" do
      system_output = invoke_executable

      expect(system_output).to be_truthy
      expect($?).to be_success
    end
  end
end
