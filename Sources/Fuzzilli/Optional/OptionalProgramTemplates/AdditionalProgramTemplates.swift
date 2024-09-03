/// Additional program templates to target specific types of bugs.
public let OptionalProgramTemplates = [
    ProgramTemplate("Codegen1") { b in
        b.buildPrefix()
        b.build(n: 1)
    },
]
