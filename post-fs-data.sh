#!/system/bin/sh
# The engine hooks Play Store. Play Store must not be in the Magisk denylist,
# otherwise Zygisk does not inject into it and nothing is filtered.

if magisk --denylist status 2>/dev/null; then
	magisk --denylist rm com.android.vending 2>/dev/null
fi
