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

class PastesController < ApplicationController
  unloadable

  include PastesHelper

  default_search_scope :pastes

  before_filter :find_paste_and_project, :authorize

  accept_rss_auth :index

  def index
    @limit = per_page_option

    @pastes_count = @pastes.count
    @pastes_pages = Paginator.new(self, @pastes_count, @limit, params[:page])
    @offset ||= @pastes_pages.current.offset
    @pastes = @pastes.all(:order => "#{Paste.table_name}.created_on DESC",
                          :offset => @offset,
                          :limit => @limit)

    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.atom { render_feed(@pastes, :title => (@project ? @project.name : Setting.app_title) + ": " + l(:label_paste_plural)) }
    end
  end

  def show
  end

  def download
    send_data @paste.text, :filename => pastebin_filename(@paste),
      :type => pastebin_mime_type(@paste),
      :disposition => 'attachment'
  end

  def new
    @paste = @project.pastes.build
  end

  def edit
  end

  def create
    @paste = @project.pastes.build(params[:paste])
    @paste.author = User.current
    @paste.secure = (params[:paste][:secure] == "1")
    @paste.expire_in(params[:paste][:expires].to_i) if params[:paste][:expires].to_i > 0
    if @paste.save
      flash[:notice] = l(:notice_paste_created)
      redirect_to @paste
    else
      render(params[:fork].blank? ? :new : :edit)
    end
  end

  def update
    if params[:fork].present?
      create
    else
      if @paste.update_attributes(params[:paste])
        flash[:notice] = l(:notice_paste_updated)
        redirect_to @paste
      else
        render :edit
      end
    end
  end

  def destroy
    @paste.destroy
    flash[:notice] = l(:notice_paste_destroyed)
    redirect_to :action => "index", :project_id => params[:project_id]
  end

  private

  def find_paste_and_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      @pastes = @project.pastes
    else
      @pastes = Paste
    end
    @pastes = @pastes.visible(User.current)

    if params[:id].present?
      if Paste.secure_id?(params[:id])
        @paste = Paste.find_by_secure_id(params[:id]) || raise(ActiveRecord::RecordNotFound)
        @pastes = nil
      else
        @paste = @pastes.find(params[:id])
      end
      @project ||= @paste.project
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
