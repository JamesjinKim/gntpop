import { Controller } from "@hotwired/stimulus"

// 페이지 자동 새로고침 컨트롤러 (기본 30초 간격)
// 사용법: <div data-controller="auto-refresh" data-auto-refresh-interval-value="30000">
export default class extends Controller {
  static values = { interval: { type: Number, default: 30000 } }
  static targets = ["countdown"]

  connect() {
    this.remaining = this.intervalValue / 1000
    this.updateCountdown()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  tick() {
    this.remaining -= 1
    this.updateCountdown()

    if (this.remaining <= 0) {
      this.refresh()
    }
  }

  refresh() {
    this.remaining = this.intervalValue / 1000
    Turbo.visit(window.location.href, { action: "replace" })
  }

  updateCountdown() {
    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = this.remaining
    }
  }
}
