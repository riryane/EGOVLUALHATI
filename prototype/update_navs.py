import re
import os

files = ['index.html', 'details-food.html', 'transactions.html', 'details-4ps.html', 'document-requirements.html']
dashboard_path = 'main-dashboard.html'

with open(dashboard_path, 'r', encoding='utf-8') as f:
    dashboard_html = f.read()

# Extract status bar
status_bar_match = re.search(r'(<div class="status-bar" style="padding-top: 18px;">.*?</div>\n        </div>)', dashboard_html, re.DOTALL)
new_status_bar = status_bar_match.group(1)

# Extract bottom nav
bottom_nav_match = re.search(r'(<div class="dash-bottom-nav">.*</div>\n    </div>)', dashboard_html, re.DOTALL)
new_bottom_nav = bottom_nav_match.group(1)

for file in files:
    if not os.path.exists(file):
        continue
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace status bar
    # Find old status bar
    content = re.sub(r'<div class="status-bar">.*?</div>\n        </div>', new_status_bar, content, flags=re.DOTALL)
    
    # Replace bottom nav if exists
    if '<div class="bottom-nav"' in content:
        content = re.sub(r'<div class="bottom-nav".*?</div>\n    </div>', new_bottom_nav, content, flags=re.DOTALL)
    else:
        # If it doesn't have bottom-nav, just replace the closing app-container div
        # But wait, action-bottom might be there. We can just replace the final `</div>\n    </div>`? No, the file ends with `    </div>\n</body>`
        # Let's just replace `    </div>\n</body>` with new_bottom_nav + `\n</body>`
        # Actually the dash-bottom-nav match includes the closing `</div>` of the app container.
        content = re.sub(r'    </div>\n</body>', new_bottom_nav + '\n</body>', content)

    # In details-food.html, I might have added a hidden bottom-nav earlier.
    # Let's clean up any `<div class="bottom-nav" style="display: none;"></div>` first
    content = re.sub(r'<div class="bottom-nav"[^>]*>.*?</div>\n*', '', content, flags=re.DOTALL)
    if 'dash-bottom-nav' not in content: # If not replaced above
        content = re.sub(r'    </div>\n</body>', new_bottom_nav + '\n</body>', content)
        
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print("Updated all files.")
