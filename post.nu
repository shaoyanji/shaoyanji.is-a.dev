# banner
tgpt --img --height 630 --width 1200 (input "prompt for image> ") | detect columns | get "pollinations.ai...".0 | 0file;
# fuzzy finder with arta
tgpt --img --provider arta --model (tgpt --help | split row "Supported models: \n" | last | split row "\n\nSupported ratios:" | first | split row ", " | input list -f) $"(input)"
| split row "Generating image with arta...\n" | last | split row "\n\nSave images?" | first | split column "Image URL: " | get column2 | input list
