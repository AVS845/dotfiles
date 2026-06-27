#version 320 es
precision mediump float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    vec4 color = texture(tex, v_texcoord);

    // Slight brightness boost
    color.rgb *= 1.05;

    // Subtle vibrancy boost
    float avg = (color.r + color.g + color.b) / 3.0;
    color.rgb = mix(vec3(avg), color.rgb, 1.15);

    // Soft top highlight sheen
    float highlight = smoothstep(1.0, 0.2, v_texcoord.y);
    color.rgb += highlight * 0.04;

    // Subtle edge glow
    float edge =
        smoothstep(0.0, 0.02, v_texcoord.x) +
        smoothstep(1.0, 0.98, v_texcoord.x) +
        smoothstep(0.0, 0.02, v_texcoord.y) +
        smoothstep(1.0, 0.98, v_texcoord.y);

    color.rgb += edge * 0.03;

    fragColor = color;
}

