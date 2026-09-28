# Verification Contract

A mutating action is incomplete until the relevant condition is checked again.

Verification should produce one of:

- `PASS`
- `FAIL`
- `CHANGED`
- `COULD_NOT_VERIFY`

Examples:

| Mutation | Verification |
| --- | --- |
| source fix | failing test rerun |
| config edit | parser/load check |
| rename | target exists and references checked |
| dependency change | install/build/test |
| generated artifact | expected file + format validation |

Verification evidence should be distinguishable from the agent's interpretation of that evidence.
