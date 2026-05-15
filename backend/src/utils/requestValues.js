import { logError } from "./logger.js";

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

export function optionalString(value, fieldName, { maxLength } = {}) {
    const cleaned = cleanString(value);

    if (!cleaned) {
        return "";
    }

    return validateStringLength(cleaned, fieldName, { maxLength });
}

export function requiredStringInRange(value, fieldName, { maxLength }) {
    return validateStringLength(requiredString(value, fieldName), fieldName, { maxLength });
}

export function requiredUUID(value, fieldName) {
    const cleaned = requiredString(value, fieldName);

    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(cleaned)) {
        throw new RequestValidationError(`${fieldName} must be a valid uuid`);
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

export function optionalNumberInRange(value, fieldName, min, max) {
    const numberValue = optionalNumber(value);

    if (numberValue === null) {
        return null;
    }

    return validateNumberRange(numberValue, fieldName, min, max);
}

export function requiredNumberInRange(value, fieldName, min, max) {
    return validateNumberRange(requiredNumber(value, fieldName), fieldName, min, max);
}

export function requiredIntegerInRange(value, fieldName, min, max) {
    const numberValue = requiredNumberInRange(value, fieldName, min, max);

    if (!Number.isInteger(numberValue)) {
        throw new RequestValidationError(`${fieldName} must be an integer`);
    }

    return numberValue;
}

export function optionalIntegerInRange(value, fieldName, min, max) {
    const numberValue = optionalNumberInRange(value, fieldName, min, max);

    if (numberValue === null) {
        return null;
    }

    if (!Number.isInteger(numberValue)) {
        throw new RequestValidationError(`${fieldName} must be an integer`);
    }

    return numberValue;
}

export function optionalDateString(value, fieldName = "date") {
    const cleaned = cleanString(value);

    if (!cleaned) {
        return null;
    }

    const date = new Date(cleaned);
    if (Number.isNaN(date.getTime())) {
        throw new RequestValidationError(`${fieldName} must be a valid date`);
    }

    return date.toISOString();
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

export function requiredEnum(value, fieldName, allowedValues) {
    const cleaned = requiredString(value, fieldName);

    if (!allowedValues.includes(cleaned)) {
        throw new RequestValidationError(`${fieldName} must be one of: ${allowedValues.join(", ")}`);
    }

    return cleaned;
}

export function optionalEnum(value, fieldName, allowedValues, fallback) {
    const cleaned = cleanString(value);

    if (!cleaned) {
        return fallback;
    }

    return requiredEnum(cleaned, fieldName, allowedValues);
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

    logError(label, { request_id: res.req?.id, error });
    return sendAPIError(res, 500, "server_error", label);
}

function validateStringLength(value, fieldName, { maxLength } = {}) {
    if (maxLength && value.length > maxLength) {
        throw new RequestValidationError(`${fieldName} must be ${maxLength} characters or fewer`);
    }

    return value;
}

function validateNumberRange(value, fieldName, min, max) {
    if (value < min || value > max) {
        throw new RequestValidationError(`${fieldName} must be between ${min} and ${max}`);
    }

    return value;
}

export class RequestValidationError extends Error {
    constructor(message, code = "validation_error") {
        super(message);
        this.name = "RequestValidationError";
        this.code = code;
    }
}
