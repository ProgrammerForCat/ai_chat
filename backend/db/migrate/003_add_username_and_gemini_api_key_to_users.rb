Sequel.migration do
  up do
    alter_table(:users) do
      add_column :username, String, null: true
      add_column :gemini_api_key, String, null: true
    end
  end

  down do
    alter_table(:users) do
      drop_column :username
      drop_column :gemini_api_key
    end
  end
end