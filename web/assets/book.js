<script>
// Move presentation metadata into Quarto's native title block.
document.addEventListener("DOMContentLoaded", () => {
  const meta = document.querySelector(".book-chapter-meta");
  const title = document.querySelector("#title-block-header");
  const eyebrow = document.querySelector(".book-eyebrow");
  if (title && eyebrow) title.prepend(eyebrow);
  if (title && meta) title.append(meta);
});
</script>
