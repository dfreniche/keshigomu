//
//  main.swift
//  KeshiGomu
//
//  Created by Diego Freniche Brito on 7/10/21.
//

import Foundation
import ArgumentParser
import Files
import ANSITerminal

@main
struct Repeat: ParsableCommand {
    @Flag(help: "Show change details for each file")
    var verbose = false

    @Flag(help: "Commit changes, actually change files")
    var commit = false
    
    @Option(help: "New Header string, this will replace the header inserted by Xcode. Separate lines with \\n")
    var newHeader: String?
    
    @Option(help: "New Header file name containing the new header that will replace the header inserted by Xcode. If file name is passed new header string option is ignored.")
    var newHeaderFileName: String?


    mutating func run() throws {
        var linesChanged = 0
          
        if let newHeaderFileName = newHeaderFileName {
            newHeader = try? NSString(contentsOfFile: newHeaderFileName, encoding: String.Encoding.utf8.rawValue) as String?
        }

        // iterate over all folders and subfolders
        Folder.current.subfolders.recursive.forEach { folder in
            log("[Folder: \(folder.name)]".asBlue.onWhite)

            // on each folder, get all Swift files
            folder.files.filter({ $0.extension == "swift" }).enumerated().forEach { (index, file) in

                log("> \(file.name)".asWhite)

                // read contents of one file into a String
                let fileContent = readFileAsString(fileName: file.path)

                // break into lines
                var fileLines = fileContent.components(separatedBy: "\n")

                // header has 6 lines
                let lastLineNumber = (fileLines.count > 6) ? 6 : fileLines.count

                // check if 1st 6 lines are comments
                var isHeaderComment = true
                for i in 0 ..< lastLineNumber {
                    if (!fileLines[i].starts(with: "//")) {
                        isHeaderComment = false
                        break
                    }
                }

                if isHeaderComment {
                    log("  [Comment Header detected]")
                    for i in 0 ..< 6 {
                        log("  >> Comment \( fileLines[i])".asGreen)
                    }

                    fileLines.removeFirst(6)

                    // insert new header if was given as argument
                    if let newHeader = newHeader {
                        fileLines.insert(contentsOf: newHeader.components(separatedBy: "\\n"), at: 0)
                        log("Output file (changed)\n".asBrown)
                    }

                    linesChanged = linesChanged + 6

                    for line in fileLines {
                        log("  \( line )".asGray)
                    }
                } else {
                    log("File unchanged".asCyan)
                }

                if commit {
                    if isHeaderComment {
                        let newFileString = fileLines.joined(separator: "\n")
                        let newFileURL = URL(fileURLWithPath: file.path)

                        log("Changed!".asYellow)
                        do {
                            try newFileString.write(to: newFileURL, atomically: true, encoding: String.Encoding.utf8)
                        } catch {
                            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                            log("Error writing file \(file.path)\nError: \(error)".asRed)
                        }
                    }
                }
            }
        }
        log("Changed \(linesChanged) lines")
    }
    
    func log(_ text: String) {
        if verbose {
            print(text)
        }
    }
}

func readFileAsString(fileName: String) -> String {
    guard let fileContent = try? NSString(contentsOfFile: fileName, encoding: String.Encoding.utf8.rawValue) as String else { return "" }
    
    return fileContent
}

