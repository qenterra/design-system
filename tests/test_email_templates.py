from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
sys.path.insert(0, str(ROOT / "scripts"))

from lib.email_templates import load_email_registry, validate_email_data, validate_email_registry  # noqa: E402


CONTACTS = {
    "contact": "contact@qenterra.com",
    "support": "support@qenterra.com",
}

GREETINGS = {
    "en": "Hello {{recipientName}}.",
    "ru": "Здравствуйте, {{recipientName}}.",
}


class EmailTemplateValidatorTests(unittest.TestCase):
    def test_canonical_registry_passes(self) -> None:
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertEqual(validate_email_registry(ROOT, version), [])

    def test_canonical_catalog_has_48_unique_templates(self) -> None:
        registry = load_email_registry(ROOT)
        identifiers = [template["id"] for template in registry["templates"]]
        self.assertEqual(len(identifiers), 48)
        self.assertEqual(len(set(identifiers)), 48)

    def valid_registry(self) -> dict:
        return {
            "$schema": "../schemas/email-templates.schema.json",
            "version": VERSION,
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
                    "retainAcrossTemplates": True,
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
                    "retainAcrossTemplates": True,
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
                "paragraphs": [{"text": GREETINGS["en"]}, {"text": "The message explains the next step."}],
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
                "paragraphs": [{"text": GREETINGS["ru"]}, {"text": "Письмо объясняет следующий шаг."}],
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
        errors = validate_email_data(registry, VERSION, CONTACTS)
        self.assertTrue(any(fragment in error for error in errors), errors)

    def test_valid_miniature_registry_passes(self) -> None:
        self.assertEqual(validate_email_data(self.valid_registry(), VERSION, CONTACTS), [])

    def test_duplicate_template_id_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][1]["id"] = registry["templates"][0]["id"]
        self.assert_error(registry, "duplicate template id")

    def test_missing_locale_fails(self) -> None:
        registry = self.valid_registry()
        del registry["templates"][0]["locales"]["ru"]
        self.assert_error(registry, "locales must be exactly")

    def test_repeated_outcome_in_greeting_fails(self) -> None:
        registry = self.valid_registry()
        registry["templates"][0]["locales"]["en"]["paragraphs"][0]["text"] = (
            "Hello {{recipientName}}, your update is ready."
        )
        self.assert_error(registry, "first paragraph must be the canonical greeting")

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

    def test_incompatible_retention_policy_fails(self) -> None:
        registry = self.valid_registry()
        registry["fields"][0]["retainAcrossTemplates"] = False
        self.assert_error(registry, "compatible values must remain available")

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
        validate_email_data(registry, VERSION, CONTACTS)
        self.assertEqual(registry, before)


if __name__ == "__main__":
    unittest.main()
