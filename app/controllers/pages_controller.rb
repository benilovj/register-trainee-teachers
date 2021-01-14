# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate, except: [:home]

  def show
    render template: "pages/#{params[:page]}"
  end

  def home
    render :home
  end

  def accessibility
    render :accessibility
  end

  def cookies
    render :cookies
  end

  def privacy_policy
    render :privacy_policy
  end

  def data_requirements
    render :data_requirements
  end
end
