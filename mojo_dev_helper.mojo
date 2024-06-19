# Easy to use:

# 1. create a file that will be the config, for example:
#    /home/user/Desktop/mojo_dev_helper_config.txt

# 2. add into it the path of the git branch, for example:
#    /home/user/Documents/GitHub/mojo_branch/

# 3. build the app with -D config_path="path of the config file"
#    for example: 
#    mojo build -D config_path="/home/user/Desktop/mojo_dev_helper_config.txt" mojo_dev_helper.mojo

# 4. probably create a symlink or move the app to the bin folder
#    Alternatively, can add it to the PATH

from python import Python
from pathlib import *
from os.env import getenv
from sys import *
from os import listdir

alias config_path = param_env.env_get_string["config_path"]()

def main():
    @parameter
    if not os_is_linux():
        print("Only linux supported, modify the program if it does not work")
    
    if getenv("SHELL", "Unknown") != "/bin/bash":
        print("Only bash supported, modify the program if it does not work")

    constrained[
        config_path.find("mojo_dev_helper_config.txt") != -1,
        "config file need to be named mojo_dev_helper_config.txt"
    ]()

    var tmp_config_file = path.Path(config_path)
    if not tmp_config_file.exists():
        print(
            "🧭 config_path", config_path , "does not exist! \n",
            "ℹ️  Please create it and add to it the path of a repo.\n",
            "\tExample: /home/user/Desktop/mojo_branch"
        )
        return

    if not str(tmp_config_file).endswith(
        "mojo_dev_helper_config.txt"
    ):
        print("config file need to be named mojo_dev_helper_config.txt")
        return
    
    if str(tmp_config_file).startswith(
        "."
    ):
        print("config file cannot start with a dot `.` (no relative path)")
        return
    
    var config: String = ""
    if tmp_config_file.is_file(): 
        config = tmp_config_file.read_text()
    else:
        print("🧭 config_path", config_path , "is not a file!")
        return

    var tmp = config.split("\n")
    var repo = path.Path(tmp[0])
    description(repo) # This is the overview (version,..)

    args = argv()
    if len(args)>1:
        # we cannot change the env, so the app output the command to use.
        if args[1] == "use_branch" or args[1] == "use_mojo":
            print("🔮 Command to use:")
            if args[1] == "use_branch":
                if repo.exists() and repo.is_dir() and (repo/"build").exists():
                    print(
                        "export MODULAR_MOJO_NIGHTLY_IMPORT_PATH=" + str(repo/"build")
                    )
            else:
                print("unset MODULAR_MOJO_NIGHTLY_IMPORT_PATH")
            print(
                "ℹ️  That command was not executed, it is there for help  "
            )
        
        if args[1] == "run_tests":
            var val = Command(str(repo/"stdlib"/"scripts"/"run-tests.sh"))
            print(val)
        
        if args[1] == "build":
            var val = repo/"stdlib"/"scripts"/"build-stdlib.sh"
            if val.exists(): 
                print("🔮 Command to use:")
                print(str(val)) # Teach the command 
                print("")
                var result = Command(str(val)) # Do a build
                print(result)
    
def description(repo:Path):
    print("🔥 Mojo:", Command("mojo -v")[5:-1])
    print("🗃️  Stdlib used by this ⌨️  terminal:")
    print("\t" + getenv("MODULAR_MOJO_NIGHTLY_IMPORT_PATH", "🔥 Default"))
    print("🎛️  DEV_HELPER_CONFIG:")
    print("\t⚙️  Config file:", config_path)
    print("\t📁 Git path:",str(repo))
    if not repo.exists():
        print("\t\t🔦 Exist:\t", Emojify(False))
    else:
        var is_fork = IsFork(repo)
        print("\t\t🚥 Is fork:\t", is_fork[1])
        if is_fork[0]:
            var version = 
                (repo/"stdlib"/"COMPATIBLE_COMPILER_VERSION").read_text()
            print("\t\t🧬 Version:\t", 
                Emojify(
                    version[:-1] in Command("mojo -v")[5:-1]
                ),
                version[:-1]
            )
    print("📚 Commands:")
    print("\tuse_branch","use_mojo","run_tests","build")


def Command(arg: String)->String:
    #Execute a bash command and returns the output
    return Python.import_module("os").popen(arg).read()

def Emojify(arg: Bool)->String:
    if arg: return "✅"
    else: return "❌"

def IsFork(repo: Path)->(Bool,String):
    var valid = True
    valid &= repo.exists()
    valid &= (repo/"stdlib"/"scripts").exists()
    valid &= (repo/"stdlib"/"COMPATIBLE_COMPILER_VERSION").exists()
    if valid:
        return (
            True,
            Emojify(repo.exists()) + " (The repo is a mojo_branch)",
        )
    else:
        return (
            False,
            Emojify(False) + str(
                " (The repo is not a mojo_branch)"
            )
        )
