let Hooks = {};

Hooks.HideFlash = {
  mounted() {
    setTimeout(() => {
      this.pushEvent("lv:clear-flash", { key: this.el.dataset.key });
      this.el.style.display = "none";
    }, 5000);
  },
};
Hooks.WindScroller = {
  mounted() {
    this.handleEvent("scroll-to-latest-wind", () => {
      requestAnimationFrame(() => {
        const lastThought = this.el.lastElementChild;
        if (lastThought) {
          const inputHeight = 200; // or however tall your input area is
          const targetScroll =
            lastThought.offsetTop - window.innerHeight + inputHeight + 96; // extra padding for comfort

          window.scrollTo({
            top: targetScroll,
            behavior: "smooth",
          });
        }
      });
    });
  },
};
Hooks.SensicalityGeneralScroller = {
  mounted() {
    this.el.addEventListener("click", () => {
      window.scrollTo({ top: 0, left: 0, behavior: "smooth" });
    });
  },
};

Hooks.Clipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const contentToCopy =
        this.el.dataset.content || this.el.textContent.trim();

      navigator.clipboard
        .writeText(contentToCopy)
        .then(() => {
          // we make it green, first get the first clipboard icon we can
          const originalIcon = this.el.querySelector(".hero-clipboard");
          if (originalIcon) {
            // save the originals
            const originalClasses = originalIcon.className;

            // add our mock successes
            originalIcon.className = originalClasses.replace(
              "text-yellow-400/70",
              "text-green-500"
            );
            originalIcon.className = originalIcon.className.replace(
              "group-hover:text-yellow-300",
              "group-hover:text-green-400"
            );

            this.el.title = "Copied!";

            // THE COOL ANIMATION ABOUT BEING COPIED! //
            const copiedText = document.createElement("div");
            copiedText.textContent = "Copied!";
            copiedText.style.position = "absolute";
            copiedText.style.left = `${this.el.offsetWidth / 2}px`;
            copiedText.style.top = "-8px";
            copiedText.style.transform = "translateX(-50%)";
            copiedText.style.color = "#10B981"; // green-500
            copiedText.style.fontSize = "0.75rem";
            copiedText.style.fontWeight = "bold";
            copiedText.style.pointerEvents = "none";
            copiedText.style.opacity = "0";
            copiedText.style.transition = "all 1.2s ease-out";

            this.el.style.position = "relative";
            this.el.appendChild(copiedText);

            setTimeout(() => {
              copiedText.style.opacity = "1";
              copiedText.style.top = "-24px";
            }, 10);

            setTimeout(() => {
              this.el.removeChild(copiedText);
            }, 1200);
            // THE COOL ANIMATION ABOUT BEING COPIED! //

            // after that, revert
            setTimeout(() => {
              originalIcon.className = originalClasses.replace(
                "text-green-500",
                "text-yellow-400/70"
              );
              originalIcon.className = originalIcon.className.replace(
                "group-hover:text-green-400",
                "group-hover:text-yellow-300"
              );
              this.el.title = "Click to copy";
            }, 1500);
          }
        })
        .catch((err) => {
          console.error("Error copying to clipboard:", err);
        });
    });
  },
};

export default Hooks;
