class AddSecurePastes < ActiveRecord::Migration
  def self.up
    add_column :pastes, :access_token, :text
  end

  def self.down
    remove_column :pastes, :access_token
  end
end
