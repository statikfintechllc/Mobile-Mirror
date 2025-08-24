from enum import Enum
import sys
from pathlib import Path
import argparse
from typing import Any
from modelLab import logger
import os
import shutil


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--requirements", required=True, help="List of requirements.txt file to install. Separated by ;")
    parser.add_argument("--cache_dir", required=True, help="Cache dir")
    parser.add_argument("--runtime_dir", required=True, help="Runtime dir")
    parser.add_argument("--release_url", required=True, help="Release URL")
    parser.add_argument("--uv", required=True, help="UV executable to use")
    return parser.parse_args()


class ActionType(Enum):
    COPY = "copy"
    PIP = "pip"
    UVPIP = "uvpip"
    DOWNLOAD = "download"
    NONE = "none"


class Action:
    def __init__(self, line:str):
        self.type = ActionType.NONE
        if not line.startswith("# "):
            return
        self.pre = True
        self.args = []
        if Action.isAction(line, ActionType.COPY):
            self.type = ActionType.COPY
            self.args = Action.getArgs(line, ActionType.COPY).split(";")
            self.pre = self.args[-1] == "pre"
        elif Action.isAction(line, ActionType.PIP):
            self.type = ActionType.PIP
            self.args = [Action.getArgs(line, ActionType.PIP)]
        elif Action.isAction(line, ActionType.UVPIP):
            self.type = ActionType.UVPIP
            self.args = Action.getArgs(line, ActionType.UVPIP).split(";")
            self.pre = self.args[-1] == "pre"
        elif Action.isAction(line, ActionType.DOWNLOAD):
            self.type = ActionType.DOWNLOAD
            self.args = [Action.getArgs(line, ActionType.DOWNLOAD)]
    
    def do(self, args, commands):
        if self.type == ActionType.COPY:
            Action.copy(self.args[0], self.args[1], args)
        elif self.type == ActionType.PIP:
            commands.append(self.args[0])
        elif self.type == ActionType.UVPIP:
            Action.uvpip(self.args[0], args)
        elif self.type == ActionType.DOWNLOAD:
            Action.download(self.args[0], args)

    @staticmethod
    def uvpip(cmd: str, args: Any):
        logger.info(cmd)
        commands = [args.uv, "pip"] +  cmd.split(" ") + ["-p", args.runtime_dir]

        import subprocess
        result = subprocess.run(commands, text=True)

        if result.returncode != 0:
            error = f"Failed to pip install {cmd}. Please check log."
            logger.info(error)
            #_logger.info(result.stderr)
            raise Exception(error)

    @staticmethod
    def copy(src: str, dst: str, args: Any):
        import glob

        src = os.path.join(args.cache_dir, src)
        dst = os.path.join(args.runtime_dir, dst)
        os.makedirs(dst, exist_ok=True)
        for file in glob.glob(src):
            dstFile = os.path.join(dst, os.path.basename(file))
            if Action.isFileSame(file, dstFile):
                continue
            try:
                shutil.copy(file, dst)
                logger.info(f"Copied {file} to {dst}")
            except:
                logger.info(f"Failed to copy {file} to {dst}, please fix by releasing process lock etc.")
                raise

    @staticmethod
    def isFileSame(src: str, dst: str):
        if not os.path.exists(dst):
            return False
        srcSize = os.path.getsize(src)
        dstSize = os.path.getsize(dst)
        if srcSize != dstSize:
            return False
        
        with open(src, 'rb') as file1, open(dst, 'rb') as file2:
            while True:
                chunk1 = file1.read(1024*1024)
                chunk2 = file2.read(1024*1024)

                if chunk1 != chunk2:
                    return False
                if not chunk1:  # End of both files
                    return True


    @staticmethod
    def download(name: str, args: Any):
        dst = os.path.join(args.cache_dir, name)
        if os.path.exists(dst):
            return
        url = args.release_url + name
        dst_temp = dst + ".tmp"
        if os.path.exists(dst_temp):
            os.remove(dst_temp)

        logger.info(f"Downloading from {url} to {dst}...")
        import requests
        with open(dst_temp, "wb") as f:
            response = requests.get(url, stream=True)
            if response.status_code != 200:
                raise Exception(f"Failed to download {url}")
            for chunk in response.iter_content(chunk_size=1024*100):
                f.write(chunk)
        shutil.move(dst_temp, dst)


    @staticmethod
    def isAction(line: str, type: ActionType):
        return line.startswith(f"# {type.value}:")

    @staticmethod
    def getArgs(line: str, type: ActionType):
        return line[(len(type.value) + 3):].strip()


def install_requirements(requirements_path: Path, args: Any):
    if not requirements_path.exists():
        error = f"Requirements file {requirements_path} does not exist."
        logger.info(error)
        raise Exception(error)
    
    logger.info(f"Installing dependencies from {requirements_path}...")
    # UV uses different strategy for --extra-index-url compared with pip
    commands = [args.uv, "pip", "install", "-p", args.runtime_dir, "-r", str(requirements_path), "--index-strategy", "unsafe-best-match"]
    actions: list[Action] = []
    with open(requirements_path, "r") as f:
        lines = f.readlines()
        for line in lines:
            action = Action(line)
            if action.type != ActionType.NONE:
                if action.pre:
                    action.do(args, commands)
                else:
                    actions.append(action)

    import subprocess
    result = subprocess.run(commands, text=True)
    
    if result.returncode == 0:
        for action in actions:
            action.do(args, commands)
        logger.info("Installation completed successfully.")
    else:
        error = "Failed to install dependencies. Please check log and requirements.txt file."
        logger.info(error)
        #_logger.info(result.stderr)
        raise Exception(error)
    

def main():
    args = parse_arguments()
    """
    Fail on error.
    """
    requirements = args.requirements.split(";")
    if len(requirements) == 0:
        raise Exception("No requirements provided.")
    for req in requirements:
        install_requirements(Path(req), args)


if __name__ == "__main__":
    main()
