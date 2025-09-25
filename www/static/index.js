const results = document.getElementById("results");
results.addEventListener("click", async ({ target }) => {
    if (target.tagName !== "CODE") return;
    await navigator.clipboard.write(target.textContent);
    window.getSelection().selectAllChildren(target);
});

const form = document.getElementById("form");
form.addEventListener("htmx:beforeRequest", disabled(true));
form.addEventListener("htmx:afterRequest", disabled(false));

function disabled(value) {
    return () =>
        form.querySelectorAll("input, button")
            .forEach(e => e.disabled = value);
}
