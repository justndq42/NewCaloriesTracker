import { normalizeSpoonacularFood } from "../utils/normalizeFood.js";
import { logWarn } from "../utils/logger.js";

const baseURL = "https://api.spoonacular.com";

export async function searchSpoonacularFoods(query) {
    const apiKey = process.env.SPOONACULAR_API_KEY;

    if (!apiKey) {
        logWarn("missing_spoonacular_api_key");
        return [];
    }

    const searchURL = new URL(`${baseURL}/recipes/complexSearch`);
    searchURL.searchParams.set("apiKey", apiKey);
    searchURL.searchParams.set("query", query);
    searchURL.searchParams.set("number", "10");

    const searchResponse = await fetch(searchURL);

    if (!searchResponse.ok) {
        throw new Error(`Spoonacular search failed: ${searchResponse.status}`);
    }

    const searchPayload = await searchResponse.json();
    const ids = (searchPayload.results || []).map((item) => item.id);

    if (ids.length === 0) {
        return [];
    }

    const nutritionURL = new URL(`${baseURL}/recipes/informationBulk`);
    nutritionURL.searchParams.set("apiKey", apiKey);
    nutritionURL.searchParams.set("ids", ids.join(","));
    nutritionURL.searchParams.set("includeNutrition", "true");

    const nutritionResponse = await fetch(nutritionURL);

    if (!nutritionResponse.ok) {
        throw new Error(`Spoonacular nutrition failed: ${nutritionResponse.status}`);
    }

    const recipes = await nutritionResponse.json();

    return recipes
        .map(normalizeSpoonacularFood)
        .filter(Boolean);
}
