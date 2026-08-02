from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from lib.email_templates import validate_email_data  # noqa: E402


CONTACTS = {
    "contact": "contact@qenterra.com",
    "support": "support@qenterra.com",
}


class EmailTemplateValidatorTests(unittest.TestCase):
    def valid_registry(self) -> dict:
        return {
            "$schema": "../schemas/email-templates.schema.json",
            "version": "1.8.0",
            "capabilities": {
                "sendsEmail": False,
                "persistsInput": False,
                "externalRequests": False,
                "marketing": False,
            },
            "fields": [
                {
                    "id": "recipientName",
                    "type": "shortText",
                    "privacy": "personal",
                    "maxLength": 80,
                    "retainAcrossTemplates": False,
                    "locales": {
                        "en": {"label": "Recipient name", "help": "Use the name from the conversation.", "example": "Alex"},
                        "ru": {"label": "Имя получателя", "help": "Используйте имя из переписки.", "example": "Алекс"},
                    },
                },
                {
                    "id": "actionUrl",
                    "type": "url",
                    "privacy": "sensitive",
                    "maxLength": 2048,
                    "retainAcrossTemplates": False,
                    "locales": {
                        "en": {"label": "Action link", "help": "Use an HTTPS link.", "example": "https://example.invalid/action"},
                        "ru": {"label": "Ссылка действия", "help": "Используйте HTTPS-ссылку.", "example": "https://example.invalid/action"},
                    },
                },
            ],
            "templates": [
                self.template("contact-received", "contact", "contact", ["recipientName"]),
                self.template("account-verify-email", "account", "support", ["recipientName", "actionUrl"]),
            ],
        }

    def template(self, identifier: str, category: str, channel: str, fields: list[str]) -> dict:
        field_refs = [{"id": field, "required": True} for field in fields]
        name = "{{recipientName}}"
        cta = None
        if "actionUrl" in fields:
            cta = {"label": "Verify email", "url": "{{actionUrl}}", "fallback": "Open this secure link:"}
        locales = {
            "en": {
                "name": "Test template",
                "summary": "A focused test template.",
                "subject": f"Update for {name}",
                "preheader": "The next step is ready.",
                "eyebrow": "QenTerra",
                "title": "Your update",
                "paragraphs": [{"text": f"Hello {name}, this message explains the result."}],
                "details": [],
                "closing": "QenTerra",
                "receipt": "You received this message after a direct request or account action.",
            },
            "ru": {
                "name": "Тестовый шаблон",
                "summary": "Сфокусированный тестовый шаблон.",
                "subject": f"Обновление для {name}",
                "preheader": "Следующий шаг готов.",
                "eyebrow": "QenTerra",
                "title": "Ваше обновление",
                "paragraphs": [{"text": f"Здравствуйте, {name}. Это письмо объясняет результат."}],
                "details": [],
                "closing": "QenTerra",
                "receipt": "Вы получили это письмо после прямого обращения или действия с аккаунтом.",
            },
        }
        if cta:
            locales["en"]["cta"] = cta
            locales["ru"]["cta"] = {
                "label": "Подтвердить почту",
                "url": "{{actionUrl}}",
                "fallback": "Откройте безопасную ссылку:",
            }
        return {
            "id": identifier,
            "category": category,
            "channel": channel,
            "risk": "security" if category == "account" else "routine",
            "allowWarmIllustration": False,
            "fields": field_refs,
            "locales": locales,
        }

    def assert_error(self, registry: dict, fragment: str) -> None:
        errors = validate_email_data(registry, "1.8.0", CONTACTS)
        self.assertTrue(any(fragment in error for error in errors), errors)

    def test_valid_miniature_registry_passes(self) -> None:
        self.assertEqual(validate_email_data(self.valid_registry(), "1.8.0", CONTACTS), [])

    def test_duplicate_template_id_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][1]["id"] = registry["templates"][0]["id"]
        self.assert_error(registry, "duplicate template id")

    def test_missing_locale_fails(self) -> None:
        registry = self.valid_registry()
        del registry["templates"][0]["locales"]["ru"]
        self.assert_error(registry, "locales must be exactly")

    def test_unknown_variable_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][0]["locales"]["en"]["subject"] = "Hello {{undeclared}}"
        self.assert_error(registry, "undeclared variable")

    def test_unused_declared_field_fails(self) -> None:
        registry = self.valid_registry()
        for locale in ("en", "ru"):
            registry["templates"][0]["locales"][locale]["subject"] = "General update"
            registry["templates"][0]["locales"][locale]["paragraphs"] = [{"text": "This message explains the result."}]
        self.assert_error(registry, "declared but unused")

    def test_swapped_channel_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][0]["channel"] = "support"
        self.assert_error(registry, "must use channel")

    def test_non_https_url_example_fails(self) -> None:
        registry = self.valid_registry()
        registry["fields"][1]["locales"]["en"]["example"] = "http://example.invalid/action"
        self.assert_error(registry, "HTTPS example")

    def test_remote_image_block_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][0]["locales"]["en"]["image"] = "https://example.invalid/nyx.png"
        self.assert_error(registry, "prohibited capability key")

    def test_marketing_category_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][0]["category"] = "marketing"
        self.assert_error(registry, "unsupported category")

    def test_persistence_capability_fails(self) -> None:
        registry = self.valid_registry()
        registry["capabilities"]["persistsInput"] = True
        self.assert_error(registry, "must remain false")

    def test_sending_endpoint_fails(self) -> None:
        registry = self.valid_registry()
        registry["sendEndpoint"] = "https://example.invalid/send"
        self.assert_error(registry, "prohibited capability key")

    def test_input_is_not_mutated(self) -> None:
        registry = self.valid_registry()
        before = copy.deepcopy(registry)
        validate_email_data(registry, "1.8.0", CONTACTS)
        self.assertEqual(registry, before)


if __name__ == "__main__":
    unittest.main()
