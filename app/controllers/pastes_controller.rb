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

  before_filter :find_project, :authorize

  accept_key_auth :index
  accept_api_auth :index, :show, :download, :create, :update, :destroy

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
      format.api
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
    if @paste.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_paste_created)
          redirect_to @paste
        }
        format.api  { render :action => 'show', :status => :created, :location => paste_url(@paste) }
      end
    else
      respond_to do |format|
        format.html { render(params[:fork].blank? ? :new : :edit) }
        format.api { render_validation_errors(@paste) }
      end
    end
  end

  def update
    if params[:fork].present?
      create
    else
      if @paste.update_attributes(params[:paste])
        flash[:notice] = l(:notice_paste_updated)

        respond_to do |format|
          format.html { redirect_to @paste }
          format.api { head :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit }
          format.api { render_validation_errors(@paste) }
        end
      end
    end
  end

  def destroy
    @paste.destroy
    flash[:notice] = l(:notice_paste_destroyed)

    respond_to do |format|
      format.html { redirect_to pastes_path(:project_id => @project.id) }
      fomat.api { head :ok }
    end
  end

  private

  def find_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
      @pastes = @project.pastes
    else
      @pastes = Paste
    end
    if params[:id].present?
      @paste = @pastes.find(params[:id])
      @project ||= @paste.project
    else
      @projects = Project.visible.has_module(:pastes)
    end
    @pastes ||= Paste.for_project(@project || @projects)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
