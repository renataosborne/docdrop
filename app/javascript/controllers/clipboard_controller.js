import { Controller } from "@hotwired/stimulus"

// Copies the value of the source field and briefly confirms on the button.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const label = this.buttonTarget.textContent
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.buttonTarget.textContent = "Copied!"
    } catch {
      this.sourceTarget.select()
      this.buttonTarget.textContent = "Press ⌘C to copy"
    }
    setTimeout(() => { this.buttonTarget.textContent = label }, 2000)
  }
}
