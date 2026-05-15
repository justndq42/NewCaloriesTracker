import express from "express";
import { searchSpoonacularFoods } from "../services/spoonacularService.js";
import { handleRouteError, requiredStringInRange, sendAPIError } from "../utils/requestValues.js";
import { logError } from "../utils/logger.js";

const router = express.Router();

router.get("/search", async (req, res) => {
    try {
        const query = requiredStringInRange(req.query.query, "query", { maxLength: 80 });
        const items = await searchSpoonacularFoods(query);

        return res.json({
            items
        });
    } catch (error) {
        if (error.name === "RequestValidationError") {
            return handleRouteError(res, error, "Food search failed");
        }
        logError("food_search_failed", { request_id: req.id, error });
        return sendAPIError(res, 500, "food_search_failed", "Food search failed");
    }
});

export default router;
