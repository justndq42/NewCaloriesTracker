# TheNewCaloriesTracker Food API

Small API proxy used by the iOS app to keep food-provider keys out of the app binary.

## Local Development

```bash
npm install
npm run dev
```

Health check:

```bash
curl http://localhost:8787/health
```

Food search:

```bash
curl "http://localhost:8787/foods/search?query=chicken"
```

## Environment

Copy `.env.example` to `.env` locally and fill in the real values.

```env
PORT=8787
SPOONACULAR_API_KEY=your_spoonacular_key_here
```

Do not commit `.env`.
