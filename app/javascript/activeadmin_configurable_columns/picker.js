// Drag-and-drop reordering for the "Columns" picker.
//
// Every row carries a hidden `columns[]` input, and browsers submit fields in
// document order, so moving a row is all it takes: the form posts the new
// order on save. Without this script the form still saves visibility.
import Sortable from "activeadmin_configurable_columns/sortable"

const LIST = "[data-aacc-list]"
const ROW = "[data-aacc-row]"
const HANDLE = "[data-aacc-handle]"

// Keyboard alternative to dragging: arrow keys on a focused handle.
const moveWithKeyboard = (event) => {
  const handle = event.target.closest(HANDLE)
  if (!handle || (event.key !== "ArrowUp" && event.key !== "ArrowDown")) return

  event.preventDefault()
  const row = handle.closest(ROW)

  if (event.key === "ArrowUp" && row.previousElementSibling) {
    row.previousElementSibling.before(row)
  } else if (event.key === "ArrowDown" && row.nextElementSibling) {
    row.nextElementSibling.after(row)
  }

  // Moving a node can drop its focus; keep the keyboard user where they were.
  handle.focus()
}

const setUp = (list) => {
  if ("aaccReady" in list.dataset) return
  list.dataset.aaccReady = ""

  Sortable.create(list, {
    handle: HANDLE,
    draggable: ROW,
    animation: 150,
    // On touch screens a short press scrolls the page; a long press drags.
    delay: 150,
    delayOnTouchOnly: true,
    // Single class names only (Sortable adds them with classList.add); the
    // list styles them with Tailwind arbitrary variants.
    ghostClass: "aacc-ghost",
    chosenClass: "aacc-chosen",
  })

  list.addEventListener("keydown", moveWithKeyboard)
}

const start = () => document.querySelectorAll(LIST).forEach(setUp)

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", start)
} else {
  start()
}
