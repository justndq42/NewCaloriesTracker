import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    cleanString,
    handleRouteError,
    optionalDateString,
    requiredDateString,
    requiredEnum,
    requiredIntegerInRange,
    requiredNumberInRange,
    requiredStringInRange,
    requiredUUID,
    RequestValidationError,
    sendAPIError
} from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    try {
        let query = supabaseAdmin
            .from("diary_entries")
            .select("*")
            .eq("user_id", req.user.id)
            .order("eaten_at", { ascending: false });

        const from = optionalDateString(req.query.from, "from");
        const to = optionalDateString(req.query.to, "to");

        if (from) {
            query = query.gte("eaten_at", from);
        }

        if (to) {
            query = query.lte("eaten_at", to);
        }

        const { data, error } = await query;

        if (error) {
            logError("diary_entries_fetch_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Diary entries fetch failed");
        }

        return res.json({
            diary_entries: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Diary entries fetch failed");
    }
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            ...buildDiaryEntryPayload(req.body),
            user_id: req.user.id
        };
        await assertCustomFoodBelongsToUser(payload.custom_food_id, req.user.id);

        const { data, error } = await supabaseAdmin
            .from("diary_entries")
            .upsert(payload, { onConflict: "user_id,client_id" })
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        return res.status(201).json({
            diary_entry: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Diary entry create failed");
    }
});

router.put("/:id", async (req, res) => {
    try {
        const payload = buildDiaryEntryPayload(req.body);
        const id = requiredUUID(req.params.id, "id");
        await assertCustomFoodBelongsToUser(payload.custom_food_id, req.user.id);

        const { data, error } = await supabaseAdmin
            .from("diary_entries")
            .update(payload)
            .eq("id", id)
            .eq("user_id", req.user.id)
            .select("*")
            .maybeSingle();

        if (error) {
            throw error;
        }

        if (!data) {
            return sendAPIError(res, 404, "not_found", "Diary entry not found");
        }

        return res.json({
            diary_entry: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Diary entry update failed");
    }
});

router.delete("/:id", async (req, res) => {
    try {
        const id = requiredUUID(req.params.id, "id");
        const { error } = await supabaseAdmin
            .from("diary_entries")
            .delete()
            .eq("id", id)
            .eq("user_id", req.user.id);

        if (error) {
            logError("diary_entry_delete_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Diary entry delete failed");
        }

        return res.json({
            ok: true
        });
    } catch (error) {
        return handleRouteError(res, error, "Diary entry delete failed");
    }
});

function buildDiaryEntryPayload(body) {
    const customFoodID = cleanString(body.custom_food_id);

    return {
        client_id: requiredStringInRange(body.client_id, "client_id", { maxLength: 128 }),
        custom_food_id: customFoodID ? requiredUUID(customFoodID, "custom_food_id") : null,
        food_name: requiredStringInRange(body.food_name, "food_name", { maxLength: 140 }),
        calories: requiredIntegerInRange(body.calories, "calories", 0, 10000),
        protein_g: requiredNumberInRange(body.protein_g, "protein_g", 0, 1000),
        carbs_g: requiredNumberInRange(body.carbs_g, "carbs_g", 0, 1000),
        fat_g: requiredNumberInRange(body.fat_g, "fat_g", 0, 1000),
        unit: requiredStringInRange(body.unit, "unit", { maxLength: 64 }),
        meal: requiredEnum(body.meal, "meal", ["Sáng", "Trưa", "Snack", "Tối"]),
        eaten_at: requiredDateString(body.eaten_at, "eaten_at")
    };
}

async function assertCustomFoodBelongsToUser(customFoodID, userID) {
    if (!customFoodID) {
        return;
    }

    const { data, error } = await supabaseAdmin
        .from("custom_foods")
        .select("id")
        .eq("id", customFoodID)
        .eq("user_id", userID)
        .maybeSingle();

    if (error) {
        throw error;
    }

    if (!data) {
        throw new RequestValidationError(
            "custom_food_id does not belong to the current user",
            "invalid_custom_food"
        );
    }
}

export default router;
