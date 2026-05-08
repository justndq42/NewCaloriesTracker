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

dotenv.config();

const app = express();
const port = process.env.PORT || 8787;
const host = process.env.HOST || "0.0.0.0";

app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => {
    res.json({
        ok: true,
        service: "the-new-calories-tracker-food-api"
    });
});

app.use("/auth", authRouter);
app.use("/foods", foodsRouter);
app.use("/me", meRouter);
app.use("/me/nutrition-goals", nutritionGoalsRouter);
app.use("/me/custom-foods", customFoodsRouter);
app.use("/me/diary-entries", diaryEntriesRouter);
app.use("/me/water-logs", waterLogsRouter);
app.use("/me/weight-logs", weightLogsRouter);

app.listen(port, host, () => {
    console.log(`Food API proxy running on ${host}:${port}`);
});
