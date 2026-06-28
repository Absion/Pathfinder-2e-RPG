# pf_condition_stunned.gd
extends PFCondition

# Stunned logic is intercepted inside PFActionComponent.regain_actions()
# where it drains actions and decrements its own value.
