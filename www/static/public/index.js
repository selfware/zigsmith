const form = document.getElementById("input");
const input = form.getElementsByTagName("input")[0];
const button = form.getElementsByTagName("button")[0];
const results = document.getElementById("results");

form.addEventListener("submit", (e) => {
  e.preventDefault();
});
input.addEventListener(
  "input",
  ({ target }) => (button.disabled = !target.value),
);

document.addEventListener("click", async ({ target }) => {
  if (target.classList.contains("copy")) {
    await navigator.clipboard.writeText(target.textContent);
    window.getSelection().selectAllChildren(target);
  }
});

function setResults(data) {
  data.forEach(({ name, latest }) => {
    const result = document.createElement("div");
    result.className = "result";

    const header = document.createElement("div");
    header.className = "header";

    const nameSpan = document.createElement("span");
    nameSpan.className = "name";
    nameSpan.textContent = name;

    const versionSpan = document.createElement("span");
    versionSpan.className = "version";
    versionSpan.textContent = latest.version;

    const code = document.createElement("code");
    code.className = "copy";
    code.textContent = `https://dl.zigsmith.com/${name}/${latest.version}/${latest.hash}.tar.xz`;

    header.append(nameSpan, versionSpan);
    result.append(header, code);
    results.append(result);
  });
}
