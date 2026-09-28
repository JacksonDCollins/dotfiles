.pragma library

// Numbers are logical pixels; percentages use the smaller monitor dimension.
function calculateValue(path, input, screen, positive) {
    const minimum = positive ? 1 : 0;
    const error = `desktop.json: ${path} must be a ${positive ? "positive" : "non-negative"} integer or percentage`;
    if (typeof input === "string" && /^\d+(\.\d+)?%$/.test(input)) {
        const percent = Number(input.slice(0, -1));
        if (!screen || !(screen.width > 0) || !(screen.height > 0))
            throw new Error(`desktop.json: ${path} needs a screen for percentage sizing`);
        if (!Number.isFinite(percent) || (positive && percent <= 0))
            throw new Error(error);
        input = Math.max(minimum, Math.round(Math.min(screen.width, screen.height) * percent / 100));
    } else if (typeof input === "string" && /^\d+$/.test(input)) {
        input = Number(input);
    }
    if (!Number.isInteger(input) || input < minimum || input > 2147483647)
        throw new Error(error);
    return input;
}

// Only dimension sections enter here, never colors or arbitrary config strings.
function resolveDimensions(path, input, screen) {
    if (!input || typeof input !== "object" || Array.isArray(input))
        throw new Error(`desktop.json: ${path} must be an object`);
    const resolved = {};
    for (const key of Object.keys(input)) {
        const value = input[key];
        const field = path + "." + key;
        resolved[key] = value && typeof value === "object" && !Array.isArray(value)
            ? resolveDimensions(field, value, screen)
            : calculateValue(field, value, screen, false);
    }
    return resolved;
}
