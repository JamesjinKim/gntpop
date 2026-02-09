import { Controller } from "@hotwired/stimulus"

// 모바일 사이드바 메뉴 토글 컨트롤러
export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  toggle() {
    this.sidebarTarget.classList.toggle("-translate-x-full")
    this.overlayTarget.classList.toggle("hidden")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
  }
}
