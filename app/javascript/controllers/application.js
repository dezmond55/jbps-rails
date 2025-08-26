import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Load registered controllers from importmap
import controllers from "./controllers/*"

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }