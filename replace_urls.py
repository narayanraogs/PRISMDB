import os
import re

directory = 'client/lib'
pattern = re.compile(r"http://(?:127\.0\.0\.1|localhost):8085")

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()

            if "const String _baseUrl" in content and "api_service.dart" in file:
                content = content.replace("const String _baseUrl = 'http://localhost:8085';", "final String _baseUrl = Uri.base.origin;")
                with open(filepath, 'w') as f:
                    f.write(content)
                continue

            if pattern.search(content):
                # Replace with ${Uri.base.origin}
                new_content = pattern.sub("${Uri.base.origin}", content)
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")

