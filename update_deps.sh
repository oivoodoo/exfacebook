#!/bin/bash

# Script to update exfacebook dependencies to latest versions
# Run this when you have network access to hex.pm

echo "🔄 Updating exfacebook dependencies..."

# Remove old lock file to force fresh resolution
echo "📦 Removing old mix.lock..."
rm -f mix.lock

# Update dependencies
echo "⬆️ Getting latest dependencies..."
mix deps.get

# Compile project
echo "🔨 Compiling project..."
mix compile

# Run tests
echo "🧪 Running tests..."
mix test

echo "✅ Dependency update complete!"