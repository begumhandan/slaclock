Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :tickets, only: %i[index show new create] do
    member do
      patch :transition
      patch :assign_to_me
    end
    resources :comments, only: :create
  end

  # Musterinin gizli linkli talep sayfasi (giris gerektirmez; erisim yalnizca tahmin edilemeyen anahtarla).
  get "t/:token" => "customer_tickets#show", as: :customer_ticket
  post "t/:token/reply" => "customer_tickets#reply", as: :customer_ticket_reply

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Render bu adresi saglik kontrolu olarak kullaniyor (bkz. AGENT.md).
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
