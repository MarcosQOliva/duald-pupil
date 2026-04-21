function pix = va2pix(va, scr)
%VA2PIX Convert degrees of visual angle into pixels.

pix = scr.subDist * tan(va * pi / 180) / (scr.width / (10 * scr.xres));
end
