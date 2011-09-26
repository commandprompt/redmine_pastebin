module RedminePastebin
  class ViewHooks < Redmine::Hook::ViewListener
    render_on :view_projects_index_activity_menu,
      :partial => 'hooks/redmine_pastebin_all_pastes_link'
  end
end
