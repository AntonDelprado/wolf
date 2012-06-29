Wolf::Application.routes.draw do

  resources :sessions, only: [:new, :create, :destroy]
  resources :users do
    member do
      put :password
    end
  end
  resources :campaigns do
    member do
      get :join
      get :invite
    end
  end
  resources :characters do
    member do
      get :export
      put :stats
      put :items
      put :skills
      put :abilities
    end

    collection do
      post :import
    end
  end


  root to: 'static_pages#home'

  # Sign up/in/out pages

  match '/signup', to: 'users#new'
  match '/signin', to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete

  # Rules pages

  match '/rules', to: 'static_pages#rules'
  match '/rules/core', to: 'static_pages#core'
  match '/rules/combat', to: 'static_pages#combat'
  match '/rules/race', to: 'static_pages#race'
  match '/rules/skills', to: 'static_pages#skills'
  match '/rules/abilities', to: 'static_pages#abilities'
  match '/rules/synergy', to: 'static_pages#synergy'
  match '/rules/item', to: 'static_pages#item'
  match '/rules/monster', to: 'static_pages#monster'
  match '/setting', to: 'static_pages#setting'
  match '/contact', to: 'static_pages#contact'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
