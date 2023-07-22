//
// Copyright 2017 Christian Reitwiessner
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [11431744302740162224733047308639664254229672390680136345132008137797091038424,
             2983338229272282614443652432994171525679802641842513997530192743046085096965],
            [12153371547089494349212235010726866740965242750986500176008774865279203306742,
             1689566981155960722061771420441140577826246146719856812834848548565198303699]
        );
        vk.IC = new Pairing.G1Point[](32);

        vk.IC[0] = Pairing.G1Point(
            431978105444438281595453241542286145393318580135873499022135625313208933384,
            17049190926277996212978895278424417127263063309290469227571439126174940060296
        );

        vk.IC[1] = Pairing.G1Point(
            3438185368765790753565042370539112125849526357798631096794240586647193656993,
            14303564527928455007206979948376676193773729971900503737039181308217955947364
        );

        vk.IC[2] = Pairing.G1Point(
            17942247043503879752787484292393676010555426719663066178484946126087724432584,
            19816826616002532490101652526640004663691518869026329898256428063230810428762
        );

        vk.IC[3] = Pairing.G1Point(
            11911673040844416809958842908611004292273492437864862567738127123899247910725,
            3582877943504641962196844447759016363607007288012844580986215508564299499449
        );

        vk.IC[4] = Pairing.G1Point(
            11494182827243281904943153193137018954367794771646924226122232127788495873624,
            9438162329474698761887163848460542991817948695051344396218449875405202216753
        );

        vk.IC[5] = Pairing.G1Point(
            13960063619725209856329968530211656349825926333938123348880329944582995859325,
            3159653219148096399188634252041518190058790491438683213400979722993852539225
        );

        vk.IC[6] = Pairing.G1Point(
            5819284744883572510638249497865722715882337942881048137296950524204289217957,
            13627286434160064094481936605677117377364103507733583915477044558528736589437
        );

        vk.IC[7] = Pairing.G1Point(
            4784331463206584024161553538386526878035273608121048999632114367808593529147,
            447481114495778493211777717794126392012556479584281277645372102147897914301
        );

        vk.IC[8] = Pairing.G1Point(
            1756007376834702356589436436588647025784281757434731288741032360991357738281,
            2456028341231649360399578299693515500019088657890358424134643004289952273689
        );

        vk.IC[9] = Pairing.G1Point(
            14081630130602444943169440474372421748169485413164794261029429366921517298633,
            5875078089004003013160540340674259054511126412584470484941820067350462820604
        );

        vk.IC[10] = Pairing.G1Point(
            19960503768007268152136607267304523973087065036314959833663527501350620019470,
            14344166937170181781210016927344028916656305970740532714930142655748130593292
        );

        vk.IC[11] = Pairing.G1Point(
            1662737701839512545342411747782541614595328838537346881377917225448054510513,
            3912481013475051997078984206433690457116137463163285062680629224049580016900
        );

        vk.IC[12] = Pairing.G1Point(
            5848225697973083657340477447968073939834340651002344515500237098589476599574,
            9562853810813824868501390785530606113484247221263155028174724641238010744294
        );

        vk.IC[13] = Pairing.G1Point(
            15670725147378965380703861934301622021828051567659831231350887505802155555245,
            9622167464927899188575542814430774490622303075394084458587251896222273741019
        );

        vk.IC[14] = Pairing.G1Point(
            2096188022110727790271326872151992143028592290101778094164465523432091648993,
            11640455589759552769917377146422728904118909317138896112203032380261867247394
        );

        vk.IC[15] = Pairing.G1Point(
            11828399936604583419060680034024186530905744083504539738860273254174673920901,
            14146464604981276524173327450059031731990510367471941251579950400086651118913
        );

        vk.IC[16] = Pairing.G1Point(
            8307155868878362467081601249390920241723328669612403781166676936614462710163,
            13997832136469468293205288623205451841369691196822038222316771746038213782605
        );

        vk.IC[17] = Pairing.G1Point(
            17216171498867185692287255434343103069807432104411239155246773186522366426851,
            19943725622373620242350977507650209996727992051771510278004173951746189908857
        );

        vk.IC[18] = Pairing.G1Point(
            10568300676830751259081595924726185532464841318276490275770963030177787785335,
            7876443869300537034370573098753264173248550524974039552772000124933422682915
        );

        vk.IC[19] = Pairing.G1Point(
            5879399752128241086801926619386409724022779437659619318934997650160223323514,
            11962447392839385547699549612675317757169770346482966329468712178476108558666
        );

        vk.IC[20] = Pairing.G1Point(
            9955014069918687875964290057822847882470163372188209819685900993617789127750,
            8841527980922416840412785003180106183381215662582870856864205431825190021084
        );

        vk.IC[21] = Pairing.G1Point(
            5023738412166441972670949599146032732336951671741494061596378831267388035104,
            11903326656313813409287167710103691264707424089581793173482908933593755260520
        );

        vk.IC[22] = Pairing.G1Point(
            4364032725988912227834795975760036257508412060209700317604360404684405007709,
            1245857268650906028877672157048635099453063033005655043992166915973941410372
        );

        vk.IC[23] = Pairing.G1Point(
            12233367475931703977033703521376261262343822448104918123761436277491256426677,
            12476459266402801909230666685948318696622309057073147732835962519149898024282
        );

        vk.IC[24] = Pairing.G1Point(
            21038272858428770369480884792666606286148040556849721431384353991108605075117,
            6045814778887463311428399025130056645312795681835793617640639560230822220546
        );

        vk.IC[25] = Pairing.G1Point(
            12274472518562866155488419712886957923856320248867961260824123833819684147643,
            1119741982833482404148947374359460379330845308882298389600868960633562514263
        );

        vk.IC[26] = Pairing.G1Point(
            746023635340216571079576626794187866681409687690647558469282355424883445573,
            18291866767077056986436709121054029063394366687621934046137236398463354280644
        );

        vk.IC[27] = Pairing.G1Point(
            5789429855111902099334462079693337015789650243980729537485278512961650609982,
            15541497159835687706032346125861213252742964845924505035959146624409836915714
        );

            653605087177725076106657193144722056193810886801070168382260832988499552253
        );

            4571924930949482733555433987323030700944606319032976166142443465762697068819
        );

        vk.IC[30] = Pairing.G1Point(
            12721124858640096684226602933173823345825336705587114184867853179879991212275,
            9641061325553413475116279187656113679306134395577285236228430983789648618521
        );

        vk.IC[31] = Pairing.G1Point(
            19896059007807093944461531290880353648459041567523812068254424401140944784259,
            8627094561408307131421717526373613506209684890822639651306678296664407872714
        );

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[31] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}