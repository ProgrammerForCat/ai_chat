class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :specialist_type, null: false
      t.string :title

      t.timestamps
    end
  end
end
