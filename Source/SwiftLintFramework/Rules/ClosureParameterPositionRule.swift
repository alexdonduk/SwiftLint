import Foundation
import SourceKittenFramework

public struct ClosureParameterPositionRule: ASTRule, ConfigurationProviderRule {
    public var configuration = ClosureParameterPositionRuleConfiguration(isNeedParamsOnNewLine: false, isNeedEmptyLineToBody: false)
    
    public init() {}
    
    public static let description = RuleDescription(
        identifier: "closure_parameter_position",
        name: "Closure Parameter Position",
        description: "Closure parameters should be on the correct position",
        kind: .style,
        nonTriggeringExamples: [
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "[1, 2].map { number -> Int in\n number + 1 \n}\n",
            "[1, 2].map { (number: Int) -> Int in\n number + 1 \n}\n",
            "[1, 2].map { [weak self] number in\n number + 1 \n}\n",
            "[1, 2].something(closure: { number in\n number + 1 \n})\n",
            "let isEmpty = [1, 2].isEmpty()\n",
            "rlmConfiguration.migrationBlock.map { rlmMigration in\n" +
                "return { migration, schemaVersion in\n" +
                "rlmMigration(migration.rlmMigration, schemaVersion)\n" +
                "}\n" +
            "}",
            "let mediaView: UIView = { [weak self] index in\n" +
                "   return UIView()\n" +
            "}(index)\n"
        ],
        triggeringExamples: [
            "[1, 2].map {\n ↓number in\n number + 1 \n}\n",
            "[1, 2].map {\n ↓number -> Int in\n number + 1 \n}\n",
            "[1, 2].map {\n (↓number: Int) -> Int in\n number + 1 \n}\n",
            "[1, 2].map {\n [weak self] ↓number in\n number + 1 \n}\n",
            "[1, 2].map { [weak self]\n ↓number in\n number + 1 \n}\n",
            "[1, 2].map({\n ↓number in\n number + 1 \n})\n",
            "[1, 2].something(closure: {\n ↓number in\n number + 1 \n})\n",
            "[1, 2].reduce(0) {\n ↓sum, ↓number in\n number + sum \n}\n"
        ]
    )
    
    private static let openBraceRegex = regex("\\{")
    
    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call else {
            return []
        }
        
        if configuration.isNeedEmptyLineToBody {
            let newLineViolations = checkInNewLine(file: file)
            if !newLineViolations.isEmpty {
                return newLineViolations
            }
        }
        
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyLength = dictionary.bodyLength,
            bodyLength > 0 else {
                return []
        }
        
        let parameters = dictionary.enclosedVarParameters
        var rangeStart = nameOffset + nameLength
        let regex = ClosureParameterPositionRule.openBraceRegex
        
        // parameters from inner closures are reported on the top-level one, so we can't just
        // use the first and last parameters to check, we need to check all of them
        return parameters.compactMap { param -> StyleViolation? in
            guard let paramOffset = param.offset else {
                return nil
            }
            
            if paramOffset < rangeStart {
                rangeStart = nameOffset
            }
            
            let rangeLength = paramOffset - rangeStart
            let contents = file.contents.bridge()
            
            guard let range = contents.byteRangeToNSRange(start: rangeStart, length: rangeLength),
                let match = regex.matches(in: file.contents, options: [], range: range).last?.range,
                match.location != NSNotFound,
                let braceOffset = contents.NSRangeToByteRange(start: match.location, length: match.length)?.location,
                let (braceLine, _) = contents.lineAndCharacter(forByteOffset: braceOffset),
                let (paramLine, _) = contents.lineAndCharacter(forByteOffset: paramOffset),
                (configuration.isNeedParamsOnNewLine && braceLine == paramLine) ||
                (!configuration.isNeedParamsOnNewLine && braceLine != paramLine) else {
                    return nil
            }
            
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: paramOffset))
        }
    }
    
    private func checkInNewLine(file: File) -> [StyleViolation] {
        let inLength = 2
        return file.match(pattern: "in\n\n|in", with: [.keyword])
            .filter({ $0.length == inLength })
            .map{ StyleViolation(ruleDescription: type(of: self).description,
                                 severity: configuration.severityConfiguration.severity,
                                 location: Location(file: file, characterOffset: $0.location + inLength + 1))}
    }
}
