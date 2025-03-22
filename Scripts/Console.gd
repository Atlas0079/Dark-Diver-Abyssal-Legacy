extends Node

var console: RichTextLabel = null

func _ready():
	# 将此脚本添加到自动加载列表中，使其成为单例
	pass

func setup_console(rich_text_label: RichTextLabel):
	console = rich_text_label

func log(message: String):
	# 在控制台中打印消息
	print(message)
	
	# 如果RichTextLabel已设置，则在其中也显示消息
	if console:
		console.add_text(message + "\n")
		# 滚动到底部
		console.scroll_to_line(console.get_line_count() - 1)

func clear_console():
	if console:
		console.clear()