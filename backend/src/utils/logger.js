export function logInfo(event, fields = {}) {
    writeLog("info", event, fields);
}

export function logWarn(event, fields = {}) {
    writeLog("warn", event, fields);
}

export function logError(event, fields = {}) {
    writeLog("error", event, fields);
}

function writeLog(level, event, fields) {
    const payload = {
        level,
        event,
        timestamp: new Date().toISOString(),
        ...sanitizeFields(fields)
    };

    const line = JSON.stringify(payload);
    if (level === "error") {
        console.error(line);
    } else if (level === "warn") {
        console.warn(line);
    } else {
        console.log(line);
    }
}

function sanitizeFields(fields) {
    return Object.fromEntries(
        Object.entries(fields).map(([key, value]) => [key, sanitizeValue(key, value)])
    );
}

function sanitizeValue(key, value) {
    const normalizedKey = key.toLowerCase();
    if (
        normalizedKey.includes("token") ||
        normalizedKey.includes("password") ||
        normalizedKey.includes("secret") ||
        normalizedKey.includes("apikey") ||
        normalizedKey.includes("api_key")
    ) {
        return "[redacted]";
    }

    if (value instanceof Error) {
        return serializeError(value);
    }

    if (Array.isArray(value)) {
        return value.map((item) => sanitizeValue(key, item));
    }

    if (value && typeof value === "object") {
        return sanitizeFields(value);
    }

    return value;
}

function serializeError(error) {
    const serialized = {
        name: error.name,
        message: error.message,
        code: error.code
    };

    if (process.env.NODE_ENV !== "production") {
        serialized.stack = error.stack;
    }

    return serialized;
}
