RedmineApp::Application.routes.draw do

  resources :pastes do
    member do
      get 'download'
    end
  end

  resources :projects do
    resources :pastes do
      member do
        get 'download'
      end
    end
  end



  # map.resources :pastes, :only => [:index, :show],
  #   :member => { :download => :get }
  # map.resources :pastes, :path_prefix => '/projects/:project_id',
  #   :member => { :download => :get }
end
