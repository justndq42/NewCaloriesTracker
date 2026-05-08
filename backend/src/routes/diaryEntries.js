import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    cleanString,
    handleRouteError,
    optionalDateString,
    requiredDateString,
    requiredNumber,
    requiredString
} from "../utils/requestValues.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    let query = supabaseAdmin
        .from("diary_entries")
        .select("*")
        .eq("user_id", req.user.id)
        .order("eaten_at", { ascending: false });

    const from = optionalDateString(req.query.from);
    const to = optionalDateString(req.query.to);

    if (from) {
        query = query.gte("eaten_at", from);
    }

    if (to) {
        query = query.lte("eaten_at", to);
    }

    const { data, error } = await query;

    if (error) {
        console.error("Diary entries fetch failed:", error);
        return res.status(500).json({
            error: "Diary entries fetch failed"
        });
    }

    res.json({
        diary_entries: data
    });
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            ...buildDiaryEntryPayload(req.body),
            user_id: req.user.id
        };

        const { data, error } = await supabaseAdmin
            .from("diary_entries")
            .insert(payload)
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        res.status(201).json({
            diary_entry: data
        });
    } catch (error) {
        handleRouteError(res, error, "Diary entry create failed");
    }
});

router.put("/:id", async (req, res) => {
    try {
        const payload = buildDiaryEntryPayload(req.body);

        const { data, error } = await supabaseAdmin
            .from("diary_entries")
            .update(payload)
            .eq("id", req.params.id)
            .eq("user_id", req.user.id)
            .select("*")
            .maybeSingle();

        if (error) {
            throw error;
        }

        if (!data) {
            return res.status(404).json({
                error: "Diary entry not found"
            });
        }

        res.json({
            diary_entry: data
        });
    } catch (error) {
        handleRouteError(res, error, "Diary entry update failed");
    }
});

router.delete("/:id", async (req, res) => {
    const { error } = await supabaseAdmin
        .from("diary_entries")
        .delete()
        .eq("id", req.params.id)
        .eq("user_id", req.user.id);

    if (error) {
        console.error("Diary entry delete failed:", error);
        return res.status(500).json({
            error: "Diary entry delete failed"
        });
    }

    res.json({
        ok: true
    });
});

function buildDiaryEntryPayload(body) {
    const customFoodID = cleanString(body.custom_food_id);

    return {
        custom_food_id: customFoodID || null,
        food_name: requiredString(body.food_name, "food_name"),
        calories: requiredNumber(body.calories, "calories"),
        protein_g: requiredNumber(body.protein_g, "protein_g"),
        carbs_g: requiredNumber(body.carbs_g, "carbs_g"),
        fat_g: requiredNumber(body.fat_g, "fat_g"),
        unit: requiredString(body.unit, "unit"),
        meal: requiredString(body.meal, "meal"),
        eaten_at: requiredDateString(body.eaten_at, "eaten_at")
    };
}

export default router;
