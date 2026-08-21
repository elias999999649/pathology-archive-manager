class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.integer :role, null: false, default: 3
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
    end

    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
    add_index :users, :reset_password_token, unique: true
    add_check_constraint :users, "role IN (0, 1, 2, 3)", name: "users_role_valid"
  end
end
