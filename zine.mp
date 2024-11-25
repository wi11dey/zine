prologues := 3;
outputtemplate := "%j.mp.svg";
outputformat := "svg";

beginfig(1);
  xheight := 400pt;
  en := 350pt;
  eccentricity := 50pt;
  spacing := 70pt;
  hang := 20pt;
  curvelength := 100pt;

  xthickness := 170pt;
  ythickness := 40pt;
  interim linejoin := mitered;
  pen rectangle;
  rectangle := pensquare xscaled xthickness yscaled ythickness;

  xshift := 0;
  pickup rectangle;

  topbound = xheight + ythickness/2;

  path z;
  z := (eccentricity, xheight)--(en, xheight)--(0, 0);
  actualen := xpart (lrcorner (envelope rectangle of z)) - xthickness/2;
  draw z shifted (xshift, 0);
  draw ((0, 0)--(actualen, 0)) shifted (xshift, 0);

  xshift := xshift + actualen + xthickness + spacing;

  % i
  draw ((0, xheight)--(0, 0)) shifted (xshift, 0);
  draw (0, xheight + 2ythickness) shifted (xshift, 0);

  xshift := xshift + xthickness + spacing;

  % n
  draw ((0, xheight)--(0, 0)) shifted (xshift, 0);
  fill ((xthickness/2, topbound - hang){dir 10}
      ..tension 1.3..(actualen + xthickness/2, topbound - curvelength){down}
      ..(actualen + xthickness/2, 0 - ythickness/2){down}
      --(actualen - xthickness/2, 0 - ythickness/2)
      --(actualen - xthickness/2, topbound - curvelength){up}
      ..(xthickness/2, topbound - hang - ythickness){dir 190}
      --cycle) shifted (xshift, 0);

  xshift := xshift + actualen + xthickness + spacing;

  % e
  draw ((0, 0)
      --(actualen, xheight - curvelength){up}
      ..(actualen/2, xheight){left}
      ..(0, xheight - curvelength){down}
      --(0, curvelength){down}
      ..(actualen/2, 0){right}
      ..(actualen, curvelength){up}) shifted (xshift, 0);
endfig;
end;
