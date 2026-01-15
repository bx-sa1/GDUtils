class_name ExpressionWatcher extends Node

@export var node: Node
@export_multiline var expressions: Array[String]

var expr_map: Dictionary[String, Variant]

signal expr_executed(expr_str: String, result: String)

func _ready() -> void:
	for expr_str in expressions:
		var expr = Expression.new()
		expr.parse(expr_str)
		expr_map[expr_str] = expr

func _process(delta: float) -> void:
	for expr_str in expr_map:
		var expr = expr_map[expr_str]
		var res = expr.execute([], node)
		if expr.has_execute_failed() or expr.get_error_text() != "":
			res = expr.get_error_text()
		else:
			res = str(res)
		expr_executed.emit(expr_str, res)
