class AddPasteExpiration < ActiveRecord::Migration
  def self.up
    add_column :pastes, :expires_at, :datetime
  end

  def self.down
    remove_column :pastes, :expires_at
  end
end
