module ring_osc(EN, OUT);
    input EN;
    output OUT;

    logic n1, n2;

    nand #5 NAND1(n1, EN, OUT);
    not #5 NOT1(n2, n1);
    not #5 NOT2(OUT, n2);

endmodule