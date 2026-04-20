"""Unit tests for cpex_test_plugin.plugin."""

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import SimpleNamespace

import pytest

PLUGIN_PATH = Path(__file__).resolve().parents[1] / "cpex_test_plugin" / "plugin.py"
PLUGIN_SPEC = spec_from_file_location("plugin_under_test", PLUGIN_PATH)
assert PLUGIN_SPEC is not None
assert PLUGIN_SPEC.loader is not None
PLUGIN_MODULE = module_from_spec(PLUGIN_SPEC)
PLUGIN_SPEC.loader.exec_module(PLUGIN_MODULE)

PluginClass = PLUGIN_MODULE.TestPlugin


@pytest.fixture
def plugin():
    """Create a plugin instance with a minimal config stub."""
    return PluginClass(config=SimpleNamespace())


@pytest.fixture
def context():
    """Create a minimal context stub."""
    return SimpleNamespace()


@pytest.mark.parametrize(
    ("method_name", "payload", "log_message"),
    [
        ("prompt_pre_fetch", SimpleNamespace(), "TestPlugin: prompt_pre_fetch"),
        ("prompt_post_fetch", SimpleNamespace(), "TestPlugin: prompt_post_fetch"),
        ("tool_pre_invoke", SimpleNamespace(), "TestPlugin: tool_pre_invoke"),
        ("tool_post_invoke", SimpleNamespace(), "TestPlugin: tool_post_invoke"),
        ("resource_pre_fetch", SimpleNamespace(), "TestPlugin: resource_pre_fetch"),
        ("resource_post_fetch", SimpleNamespace(), "TestPlugin: resource_post_fetch"),
        ("agent_pre_invoke", SimpleNamespace(), "TestPlugin: agent_pre_invoke"),
        ("agent_post_invoke", SimpleNamespace(), "TestPlugin: agent_post_invoke"),
    ],
)
async def test_hook_returns_continue_processing_and_logs(plugin, context, method_name, payload, log_message, caplog):
    """Each hook should log and allow processing to continue."""
    with caplog.at_level("INFO"):
        result = await getattr(plugin, method_name)(payload, context)

    assert result.continue_processing is True
    assert log_message in caplog.text

# Made with Bob
