import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    handleRouteError,
    optionalEnum,
    optionalIntegerInRange,
    optionalNumberInRange,
    optionalString,
    sendAPIError
} from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.use(requireAuth);

router.get("/profile", async (req, res) => {
    const { data, error } = await supabaseAdmin
        .from("profiles")
        .select("*")
        .eq("user_id", req.user.id)
        .maybeSingle();

    if (error) {
        logError("profile_fetch_failed", { request_id: req.id, error });
        return sendAPIError(res, 500, "server_error", "Profile fetch failed");
    }

    res.json({
        profile: data
    });
});

router.post("/profile", async (req, res) => {
    try {
        const payload = buildProfilePayload(req.user.id, req.body);

        const { data, error } = await supabaseAdmin
            .from("profiles")
            .upsert(payload, { onConflict: "user_id" })
            .select("*")
            .single();

        if (error) {
            logError("profile_save_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Profile save failed");
        }

        return res.json({
            profile: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Profile save failed");
    }
});

function buildProfilePayload(userID, body) {
    return {
        user_id: userID,
        display_name: optionalString(body.display_name, "display_name", { maxLength: 100 }),
        gender: optionalEnum(body.gender, "gender", ["male", "female", "unspecified"], "unspecified"),
        age: optionalIntegerInRange(body.age, "age", 1, 120),
        height_cm: optionalNumberInRange(body.height_cm, "height_cm", 50, 260),
        current_weight_kg: optionalNumberInRange(body.current_weight_kg, "current_weight_kg", 20, 400),
        target_weight_kg: optionalNumberInRange(body.target_weight_kg, "target_weight_kg", 20, 400),
        goal_type: optionalEnum(body.goal_type, "goal_type", ["lose", "maintain", "gain"], "maintain"),
        activity_level: optionalEnum(
            body.activity_level,
            "activity_level",
            ["sedentary", "light", "moderate", "active", "athlete"],
            "moderate"
        )
    };
}

export default router;
