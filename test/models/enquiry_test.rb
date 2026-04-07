require "test_helper"

class EnquiryTest < ActiveSupport::TestCase
  # --- phone validation ---

  test "valid Australian mobile number" do
    assert build(phone: "0412345678").valid?
  end

  test "valid Australian landline" do
    assert build(phone: "0291234567").valid?
  end

  test "valid with +61 prefix" do
    assert build(phone: "+61412345678").valid?
  end

  test "normalises spaces before validating" do
    assert build(phone: "0412 345 678").valid?
  end

  test "normalises dashes before validating" do
    assert build(phone: "0412-345-678").valid?
  end

  test "rejects non-Australian number" do
    assert_not build(phone: "81326422528").valid?
  end

  test "rejects too-short number" do
    assert_not build(phone: "041234567").valid?
  end

  test "rejects letters" do
    assert_not build(phone: "041234abcd").valid?
  end

  test "blank phone is allowed" do
    assert build(phone: "").valid?
  end

  private

  def build(phone:)
    Enquiry.new(name: "Test User", email: "test@example.com", phone: phone)
  end
end