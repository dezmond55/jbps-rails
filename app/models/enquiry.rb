class Enquiry < ApplicationRecord
  serialize :services, coder: JSON

  before_validation :normalize_phone

  AU_PHONE_REGEX = /\A(\+?61[2-9]\d{8}|0[2-9]\d{8})\z/

  validates :phone, format: {
    with: AU_PHONE_REGEX,
    message: "must be a valid Australian phone number (e.g. 0412 345 678)"
  }, allow_blank: true

  private

  def normalize_phone
    self.phone = phone.gsub(/[\s\-\(\)\.]+/, "") if phone.present?
  end
end
