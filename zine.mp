prologues := 3;
outputtemplate := "%j.mp.svg";
outputformat := "svg";

beginfig(1);
  xheight := 400pt;
  en := 400pt;
  eccentricity := 50pt;
  spacing := 70pt;

  xthickness := 170pt;
  ythickness := 40pt;
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
  p3 := (2068.7944pt, 269.46484pt) .. controls (1894.5761pt, 269.46484pt) and (1813.0352pt, 289.72474pt) .. (1813.0352pt, 354.59766pt) --
    (1813.0352pt, 632.54102pt) .. controls (1813.0352pt, 747pt) and (1962.5172pt, 747.23242pt) .. (2121.7944pt, 747.23242pt) --
    (2430.5536pt, 747.23242pt) .. controls (2430.5536pt, 705.34359pt) and (2430.5536pt, 624.17773pt) .. (2430.5536pt, 542.79102pt) --
    (2252.9589pt, 720.79102pt) --
    (2252.9589pt, 782.28264pt) .. controls (2252.9589pt, 802.86702pt) and (2211.3571pt, 836.66868pt) .. (2152.6235pt, 836.66868pt) --
    (2093.8899pt, 836.66868pt) .. controls (2035.1563pt, 836.66868pt) and (2093.8899pt, 836.66868pt) .. (2093.8899pt, 759.18182pt) --
    (2469.1554pt, 390.16006pt) .. controls (2469.1554pt, 349.63351pt) and (2283.6144pt, 348.09835pt) .. (2109.3961pt, 348.09835pt) --
    cycle;
  fill p3 withcolor black;
  draw p3 withpen pencircle scaled 1bp withcolor black;

endfig;
end;
