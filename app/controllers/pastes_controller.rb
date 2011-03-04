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

  before_filter :find_project, :authorize

  def index
    @pastes = @project.pastes.all(:order => "pastes.created_at DESC")
  end

  def show
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
      flash[:notice] = "Pasted successfully"
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
        @paste.update_attribute(:author_id, User.current.id)

        flash[:notice] = "Paste updated successfully"
        redirect_to @paste
      else
        render :edit
      end
    end
  end

  def destroy
    @paste.destroy
    flash[:notice] = "Paste destroyed"
    redirect_to pastes_path(:project_id => @project.id)
  end

  private

  def find_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    else
      @paste = Paste.find(params[:id])
      @project = @paste.project
    end
  end
end
