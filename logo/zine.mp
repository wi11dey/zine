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
      ..tension 1.2..(actualen + xthickness/2, topbound - curvelength){down}
      ..(actualen + xthickness/2, -ythickness/2){down}
      --(actualen - xthickness/2, -ythickness/2)
      --(actualen - xthickness/2, topbound - curvelength){up}
      ..(xthickness/2, topbound - hang - ythickness){dir 190}
      --cycle) shifted (xshift, 0);

  xshift := xshift + actualen + xthickness + spacing;

  % e
  fill ((actualen + xthickness/2, topbound - ythickness - curvelength/2){up}
      ..(actualen - xthickness/2, topbound){left}
      --(xthickness/2, topbound){left}
      ..(-xthickness/2, topbound - curvelength){down}
      --(-xthickness/2, curvelength - ythickness/2){down}
      ..(xthickness/2, -ythickness/2){right}
      --(actualen - xthickness/2, -ythickness/2){right}
      ..(actualen + xthickness/2, curvelength - ythickness/2){up}
      --(actualen + xthickness/2, 250)
      --(actualen - xthickness/2, 75)
      --(actualen - xthickness/2, ythickness/2 + curvelength/2){down}
      ..(actualen - xthickness, ythickness/2){left}
      ..(xthickness, ythickness/2){left}
      ..(xthickness/2, ythickness/2 + curvelength/2){up}
      --(xthickness/2, topbound - ythickness - curvelength/2){up}
      ..(xthickness, topbound - ythickness){right}
      --(actualen - xthickness, topbound - ythickness){right}
      ..(actualen - xthickness/2, topbound - ythickness - 0.25curvelength){dir 225}
      --(0, 0)
      --(xthickness, 0)
      --cycle) shifted (xshift, 0);
endfig;
end;
