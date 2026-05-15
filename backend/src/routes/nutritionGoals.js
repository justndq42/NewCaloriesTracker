import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    handleRouteError,
    optionalIntegerInRange,
    requiredIntegerInRange,
    RequestValidationError,
    sendAPIError
} from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    const { data, error } = await supabaseAdmin
        .from("nutrition_goals")
        .select("*")
        .eq("user_id", req.user.id)
        .maybeSingle();

    if (error) {
        logError("nutrition_goals_fetch_failed", { request_id: req.id, error });
        return sendAPIError(res, 500, "server_error", "Nutrition goals fetch failed");
    }

    res.json({
        nutrition_goals: data
    });
});

router.post("/", async (req, res) => {
    try {
        const payload = buildNutritionGoalPayload(req.user.id, req.body);

        const { data, error } = await supabaseAdmin
            .from("nutrition_goals")
            .upsert(payload, { onConflict: "user_id" })
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        return res.json({
            nutrition_goals: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Nutrition goals save failed");
    }
});

function buildNutritionGoalPayload(userID, body) {
    const proteinPercent = requiredIntegerInRange(body.protein_percent, "protein_percent", 0, 100);
    const carbsPercent = requiredIntegerInRange(body.carbs_percent, "carbs_percent", 0, 100);
    const fatPercent = requiredIntegerInRange(body.fat_percent, "fat_percent", 0, 100);

    if (proteinPercent + carbsPercent + fatPercent !== 100) {
        throw new RequestValidationError("Macro percentages must total 100");
    }

    return {
        user_id: userID,
        target_calories: requiredIntegerInRange(body.target_calories, "target_calories", 800, 8000),
        protein_percent: proteinPercent,
        carbs_percent: carbsPercent,
        fat_percent: fatPercent,
        bmr: optionalIntegerInRange(body.bmr, "bmr", 500, 6000),
        tdee: optionalIntegerInRange(body.tdee, "tdee", 500, 8000),
        calorie_delta: optionalIntegerInRange(body.calorie_delta, "calorie_delta", -3000, 3000) ?? 0
    };
}

export default router;
