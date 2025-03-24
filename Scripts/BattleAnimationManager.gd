# AutoLoad 
extends Node

var animation_map = {
    "slash": "res://Scripts/SkillAnimations/SlashAnimation.gd",

}


func build_animation_queue(battle_info: Array):
    for event in battle_info:
        var animation = event.skill_info.get("animation")
        var extra_event_list 
        if animation:
            #使用对应动画脚本的extra_event函数，返回一个字典{事件插入的位置：事件引用}
            extra_event_list.append(animation.extra_event(event))
        #根据这个list，在原列表插入新的事件，然后移交给play_animation_with_queue依次播放动画。

    var animation_queue = []



func play_animation_with_queue(animation_queue: Array) -> void:
    pass

