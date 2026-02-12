import { Controller } from "@hotwired/stimulus"

// 플래시 메시지 자동 닫기 및 수동 닫기 기능을 제공하는 컨트롤러
export default class extends Controller {
  static targets = ["message"]

  connect() {
    // 5초 후 자동으로 플래시 메시지 제거
    this.timeout = setTimeout(() => {
      this.close()
    }, 5000)
  }

  disconnect() {
    // 컨트롤러가 제거될 때 타이머 정리
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close() {
    // 부드러운 fade-out 애니메이션 적용
    this.element.style.transition = "opacity 0.3s ease-out"
    this.element.style.opacity = "0"

    // 애니메이션 완료 후 DOM에서 제거
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
