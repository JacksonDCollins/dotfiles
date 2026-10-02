function entries(clips) {
  return clips.map((clip) => {
    // ponytail: 0.7 exposes types through preview markers, not authoritative MIME metadata.
    const image = /^\[\[ binary data (.+?) (png|jpe?g|gif|webp|bmp|tiff?|ico) (\d+)x(\d+) \]\]$/i.exec(clip.preview);
    const binary = clip.preview.startsWith("[[ binary data ");
    const format = image ? image[2].toLowerCase().replace("jpg", "jpeg").replace(/^tif$/, "tiff") : "";
    let kind = binary ? "binary" : "text";
    let details = binary ? "Binary data" : "Text";
    if (image) {
      kind = "image";
      details = format.toUpperCase() + " · " + image[3] + "×" + image[4] + " · " + image[1];
    }
    return { id: clip.id, preview: clip.preview, kind: kind, format: format, details: details };
  });
}

function search(items, query) {
  if (!query.trim()) return items;
  return items
    .map((item, index) => ({
      item: item,
      index: index,
      rank: score(item.preview, query),
    }))
    .filter((hit) => hit.rank >= 0)
    .sort((a, b) => a.rank - b.rank || a.index - b.index)
    .map((hit) => hit.item);
}

function score(text, query) {
  const normalized = text.toLowerCase();
  const words = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
  let total = 0;
  for (const word of words) {
    let previous = -1;
    for (const letter of word) {
      const index = normalized.indexOf(letter, previous + 1);
      if (index < 0) return -1;
      total += index - previous - 1;
      previous = index;
    }
  }
  return total;
}
