import { sendAPIError } from "../utils/requestValues.js";

const buckets = new Map();

export function createRateLimiter({
    keyPrefix,
    windowMS,
    maxRequests,
    message = "Bạn thao tác quá nhanh. Vui lòng thử lại sau."
}) {
    return function rateLimiter(req, res, next) {
        const now = Date.now();
        const key = `${keyPrefix}:${clientIP(req)}`;
        const bucket = currentBucket(key, now, windowMS);

        bucket.count += 1;

        if (bucket.count > maxRequests) {
            const retryAfterSeconds = Math.max(1, Math.ceil((bucket.resetAt - now) / 1000));
            res.set("Retry-After", String(retryAfterSeconds));
            return sendAPIError(res, 429, "rate_limited", message);
        }

        next();
    };
}

function currentBucket(key, now, windowMS) {
    const existingBucket = buckets.get(key);

    if (existingBucket && existingBucket.resetAt > now) {
        return existingBucket;
    }

    const bucket = {
        count: 0,
        resetAt: now + windowMS
    };

    buckets.set(key, bucket);
    return bucket;
}

function clientIP(req) {
    const forwardedFor = req.headers["x-forwarded-for"];

    if (typeof forwardedFor === "string" && forwardedFor.trim()) {
        return forwardedFor.split(",")[0].trim();
    }

    return req.ip || req.socket.remoteAddress || "unknown";
}
