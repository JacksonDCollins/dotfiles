/* exported entries, search */
// QML imports these functions; keep this file usable by the regression check too.
function shortcut(binding) {
    const parts = [];
    for (const pair of [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]) {
        if (binding.modmask & pair[0]) parts.push(pair[1]);
    }
    const names = { Return: "Enter", space: "Space", slash: "/", Comma: ",",
        Page_Up: "Page Up", Page_Down: "Page Down", "mouse:272": "Left mouse",
        "mouse:273": "Right mouse", XF86AudioRaiseVolume: "Volume Up",
        XF86AudioLowerVolume: "Volume Down", XF86AudioMute: "Mute",
        XF86AudioPlay: "Play/Pause", XF86AudioNext: "Next track", XF86AudioPrev: "Previous track" };
    parts.push(names[binding.key] || binding.key || `Keycode ${binding.keycode}`);
    return parts.join(" + ");
}

// eslint-disable-next-line no-unused-vars -- public QML script API
function entries(bindings) {
    return bindings.map(binding => ({
        shortcut: shortcut(binding),
        description: binding.description || [binding.dispatcher, binding.arg].filter(Boolean).join(" "),
        context: [binding.submap && `Submap: ${binding.submap}`,
            binding.release && "On release", binding.repeat && "Repeats"].filter(Boolean).join(" · ")
    }));
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

// eslint-disable-next-line no-unused-vars -- public QML script API
function search(items, query) {
    if (!query.trim()) return items;
    return items.map((item, index) => ({ item: item, index: index,
        rank: score(`${item.shortcut} ${item.description} ${item.context}`, query) }))
        .filter(hit => hit.rank >= 0)
        .sort((a, b) => a.rank - b.rank || a.index - b.index)
        .map(hit => hit.item);
}
