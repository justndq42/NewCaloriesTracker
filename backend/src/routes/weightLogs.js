import express from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabaseClient.js";
import { handleRouteError, optionalDateString, requiredDateString, requiredNumber } from "../utils/requestValues.js";

const router = express.Router();

router.use(requireAuth);

router.get("/", async (req, res) => {
    let query = supabaseAdmin
        .from("weight_logs")
        .select("*")
        .eq("user_id", req.user.id)
        .order("recorded_at", { ascending: false });

    const from = optionalDateString(req.query.from);
    const to = optionalDateString(req.query.to);

    if (from) {
        query = query.gte("recorded_at", from);
    }

    if (to) {
        query = query.lte("recorded_at", to);
    }

    const { data, error } = await query;

    if (error) {
        console.error("Weight logs fetch failed:", error);
        return res.status(500).json({
            error: "Weight logs fetch failed"
        });
    }

    res.json({
        weight_logs: data
    });
});

router.post("/", async (req, res) => {
    try {
        const payload = {
            user_id: req.user.id,
            weight_kg: requiredNumber(req.body.weight_kg, "weight_kg"),
            recorded_at: requiredDateString(req.body.recorded_at ?? new Date().toISOString(), "recorded_at")
        };

        const { data, error } = await supabaseAdmin
            .from("weight_logs")
            .insert(payload)
            .select("*")
            .single();

        if (error) {
            throw error;
        }

        res.status(201).json({
            weight_log: data
        });
    } catch (error) {
        handleRouteError(res, error, "Weight log create failed");
    }
});

router.delete("/:id", async (req, res) => {
    const { error } = await supabaseAdmin
        .from("weight_logs")
        .delete()
        .eq("id", req.params.id)
        .eq("user_id", req.user.id);

    if (error) {
        console.error("Weight log delete failed:", error);
        return res.status(500).json({
            error: "Weight log delete failed"
        });
    }

    res.json({
        ok: true
    });
});

export default router;
