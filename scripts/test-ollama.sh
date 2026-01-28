#!/bin/bash
#
# Test Ollama in Docker container
#

set -e

echo "🦇 Testing Ollama in Docker"
echo "==========================="
echo ""

# Test 1: Check if Ollama is running
echo "Test 1: Checking Ollama availability..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✓ Ollama is running"
else
    echo "✗ Ollama is not responding"
    exit 1
fi

# Test 2: List available models
echo ""
echo "Test 2: Available models..."
curl -s http://localhost:11434/api/tags | python3 -m json.tool | grep '"name"'

# Test 3: Simple generation test
echo ""
echo "Test 3: Generation test..."
RESPONSE=$(curl -s http://localhost:11434/api/generate \
    -d '{
        "model": "qwen2.5-coder:7b",
        "prompt": "Write a one-line Python function that returns \"Hello, Night Architecture!\"",
        "stream": false
    }')

echo "Response:"
echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])"

# Test 4: Devil's Advocate test
echo ""
echo "Test 4: Devil's Advocate mode..."
RESPONSE=$(curl -s http://localhost:11434/api/generate \
    -d '{
        "model": "qwen2.5-coder:7b",
        "prompt": "You are a Devil'\''s Advocate. Find 3 problems with this plan: '\''Use MongoDB for a new project'\''",
        "stream": false
    }')

echo "Devil's Advocate response:"
echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'][:500] + '...')"

echo ""
echo "✓ All tests passed!"
echo ""
