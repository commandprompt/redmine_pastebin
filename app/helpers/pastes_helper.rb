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
  PASTEBIN_LANGS = ["Plain Text", "C", "C++", "Java", "JavaScript",
                    "Python", "Ruby", "SQL", "XML", "Diff"]
  PASTEBIN_SCANNERS_MAP = {
    "Plain Text" => "Plaintext",
    "C++" => "CPlusPlus"
  }

  def pastebin_lang_to_scanner(lang)
    PASTEBIN_SCANNERS_MAP[lang] || lang
  end

  def pastebin_language_name(lang)
    PASTEBIN_SCANNERS_MAP.invert[lang] || lang
  end

  def pastebin_language_choices
    PASTEBIN_LANGS.map { |v| [v, pastebin_lang_to_scanner(v)] }
  end

  def highlighted_content_for_paste(paste)
    #Redmine::SyntaxHighlighting.highlight_by_language(paste.text, paste.lang)

    # TODO: hard-coding code-ray for :table option
    content_tag :div, :class => "syntaxhl" do
      ::CodeRay.scan(paste.text, paste.lang).html(:line_numbers => :table)
    end
  end

  def paste_title(paste)
    if paste.title.present?
      paste.title
    else
      "#{paste_timestamp(paste)} - Paste ##{paste.id}"
    end
  end

  def paste_timestamp(paste)
    paste.created_on.to_s(:db)
  end

  def link_to_paste(paste)
    link_to paste_title(paste), paste
  end

  def edit_paste_link(paste, title = "Edit")
    link_to_if_authorized title, { :action => "edit", :id => paste },
      :class => "icon icon-edit"
  end

  def delete_paste_link(paste, title = "Delete")
    link_to_if_authorized title, { :action => "destroy", :id => paste },
      :class => "icon icon-del",
      :method => :delete, :confirm => "Are you sure?"
  end

  def manage_paste_links(paste)
    [edit_paste_link(paste), delete_paste_link(paste)].join("\n")
  end

  def link_to_all_pastes
    link_to "View all pastes", pastes_path(:project_id => @project),
      :class => "icon icon-multiple"
  end

  def link_to_new_paste
    link_to_if_authorized "New paste", { :action => "new",
      :project_id => @project }, :class => "icon icon-add"
  end
end
