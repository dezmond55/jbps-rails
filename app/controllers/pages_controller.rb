class PagesController < ApplicationController
  def home
    render "home" # Explicitly render the home view
    provide(:title, "Jbps")
  end
end
