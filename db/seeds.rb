Service.delete_all

Service.create!(
  name: "Commercial Construction",
  description: "New commercial builds including office construction, bank refurbishments, and council facilities with proven project delivery."
)

Service.create!(
  name: "Residential Construction",
  description: "Quality residential builds, unit developments, and project management with comprehensive construction services."
)

Service.create!(
  name: "Project Management and Estimating",
  description: "Professional project management services including cost tracking, estimating, and coordination of all construction works."
)

Service.create!(
  name: "Programmed and Responsive Maintenance",
  description: "Multi-trade maintenance contracts for corporate and government bodies including 24/7 emergency repairs."
)

Service.create!(
  name: "Property & Facilities Management",
  description: "Comprehensive facilities management for real estate agencies, government departments, and commercial properties."
)

Service.create!(
  name: "Fit-out and Refurbishment",
  description: "Professional fit-out and refurbishment services for commercial spaces, banks, dental clinics, and office upgrades."
)

puts "Seeded #{Service.count} services!"
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
