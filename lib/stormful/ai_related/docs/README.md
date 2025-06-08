# AI-Related Features

This directory contains AI-powered features for Stormful.

## Thought Extraction System 🧠

The thought extraction system automatically analyzes user thoughts using OpenRouter's AI models and logs insightful responses.

### How It Works

1. **User writes a thought** in the Storm Input component
2. **Thought gets saved** as a Wind in the database
3. **AI analysis gets queued automatically** with generous rate limits (50/minute)
4. **Background worker processes** the AI request via OpenRouter
5. **AI response gets logged** with beautiful formatting

### Components

- **`OpenRouterClient`** - Secure API client for OpenRouter
- **`ThoughtExtractionHelper`** - High-level helper for queuing thought analysis
- **Queue Integration** - Uses the existing queue system with `thought_extraction` task type
- **Worker Processing** - Handles AI requests in the background

### Configuration

Set your OpenRouter API key:
```bash
export OPENROUTER_API_KEY="your-openrouter-api-key-here"
```

### Usage Examples

```elixir
# Queue immediate thought analysis
{:ok, job} = ThoughtExtractionHelper.complete_async(
  "openai/gpt-3.5-turbo",
  "I'm feeling productive today!",
  max_tokens: 150,
  temperature: 0.7,
  user_id: user.id
)

# Queue delayed analysis (5 minutes)
{:ok, job} = ThoughtExtractionHelper.complete_delayed(
  "openai/gpt-3.5-turbo",
  "Process this later",
  300, # seconds
  user_id: user.id
)

# Check job status
{:ok, status} = ThoughtExtractionHelper.get_job_status(job.id)
```

### Log Output

When a thought is processed, you'll see beautiful logs like:

```
═══════════════════════════════════════════════════════════════════
🧠 THOUGHT EXTRACTION RESULT - Job 130
═══════════════════════════════════════════════════════════════════
Original Prompt: I'm excited about building this new AI feature!

AI Response: That's wonderful! Your excitement is contagious and shows
you're passionate about innovation. Channel that energy into creating
something amazing!

Model: openai/gpt-3.5-turbo | Timestamp: 2025-06-06 21:20:54Z
═══════════════════════════════════════════════════════════════════
```

### Rate Limiting

- **50 jobs per minute** for thought extraction (generous limits)
- Can handle bursts gracefully
- Integrates with existing queue rate limiting system

### Integration Points

- **Storm Input Component** - Automatically triggers on thought creation
- **Queue System** - Uses existing background job infrastructure
- **Worker System** - Processes jobs with proper error handling
- **Health Monitoring** - Included in queue health checks

The system is designed to be non-intrusive and enhance the user experience without blocking the UI.
