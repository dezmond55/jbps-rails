class CreateEnquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :enquiries do |t|
      t.string :name
      t.string :company
      t.string :email
      t.string :phone
      t.string :location
      t.string :budget
      t.string :services
      t.string :timeline
      t.string :source
      t.text :description

      t.timestamps
    end
  end
end
