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

  belongs_to :project
  belongs_to :author, :class_name => 'User'

  scope :for_project, -> (project) {
    where({ :project_id => project })
  }

  scope :secure, -> {
    where("access_token IS NOT NULL")
  }

  scope :expired, -> {
    where("expires_at <= current_timestamp")
  }

  scope :unexpired, -> {
    where("expires_at IS NULL OR expires_at > current_timestamp")
  }

  #
  # * Restrict to projects where the user has a role allowing to view
  #   pastes.
  #
  # * Restrict to specific project, if given.
  #
  # * Admin users should be able to see all pastes, even secure ones.
  #
  # * An ordinary user can see a secure paste only if he has authored it.
  #
  # * Never show expired pastes even to an admin.
  #
  scope :visible, -> (user=nil, options={}) {
    user ||= User.current

    s = where(Project.allowed_to_condition(user, :view_pastes, options)).joins(:project)
    unless user.admin?
      s = s.where(["access_token IS NULL OR author_id = ?", user.id])
    end
    s.unexpired
  }

  #
  # The default scope limits what's exposed by event providers below.
  #
  # The use of block is important so that current user is evaluated
  # every time inside the visible scope as opposed to being captured
  # at the time of Paste class load.
  #
  default_scope { visible }

  #
  # We need to use exclusive scope to be able to specify a user other
  # than the current one.  Otherwise the default scope will be in
  # conflict by overriding the user.
  #
  def self.visible_to(user, options={})
    unscoped do
      Paste.visible(user, options)
    end
  end

  acts_as_searchable :columns => ["#{table_name}.title", "#{table_name}.text"],
    :scope => preload(:project)

  acts_as_event :title => Proc.new{ |o| o.title },
    :url => Proc.new{ |o| { :controller => 'pastes', :action => 'show',
      :id => o.to_param } }

  acts_as_activity_provider :scope => preload([:project, :author]),
    :author_key => :author_id

  def title
    return if new_record?
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
    unscoped do
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
    unscoped do
      Paste.expired.delete_all
    end
  end

  private

  def make_access_token
    Digest::SHA1.hexdigest("#{self.inspect}@#{Time.now.to_f}")
  end
end
