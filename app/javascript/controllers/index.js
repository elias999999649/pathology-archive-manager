import { Application } from "@hotwired/stimulus"
import ThemeController from "./theme_controller"
import RuleBuilderController from "./rule_builder_controller"
import GlobalSearchController from "./global_search_controller"

window.Stimulus = Application.start()
Stimulus.register("theme", ThemeController)
Stimulus.register("rule-builder", RuleBuilderController)
Stimulus.register("global-search", GlobalSearchController)
