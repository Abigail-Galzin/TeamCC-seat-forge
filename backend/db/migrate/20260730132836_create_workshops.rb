class CreateWorkshops < ActiveRecord::Migration[8.1]
  def change
    create_table :workshops do |t|
      t.string :title, null: false
      t.string :description
      t.string :topic, null: false
      t.boolean :active, null: false, default: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
