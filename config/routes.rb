Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :tickets, only: %i[index show new create] do
    member do
      patch :transition
      patch :assign_to_me
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Render bu adresi saglik kontrolu olarak kullaniyor (bkz. AGENT.md).
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
