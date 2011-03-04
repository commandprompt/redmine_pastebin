class RenamePasteTimestamps < ActiveRecord::Migration
  def self.up
    rename_column :pastes, :created_at, :created_on
    rename_column :pastes, :updated_at, :updated_on
  end

  def self.down
    rename_column :pastes, :created_on, :created_at
    rename_column :pastes, :updated_on, :updated_at
  end
end
