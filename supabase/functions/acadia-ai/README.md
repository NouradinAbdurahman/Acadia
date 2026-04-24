# acadia-ai Edge Function

Tool-based AI assistant for academic questions.

## Environment

Use project root env and Supabase secrets (no function-local `.env`).

Required variables:

- `NVIDIA_API_KEY`
- `NVIDIA_MODEL` (default: `meta/llama-3.1-70b-instruct`)
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## Local run

```bash
supabase functions serve acadia-ai --env-file .env
```

## Secrets (production)

```bash
supabase secrets set NVIDIA_API_KEY=your_key
supabase secrets set NVIDIA_MODEL=meta/llama-3.1-70b-instruct
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## Request body

```json
{
  "message": "Do I have tasks due tomorrow?"
}
```

## Response body

```json
{
  "reply": "You have 2 tasks due tomorrow...",
  "usedTools": ["get_tasks"]
}
```
