# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate

  def start
    session[:requested_path] = root_path
    if authenticated?
      if FeatureService.enabled?(:user_can_have_multiple_organisations) && organisation_not_set?
        redirect_to(organisations_path) && return
      end

      @trainees = policy_scope(Trainee.all)
      @home_view = HomeView.new(@trainees)
      render(:home)
    else
      render(:start)
    end
  end

  def accessibility
    render(:accessibility)
  end

  def privacy_notice
    render(:privacy_notice)
  end

  def guidance
    render(:guidance)
  end

  def dttp_replaced
    render(:dttp_replaced)
  end

  def data_sharing_agreement
    render(:data_sharing_agreement)
  end

private

  def organisation_not_set?
    current_user.organisation.nil? && !current_user.system_admin?
  end
end
