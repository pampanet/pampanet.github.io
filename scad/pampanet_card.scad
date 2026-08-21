include <qr.scad>
// Pampanet 3D Business Card (OpenSCAD)
// Dimensions: 85mm x 54mm x 2mm (top-heavy layout, embossed elements)
// NOTE: This file uses OpenSCAD's text() primitive for embossing. To export to STL:
// - Install OpenSCAD (https://www.openscad.org/)
// - Open this .scad file and choose Design -> Compile, then Design -> Export -> Export as STL
//
// QR placeholder:
// The 'qr_matrix' below is a sample 21x21 pattern and is NOT a valid QR code.
// To make a scannable QR, generate a QR matrix (0/1) for the string "https://pampanet.github.io"
// using any QR generator (e.g., Python 'qrcode' library -> get_matrix()), then paste the boolean grid here.
// Each 1 will be embossed as a raised module.
//
// Layout: top-heavy — logo & text placed near top, QR at bottom-right.
//
// Parameters
current_color = "ALL";
card_w = 85;
card_h = 54;
card_t = 2;       // overall thickness
emboss_h = 1.0;  // emboss height above card surface
margin = 4;

// font settings (OpenSCAD uses system fonts; you can change to a specific installed font)
font_size_logo = 8;
font_size_sub = 3.5;
font = "Liberation Sans"; // fallback; change if different font installed

module rounded_card(w, h, t, r=2) {
    // rounded rectangle by minkowski of square and circle
    difference() {
        minkowski() {
            cube([w-2*r, h-2*r, t], center=true);
            translate([0,0,r]) cylinder(h=1, r=r, $fn=48);
        }
        // Cut bottom to make flat reference at z=0
        translate([0,0,-1]) cube([w,h,1], center=true);
    }
}

/* Similar to the color function, but can be used for generating multi-color models for printing.
 * The global current_color variable indicates the color to print.
 */
module multicolor(color) {
    if (current_color != "ALL" && current_color != color) { 
        // ignore our children.
        // (I originally used "scale([0,0,0])" which also works but isn't needed.) 
    } else {
        color(color)
        children();
    }        
}


// Main assembly
translate([card_w/2, card_h/2, 2]) rotate([0,0,0]) {
    // Place rounded card centered at origin, then translate pieces relative to it
    // We'll use coordinate system where card origin is at its center; easier to reason then translate to (0,0).
    // Draw base
    multicolor("black") translate([0,0,-3.0]) rounded_card(card_w, card_h, card_t);

    // Embossed Logo text near top (centered horizontally)
    // Place at y = +12 mm from center (top-heavy)
    multicolor("gray") translate([margin, 18, 1])
      linear_extrude(height=emboss_h)
        text(text = "pampanet.org", size = font_size_logo, halign = "center", valign = "center", font="Liberation Sans:style=Bold");

    // Subtitle under logo
    multicolor("gray") translate([1.5, 9, 1])
      linear_extrude(height=emboss_h)
        text(text = "Independent Development Studio", size = font_size_sub, halign = "center", valign = "center", font="Liberation Sans:style=Bold");

    // Creator line
    multicolor("gray") translate([-4.0 * margin, 0, 1])
      linear_extrude(height=emboss_h)
        text(text = "Creator of \"El Polímata\"", size = font_size_sub/1.2, halign = "center", valign = "center", font="Liberation Sans:style=Bold");

    // QR area at bottom-right, size approx 28mm square
    qr_size = 28;
    multicolor("gray")
        translate([card_w/4 + margin, -card_h/8 - margin, 1])
        qr("https://pampanet.github.io", center=true, thickness=1, width=24, height=24);

    // URL under QR (right side)
    multicolor("gray") translate([ (card_w/2 - margin - qr_size/2) - card_w/2, (-card_h/2 + margin + qr_size + 6) - card_h/2, 1])
      linear_extrude(height=emboss_h)
        text(text = "pampanet.github.io", size = 3.2, halign = "center", valign = "center", font="Liberation Sans:style=Bold");
}
