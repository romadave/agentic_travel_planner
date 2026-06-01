import os
import asyncio
import logging
from dotenv import load_dotenv
from google import genai
from google.genai import types
from google.genai.errors import ServerError, ClientError

logger = logging.getLogger(__name__)

def _is_retryable(exc: Exception) -> bool:
    if isinstance(exc, ServerError):
        return True
    if isinstance(exc, ClientError) and exc.code == 429:
        return True
    return False

def _is_503(exc: Exception) -> bool:
    return isinstance(exc, ServerError) and getattr(exc, "code", None) == 503

_MAX_RETRIES = 3
_BACKOFF_BASE = 2.0


class GeminiClient:
    def __init__(self) -> None:
        load_dotenv()
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY is not set")
        self._client = genai.Client(api_key=api_key)
        self.default_model = "gemini-2.5-pro"
        self.fallback_model = "gemini-2.5-flash"

    async def generate_text(
        self,
        *,
        user_prompt: str,
        system_prompt: str,
        model: str | None = None,
        fallback_model: str | None = None,
        thinking_level: str = "medium",
    ) -> str:
        target_model = model or self.default_model
        fb_model = fallback_model if fallback_model is not None else self.fallback_model
        switched_to_fallback = False
        last_exc: Exception | None = None

        config = types.GenerateContentConfig(
            system_instruction=system_prompt,
            thinking_config=types.ThinkingConfig(thinking_level=thinking_level),
        )

        for attempt in range(_MAX_RETRIES):
            try:
                response = await asyncio.to_thread(
                    self._client.models.generate_content,
                    model=target_model,
                    contents=user_prompt,
                    config=config,
                )
                return response.text or ""
            except (ServerError, ClientError) as exc:
                if not _is_retryable(exc):
                    raise
                if _is_503(exc) and fb_model and not switched_to_fallback:
                    logger.warning(
                        "[gemini_client] 503 on %s — switching to fallback %s immediately",
                        target_model, fb_model,
                    )
                    target_model = fb_model
                    switched_to_fallback = True
                    last_exc = exc
                    continue
                last_exc = exc
                wait = _BACKOFF_BASE ** attempt
                logger.warning(
                    "[gemini_client] %s on attempt %d/%d — retrying in %.1fs",
                    type(exc).__name__, attempt + 1, _MAX_RETRIES, wait,
                )
                await asyncio.sleep(wait)

        raise last_exc


gemini_client = GeminiClient()
