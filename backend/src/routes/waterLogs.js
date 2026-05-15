import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import { handleRouteError, requiredISODate, requiredNumber, sendAPIError } from "../utils/requestValues.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    let query = supabaseAdmin
        .from("water_logs")
        .select("*")
        .eq("user_id", req.user.id)
        .order("log_date", { ascending: false });

    if (req.query.date) {
        query = query.eq("log_date", req.query.date);
    }

    const { data, error } = await query;

    if (error) {
        console.error("Water logs fetch failed:", error);
        return sendAPIError(res, 500, "server_error", "Water logs fetch failed");
    }

    res.json({
        water_logs: data
    });
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            user_id: req.user.id,
            log_date: requiredISODate(req.body.log_date, "log_date"),
            consumed_ml: requiredNumber(req.body.consumed_ml, "consumed_ml"),
            goal_ml: requiredNumber(req.body.goal_ml, "goal_ml")
        };

        const { data, error } = await supabaseAdmin
            .from("water_logs")
            .upsert(payload, { onConflict: "user_id,log_date" })
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        res.json({
            water_log: data
        });
    } catch (error) {
        handleRouteError(res, error, "Water log save failed");
    }
});

router.delete("/:id", async (req, res) => {
    const { error } = await supabaseAdmin
        .from("water_logs")
        .delete()
        .eq("id", req.params.id)
        .eq("user_id", req.user.id);

    if (error) {
        console.error("Water log delete failed:", error);
        return sendAPIError(res, 500, "server_error", "Water log delete failed");
    }

    res.json({
        ok: true
    });
});

export default router;
