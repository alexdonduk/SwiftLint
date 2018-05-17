import Foundation

private enum ConfigurationKey: String {
    case newLine = "parameters_on_new_line"
    case emptyLine = "empty_line_to_body"
}

public struct ClosureParameterPositionRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var isNeedParamsOnNewLine: Bool
    private(set) var isNeedEmptyLineToBody: Bool
    let severityConfiguration = SeverityConfiguration(.warning)
    
    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
        "\(ConfigurationKey.newLine.rawValue): \(isNeedParamsOnNewLine)" +
        "\(ConfigurationKey.emptyLine.rawValue): \(isNeedEmptyLineToBody)"
    }
    
    public init(isNeedParamsOnNewLine: Bool, isNeedEmptyLineToBody: Bool) {
        self.isNeedParamsOnNewLine = isNeedParamsOnNewLine
        self.isNeedEmptyLineToBody = isNeedEmptyLineToBody
    }
    
    public mutating func apply(configuration: Any) throws {
        if let configDict = configuration as? [String: Any], !configDict.isEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                switch (key, value) {
                case (.newLine, let boolValue as Bool):
                    isNeedParamsOnNewLine = boolValue
                case (.emptyLine, let boolValue as Bool):
                    isNeedEmptyLineToBody = boolValue
                default:
                    throw ConfigurationError.unknownConfiguration
                }
            }
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
    
    public static func == (lhs: ClosureParameterPositionRuleConfiguration,
                           rhs: ClosureParameterPositionRuleConfiguration) -> Bool {
        return lhs.isNeedParamsOnNewLine == rhs.isNeedParamsOnNewLine &&
            lhs.isNeedEmptyLineToBody == rhs.isNeedEmptyLineToBody
    }
}
