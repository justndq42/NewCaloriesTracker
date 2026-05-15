import { supabaseAuth } from "../services/supabaseClient.js";
import { sendAPIError } from "../utils/requestValues.js";

export async function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization || "";
    const [scheme, token] = authHeader.split(" ");

    if (scheme !== "Bearer" || !token) {
        return sendAPIError(
            res,
            401,
            "auth_missing_token",
            "Bạn cần đăng nhập để tiếp tục."
        );
    }

    let authResult;

    try {
        authResult = await supabaseAuth.auth.getUser(token);
    } catch (error) {
        console.error("Auth token verification failed:", error);
        return sendAPIError(
            res,
            401,
            "auth_invalid_token",
            "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        );
    }

    if (authResult.error || !authResult.data?.user) {
        return sendAPIError(
            res,
            401,
            "auth_invalid_token",
            "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        );
    }

    req.user = authResult.data.user;
    next();
}
