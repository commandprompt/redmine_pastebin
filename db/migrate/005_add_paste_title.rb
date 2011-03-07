class AddPasteTitle < ActiveRecord::Migration
  def self.up
    add_column :pastes, :title, :string
  end

  def self.down
    remove_column :pastes, :title
  end
end
