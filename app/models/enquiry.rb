class Enquiry < ApplicationRecord
  serialize :services, coder: JSON
end
