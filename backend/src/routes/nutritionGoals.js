import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import { handleRouteError, optionalNumber, requiredNumber, RequestValidationError } from "../utils/requestValues.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    const { data, error } = await supabaseAdmin
        .from("nutrition_goals")
        .select("*")
        .eq("user_id", req.user.id)
        .maybeSingle();

    if (error) {
        console.error("Nutrition goals fetch failed:", error);
        return res.status(500).json({
            error: "Nutrition goals fetch failed"
        });
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

        res.json({
            nutrition_goals: data
        });
    } catch (error) {
        handleRouteError(res, error, "Nutrition goals save failed");
    }
});

function buildNutritionGoalPayload(userID, body) {
    const proteinPercent = requiredNumber(body.protein_percent, "protein_percent");
    const carbsPercent = requiredNumber(body.carbs_percent, "carbs_percent");
    const fatPercent = requiredNumber(body.fat_percent, "fat_percent");

    if (proteinPercent + carbsPercent + fatPercent !== 100) {
        throw new RequestValidationError("Macro percentages must total 100");
    }

    return {
        user_id: userID,
        target_calories: requiredNumber(body.target_calories, "target_calories"),
        protein_percent: proteinPercent,
        carbs_percent: carbsPercent,
        fat_percent: fatPercent,
        bmr: optionalNumber(body.bmr),
        tdee: optionalNumber(body.tdee),
        calorie_delta: optionalNumber(body.calorie_delta) ?? 0
    };
}

export default router;
