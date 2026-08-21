import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const saved = localStorage.getItem("pam-theme")
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    this.setTheme(saved || (prefersDark ? "dark" : "light"))
  }

  toggle() {
    this.setTheme(document.documentElement.classList.contains("dark") ? "light" : "dark")
  }

  setTheme(theme) {
    document.documentElement.classList.toggle("dark", theme === "dark")
    localStorage.setItem("pam-theme", theme)
  }
}
