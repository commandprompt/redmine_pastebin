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

require 'coderay'

module PastesHelper
  PASTEBIN_LANG_HASH = {
    "C" => "C",
    "C++" => "CPlusPlus",
    "Ruby" => "Ruby",
    "Python" => "Python",
    "JavaScript" => "JavaScript"
  }

  def pastebin_language_choices
    PASTEBIN_LANG_HASH.map { |k,v| [k, v] }
  end

  def pastebin_language_name(lang)
    PASTEBIN_LANG_HASH.invert[lang]
  end

  def highlighted_content_for_paste(paste)
    #Redmine::SyntaxHighlighting.highlight_by_language(paste.text, paste.lang)

    # TODO: hard-coding code-ray for :table option
    content_tag :div, :class => "syntaxhl" do
      ::CodeRay.scan(paste.text, paste.lang).html(:line_numbers => :table)
    end
  end

  PASTEBIN_TEXT_PREVIEW_LIMIT = 100

  def pastebin_text_preview(text)
    if text.length < PASTEBIN_TEXT_PREVIEW_LIMIT
      text
    else
      text[0..PASTEBIN_TEXT_PREVIEW_LIMIT] + "..."
    end
  end

  def edit_paste_link(paste, title = "Edit")
    link_to title, edit_paste_path(paste), :class => "icon icon-edit"
  end

  def delete_paste_link(paste, title = "Delete")
    link_to title, paste_path(paste), :class => "icon icon-del",
      :method => :delete, :confirm => "Are you sure?"
  end

  def manage_paste_links(paste)
    if User.current.allowed_to?(:manage_pastes, @project)
      edit_paste_link(paste) + delete_paste_link(paste)
    end
  end
end
