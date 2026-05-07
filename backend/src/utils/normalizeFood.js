export function normalizeSpoonacularFood(recipe) {
    const nutrients = recipe?.nutrition?.nutrients || [];

    const calories = nutrientValue(nutrients, "Calories");
    const protein = nutrientValue(nutrients, "Protein");
    const carbs = nutrientValue(nutrients, "Carbohydrates");
    const fat = nutrientValue(nutrients, "Fat");

    if (!recipe?.title || calories <= 0) {
        return null;
    }

    return {
        name: recipe.title,
        calories: Math.round(calories),
        protein,
        carbs,
        fat,
        unit: "1 serving",
        source: "spoonacular"
    };
}

function nutrientValue(nutrients, name) {
    const nutrient = nutrients.find((item) => item.name === name);
    return Number(nutrient?.amount || 0);
}
