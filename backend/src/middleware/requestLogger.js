import crypto from "node:crypto";
import { logInfo } from "../utils/logger.js";

export function requestLogger(req, res, next) {
    const requestID = requestIDFrom(req) || crypto.randomUUID();
    const startedAt = Date.now();

    req.id = requestID;
    res.set("X-Request-ID", requestID);

    res.on("finish", () => {
        logInfo("http_request", {
            request_id: requestID,
            method: req.method,
            path: req.path,
            status_code: res.statusCode,
            duration_ms: Date.now() - startedAt,
            user_id: req.user?.id
        });
    });

    next();
}

function requestIDFrom(req) {
    const headerValue = req.headers["x-request-id"];

    if (typeof headerValue === "string" && headerValue.trim()) {
        return headerValue.trim().slice(0, 100);
    }

    return null;
}
