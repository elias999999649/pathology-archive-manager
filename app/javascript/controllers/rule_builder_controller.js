import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["groups", "groupTemplate", "conditionTemplate", "actions", "actionTemplate", "message"]

  addGroup() {
    const index = this.groupsTarget.querySelectorAll("[data-rule-group]").length
    this.groupsTarget.insertAdjacentHTML("beforeend", this.groupTemplateTarget.innerHTML.replaceAll("GROUP_INDEX", index))
  }

  addCondition(event) {
    const group = event.target.closest("[data-rule-group]")
    const groupIndex = group.dataset.groupIndex
    const index = group.querySelectorAll("[data-condition]").length
    group.querySelector("[data-conditions]").insertAdjacentHTML("beforeend", this.conditionTemplateTarget.innerHTML.replaceAll("GROUP_INDEX", groupIndex).replaceAll("CONDITION_INDEX", index))
  }

  addAction() {
    const index = this.actionsTarget.querySelectorAll("[data-action-row]").length
    this.actionsTarget.insertAdjacentHTML("beforeend", this.actionTemplateTarget.innerHTML.replaceAll("ACTION_INDEX", index))
  }

  removeCondition(event) {
    const group = event.target.closest("[data-rule-group]")
    if (group.querySelectorAll("[data-condition]").length <= 1) return this.showMessage("Each condition group needs at least one condition.")
    event.target.closest("[data-condition]").remove()
  }

  removeGroup(event) {
    if (this.groupsTarget.querySelectorAll("[data-rule-group]").length <= 1) return this.showMessage("A rule needs at least one condition group.")
    event.target.closest("[data-rule-group]").remove()
  }

  removeAction(event) {
    if (this.actionsTarget.querySelectorAll("[data-action-row]").length <= 1) return this.showMessage("A rule needs at least one decision action.")
    event.target.closest("[data-action-row]").remove()
  }

  showMessage(message) {
    this.messageTarget.textContent = message
    this.messageTarget.classList.remove("hidden")
  }
}
