import filemanager;
import updater;
import nspire;
import nspire.device;
import std.stdio;
import std.path : baseName;
import std.string : stripLeft;
import std.algorithm.searching : startsWith;

enum mainName = "nspire-tools";
enum prefix = "nspire-";

int main(string[] args) {
    auto name = args[0].baseName;

    if (name != mainName) {
        if (name.startsWith(prefix)) {
            name = name.stripLeft(prefix);
        }
        
        return call(name, args[1..$]);
    } else {
        if (args.length < 2) {
            help();
            return 1;
        }
        
        return call(args[1], args[2..$]);
    }
}

int call(string functionName, string[] args) {
    auto nspire = NSpire();
    auto error = nspire.init();
    
    if (error == ErrorCodes.NSPIRE_ERR_NODEVICE) {
        writeln("Error: Device not found, check USB connection and your user permissions");
        return error;
    }
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    scope(exit) nspire.deinit();
    
    auto deviceInfo = nspire.getDeviceInfo(error);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    switch (functionName) {
        case "filemanager" : {
            return filemanagerFun(nspire, deviceInfo, args);
        }
        
        case "updater" : {
            return updaterFun(nspire, deviceInfo, args);
        }
        
        case "info" : {
            return infoFun(nspire, deviceInfo);
        }
        
        default : {
            help();
            return 1;
        }
    }
}

int infoFun(NSpire nspire, DeviceInfo deviceInfo) {    
    writeln("NSpire Tools - Info");
    writeln();
    writeln("Device name: ", deviceInfo.deviceName);
    writeln("Hardware type: ", deviceInfo.hwType);
    writeln("Clock speed: ", deviceInfo.clockSpeed);
    writeln("Electronic Id: ", deviceInfo.electronicId);
    writeln();
    writeln("Total flash storage: ", deviceInfo.flashStorage.total);
    writeln("Available flash storage: ", deviceInfo.flashStorage.free);
    writeln();
    writeln("Total memory: ", deviceInfo.memory.total);
    writeln("Free memory: ", deviceInfo.memory.free);
    writeln();
    writeln("OS version: ", deviceInfo.versionOs.major, ".", deviceInfo.versionOs.minor, ".", deviceInfo.versionOs.build);
    writeln("BOOT2 version: ", deviceInfo.versionBoot2.major, ".", deviceInfo.versionBoot2.minor, ".", deviceInfo.versionBoot2.build);
    writeln("BOOT1 version: ", deviceInfo.versionBoot1.major, ".", deviceInfo.versionBoot1.minor, ".", deviceInfo.versionBoot1.build);
    writeln();
    writeln("Battery status: ", deviceInfo.batteryStatus);
    writeln("Charging: ", deviceInfo.isCharging ? "Yes" : "No");
    writeln();
    writeln("LCD width: ", deviceInfo.lcd.width);
    writeln("LCD height: ", deviceInfo.lcd.height);
    writeln("LCD bbp: ", deviceInfo.lcd.bbp);
    writeln("LCD sample mode: ", deviceInfo.lcd.sampleMode);
    writeln();
    writeln("File extension for file: ", deviceInfo.fileExtensions.file);
    writeln("File extension for OS: ", deviceInfo.fileExtensions.os);
    return 0;
}


void help() {
    writeln("NSpire Tools - The Swiss Army Knife for Ti-NSpire\n");
    writeln("Usage: nspire-tools [function [arguments]...]");
    writeln("\tor: nspire-function [arguments]...\n");
    writeln("Currently defined functions:");
    writeln("\tfilemanager\n\tupdater\n\tinfo");
}

void helpUpdater() {
    writeln("NSpire Tools - Updater\n");
    writeln("Usage: nspire-tools updater <operating system image path>");
    writeln("\tor: nspire-updater <operating system image path>\n");
}
