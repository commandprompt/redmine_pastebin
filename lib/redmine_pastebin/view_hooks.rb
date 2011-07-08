module RedminePastebin
  class ViewHooks < Redmine::Hook::ViewListener
    render_on :view_projects_index_activity_menu,
      :partial => 'hooks/view_projects_index_activity_menu'
  end
end
