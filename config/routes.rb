Rails.application.routes.draw do
  root "greetings#hello"

  match "/compile", to: "compilation#compile", via: :post
  match "/run",     to: "compilation#run",     via: :post
end
