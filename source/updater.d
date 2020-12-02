module updater;

import filemanager;
import nspire;
import nspire.device;
import std.stdio;
import std.string;
import std.file;
import std.format;
import std.path;
import std.zip;

int updaterFun(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    writeln("NSpire Tools - Operating System Updater\n");
    
    if (args.length < 1) {
        writeln("Usage: nspire-tools updater <operating system image path>");
        writeln("\tor: nspire-updater <operating system image path>\n");
        return 1;
    }
    
    writeln("\033[1mWARNING: Updating your operating system may cause a permanent hard brick");
    writeln("of your TI-NSpire, always check what you are doing\033[22m");
    writeln();
    writeln();
    
    if (!checkExtOs(deviceInfo, args[0])) {
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    if (!args[0].exists || !args[0].isFile) {
        writeln(args[0], " is not a valid file");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    writeln("Update file: ", args[0].absolutePath);
    writeln("Update size: ", args[0].getSize); 
    
    void[] fileBuf;
    ZipArchive zip;
    string manifest;
    
    try {
        fileBuf = read(args[0]);
    } catch (FileException e) {
        writeln("Error: failed file read on local side");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    try {
        zip = new ZipArchive(fileBuf);
    } catch (ZipException e) {
        writeln(args[0], " is not a valid file");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    if (("manifest.txt" in zip.directory) is null) {
        writeln(args[0], " is not a valid file");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    try {
        manifest = (cast(char[]) zip.expand(zip.directory["manifest.txt"])).dup;
    } catch (ZipException e) {
        writeln(args[0], " is not a valid file");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    auto updateVersion =  manifest.splitLines[1].strip;
    auto currentVersion = format!"%u.%u.%u"(deviceInfo.versionOs.major, deviceInfo.versionOs.minor, deviceInfo.versionOs.build);
    
    writeln("Update OS version: ", updateVersion);
    writeln("Current OS version: ", currentVersion);
    
    if (updateVersion == currentVersion) {
        writeln("\033[1mWarning: you have already installed this update!\033[22m");
    }
    
    writeln();
    writeln("\033[1mDuring the update, make sure not to disconnect the USB cable and not turn off the computer!\033[22m");
    writeln("\033[1mIf you are using a laptop connected to the power supply before continue.\033[22m");
    writeln();
    write("Enter the version of the OS you want to update to confirm the start of the updater: ");
    auto checkVersion = stdin.readln.strip;
    
    if (checkVersion != updateVersion) {
        writeln("Error: Update process aborted, user check failed!");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    writeln();
    writeln("\033[1mUpdate in progress (it takes a long time)... DO NOT DISCONNECT THE USB CABLE OR TURN OFF THE COMPUTER\033[22m");
    auto error = nspire.sendOs(fileBuf);
    writeln();
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        writeln("\033[1mAn An error in the update process can have serious consequences,\033[22m");
        writeln("\033[1mAn make sure you understand what happened before taking any action\033[22m");
        
        return error;
    }
    
    writeln("\033[1mUpdate successful! Your NSpire is restarting with the OS version ", updateVersion, "\033[22m");
    return 0;
}
