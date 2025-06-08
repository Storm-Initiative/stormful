# Stormful Queue System

A modular, extensible background job processing system built on top of Elixir/Phoenix.

## Architecture Overview

The queue system has been refactored into a clean, modular architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     Queue System                           │
├─────────────────────────────────────────────────────────────┤
│ 1. Queue Context (queue.ex)                                │
│    • Job enqueueing & management                           │
│    • Rate limiting                                         │
│    • Job lifecycle                                         │
├─────────────────────────────────────────────────────────────┤
│ 2. Processor (processor.ex)                                │
│    • Polls for ready jobs                                  │
│    • Manages concurrency                                   │
│    • Handles retries & failures                           │
├─────────────────────────────────────────────────────────────┤
│ 3. Worker Dispatcher (worker.ex)                           │
│    • Routes jobs to handlers                               │
│    • Lightweight "igniter"                                 │
├─────────────────────────────────────────────────────────────┤
│ 4. Handler Registry (handler_registry.ex)                  │
│    • Auto-discovers handlers                               │
│    • Naming convention mapping                             │
│    • Custom handler registration                           │
├─────────────────────────────────────────────────────────────┤
│ 5. Job Handlers (handlers/*.ex)                            │
│    • Individual job processing logic                       │
│    • Implements JobHandler behavior                        │
│    • Complete separation of concerns                       │
└─────────────────────────────────────────────────────────────┘
```

## Key Benefits

### ✅ **Extensibility**
- Add new job types without modifying existing code
- Zero-config handler discovery
- Clean separation of concerns

### ✅ **Maintainability**
- Each job type has its own module
- Behavior-driven contracts
- Easy to test and debug

### ✅ **Flexibility**
- Support for custom handlers
- Automatic naming convention discovery
- Optional payload validation

## Adding New Job Types

### Method 1: Naming Convention (Recommended)

1. Create a handler in `lib/stormful/queue/handlers/`
2. Follow the naming pattern: `{JobType}Handler`
3. Implement the `JobHandler` behavior

```elixir
# For job type "sms"
defmodule Stormful.Queue.Handlers.SmsHandler do
  @behaviour Stormful.Queue.JobHandler

  @impl true
  def validate_payload(payload) do
    # Optional validation
    :ok
  end

  @impl true
  def handle_job(job) do
    # Your SMS sending logic here
    {:ok, %{sent_at: DateTime.utc_now()}}
  end
end
```

4. Enqueue jobs using the new type:

```elixir
Queue.enqueue_job("sms", %{
  "phone" => "+1234567890",
  "message" => "Hello from Stormful!"
})
```

**That's it!** The system automatically discovers and routes to your handler.

### Method 2: Custom Registration

For non-standard naming or external handlers:

```elixir
# Register a custom handler
HandlerRegistry.register_handler("custom_job", MyApp.CustomHandler)

# Now you can enqueue jobs of type "custom_job"
Queue.enqueue_job("custom_job", %{"data" => "value"})
```

## Built-in Handlers

### 📧 EmailHandler
- **Job Type**: `"email"`
- **Purpose**: Email delivery via Swoosh
- **Required Fields**: `["to", "subject"]`
- **Optional**: `body`, `html_body`, `attachments`, etc.

### 🤖 AiProcessingHandler
- **Job Type**: `"ai_processing"`
- **Purpose**: Generic AI processing tasks
- **Required Fields**: `["prompt"]`
- **Optional**: `model`, `max_tokens`, `temperature`

### 🧠 ThoughtExtractionHandler
- **Job Type**: `"thought_extraction"`
- **Purpose**: OpenRouter-based thought processing
- **Required Fields**: `["model", "prompt"]`
- **Optional**: `max_tokens`, `temperature`, `top_p`

### 🔗 WebhookHandler (Example)
- **Job Type**: `"webhook"`
- **Purpose**: HTTP webhook delivery
- **Required Fields**: `["url", "payload"]`
- **Optional**: `method`, `headers`, `timeout`

## JobHandler Behavior

All handlers must implement this behavior:

```elixir
@callback handle_job(job :: map()) :: {:ok, any()} | {:error, any()}
@callback validate_payload(payload :: map()) :: :ok | {:error, String.t()}
```

The `validate_payload/1` callback is optional but recommended.

## Handler Discovery

The system uses the following discovery order:

1. **Explicit Registration**: Check `HandlerRegistry` for custom handlers
2. **Naming Convention**: Convert job type to module name
   - `"email"` → `Stormful.Queue.Handlers.EmailHandler`
   - `"ai_processing"` → `Stormful.Queue.Handlers.AiProcessingHandler`
   - `"my_custom_job"` → `Stormful.Queue.Handlers.MyCustomJobHandler`

## Usage Examples

```elixir
# Email job
Queue.enqueue_email(%{
  "to" => "user@example.com",
  "subject" => "Welcome!",
  "body" => "Thanks for signing up!"
})

# AI processing
Queue.enqueue_ai_processing(%{
  "prompt" => "Analyze this text",
  "model" => "gpt-4"
})

# Thought extraction
Queue.enqueue_thought_extraction(%{
  "model" => "openai/gpt-3.5-turbo",
  "prompt" => "Extract calendar events from: Meeting tomorrow at 3pm"
})

# Custom webhook
Queue.enqueue_job("webhook", %{
  "url" => "https://api.example.com/webhook",
  "payload" => %{"event" => "user_signup", "user_id" => 123}
})
```

## Rate Limiting

The system includes built-in rate limiting per job type:

- **Email**: 100 jobs per 60 seconds
- **AI Processing**: 30 jobs per 60 seconds
- **Thought Extraction**: 50 jobs per 60 seconds

Rate limits are enforced at the queue level before jobs reach handlers.

## Monitoring & Health Checks

```elixir
# Check worker health
Worker.health_check()

# Get processing stats
Worker.get_processing_stats()

# List registered handlers
HandlerRegistry.list_handlers()

# Validate all handlers
HandlerRegistry.validate_all_handlers()
```

## Migration from Old System

The old monolithic `Worker` module has been refactored into:

- **Worker** → Lightweight dispatcher
- **Email Logic** → `Handlers.EmailHandler`
- **AI Logic** → `Handlers.AiProcessingHandler`
- **Thought Extraction** → `Handlers.ThoughtExtractionHandler`

All existing functionality is preserved, but now properly organized and extensible!

---

**🚀 The queue system is now your "igniter" - the fire (handlers) can be anywhere you want!**
