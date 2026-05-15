import express from "express";
import { searchSpoonacularFoods } from "../services/spoonacularService.js";
import { sendAPIError } from "../utils/requestValues.js";

const router = express.Router();

router.get("/search", async (req, res) => {
    const query = String(req.query.query || "").trim();

    if (!query) {
        return sendAPIError(res, 400, "missing_query", "Search query is required");
    }

    try {
        const items = await searchSpoonacularFoods(query);

        res.json({
            items
        });
    } catch (error) {
        console.error("Food search failed:", error);

        sendAPIError(res, 500, "food_search_failed", "Food search failed");
    }
});

export default router;
