# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate

  def callback
    DfESignInUser.begin_session!(session, request.env["omniauth.auth"])

    if current_user
      DfESignInUsers::Update.call(user: current_user, dfe_sign_in_user: dfe_sign_in_user)
      SendWelcomeEmailService.call(current_user: current_user)

      redirect_to(login_redirect_path)
    else
      session.delete(:requested_path)
      DfESignInUser.end_session!(session)
      redirect_to(sign_in_user_not_found_path)
    end
  end

  def signout
    redirect_to(root_path)
  end

private

  def login_redirect_path
    return organisations_path if current_user.multiple_organisations? || current_user.no_organisation?

    (session.delete(:requested_path) || root_path)
  end
end
