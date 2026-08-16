this is a high grade mega ai platform which is capable of completion in any situation it may be faced with

## What this project is

`mega-ai` is a Next.js AI chatbot app built with the Vercel AI SDK. It includes:

- Auth flows (register/login plus guest fallback)
- Streaming chat with model/tool integration
- Postgres persistence via Drizzle ORM migrations
- Redis-backed resumable streams
- Artifact/document workflows (text, code, image, and sheet)
- Blob upload support for attachments

## Prerequisites

- Node.js 20+
- pnpm 9+
- Docker (with Docker Compose)

## Local development (one-command setup)

1. Install dependencies:

   ```bash
   pnpm install
   ```

2. Create local env vars:

   ```bash
   cp .env.example .env.local
   ```

   Default local values (already in `.env.example`):

   ```env
   POSTGRES_URL=postgresql://postgres:localdev@localhost:5432/mega_ai
   REDIS_URL=redis://localhost:6379
   ```

   Fill in required placeholders for:
   - `AUTH_SECRET`
   - `AI_GATEWAY_API_KEY`
   - `BLOB_READ_WRITE_TOKEN`

3. Bootstrap local infrastructure + migrations:

   ```bash
   pnpm dev:setup
   ```

4. Start the app:

   ```bash
   pnpm dev
   ```

5. Open http://localhost:3000

### Stop local infrastructure

```bash
pnpm dev:down
```

`dev:down` stops/removes containers but keeps named volumes so Postgres/Redis data persists.
To reset local data completely, run:

    docker compose down -v
    # or (legacy Docker Compose):
    docker-compose down -v

## Database migrations and seeding

Run migrations at any time with:

```bash
pnpm db:migrate
```

This repository does not currently include a dedicated seed script. For local seed data, use one of:

- Start the app and create data through normal flows (auth/chat/artifacts)
- Use Drizzle Studio to insert records manually:

  ```bash
  pnpm db:studio
  ```

## Deploying to Vercel

1. Import this repository into Vercel.
2. Provision/connect:
   - Vercel Postgres
   - Vercel Redis
   - Vercel Blob
   - AI Gateway
3. Set environment variables in Vercel project settings:
   - `AUTH_SECRET`
   - `POSTGRES_URL`
   - `REDIS_URL`
   - `BLOB_READ_WRITE_TOKEN`
   - `AI_GATEWAY_API_KEY` (if not relying on Vercel's automatic OIDC path)
4. Deploy.

After deployment, Vercel provides service environment variables automatically once integrations are connected; keep local `.env.local` for non-Vercel development.
