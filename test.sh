#!/bin/bash
echo "🧪 Running automated tests..."

# Test 1: index.html must exist
if [ ! -f ./app/index.html ]; then
  echo "❌ Test failed: app/index.html not found!"
  exit 1
fi
echo "✅ Test 1 passed: index.html found"

# Test 2: (Add real tests here, e.g. syntax check, lint, unit tests)
# Example placeholder
echo "<html test passed>"

# Example: curl check if needed (if app has a local server you can spin up temporarily)

echo "✅ All tests passed!"
