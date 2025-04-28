import { getHashes, searchPackages } from "./api.js";

const { cdnUrl } = JSON.parse(document.getElementById("config").textContent);
let searchController;

const input = document.getElementById("input");
const [search] = input.getElementsByTagName("input");
const [button] = input.getElementsByTagName("button");
let results = document.getElementById("results");

input.addEventListener("submit", async e => {
    e.preventDefault();

    if (searchController) searchController.abort();
    searchController = new AbortController();

    search.disabled = true;
    button.disabled = true;
    replaceResults(document.createElement("div"));

    try {
        const pkgs = await searchPackages(
            search.value.trim(),
            searchController.signal
        );
        if (pkgs.length == 0) {
            sendMessage("No packages found.", "warn");
            return;
        }

        pkgs.forEach((version) =>
            results.appendChild(PackageResult(version)));
    } catch (err) {
        if (err.name != "AbortError") unexpectedError(err);
    } finally {
        reset();
    }
});
search.addEventListener("input", reset);

document.addEventListener("click", async ({ target }) => {
    if (target.tagName != "CODE") return;
    await navigator.clipboard.writeText(target.textContent);
    window.getSelection().selectAllChildren(target);
});

function PackageResult({name, versions}) {
    const result = document.createElement("div");
    result.className = "result";

    const header = document.createElement("div");
    header.className = "header";

    const nameSpan = document.createElement("span");
    nameSpan.textContent = name;

    const selectors = document.createElement("div");
    selectors.className = "selectors";

    const versionSel = createSelect("version", versions.map(v => v.version));
    const hashSel = createSelect("hash", [], true);

    const code = document.createElement("code");

    selectors.append(versionSel, hashSel);
    header.append(nameSpan, selectors);
    result.append(header, code);

    async function updateHash(version) {
        hashSel.disabled = true;

        const versionObj = versions.find(v => v.version == version);
        if (versionObj.hashes)
            setOptions(hashSel, versionObj.hashes);
        else {
            setOptions(hashSel, [versionObj.latestHash]);
            try {
                const hashes = await getHashes(
                    name,
                    version,
                    searchController.signal
                );

                // this only happens if you lose sync with the db
                // so rare we'll just error
                if (hashes[0] != versionObj.latestHash)
                    throw new Error("hashes not in sync");
                hashes.shift();

                hashes.forEach(hash => hashSel.append(createOption(hash)));
            } catch (err) {
                unexpectedError(err);
            }
        }
        
        hashSel.disabled = false;
        updateCode();
    }

    function updateCode() {
        code.textContent = `https://${cdnUrl}/${hashSel.value}.tar.xz`;
    }

    versionSel.addEventListener("change", () => updateHash(versionSel.value));
    hashSel.addEventListener("change", () => updateCode());
    updateHash(versions[0].version);

    return result;
}

function createSelect(className, options = [], disabled = false) {
    const sel = document.createElement("select");
    sel.className = className;
    sel.disabled = disabled;

    sel.append(...options.map(createOption));
    return sel;
}

function setOptions(select, options) {
    select.replaceChildren(...options.map(createOption));
}

function createOption(value) {
    const opt = document.createElement("option");
    opt.textContent = value;
    return opt;
}

function reset() {
    search.disabled = false;
    button.disabled = !search.value;
}

function replaceResults(div) {
    div.id = "results";
    results.replaceWith(div);
    results = div;
}

function sendMessage(msg, level) {
    const div = document.createElement("div");
    div.classList.add(level);
    div.textContent = msg;

    replaceResults(div);
}

function unexpectedError(err) {
    console.log(err);
    sendMessage("An unexpected error occurred.", "error");
}
