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

  named_scope :for_project, lambda { |project|
    { :conditions => { :project_id => project } }
  }

  named_scope :secure, :conditions => "access_token IS NOT NULL"
  named_scope :visible_to, lambda { |user|
    { :conditions => (user.admin? ? nil : ["access_token IS NULL OR author_id = ?", user.id]) }
  }

  named_scope :expired, :conditions => "expires_at <= current_timestamp"
  default_scope :conditions => "expires_at IS NULL OR expires_at > current_timestamp"

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

  def expired?
    expires_at.present? && expires_at <= Time.now
  end

  def expire_in(seconds)
    self.expires_at = Time.now + seconds
  end

  private

  def make_access_token
    Digest::SHA1.hexdigest("#{self.inspect}@#{Time.now.to_f}")
  end
end
