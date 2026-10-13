import { Controller } from "@hotwired/stimulus"

// Adds and removes checklist item fields in the request form without a page reload.
// New rows are cloned from a <template>; existing rows are hidden and flagged with _destroy.
export default class extends Controller {
  static targets = ["list", "template", "item"]

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.itemTargets.at(-1).querySelector("input[type=text]").focus()
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-checklist-form-target='item']")

    if (item.dataset.newRecord === "true") {
      item.remove()
    } else {
      item.querySelector("input[name*='_destroy']").value = "1"
      item.hidden = true
    }
  }
}
