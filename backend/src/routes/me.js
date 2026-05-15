import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import { cleanString, optionalNumber, sendAPIError } from "../utils/requestValues.js";

const router = express.Router();

router.use(requireAuth);

router.get("/profile", async (req, res) => {
    const { data, error } = await supabaseAdmin
        .from("profiles")
        .select("*")
        .eq("user_id", req.user.id)
        .maybeSingle();

    if (error) {
        console.error("Profile fetch failed:", error);
        return sendAPIError(res, 500, "server_error", "Profile fetch failed");
    }

    res.json({
        profile: data
    });
});

router.post("/profile", async (req, res) => {
    const payload = {
        user_id: req.user.id,
        display_name: cleanString(req.body.display_name),
        gender: cleanString(req.body.gender) || "unspecified",
        age: optionalNumber(req.body.age),
        height_cm: optionalNumber(req.body.height_cm),
        current_weight_kg: optionalNumber(req.body.current_weight_kg),
        target_weight_kg: optionalNumber(req.body.target_weight_kg),
        goal_type: cleanString(req.body.goal_type) || "maintain",
        activity_level: cleanString(req.body.activity_level) || "moderate"
    };

    const { data, error } = await supabaseAdmin
        .from("profiles")
        .upsert(payload, { onConflict: "user_id" })
        .select("*")
        .single();

    if (error) {
        console.error("Profile save failed:", error);
        return sendAPIError(res, 500, "server_error", "Profile save failed");
    }

    res.json({
        profile: data
    });
});

export default router;
