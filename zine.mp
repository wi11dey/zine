prologues := 3;
outputtemplate := "%j.mp.svg";
outputformat := "svg";

u := 1pt;
beginfig(1);

  xheight := 400u;
  en := 400u;
  eccentricity := 50u;
  spacing := 70u;

  xthickness := 170u;
  ythickness := 40u;
  interim linejoin := mitered;
  pen rectangle;
  rectangle := pensquare xscaled xthickness yscaled ythickness;

  xshift := 0;
  pickup rectangle;

  path z, zbase;
  z := (eccentricity, xheight)--(en, xheight)--(0, 0);
  actualen := xpart (lrcorner (envelope rectangle of z)) - xthickness/2;
  zbase := (0, 0)--(actualen, 0);
  draw z shifted (xshift, 0);
  draw zbase shifted (xshift, 0);

  xshift := xshift + actualen + xthickness + spacing;

  path i, idot;
  i := (0, xheight)--(0, 0);
  idot := (0, xheight + 2ythickness);
  draw idot shifted (xshift, 0);
  draw i shifted (xshift, 0);

  xshift := xshift + xthickness + spacing;

  path nbar, n;
  nbar := (0, xheight)--(0, 0);
  n = (0, xheight - ythickness)..(en/2, xheight)..(en, xheight - ythickness)--(en, 0);
  draw nbar shifted (xshift, 0);
  draw n shifted (xshift, 0);

  path p[];
  p3 := (2068.7944u, 269.46484u) .. controls (1894.5761u, 269.46484u) and (1813.0352u, 289.72474u) .. (1813.0352u, 354.59766u) --
    (1813.0352u, 632.54102u) .. controls (1813.0352u, 747u) and (1962.5172u, 747.23242u) .. (2121.7944u, 747.23242u) --
    (2430.5536u, 747.23242u) .. controls (2430.5536u, 705.34359u) and (2430.5536u, 624.17773u) .. (2430.5536u, 542.79102u) --
    (2252.9589u, 720.79102u) --
    (2252.9589u, 782.28264u) .. controls (2252.9589u, 802.86702u) and (2211.3571u, 836.66868u) .. (2152.6235u, 836.66868u) --
    (2093.8899u, 836.66868u) .. controls (2035.1563u, 836.66868u) and (2093.8899u, 836.66868u) .. (2093.8899u, 759.18182u) --
    (2469.1554u, 390.16006u) .. controls (2469.1554u, 349.63351u) and (2283.6144u, 348.09835u) .. (2109.3961u, 348.09835u) --
    cycle;
  fill p3 withcolor black;
  draw p3 withpen pencircle scaled 1bp withcolor black;

endfig;
end;
