#!/bin/bash
BUCKET="dev-starttech-frontend-125168806853"
echo "🔥 Nuking bucket: $BUCKET"

# 1. Delete all Object Versions
echo "Listing versions..."
aws s3api list-object-versions --bucket "$BUCKET" --output json --query 'Versions[].[Key, VersionId]' | jq -r '.[] | @tsv' | while read key version; do
    if [ -n "$key" ]; then
        echo "Deleting version: $key ($version)"
        aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version"
    fi
done

# 2. Delete all Delete Markers
echo "Listing delete markers..."
aws s3api list-object-versions --bucket "$BUCKET" --output json --query 'DeleteMarkers[].[Key, VersionId]' | jq -r '.[] | @tsv' | while read key version; do
    if [ -n "$key" ]; then
        echo "Deleting marker: $key ($version)"
        aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version"
    fi
done

echo "✅ Bucket empty."
