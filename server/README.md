Simple Imageapp server backed by PostgreSQL

Run locally for development (Node.js required):

Install dependencies:

```bash
cd server
npm install
```

Create a PostgreSQL database for the server.

Example using the default values:

```bash
createdb imageapp
```

Optionally, create a `.env` file in `server/` with your database connection details:

```bash
cp .env.example .env
```

Start the server:

```bash
npm start
```

By default the server listens on port 3000. It exposes two endpoints:

- `GET /api/favorites` -> { favorites: [1,2,3] }
- `POST /api/favorites` -> accepts { favorites: [1,2,3] } and persists to Postgres

When running the Flutter app on Android emulator, use `10.0.2.2:3000` as the host.
