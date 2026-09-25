import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Ticks a <time datetime> element down to its datetime as mm:ss, then reloads the page.
export default class extends Controller {
  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)

    // Once the hold runs out the server redirects back to checkout; skipped if it already had, so clock skew can't loop.
    const remaining = new Date(this.element.dateTime) - Date.now()
    if (remaining > 0) this.reload = setTimeout(() => Turbo.visit(window.location.href, { action: "replace" }), remaining)
  }

  disconnect() {
    clearInterval(this.timer)
    clearTimeout(this.reload)
  }

  tick() {
    const seconds = Math.max(0, Math.round((new Date(this.element.dateTime) - Date.now()) / 1000))
    const pad = (n) => String(n).padStart(2, "0")

    this.element.textContent = `${pad(Math.floor(seconds / 60))}:${pad(seconds % 60)}`
    if (seconds === 0) clearInterval(this.timer)
  }
}
