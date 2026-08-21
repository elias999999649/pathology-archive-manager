import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    window.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKeydown)
  }

  onKeydown(event) {
    const target = event.target
    const typing = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement
    if ((event.key === "/" && !typing) || ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k")) {
      event.preventDefault()
      this.inputTarget.focus()
      this.inputTarget.select()
    }
    if (event.key === "Escape" && document.activeElement === this.inputTarget) this.inputTarget.blur()
  }
}
