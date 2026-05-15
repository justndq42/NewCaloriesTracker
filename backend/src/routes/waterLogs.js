import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    handleRouteError,
    requiredIntegerInRange,
    requiredISODate,
    requiredUUID,
    sendAPIError
} from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    try {
        let query = supabaseAdmin
            .from("water_logs")
            .select("*")
            .eq("user_id", req.user.id)
            .order("log_date", { ascending: false });

        if (req.query.date) {
            query = query.eq("log_date", requiredISODate(req.query.date, "date"));
        }

        const { data, error } = await query;

        if (error) {
            logError("water_logs_fetch_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Water logs fetch failed");
        }

        return res.json({
            water_logs: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Water logs fetch failed");
    }
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            user_id: req.user.id,
            log_date: requiredISODate(req.body.log_date, "log_date"),
            consumed_ml: requiredIntegerInRange(req.body.consumed_ml, "consumed_ml", 0, 10000),
            goal_ml: requiredIntegerInRange(req.body.goal_ml, "goal_ml", 500, 10000)
        };

        const { data, error } = await supabaseAdmin
            .from("water_logs")
            .upsert(payload, { onConflict: "user_id,log_date" })
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        return res.json({
            water_log: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Water log save failed");
    }
});

router.delete("/:id", async (req, res) => {
    try {
        const id = requiredUUID(req.params.id, "id");
        const { error } = await supabaseAdmin
            .from("water_logs")
            .delete()
            .eq("id", id)
            .eq("user_id", req.user.id);

        if (error) {
            logError("water_log_delete_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Water log delete failed");
        }

        return res.json({
            ok: true
        });
    } catch (error) {
        return handleRouteError(res, error, "Water log delete failed");
    }
});

export default router;
