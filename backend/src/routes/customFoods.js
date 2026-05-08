import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import { handleRouteError, requiredNumber, requiredString } from "../utils/requestValues.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    const { data, error } = await supabaseAdmin
        .from("custom_foods")
        .select("*")
        .eq("user_id", req.user.id)
        .order("created_at", { ascending: false });

    if (error) {
        console.error("Custom foods fetch failed:", error);
        return res.status(500).json({
            error: "Custom foods fetch failed"
        });
    }

    res.json({
        custom_foods: data
    });
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            ...buildCustomFoodPayload(req.body),
            user_id: req.user.id
        };

        const { data, error } = await supabaseAdmin
            .from("custom_foods")
            .insert(payload)
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        res.status(201).json({
            custom_food: data
        });
    } catch (error) {
        handleRouteError(res, error, "Custom food create failed");
    }
});

router.put("/:id", async (req, res) => {
    try {
        const payload = buildCustomFoodPayload(req.body);

        const { data, error } = await supabaseAdmin
            .from("custom_foods")
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
                error: "Custom food not found"
            });
        }

        res.json({
            custom_food: data
        });
    } catch (error) {
        handleRouteError(res, error, "Custom food update failed");
    }
});

router.delete("/:id", async (req, res) => {
    const { error } = await supabaseAdmin
        .from("custom_foods")
        .delete()
        .eq("id", req.params.id)
        .eq("user_id", req.user.id);

    if (error) {
        console.error("Custom food delete failed:", error);
        return res.status(500).json({
            error: "Custom food delete failed"
        });
    }

    res.json({
        ok: true
    });
});

function buildCustomFoodPayload(body) {
    return {
        name: requiredString(body.name, "name"),
        calories: requiredNumber(body.calories, "calories"),
        protein_g: requiredNumber(body.protein_g, "protein_g"),
        carbs_g: requiredNumber(body.carbs_g, "carbs_g"),
        fat_g: requiredNumber(body.fat_g, "fat_g"),
        unit: requiredString(body.unit, "unit")
    };
}

export default router;
