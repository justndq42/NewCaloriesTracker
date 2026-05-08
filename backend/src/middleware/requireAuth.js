import { supabaseAuth } from "../services/supabaseClient.js";

export async function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization || "";
    const [scheme, token] = authHeader.split(" ");

    if (scheme !== "Bearer" || !token) {
        return res.status(401).json({
            error: "Missing bearer token"
        });
    }

    const { data, error } = await supabaseAuth.auth.getUser(token);

    if (error || !data.user) {
        return res.status(401).json({
            error: "Invalid bearer token"
        });
    }

    req.user = data.user;
    next();
}
