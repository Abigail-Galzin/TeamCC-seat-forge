class CreateWorkshops < ActiveRecord::Migration[7.2]
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
