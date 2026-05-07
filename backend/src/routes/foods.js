import express from "express";
import { searchSpoonacularFoods } from "../services/spoonacularService.js";

const router = express.Router();

router.get("/search", async (req, res) => {
    const query = String(req.query.query || "").trim();

    if (!query) {
        return res.status(400).json({
            error: "Missing query"
        });
    }

    try {
        const items = await searchSpoonacularFoods(query);

        res.json({
            items
        });
    } catch (error) {
        console.error("Food search failed:", error);

        res.status(500).json({
            error: "Food search failed"
        });
    }
});

export default router;
