shader_type canvas_item;
 
uniform sampler2D stencil_tex;
 
void fragment() {
COLOR.a = texture(stencil_tex, UV).g;
}