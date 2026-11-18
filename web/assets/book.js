<script>
// Move presentation metadata into Quarto's native title block.
document.addEventListener("DOMContentLoaded", () => {
  const meta = document.querySelector(".book-chapter-meta");
  const title = document.querySelector("#title-block-header");
  const eyebrow = document.querySelector(".book-eyebrow");
  if (title && eyebrow) title.prepend(eyebrow);
  if (title && meta) title.append(meta);
  // Quarto leaves an empty author grid on chapter pages and a nonbreaking
  // space after the hidden chapter number. Keep the title aligned to prose.
  document.querySelectorAll('.quarto-title-meta').forEach(element => {
    if (!element.textContent.trim()) element.hidden = true;
  });
  document.querySelectorAll('h1.title .chapter-number').forEach(element => {
    const spacer = element.nextSibling;
    if (spacer?.nodeType === Node.TEXT_NODE && !spacer.textContent.trim()) spacer.remove();
  });
  // Wide research tables scroll on their own, without widening the page.
  document.querySelectorAll('main.content table').forEach(table => {
    if (table.closest('.book-table-wrap')) return;
    const wrapper = document.createElement('div');
    wrapper.className = 'book-table-wrap';
    wrapper.setAttribute('role', 'region');
    wrapper.setAttribute('aria-label', table.caption?.textContent || 'Table');
    table.before(wrapper);
    wrapper.append(table);
  });
  const updateTableAccess = () => {
    document.querySelectorAll('.book-table-wrap').forEach(wrapper => {
      if (wrapper.scrollWidth > wrapper.clientWidth + 1) wrapper.tabIndex = 0;
      else wrapper.removeAttribute('tabindex');
    });
  };
  document.fonts.ready.then(updateTableAccess);
  window.addEventListener('resize', updateTableAccess, {passive: true});
});
</script>
