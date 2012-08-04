string_contains = (haystack, needle) -> haystack.indexOf needle != -1
agent_has = (needle) -> string_contains navigator.userAgent, needle
window.vendor_prefix = if agent_has('WebKit') then '-webkit' else ''
