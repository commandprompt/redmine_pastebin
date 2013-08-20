# redmine_pastebin -- A real pastebin plugin for Redmine.
#
# Copyright (C) 2011  Alex Shuglin <ash@commandprompt.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require "digest/sha1"

class Paste < ActiveRecord::Base
  unloadable # really?

  attr_accessible :title, :lang, :text

  belongs_to :project
  belongs_to :author, :class_name => 'User'

  scope :for_project, lambda { |project|
    where({ :project_id => project })
  }

  scope :secure, where("access_token IS NOT NULL")

  scope :expired, where("expires_at <= current_timestamp")
  scope :unexpired, where("expires_at IS NULL OR expires_at > current_timestamp")

  #
  # * Restrict to projects where the user is a member with a role
  #   allowing to view pastes.
  #
  # * Restrict to specific project, if given.
  #
  # * Admin users should be able to see all pastes, even secure ones)
  #
  # * An ordinary user can see a secure paste only if he has authored it.
  #
  # * Never show expired pastes even to an admin.
  #
  scope :visible, lambda{ |user=User.current, *args|
    o = args.first || {}
    o = o.merge(:member => true)

    s = self
    unless user.admin?
      s = s.where(Project.allowed_to_condition(user, :view_pastes, o)).includes(:project)
      s = s.where(["access_token IS NULL OR author_id = ?", user.id])
    end
    s.unexpired
  }

  default_scope visible

  acts_as_searchable :columns => ["#{table_name}.title", "#{table_name}.text"],
    :include => :project

  acts_as_event :title => Proc.new{ |o| o.title },
    :url => Proc.new{ |o| { :controller => 'pastes', :action => 'show',
      :id => o.id } }

  acts_as_activity_provider :find_options => {:include => [:project, :author]},
    :author_key => :author_id

  def title
    t = super
    t.present? ? t : "Paste ##{id}"
  end

  def description
    short_text
  end

  SHORT_TEXT_LIMIT = 100

  def short_text
    if text.length < SHORT_TEXT_LIMIT
      text
    else
      text[0..SHORT_TEXT_LIMIT] + "..."
    end
  end

  def secure?
    access_token.present?
  end
  alias_method :secure, :secure?

  def to_param
    secure? ? access_token : id.to_s
  end

  def secure!
    # update_attribute won't work as access_token isn't listed as
    # `accessible'
    self.secure = true
    save!
  end

  def secure=(value)
    self.access_token = value ? make_access_token : nil
  end

  def self.secure_id?(id)
    # assume SHA1 hexdigest
    id =~ /^[0-9a-f]{40}$/
  end

  def self.find_by_secure_id(id)
    with_exclusive_scope do
      find_by_access_token(id)
    end
  end

  def expired?
    expires_at.present? && expires_at <= Time.now
  end

  def expire_in(seconds)
    self.expires_at = Time.now + seconds
  end

  def self.wipe_all_expired
    with_exclusive_scope do
      Paste.expired.delete_all
    end
  end

  private

  def make_access_token
    Digest::SHA1.hexdigest("#{self.inspect}@#{Time.now.to_f}")
  end
end
