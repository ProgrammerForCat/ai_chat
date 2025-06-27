Sequel.migration do
  up do
    create_table(:conversations) do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, null: false
      String :specialist_type, null: false
      String :title
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end

    create_table(:messages) do
      primary_key :id, type: :Bignum
      foreign_key :conversation_id, :conversations, null: false
      String :role, null: false
      Text :content, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:messages)
    drop_table(:conversations)
  end
end