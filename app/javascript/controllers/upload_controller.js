import { Controller } from "@hotwired/stimulus"

// Turns the per-item upload form into a single button: picking files submits right away.
// Without JavaScript the plain file input and submit button still work.
export default class extends Controller {
  static targets = ["input", "button", "submit"]

  connect() {
    this.submitTarget.hidden = true
    this.inputTarget.classList.add("sr-only")
    this.buttonTarget.hidden = false
  }

  choose() {
    this.inputTarget.click()
  }

  submit() {
    if (this.inputTarget.files.length === 0) return

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Uploading…"
    this.element.requestSubmit()
  }
}
