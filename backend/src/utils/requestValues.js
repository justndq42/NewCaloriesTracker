export function cleanString(value) {
    return typeof value === "string" ? value.trim() : "";
}

export function requiredString(value, fieldName) {
    const cleaned = cleanString(value);

    if (!cleaned) {
        throw new RequestValidationError(`${fieldName} is required`);
    }

    return cleaned;
}

export function optionalNumber(value) {
    if (value === null || value === undefined || value === "") {
        return null;
    }

    const numberValue = Number(value);
    return Number.isFinite(numberValue) ? numberValue : null;
}

export function requiredNumber(value, fieldName) {
    const numberValue = optionalNumber(value);

    if (numberValue === null) {
        throw new RequestValidationError(`${fieldName} must be a number`);
    }

    return numberValue;
}

export function optionalDateString(value) {
    const cleaned = cleanString(value);

    if (!cleaned) {
        return null;
    }

    const date = new Date(cleaned);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function requiredDateString(value, fieldName) {
    const dateString = optionalDateString(value);

    if (!dateString) {
        throw new RequestValidationError(`${fieldName} must be a valid date`);
    }

    return dateString;
}

export function requiredISODate(value, fieldName) {
    const cleaned = cleanString(value);

    if (!/^\d{4}-\d{2}-\d{2}$/.test(cleaned)) {
        throw new RequestValidationError(`${fieldName} must use YYYY-MM-DD`);
    }

    return cleaned;
}

export function sendAPIError(res, status, code, message) {
    return res.status(status).json({
        error: {
            code,
            message
        }
    });
}

export function handleRouteError(res, error, label) {
    if (error instanceof RequestValidationError) {
        return sendAPIError(res, 400, error.code, error.message);
    }

    console.error(`${label}:`, error);
    return sendAPIError(res, 500, "server_error", label);
}

export class RequestValidationError extends Error {
    constructor(message, code = "validation_error") {
        super(message);
        this.name = "RequestValidationError";
        this.code = code;
    }
}
