import os
import json
import logging
from typing import Type, TypeVar, Optional, Any, Dict
from pydantic import BaseModel
from backend.app.core.config import settings

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)

class GeminiClient:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY")
        self._genai_client = None
        self._legacy_genai = None
        self._init_client()

    def _init_client(self):
        if not self.api_key:
            logger.warning("No GEMINI_API_KEY provided. Operating in adaptive fallback/mock mode.")
            return

        try:
            # Try Google GenAI SDK (new SDK)
            from google import genai
            self._genai_client = genai.Client(api_key=self.api_key)
            logger.info("Initialized Google GenAI SDK Client successfully.")
        except Exception as e:
            logger.warning(f"Failed to initialize google-genai: {e}. Trying google-generativeai.")
            try:
                import google.generativeai as genai_legacy
                genai_legacy.configure(api_key=self.api_key)
                self._legacy_genai = genai_legacy
                logger.info("Initialized legacy google.generativeai successfully.")
            except Exception as ex:
                logger.error(f"Failed to initialize any Gemini client: {ex}")

    def is_configured(self) -> bool:
        return bool(self.api_key and (self._genai_client or self._legacy_genai))

    async def generate_structured(
        self,
        prompt: str,
        system_instruction: str,
        response_model: Type[T],
        use_grounding: bool = False,
        fallback_data: Optional[Dict[str, Any]] = None
    ) -> T:
        """
        Generates structured response parsed directly into a Pydantic model.
        """
        if not self.is_configured():
            logger.info(f"Gemini API key not active. Returning calibrated fallback for {response_model.__name__}.")
            if fallback_data:
                return response_model.model_validate(fallback_data)
            raise ValueError("Gemini client not configured and no fallback data provided.")

        try:
            if self._genai_client:
                # Use modern google-genai SDK
                config_kwargs: Dict[str, Any] = {
                    "response_mime_type": "application/json",
                    "response_schema": response_model,
                    "system_instruction": system_instruction,
                    "temperature": 0.4,
                }
                
                # Note: Grounding can be passed via tools if enabled
                response = self._genai_client.models.generate_content(
                    model=settings.GEMINI_MODEL,
                    contents=prompt,
                    config=config_kwargs
                )
                
                # Parse output
                text_content = response.text
                parsed_json = json.loads(text_content)
                return response_model.model_validate(parsed_json)

            elif self._legacy_genai:
                model = self._legacy_genai.GenerativeModel(
                    model_name="gemini-1.5-flash",
                    system_instruction=system_instruction,
                    generation_config={"response_mime_type": "application/json"}
                )
                full_prompt = f"{prompt}\n\nStrictly output valid JSON matching this schema:\n{json.dumps(response_model.model_json_schema())}"
                response = model.generate_content(full_prompt)
                parsed_json = json.loads(response.text)
                return response_model.model_validate(parsed_json)

        except Exception as e:
            logger.error(f"Error generating structured content from Gemini: {e}")
            if fallback_data:
                logger.info("Utilizing fallback data due to API error.")
                return response_model.model_validate(fallback_data)
            raise e

    async def generate_text(
        self,
        prompt: str,
        system_instruction: Optional[str] = None,
        temperature: float = 0.7
    ) -> str:
        """
        Generates freeform text using Gemini.
        """
        if not self.is_configured():
            return "Simulated AI Response: Product analyzed and outreach generated successfully."

        try:
            if self._genai_client:
                config_kwargs = {"temperature": temperature}
                if system_instruction:
                    config_kwargs["system_instruction"] = system_instruction
                    
                response = self._genai_client.models.generate_content(
                    model=settings.GEMINI_MODEL,
                    contents=prompt,
                    config=config_kwargs
                )
                return response.text
            elif self._legacy_genai:
                model = self._legacy_genai.GenerativeModel(
                    model_name="gemini-1.5-flash",
                    system_instruction=system_instruction
                )
                response = model.generate_content(prompt)
                return response.text
        except Exception as e:
            logger.error(f"Error in generate_text: {e}")
            return f"Error communicating with Gemini: {str(e)}"

# Singleton instance
gemini_client = GeminiClient()
