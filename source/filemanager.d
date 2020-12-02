module filemanager;
import nspire;
import nspire.device;
import std.stdio;

int filemanagerFun(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    int error;
    
    if (args.length < 1) {
        help();
        return 1;
    }
    
    switch (args[0]) {
        case "ls" : {
            error = ls(nspire, args[1..$]);
            break;
        }
        
        case "info" : {
            error = info(nspire, args[1..$]);
            break;
        }
        
        case "cp" : {
            error = cp(nspire, deviceInfo, args[1..$]);
            break;
        }
        
        case "mv" : {
            error = mv(nspire, deviceInfo, args[1..$]);
            break;
        }
        
        case "rm" : {
            error = rm(nspire, deviceInfo, args[1..$]);
            break;
        }
        
        case "mkdir" : {
            error = mkdir(nspire, args[1..$]);
            break;
        }
        
        case "rmdir" : {
            error = rmdir(nspire, args[1..$]);
            break;
        }
        
        case "push" : {
            error = push(nspire, deviceInfo, args[1..$]);
            break;
        }
        
        case "pull" : {
            error = pull(nspire, deviceInfo, args[1..$]);
            break;
        }
        
        default : {
            help();
            return 1;
        }
    }
    
    return error;
} 

int ls(NSpire nspire, string[] args) {
    import std.datetime.systime;
    
    int error;

    if (args.length < 1) {
        args ~= "/";
    }
    
    auto dirs = nspire.dirList(args[0], error);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    foreach (dir; dirs) {
        auto name = dir.type == DirType.NSPIRE_DIR ? "\033[1m\x1B[94m" ~ dir.name ~ "\x1B[0m\033[22m" : dir.name;
        writeln(dir.size, "\t", SysTime.fromUnixTime(dir.date), "\t", name);
    }
    
    return 0;
}

int info(NSpire nspire, string[] args) {
    import std.datetime.systime;
    import std.math : pow;
    
    int error;

    if (args.length < 1) {
        help();
        return 1;
    }
    
    auto attr = nspire.getAttr(args[0], error);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    writeln("Name: ", attr.name);
    writeln("Size: ", attr.size, " bytes or ", cast(double) attr.size / pow(2, 10), " KiB");
    writeln("Date: ", SysTime.fromUnixTime(attr.date));
    writeln("Type: ", attr.type == DirType.NSPIRE_DIR ? "directory" : "file");
    
    return 0;
}

int cp(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    if (args.length < 2) {
        help();
        return 1;
    }
    
    if (!checkExtFile(deviceInfo, args[0], args[1])) {
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    auto error = nspire.copyFile(args[0], args[1]);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    return 0;
}

int mv(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    import std.algorithm.searching : endsWith;
    
    if (args.length < 2) {
        help();
        return 1;
    }
    
    if (!checkExtFile(deviceInfo, args[0], args[1])) {
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    auto error = nspire.moveFile(args[0], args[1]);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    return 0;
}

int rm(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    import std.algorithm.searching : endsWith;
    
    if (args.length < 1) {
        help();
        return 1;
    }
    
    if (!checkExtFile(deviceInfo, args[0])) {
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    auto error = nspire.deleteFile(args[0]);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    return 0;
}

int mkdir(NSpire nspire, string[] args) {
    if (args.length < 1) {
        help();
        return 1;
    }
    
    auto error = nspire.createDirectory(args[0]);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    return 0;
}

int rmdir(NSpire nspire, string[] args) {
    if (args.length < 1) {
        help();
        return 1;
    }
    
    auto error = nspire.deleteDirectory(args[0]);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    return 0;
}

int push(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    import std.algorithm.searching : endsWith;
    import std.file : read, FileException;
    
    if (args.length < 2) {
        help();
        return 1;
    }
    
    void[] fileBuf;
    
    if (!checkExtFile(deviceInfo, args[0], args[1])) {
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    try {
        fileBuf = read(args[0]);
    } catch (FileException e) {
        writeln("Error: failed file read on local side");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    auto error = nspire.writeFile(args[1], fileBuf);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    return 0;
}

int pull(NSpire nspire, DeviceInfo deviceInfo, string[] args) {
    import std.algorithm.searching : endsWith;
    import std.file : write, FileException;
    
    if (args.length < 2) {
        help();
        return 1;
    }
    
    void[] fileBuf;
    int error;
    size_t readBytes;
    
    if (!checkExtFile(deviceInfo, args[0], args[1])) {
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }

    auto attr = nspire.getAttr(args[0], error);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    fileBuf = new void[attr.size];
    
    error = nspire.readFile(args[0], fileBuf, readBytes);
    
    if (error != ErrorCodes.NSPIRE_ERR_SUCCESS) {
        writeln("Error: ", NSpire.errorStr(error));
        return error;
    }
    
    if (readBytes < attr.size) {
        writeln("033[1mWarning: the received file is smaller than expected, it may be corrupt\033[22m");
    }
    
    if (readBytes > attr.size) {
        writeln("Error: ", NSpire.errorStr(ErrorCodes.NSPIRE_ERR_NOMEM));
        return ErrorCodes.NSPIRE_ERR_NOMEM;
    }
    
    try {
        write(args[1], fileBuf);
    } catch (FileException e) {
        writeln("Error: failed file write on local side");
        return ErrorCodes.NSPIRE_ERR_INVALID;
    }
    
    return 0;
}

void help() {
    writeln("NSpire Tools - filemanager\n");
    writeln("Usage: nspire-tools filemanager [function [arguments]...]");
    writeln("\tor: nspire-filemanager [function [arguments]...]...\n");
    writeln("Currently defined functions:");
    writeln("\tls (default /)");
    writeln("\tls <path>");
    writeln("\tinfo <path>");
    writeln("\tcp <source path> <destination path>");
    writeln("\tmv <source path> <destination path>");
    writeln("\trm <path>");
    writeln("\tmkdir <path>");
    writeln("\trmdir <path>");
    writeln("\tpush <local path> <remote path>");
    writeln("\tpull <remote path> <local path>");
}

bool checkExtFile(DeviceInfo deviceInfo, string[] paths...) {
    import std.string : fromStringz;
    return checkExt(deviceInfo.fileExtensions.file.ptr.fromStringz.idup, paths);
}

bool checkExtOs(DeviceInfo deviceInfo, string[] paths...) {
    import std.string : fromStringz;
    return checkExt(deviceInfo.fileExtensions.os.ptr.fromStringz.idup, paths);
}

private bool checkExt(string ext, string[] paths...) {
    foreach (path; paths) {
        if (path.length < 4 || path[$-ext.length..$] != ext) {
            writeln("Error: files must have an ", ext, " extension");
            return false;
        }
    }
    
    return true;
}
