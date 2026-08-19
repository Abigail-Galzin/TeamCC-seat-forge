class CreateAuthTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :auth_tokens do |t|
      t.string :token_digest, null: false
      t.references :user, foreign_key: true, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :auth_tokens, :token_digest, unique: true
  end
end