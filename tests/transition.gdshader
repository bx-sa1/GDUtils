shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float delta;
uniform sampler2D gradient;

void fragment() {
	vec4 g = texture(gradient, UV);
    COLOR = vec4(0,0,0,1);
	COLOR.a = g.r * delta;
}
