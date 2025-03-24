class_name SlashAnimation
extends BaseSkillAnimation


func _init() -> void:
    super()
    
func play(phase: AnimationPhase) -> void:
    match phase:
        AnimationPhase.PREPARE:
            play_prepare()
        AnimationPhase.EXECUTE:
            play_execute()
        AnimationPhase.FINISH:
            play_finish()
        _:
            play_prepare()
            play_execute()
            play_finish()

func play_prepare() -> void:

    pass

func play_execute() -> void:
    pass

func play_finish() -> void:
    pass

