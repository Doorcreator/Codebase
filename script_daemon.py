import os, time, subprocess, datetime
from config_manager import CONFIG_MANAGER
class SCRIPT_DAEMON():
    def __init__(self):
        pass
    def mail(self, text):
        tdy = datetime.datetime.now()
        dat = tdy.strftime("%d%b%y")
        subj = f"Crontab job deployed on server failed on {dat}"
        cmd='''echo "%s" | mail -s "%s" iyhpi@sina.cn'''%(text, subj)
        subprocess.run(cmd, shell=True,  check=True, encoding="utf-8")
    def check_exe_status(self, path, app, script, count, delay):
    # To check if a script has been executed as expected, and reexecute it on any failure
    # path: log file of a script execution, presence of it indicates failure of execution
    # app: application to execute a script (/usr/bin/sh, /usr/bin/python, etc.)
    # script: script to execute (.py, .sh, etc.)
    # count: time of attempts to reexecute a script
    # delay: time to wait for before reexecuting a script
        if count < 2:
            if os.path.exists(path):
                os.remove(path)
                cmd = f'{app} {script}'
                subprocess.run(cmd, shell=True, check=True, encoding="utf-8")
                time.sleep(delay)
                count+=1
                return self.check_exe_status(path, app, script, count, delay)
            else:
                print("Script executed successfully!")
                return
        else:
            print("Max retry limit exceeded.")
            self.mail(f"Failed to execute script: {script}")
            return
path = CONFIG_MANAGER().read_ini("BOOK", "location")
path = f"{os.sep}".join([path, "log"])
SCRIPT_DAEMON().check_exe_status(path, "/usr/bin/python", "/root/nutshell/economist_recipe.py", 0, 1800)