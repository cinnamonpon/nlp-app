class CreateQualities < ActiveRecord::Migration
  def change
    create_table :qualities do |t|
      t.string :name
      t.integer :count
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
