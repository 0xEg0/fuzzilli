// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

public class CompilerUtils {
    
    let jsFileExtension = ".js"
    let protoBufFileExtension = ".fzil"

    let jsPrefix = ""
    let jsSuffix = ""

    public init() {
        self.jsLifter = JavaScriptLifter(prefix: jsPrefix, suffix: jsSuffix, ecmaVersion: ECMAScriptVersion.es6)
        self.fuzzILLifter = FuzzILLifter()    
    }
    
    private let jsLifter : JavaScriptLifter
    private let fuzzILLifter : FuzzILLifter
 
    // Default list of functions that are filtered out during compilation. These are functions that may be used in testcases but which do not influence the test's behaviour and so should be omitted for fuzzing.
    // The functions can use the wildcard '*' character as _last_ character, in which case a prefix match will be performed.
    let filteredFunctionsForCompiler = [
        "assert*",
        "print*",
        "enterFunc",
        "startTest"
    ]

    // Loads a serialized FuzzIL program from the given file
    public func loadProgram(from path: String) throws -> Program {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let proto = try Fuzzilli_Protobuf_Program(serializedBytes: data)
        let program = try Program(from: proto)
        return program
    }

    public func loadAllPrograms(in dirPath: String) -> [(filename: String, program: Program)] {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: dirPath, isDirectory:&isDir) || !isDir.boolValue {
            print("\(dirPath) is not a directory!")
            exit(-1)
        }

        let fileEnumerator = FileManager.default.enumerator(atPath: dirPath)
        var results = [(String, Program)]()
        while let filename = fileEnumerator?.nextObject() as? String {
            guard filename.hasSuffix(protoBufFileExtension) else { continue }
            let path = dirPath + "/" + filename
            do {
                let program = try loadProgram(from: path)
                results.append((filename, program))
            } catch FuzzilliError.programDecodingError(let reason) {
                print("Failed to load program \(path): \(reason)")
            } catch {
                print("Failed to load program \(path) due to unexpected error: \(error)")
            }
        }
        return results
    }

    // Take a program and lifts it to JavaScript
    public func liftToJS(_ prog: Program) -> String {
        let res = jsLifter.lift(prog)
        return res.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Take a program and lifts it to FuzzIL's text format
    public func liftToFuzzIL(_ prog: Program) -> String {
        let res = fuzzILLifter.lift(prog)
        return res.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Loads all .fzil files in a directory, and lifts them to JS
    // Returns the number of files successfully converted
    public func liftAllPrograms(in dirPath: String, with lifter: Lifter, fileExtension: String) -> Int {
        var numLiftedPrograms = 0
        for (filename, program) in loadAllPrograms(in: dirPath) {
            let newFilePath = "\(dirPath)/\(filename.dropLast(protoBufFileExtension.count))\(fileExtension)"
            let content = lifter.lift(program)
            do {
                try content.write(to: URL(fileURLWithPath: newFilePath), atomically: false, encoding: String.Encoding.utf8)
                numLiftedPrograms += 1
            } catch {
                print("Failed to write file \(newFilePath): \(error)")
            }
        }
        return numLiftedPrograms
    }

    public func loadProgramOrExit(from path: String) -> Program {
        do {
            return try loadProgram(from: path)
        } catch {
            print("Failed to load program from \(path): \(error)")
            exit(-1)
        }
    }

    // Compile a JavaScript program to a FuzzIL program. Requires node.js
    public func compileJavascript(_ path: String) -> String{
        // We require a NodeJS executor here as we need certain node modules.
        guard let nodejs = JavaScriptExecutor(type: .nodejs) else {
            print("Could not find the NodeJS executable.")
            exit(-1)
        }
        guard let parser = JavaScriptParser(executor: nodejs) else {
            print("The JavaScript parser does not appear to be working. See Sources/Fuzzilli/Compiler/Parser/README.md for instructions on how to set it up.")
            exit(-1)
        }

        let ast: JavaScriptParser.AST
        do {
            ast = try parser.parse(path)
        } catch {
            print("Failed to parse \(path): \(error)")
            exit(-1)
        }

        let compiler = JavaScriptCompiler(deletingCallTo: filteredFunctionsForCompiler)
        let program: Program
        do {
            program = try compiler.compile(ast)
        } catch {
            print("Failed to compile: \(error)")
            exit(-1)
        }

        print(fuzzILLifter.lift(program))
        print()
        print(jsLifter.lift(program))

        do {
            let outputPath = URL(fileURLWithPath: path).deletingPathExtension().appendingPathExtension("fzil")
            try program.asProtobuf().serializedData().write(to: outputPath)
            print("FuzzIL program written to \(outputPath.relativePath)")
            return outputPath.lastPathComponent
        } catch {
            print("Failed to store output program to disk: \(error)")
            exit(-1)
        }
    }
}