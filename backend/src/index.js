import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import authRouter from "./routes/auth.js";
import foodsRouter from "./routes/foods.js";
import meRouter from "./routes/me.js";
import nutritionGoalsRouter from "./routes/nutritionGoals.js";
import customFoodsRouter from "./routes/customFoods.js";
import diaryEntriesRouter from "./routes/diaryEntries.js";
import waterLogsRouter from "./routes/waterLogs.js";
import weightLogsRouter from "./routes/weightLogs.js";
import { createRateLimiter } from "./middleware/rateLimit.js";

dotenv.config();

const app = express();
const port = process.env.PORT || 8787;
const host = process.env.HOST || "0.0.0.0";

app.use(cors());
app.use(express.json());
app.set("trust proxy", 1);

app.get("/health", (req, res) => {
    res.json({
        ok: true,
        service: "the-new-calories-tracker-food-api"
    });
});

app.get("/health/deep", (req, res) => {
    const checks = {
        supabase_url: Boolean(process.env.SUPABASE_URL),
        supabase_anon_key: Boolean(process.env.SUPABASE_ANON_KEY),
        supabase_service_role_key: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
        spoonacular_api_key: Boolean(process.env.SPOONACULAR_API_KEY)
    };
    const ok = Object.values(checks).every(Boolean);

    res.status(ok ? 200 : 503).json({
        ok,
        service: "the-new-calories-tracker-food-api",
        checks
    });
});

app.use(
    "/auth",
    createRateLimiter({
        keyPrefix: "auth",
        windowMS: 15 * 60 * 1000,
        maxRequests: 30
    }),
    authRouter
);
app.use(
    "/foods",
    createRateLimiter({
        keyPrefix: "foods",
        windowMS: 60 * 1000,
        maxRequests: 60,
        message: "Bạn đang tra cứu quá nhanh. Vui lòng thử lại sau."
    }),
    foodsRouter
);
app.use("/me", meRouter);
app.use("/me/nutrition-goals", nutritionGoalsRouter);
app.use("/me/custom-foods", customFoodsRouter);
app.use("/me/diary-entries", diaryEntriesRouter);
app.use("/me/water-logs", waterLogsRouter);
app.use("/me/weight-logs", weightLogsRouter);

app.listen(port, host, () => {
    console.log(`Food API proxy running on ${host}:${port}`);
});
