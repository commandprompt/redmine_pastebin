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

require 'redmine'
require 'dispatcher'

require_dependency 'redmine_pastebin/view_hooks'

Dispatcher.to_prepare :redmine_model_dependencies do
  require_dependency 'project'
  require_dependency 'user'

  unless Project.included_modules.include? RedminePastebin::ProjectPastesPatch
    Project.send(:include, RedminePastebin::ProjectPastesPatch)
  end

  unless User.included_modules.include? RedminePastebin::UserPastesPatch
    User.send(:include, RedminePastebin::UserPastesPatch)
  end
end

Redmine::Plugin.register :redmine_pastebin do
  name 'Redmine Pastebin plugin'
  author 'Alex Shulgin <ash@commandprompt.com>'
  description 'A real pastebin plugin for redmine'
  version '0.0.1'
  url 'https://github.com/commandprompt/redmine_pastebin/'
#  author_url 'http://example.com/about'

  requires_redmine :version_or_higher => '1.1.0'

  project_module :pastes do
    permission :view_pastes,   :pastes => [:index, :show]
    permission :add_pastes,    :pastes => [:new, :create]
    permission :edit_pastes,   :pastes => [:edit, :update]
    permission :delete_pastes, :pastes => [:destroy]
  end

  menu :project_menu, :pastes, { :controller => 'pastes', :action => 'index' },
    :caption => :label_paste_plural, :after => :label_wiki,
    :param => :project_id
end

Redmine::Activity.map do |activity|
  activity.register :pastes
end

Redmine::Search.map do |search|
  search.register :pastes
end
