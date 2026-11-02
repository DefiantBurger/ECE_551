module MSFF(clk, d, q);
    input clk, d;
    output q;

    wire md, mq, sd, not_clk;

    not NOT0(not_clk, clk);
    notif1 NOTIF0(md, d, not_clk);
    not NOT1(mq, md);
    not (weak1, weak0) NOT2(md, mq);
    notif1 NOTIF1(sd, mq, clk);
    not NOT3(q, sd);
    not (weak1, weak0) NOT4(sd, q);

endmodule