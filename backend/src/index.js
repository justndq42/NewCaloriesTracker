import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import foodsRouter from "./routes/foods.js";

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

app.use("/foods", foodsRouter);

app.listen(port, host, () => {
    console.log(`Food API proxy running on ${host}:${port}`);
});
