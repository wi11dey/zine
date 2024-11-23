prologues := 3;
outputtemplate := "%j-%c.mps";

beginfig(1);
  u := 1pt;
  path p[];

  p1 := (198.42625u, 271u) --
    (198.42625u, 313.88481u) --
    (562.97483u, 313.88481u) --
    (168.42625u, 705.60284u) --
    (168.42625u, 747u) --
    (777.49059u, 747u) --
    (777.49059u, 705.60284u) --
    (350.88775u, 705.60284u) --
    (785.49059u, 271u) --
    cycle;
  fill p1 withcolor black;
  draw p1 withpen pencircle scaled 1bp withcolor black;

  p2 := (864.95015u, 270.5u) --
    (864.95015u, 747u) --
    (1047.4346u, 747.5u) --
    (1047.4346u, 271u) --
    cycle;
  fill p2 withcolor black;
  draw p2 withpen pencircle scaled 1bp withcolor black;

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

  p4 := (1521.4771u, 269.99805u) .. controls (1473.1037u, 268.91071u) and (1308.6714u, 294.97461u) .. (1308.6714u, 294.97461u) --
    (1308.6714u, 271u) --
    (1126.187u, 270.5u) --
    (1126.187u, 747u) --
    (1308.6714u, 747.5u) --
    (1308.6714u, 343.82617u) --
    (1308.6714u, 343.82617u) --
    (1421.2348u, 324.79592u) --
    (1542.7982u, 324.79592u) .. controls (1582.012u, 324.79592u) and (1664.3617u, 324.79592u) .. (1664.3617u, 389.52639u) --
    (1664.3617u, 747u) --
    (1846.8461u, 747.5u) --
    (1846.8461u, 339.52539u) .. controls (1846.8461u, 273.73226u) and (1689.6458u, 271.24795u) .. (1634.0405u, 269.99805u) --
    cycle;
  fill p4 withcolor black;
  draw p4 withpen pencircle scaled 1bp withcolor black;

  p5 := (864.45017u, 226.25706u) --
    (1047.9346u, 226.25706u) --
    (1047.9346u, 157.19814u) --
    (864.45017u, 157.19814u) --
    cycle;
  fill p5 withcolor black;
  draw p5 withpen pencircle scaled 1bp withcolor black;

endfig;
end;
