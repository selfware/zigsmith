export async function getCdnUrl() {
    const res = await fetch("/api/cdn");
    if (!res.ok) throw new Error(res.statusText);
    const data = await res.json();
    return data.url;
}

export async function countPackages() {
    const res = await fetch("/api/packages");
    if (!res.ok) throw new Error(res.statusText);
    const data = await res.json();
    return data.count;
}

export async function searchPackages(query, signal) {
    const res = await fetch(
        "/api/packages?" + new URLSearchParams({ q: query }),
        { signal },
    );
    if (!res.ok) throw new Error(res.statusText);
    return await res.json();
}

export async function getHashes(name, version, signal) {
   const res = await fetch(`/api/packages/${name}/${version}`, { signal });
   if (!res.ok) throw new Error(res.statusText);
   return await res.json();
}
