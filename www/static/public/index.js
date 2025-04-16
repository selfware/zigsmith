const form = document.getElementById("input");
const input = form.getElementsByTagName("input")[0];
const button = form.getElementsByTagName("button")[0];
const results = document.getElementById("results");

form.addEventListener("submit", (e) => {
    e.preventDefault();

    setResults([
        {
            name: "pugixml",
            builds: [
                {
                    version: "1.15.0",
                    hash: "asdf",
                },
            ],
        },
    ]);
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
    // I'm not sure this is an efficient or "correct" way to do this
    while (results.firstChild) results.removeChild(results.firstChild);

    data.forEach(({ name, builds }) => {
        const result = document.createElement("div");
        result.className = "result";

        const header = document.createElement("div");
        header.className = "header";

        const nameSpan = document.createElement("span");
        nameSpan.className = "name";
        nameSpan.textContent = name;

        const versionSpan = document.createElement("span");
        versionSpan.className = "version";
        versionSpan.textContent = builds[0].version;

        const code = document.createElement("code");
        code.className = "copy";
        code.textContent = `https://dl.zigsmith.com/${name}/${builds[0].version}/${builds[0].hash}.tar.xz`;

        header.append(nameSpan, versionSpan);
        result.append(header, code);
        results.append(result);
    });
}
