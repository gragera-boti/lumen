#!/bin/zsh

ASSETS_DIR="/Users/gragera/code/antigravity/lumen/Lumen/Resources/Assets.xcassets"
IMAGES_DIR="/Users/gragera/.gemini/antigravity/brain/83f47e69-46de-4ef4-83a5-3e385578a120"

# Find the newest image for each prefix
declare -A name_to_file
for file in "$IMAGES_DIR"/ai_bg_*.png; do
    # Extract the base name without the timestamp
    base=$(basename "$file")
    # Using regex to extract the prefix up to the last underscore before the timestamp
    if [[ $base =~ "^(ai_bg_[a-z_]+)_[0-9]+\.png$" ]]; then
        prefix="${match[1]}"
        name_to_file[$prefix]=$file
    fi
done

for name in "${(@k)name_to_file}"; do
    img_path=${name_to_file[$name]}
    imageset_dir="$ASSETS_DIR/$name.imageset"
    
    # Create the imageset directory
    mkdir -p "$imageset_dir"
    
    # Copy the image (it's already 1x/universal scale for this simple setup)
    cp "$img_path" "$imageset_dir/$name.png"
    
    # Create Contents.json
    cat <<EOF > "$imageset_dir/Contents.json"
{
  "images" : [
    {
      "filename" : "$name.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    echo "Added $name to Assets"
done

echo "Done"
