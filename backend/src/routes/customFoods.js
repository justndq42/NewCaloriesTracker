import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    handleRouteError,
    requiredIntegerInRange,
    requiredNumberInRange,
    requiredStringInRange,
    requiredUUID,
    sendAPIError
} from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    const { data, error } = await supabaseAdmin
        .from("custom_foods")
        .select("*")
        .eq("user_id", req.user.id)
        .order("created_at", { ascending: false });

    if (error) {
        logError("custom_foods_fetch_failed", { request_id: req.id, error });
        return sendAPIError(res, 500, "server_error", "Custom foods fetch failed");
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
            .upsert(payload, { onConflict: "user_id,client_id" })
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        return res.status(201).json({
            custom_food: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Custom food create failed");
    }
});

router.put("/:id", async (req, res) => {
    try {
        const id = requiredUUID(req.params.id, "id");
        const payload = buildCustomFoodPayload(req.body);

        const { data, error } = await supabaseAdmin
            .from("custom_foods")
            .update(payload)
            .eq("id", id)
            .eq("user_id", req.user.id)
            .select("*")
            .maybeSingle();

        if (error) {
            throw error;
        }

        if (!data) {
            return sendAPIError(res, 404, "not_found", "Custom food not found");
        }

        return res.json({
            custom_food: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Custom food update failed");
    }
});

router.delete("/:id", async (req, res) => {
    try {
        const id = requiredUUID(req.params.id, "id");
        const { error } = await supabaseAdmin
            .from("custom_foods")
            .delete()
            .eq("id", id)
            .eq("user_id", req.user.id);

        if (error) {
            logError("custom_food_delete_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Custom food delete failed");
        }

        return res.json({
            ok: true
        });
    } catch (error) {
        return handleRouteError(res, error, "Custom food delete failed");
    }
});

function buildCustomFoodPayload(body) {
    return {
        client_id: requiredStringInRange(body.client_id, "client_id", { maxLength: 128 }),
        name: requiredStringInRange(body.name, "name", { maxLength: 140 }),
        calories: requiredIntegerInRange(body.calories, "calories", 0, 10000),
        protein_g: requiredNumberInRange(body.protein_g, "protein_g", 0, 1000),
        carbs_g: requiredNumberInRange(body.carbs_g, "carbs_g", 0, 1000),
        fat_g: requiredNumberInRange(body.fat_g, "fat_g", 0, 1000),
        unit: requiredStringInRange(body.unit, "unit", { maxLength: 64 })
    };
}

export default router;
