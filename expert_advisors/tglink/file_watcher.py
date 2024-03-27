import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from datetime import date
import shutil

today = str(date.today())
datestring = today.replace("-","")

#brokers = ["Traders Global MetaTrader 4 Terminal"]
mt4_brokers = ["Eightcap MetaTrader 4", "Traders Global MetaTrader 4 Terminal"]
mt5_brokers = ["EightCap MetaTrader 5"]
#sourceStr = f"C:\\Program Files (x86)\\MetaTrader 4 IC Markets\\MQL4\\Files\\trades\\{datestring}.txt"

sourceDir = ""
sourceStr = ""


#event handler: handles event changes
if __name__ == "__main__":
	print(f"Today: {datestring}")
	#init comments here 
	sourceDir = "."
	sourceFile = input("Source Filename: ")

	sourceStr = f"{sourceDir}\\{sourceFile}"

	print(f"Source: {sourceStr}")
	for broker in mt4_brokers: 
		targetStr = f"C:\\Program Files (x86)\\{broker}\\MQL4\\Experts\\{sourceFile}"
		print(f"MT4 Brokers: {broker}")

	for mt5 in mt5_brokers:
		targetStr_mt5 = f"C:\\Program Files\\{mt5}\\MQL5\\Experts\\{sourceFile}"
		print(f"MT5 Brokers: {mt5}")

	patterns = ["*"]
	ignore_patterns = None
	ignore_directories = False
	case_sensitive = True
	my_event_handler = PatternMatchingEventHandler(patterns, ignore_patterns, ignore_directories, case_sensitive)


def on_created(event):
	if datestring in event.src_path:
		##trigger copy to different directories here
		print(f"Trade File has been created. {event.src_path}")
		copyFile();
		
		
	else: 
		print(f"New File")

def on_deleted(event):
	print(f"File deleted. {event.src_path}")

def on_modified(event):
	if event.src_path == sourceStr:
		print(f"File modified. {event.src_path}")
		copyFile();

def on_moved(event):
	print(f"File moved. {event.src_path}")

def copyFile():
	
	for broker in mt4_brokers:
		targetStr = f"C:\\Program Files (x86)\\{broker}\\MQL4\\Experts\\{sourceFile}"
		shutil.copyfile(sourceStr, targetStr)
		print(f"File Copied To {targetStr}")

	for mt5 in mt5_brokers:
		targetStr_mt5 = f"C:\\Program Files\\{mt5}\\MQL5\\Experts\\{sourceFile}"
		shutil.copyfile(sourceStr, targetStr_mt5)
		print(f"File Copied To {targetStr_mt5}")


my_event_handler.on_created = on_created
my_event_handler.on_deleted = on_deleted
my_event_handler.on_modified = on_modified
my_event_handler.on_moved = on_moved

#observer: monitors filesystem for changes to be handled by the event handler
#directory to monitor
path = sourceDir
go_recursively = True
my_observer = Observer()
my_observer.schedule(my_event_handler, path, recursive = go_recursively)

#start the observer thread

my_observer.start()
try: 
	while True:
		time.sleep(1)
except KeyboardInterrupt:
	my_observer.stop()
	my_observer.join()