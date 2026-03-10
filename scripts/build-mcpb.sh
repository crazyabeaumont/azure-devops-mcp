#!/bin/bash
# Build the .mcpb bundle for Claude Desktop
# An mcpb file is a zip containing manifest.json, server/, node_modules/, etc.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_NAME="azure-devops-mcp.mcpb"
STAGING_DIR="$PROJECT_DIR/.mcpb-staging"

echo "==> Building MCP server..."
cd "$PROJECT_DIR"
npm run build

echo "==> Preparing staging directory..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/server"

# Copy manifest (required at bundle root)
cp manifest.json "$STAGING_DIR/"

# Copy compiled server code into server/ (matching manifest entry_point)
cp -R dist/* "$STAGING_DIR/server/"

# Copy production node_modules
echo "==> Installing production dependencies..."
cp package.json "$STAGING_DIR/"
cp package-lock.json "$STAGING_DIR/"
cd "$STAGING_DIR"
npm ci --omit=dev --ignore-scripts 2>/dev/null
rm -f package-lock.json

# Copy license
cp "$PROJECT_DIR/LICENSE.md" "$STAGING_DIR/" 2>/dev/null || true
cp "$PROJECT_DIR/README.md" "$STAGING_DIR/" 2>/dev/null || true

echo "==> Creating $BUNDLE_NAME..."
cd "$STAGING_DIR"
rm -f "$PROJECT_DIR/$BUNDLE_NAME"
zip -r "$PROJECT_DIR/$BUNDLE_NAME" . -x "*.DS_Store" > /dev/null

echo "==> Cleaning up..."
rm -rf "$STAGING_DIR"

BUNDLE_SIZE=$(du -h "$PROJECT_DIR/$BUNDLE_NAME" | cut -f1)
echo "==> Built $BUNDLE_NAME ($BUNDLE_SIZE)"
echo ""
echo "Bundle contents:"
unzip -l "$PROJECT_DIR/$BUNDLE_NAME" | tail -1
