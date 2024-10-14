
const focusKeyboarderListener = () => {
  window.addEventListener("phx:focus-keyboarder", () => {
    document.activeElement.blur()
  })
}

export default function initiateAllListeners() {
  focusKeyboarderListener()
}

