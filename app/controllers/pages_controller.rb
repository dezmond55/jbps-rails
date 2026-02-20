class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    render "home"
  end

  def about
    render "about"
  end
end
