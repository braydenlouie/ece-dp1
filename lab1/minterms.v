module minterms (
    input A, B, C, D,
    output F
);
    wire notB, notD, notBnotD, BD, ABC;

    not (notB, B);
    not (notD, D);

    and(notBnotD, notB, notD);
    and (BD, B, D);
    and (ABC, A, B, C);

    or (F, notBnotD, BD, ABC);
endmodule