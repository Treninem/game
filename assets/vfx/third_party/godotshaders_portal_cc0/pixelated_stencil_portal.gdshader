shader_type spatial;
render_mode unshaded, cull_disabled;
stencil_mode write, 1;

/** The mask defining the portal area. Solid pixels become the portal area. */
uniform sampler2D mask: hint_default_transparent, filter_nearest;

/** The minimum transparency of a mask pixel considered part of the portal. */
uniform float mask_threshold = 0.5;

void fragment() {
	float mask_alpha = texture(mask, UV).a;
	if (mask_alpha >= mask_threshold) {
		// Hide portal pixels so the stencil is set but not blocked by the mask.
		ALPHA = 0.0;
	} else {
		// Do not set the stencil buffer for pixels not part of the portal.
		discard;
	}
}
