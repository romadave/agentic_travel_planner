import os
from dotenv import load_dotenv
from google import genai

# reads the .env file in your project and loads the values inside it into environment variables.
class GeminiClient:
    def __init__(self) -> None:
        load_dotenv()
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY is not set")
        self._client = genai.Client(api_key=api_key)
        self.default_model = "gemini-flash-latest"

    def generate_text(
        self,
        *,
        user_prompt: str,
        system_prompt: str,
        model: str | None = None,
    ) -> str:
        response = self._client.models.generate_content(
            model=model or self.default_model,
            contents=user_prompt,
            config={
                "system_instruction": system_prompt,
            },
        )
        return response.text or ""


gemini_client = GeminiClient()