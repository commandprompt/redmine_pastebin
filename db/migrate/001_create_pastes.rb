class CreatePastes < ActiveRecord::Migration
  def self.up
    create_table :pastes do |t|
      t.column :text, :text
      t.column :lang, :string
      t.column :author_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :pastes
  end
end
