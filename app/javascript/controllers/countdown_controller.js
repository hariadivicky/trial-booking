import { Controller } from "@hotwired/stimulus"

// Ticks a <time datetime> element down to its datetime as mm:ss.
export default class extends Controller {
  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const seconds = Math.max(0, Math.round((new Date(this.element.dateTime) - Date.now()) / 1000))
    const pad = (n) => String(n).padStart(2, "0")

    this.element.textContent = `${pad(Math.floor(seconds / 60))}:${pad(seconds % 60)}`
    if (seconds === 0) clearInterval(this.timer)
  }
}
