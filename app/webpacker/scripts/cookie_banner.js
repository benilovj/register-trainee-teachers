import {
  setViewedCookieMessage,
  viewedCookieMessageExists
} from './utils/cookie_helper'

export default class CookieBanner {
  static init () {
    return new CookieBanner()
  }

  constructor () {
    this.$module = document.querySelector(
      '[data-module="govuk-cookie-banner"]'
    )

    if (!this.$module) return

    this.hideButton = this.$module.querySelector(
      '[data-qa="govuk-cookie-banner__hide"]'
    )

    if (!viewedCookieMessageExists()) {
      this.showCookieMessage()
      this.bindEvents()
    }
  }

  bindEvents () {
    this.hideButton.addEventListener('click', () => this.viewedCookieBanner())
  }

  viewedCookieBanner () {
    this.hideCookieMessage()
    setViewedCookieMessage(true)
  }

  showCookieMessage () {
    this.$module.classList.remove('govuk-cookie-banner--hidden')
    this.hideButton.classList.remove('govuk-cookie-banner__hide')
  }

  hideCookieMessage () {
    this.$module.classList.add('govuk-cookie-banner--hidden')
  }
}
