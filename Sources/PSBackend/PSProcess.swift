//
//  PSProcess.swift
//  PSBackend
//
import Foundation
import PathKit
import PySwiftKit
import PySerializing
import PySwiftWrapper


@PyClass
final class PSProcess {
    
    let executable: Path
    
    @PyInit
    init(executable: Path) {
        self.executable = executable
    }
    
    @PyMethod
    func run(args: [String], env: [String:String]?) throws {
        let task = Process()
        
        var task_env = ProcessInfo.processInfo.environment
        if let env {
            task_env.merge(env)
        }
        task.arguments = args
        task.executablePath = executable
        task.environment = task_env
        task.standardInput = nil
        task.launch()
        task.waitUntilExit()
    }
    
}

