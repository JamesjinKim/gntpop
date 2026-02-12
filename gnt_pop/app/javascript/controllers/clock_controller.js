import { Controller } from "@hotwired/stimulus"

// 실시간 시계 컨트롤러 (매초 갱신)
// 사용법: <span data-controller="clock"><span data-clock-target="display"></span></span>
export default class extends Controller {
  static targets = ["display"]

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  tick() {
    if (this.hasDisplayTarget) {
      const now = new Date()
      this.displayTarget.textContent = now.toLocaleString("ko-KR", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hour12: false
      })
    }
  }
}
