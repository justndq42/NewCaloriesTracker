import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import {
    handleRouteError,
    optionalDateString,
    requiredDateString,
    requiredNumberInRange,
    requiredStringInRange,
    requiredUUID,
    sendAPIError
} from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    try {
        let query = supabaseAdmin
            .from("weight_logs")
            .select("*")
            .eq("user_id", req.user.id)
            .order("recorded_at", { ascending: false });

        const from = optionalDateString(req.query.from, "from");
        const to = optionalDateString(req.query.to, "to");

        if (from) {
            query = query.gte("recorded_at", from);
        }

        if (to) {
            query = query.lte("recorded_at", to);
        }

        const { data, error } = await query;

        if (error) {
            logError("weight_logs_fetch_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Weight logs fetch failed");
        }

        return res.json({
            weight_logs: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Weight logs fetch failed");
    }
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            user_id: req.user.id,
            client_id: requiredStringInRange(req.body.client_id, "client_id", { maxLength: 128 }),
            weight_kg: requiredNumberInRange(req.body.weight_kg, "weight_kg", 20, 400),
            recorded_at: requiredDateString(req.body.recorded_at ?? new Date().toISOString(), "recorded_at")
        };

        const { data, error } = await supabaseAdmin
            .from("weight_logs")
            .upsert(payload, { onConflict: "user_id,client_id" })
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        return res.status(201).json({
            weight_log: data
        });
    } catch (error) {
        return handleRouteError(res, error, "Weight log create failed");
    }
});

router.delete("/:id", async (req, res) => {
    try {
        const id = requiredUUID(req.params.id, "id");
        const { error } = await supabaseAdmin
            .from("weight_logs")
            .delete()
            .eq("id", id)
            .eq("user_id", req.user.id);

        if (error) {
            logError("weight_log_delete_failed", { request_id: req.id, error });
            return sendAPIError(res, 500, "server_error", "Weight log delete failed");
        }

        return res.json({
            ok: true
        });
    } catch (error) {
        return handleRouteError(res, error, "Weight log delete failed");
    }
});

export default router;
