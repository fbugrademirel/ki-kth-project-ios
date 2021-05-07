//
//  Log.swift
//  ki-kth-project
//
//  Created by Faruk Buğra DEMIREL on 2021-05-05.
//

import Foundation

enum LogEvent: String {
    case e = "[ERROR]" // error
    case i = "[INFO]" // info
    case w = "[WARNING]" // warning
    case s = "[SUCCESS]" // severe
    case t = "[TEMPORARY]" // temporary
}

#if DEVELOPMENT
private var list = [Any]()
#endif

func print(_ object: Any) {
    // Only allowing in DEBUG mode
    #if DEBUG
    Swift.print(object)
    #endif

    // Only appending in DEVELOPMENT mode
    #if DEVELOPMENT
    list.append(object)
    #endif
}

/*
 Usage:
    Depending of what log event you want to use e, i, w or s.
    Log.i(message)
 */

public final class Log {
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }

    private static var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /*
     Will return a list containing all logs.
     Only possible in DEVELOPMENT
     */
    #if DEVELOPMENT
    public class func getList() -> [Any] {
        return list
    }
    #endif

    /*
     Logs info messages on console with prefix [ERROR]
     Parameters:
        - object: Object or message to be logged
        - filename: File name from where loggin to be done
        - line: Line number in file from where the logging is done
        - column: Column number of the log message
        - funcName: Name of the function from where the logging is done
     */
    public class func e( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("❌ \(LogEvent.e.rawValue) \(object) - [\(sourceFileName(filePath: filename)) - \(line)] - \(Date().toString())]")
        }
    }

    /*
     Used to diagnose chained guard/if let statements.
     The function is called on the failed line which will give us the broken condition.

     Logs info messages on console with prefix [ERROR]
     Parameters:
     - object: Object or message to be logged
     - filename: File name from where loggin to be done
     - line: Line number in file from where the logging is done
     - column: Column number of the log message
     - funcName: Name of the function from where the logging is done

     Return value is always nil
     */
    public class func diagnose<T>( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) -> T? {
        if isLoggingEnabled {
            print("❌ \(LogEvent.e.rawValue) \(object) - [\(sourceFileName(filePath: filename)) - \(line)] - \(Date().toString())]")
        }
        return nil
    }

    /*
     Logs info messages on console with prefix [INFO]
     Parameters:
     - object: Object or message to be logged
     - filename: File name from where loggin to be done
     - line: Line number in file from where the logging is done
     - column: Column number of the log message
     - funcName: Name of the function from where the logging is done
     */
    public class func i( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("ℹ️ \(LogEvent.i.rawValue) \(object) - [\(sourceFileName(filePath: filename)) - \(line)] - \(Date().toString())]")
        }
    }

    /*
     Logs info messages on console with prefix [WARNING]
     Parameters:
     - object: Object or message to be logged
     - filename: File name from where loggin to be done
     - line: Line number in file from where the logging is done
     - column: Column number of the log message
     - funcName: Name of the function from where the logging is done
     */
    public class func w( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("⚠️ \(LogEvent.w.rawValue) \(object) - [\(sourceFileName(filePath: filename)) - \(line)] - \(Date().toString())]")
        }
    }

    /*
     Logs info messages on console with prefix [SEVERE]
     Parameters:
     - object: Object or message to be logged
     - filename: File name from where loggin to be done
     - line: Line number in file from where the logging is done
     - column: Column number of the log message
     - funcName: Name of the function from where the logging is done
     */
    public class func s( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("✅ \(LogEvent.s.rawValue) \(object) - [\(sourceFileName(filePath: filename)) - \(line)] - \(Date().toString())]")
        }
    }

    /*
     Logs info messages on console with prefix [TEMPORARY]
     Parameters:
     - object: Object or message to be logged
     - filename: File name from where loggin to be done
     - line: Line number in file from where the logging is done
     - column: Column number of the log message
     - funcName: Name of the function from where the logging is done
     */
    public class func t( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("😃🔥👽🍔🍟🚑 \(LogEvent.t.rawValue) \(object) - [\(sourceFileName(filePath: filename)) - \(line)] - \(Date().toString())]")
        }
    }

    /*
     Logs info messages on console for environment selected
     Parameters:
     - object: Object or message to be logged
     - filename: File name from where loggin to be done
     - line: Line number in file from where the logging is done
     - column: Column number of the log message
     - funcName: Name of the function from where the logging is done
     */
    public class func env( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if isLoggingEnabled {
            print("🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶 \(object) - [\(sourceFileName(filePath: filename)) - \(line)] 🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶🔶")
        }
    }

    /*
     Extract the file name from the file path
        - Parameter filePath: Full file path in bundle
        - Returns: File Name with extension
     */
    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}

private extension Date {
    func toString() -> String {
        return Log.dateFormatter.string(from: self as Date)
    }
}
