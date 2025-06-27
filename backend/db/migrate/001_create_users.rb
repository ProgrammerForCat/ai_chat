Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id, type: :Bignum
      String :email, null: false, unique: true
      String :password_digest, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table(:users)
  end
end