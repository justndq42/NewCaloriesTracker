import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin, supabaseAuth } from "../services/supabaseClient.js";
import {
    cleanString,
    handleRouteError,
    requiredString,
    RequestValidationError,
    sendAPIError
} from "../utils/requestValues.js";

const router = express.Router();

router.post("/signup", async (req, res) => {
    try {
        const email = requiredEmail(req.body.email);
        const password = requiredPassword(req.body.password);
        const displayName = cleanString(req.body.display_name);

        const { data, error } = await supabaseAuth.auth.signUp({
            email,
            password,
            options: displayName ? { data: { display_name: displayName } } : undefined
        });

        if (error) {
            return sendAuthError(res, error, 400);
        }

        return res.status(201).json(toAuthResponse(data));
    } catch (error) {
        return handleRouteError(res, error, "Auth signup failed");
    }
});

router.post("/login", async (req, res) => {
    try {
        const email = requiredEmail(req.body.email);
        const password = requiredPassword(req.body.password);

        const { data, error } = await supabaseAuth.auth.signInWithPassword({
            email,
            password
        });

        if (error) {
            return sendAuthError(res, error, 401);
        }

        return res.json(toAuthResponse(data));
    } catch (error) {
        return handleRouteError(res, error, "Auth login failed");
    }
});

router.post("/refresh", async (req, res) => {
    try {
        const refreshToken = requiredString(req.body.refresh_token, "refresh_token");

        const { data, error } = await supabaseAuth.auth.refreshSession({
            refresh_token: refreshToken
        });

        if (error) {
            return sendAuthError(res, error, 401);
        }

        return res.json(toAuthResponse(data));
    } catch (error) {
        return handleRouteError(res, error, "Auth refresh failed");
    }
});

router.post("/password-reset", async (req, res) => {
    try {
        const email = requiredEmail(req.body.email);
        const options = passwordResetRedirectURL()
            ? { redirectTo: passwordResetRedirectURL() }
            : undefined;

        const { error } = await supabaseAuth.auth.resetPasswordForEmail(email, options);

        if (error) {
            return sendAuthError(res, error, 400);
        }

        return res.json({ ok: true });
    } catch (error) {
        return handleRouteError(res, error, "Password reset request failed");
    }
});

router.post("/password-reset/complete", async (req, res) => {
    try {
        const newPassword = requiredPassword(req.body.new_password);
        const resetIdentity = await resolvePasswordResetIdentity(req.body);

        if (!resetIdentity?.id) {
            return passwordResetLinkErrorResponse(res);
        }

        const { error } = await supabaseAdmin.auth.admin.updateUserById(resetIdentity.id, {
            password: newPassword
        });

        if (error) {
            return sendAuthError(res, error, 400);
        }

        return res.json({ ok: true });
    } catch (error) {
        return handleRouteError(res, error, "Password reset completion failed");
    }
});

router.post("/change-password", requireAuth, async (req, res) => {
    try {
        const currentPassword = requiredString(req.body.current_password, "current_password");
        const newPassword = requiredPassword(req.body.new_password);

        const passwordError = await verifyCurrentPassword(req.user.email, currentPassword);
        if (passwordError) {
            return passwordErrorResponse(res);
        }

        const { error } = await supabaseAdmin.auth.admin.updateUserById(req.user.id, {
            password: newPassword
        });

        if (error) {
            return sendAuthError(res, error, 400);
        }

        return res.json({ ok: true });
    } catch (error) {
        return handleRouteError(res, error, "Password change failed");
    }
});

router.delete("/account", requireAuth, async (req, res) => {
    try {
        const password = requiredString(req.body.password, "password");

        const passwordError = await verifyCurrentPassword(req.user.email, password);
        if (passwordError) {
            return passwordErrorResponse(res);
        }

        const { error } = await supabaseAdmin.auth.admin.deleteUser(req.user.id);

        if (error) {
            return sendAuthError(res, error, 400);
        }

        return res.json({ ok: true });
    } catch (error) {
        return handleRouteError(res, error, "Account delete failed");
    }
});

function requiredEmail(value) {
    const email = requiredString(value, "email").toLowerCase();

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new RequestValidationError("email must be valid");
    }

    return email;
}

function requiredPassword(value) {
    const password = requiredString(value, "password");

    if (password.length < 6) {
        throw new RequestValidationError("password must be at least 6 characters");
    }

    return password;
}

function passwordResetRedirectURL() {
    return cleanString(process.env.PASSWORD_RESET_REDIRECT_URL);
}

async function resolvePasswordResetIdentity(body) {
    const accessToken = cleanString(body.access_token);
    const code = cleanString(body.code);

    if (accessToken) {
        const { data, error } = await supabaseAuth.auth.getUser(accessToken);
        if (error) {
            return null;
        }

        return data.user;
    }

    if (code) {
        const { data, error } = await supabaseAuth.auth.exchangeCodeForSession(code);
        if (error) {
            return null;
        }

        return data.user;
    }

    return null;
}

async function verifyCurrentPassword(email, password) {
    if (!email) {
        return new Error("Missing account email");
    }

    const { error } = await supabaseAuth.auth.signInWithPassword({
        email,
        password
    });

    return error;
}

function passwordErrorResponse(res) {
    return sendAPIError(
        res,
        401,
        "auth_invalid_password",
        "Mật khẩu hiện tại không chính xác."
    );
}

function passwordResetLinkErrorResponse(res) {
    return sendAPIError(
        res,
        401,
        "auth_invalid_reset_link",
        "Link đặt lại mật khẩu không hợp lệ hoặc đã hết hạn."
    );
}

function toAuthResponse(data) {
    return {
        user: data.user ? toUser(data.user) : null,
        session: data.session ? toSession(data.session) : null,
        requires_email_confirmation: !data.session
    };
}

function toUser(user) {
    return {
        id: user.id,
        email: user.email,
        display_name: user.user_metadata?.display_name ?? ""
    };
}

function toSession(session) {
    return {
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        expires_at: session.expires_at,
        expires_in: session.expires_in,
        token_type: session.token_type
    };
}

function sendAuthError(res, error, fallbackStatus) {
    const message = error.message ?? "";
    const normalizedMessage = message.toLowerCase();

    if (normalizedMessage.includes("already registered")) {
        return sendAPIError(
            res,
            409,
            "auth_email_registered",
            "Email này đã được đăng ký. Hãy chuyển sang đăng nhập hoặc dùng email khác."
        );
    }

    if (normalizedMessage.includes("email not confirmed")) {
        return sendAPIError(
            res,
            401,
            "auth_email_unconfirmed",
            "Email chưa được xác nhận. Vui lòng kiểm tra hộp thư trước khi đăng nhập."
        );
    }

    if (normalizedMessage.includes("invalid login credentials")) {
        return sendAPIError(
            res,
            401,
            "auth_invalid_credentials",
            "Email hoặc mật khẩu không chính xác."
        );
    }

    return sendAPIError(
        res,
        fallbackStatus,
        "auth_failed",
        message || "Xác thực thất bại. Vui lòng thử lại."
    );
}

export default router;
