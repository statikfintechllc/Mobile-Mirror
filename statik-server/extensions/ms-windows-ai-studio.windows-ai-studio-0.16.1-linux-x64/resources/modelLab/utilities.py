import argparse

def zipTemplate(args):
    import os
    import zipfile
        
    with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED) as zipf:
       # Iterate over all the files in the folder
        for root, dirs, files in os.walk(args.input):
            # Exclude .git folder
            if '.git' in dirs:
                dirs.remove('.git')
            for file in files:
                # Create the full file path
                full_path = os.path.join(root, file)
                # Add file to zip
                zipf.write(full_path, os.path.relpath(full_path, args.input))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--task", required=True, help="One of zipTemplate")
    parser.add_argument("--input", type=str)
    parser.add_argument("--output", type=str)
    args = parser.parse_args()
    if args.task == "zipTemplate":
        zipTemplate(args)
