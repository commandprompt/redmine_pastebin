routedef = Proc.new do |options|
  resources :pastes, options do
    member do
      get :download
    end
  end
end

# new paste can be only created on a project
routedef.call :except => :new

scope '/projects/:project_id', :as => 'per_project' do
  routedef.call({})
end
