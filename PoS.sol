pragma solidity ^0.4.11;

contract ProofOfStake {
    // Declaring public variables to be used in the following functions.

    address public issuer;
    Float Kparam = Float(12313701368600,6);
    Float Kparam_invroot = Float(43304908700,-17);

    // Constructor.
    function ProofOfStake() {
    }

    // Custom type to be used for math calculations, equivalent to "data*(10**exp)".
    struct Float {
        int data;
        int exp;
    }

    modifier onlyIssuer() { if (msg.sender == issuer) _; }


    // Testing.
    /*
    Float block_target_year = Float(185505800,-2);                                      // 1855058.00
    Float block_target_4year = Float(4*185505800,-2);                                   // 7420232.00
    Float bias = Float(103,-2);                                                         // 1.03
    Float init_reward = Float(1,-1);                                                    // 0.1
    Float test_a = Float(100,-1);                                                       // 10.0
    Float test_b = Float(4,-1);                                                         // 0.4


    Float test_add = FP_add(test_a,test_b);                                             // Should equal 10.4
    Float test_sub = FP_sub(test_a,test_b);                                             // Should equal 9.6
    Float test_mul = FP_mul(test_a,test_b);                                             // Should equal 4.00
    Float test_div = FP_div(test_a,test_b);                                             // Should equal 25
    Float test_reward_year = reward(block_target_year,bias,Kparam,init_reward);         // Should be ~ 0.75
    Float test_reward_4year = reward(block_target_4year,bias,Kparam,init_reward);       // Should equal 1
    Float invcube = inv_cuberoot(Float(50,1),Float(12,-2));                             // Should be ~ 0.12599
    */


    // Main function, responsible for calculating the rewards.

    function reward(Float block_num, Float bias, Float Kparam, Float init_reward) private returns(Float) {
        Float memory inv_root = inv_cuberoot(FP_add(FP_mul(block_num,FP_mul(block_num,block_num)),Kparam),give_guess(block_num));
        Float memory reward = FP_add(FP_mul(FP_mul(FP_sub(bias,init_reward),block_num),inv_root),init_reward);

        if (reward.data > int(10**uint(-reward.exp))) {reward = Float(1,0);}
        return reward;
    }


    // Float Math

    function FP_add(Float a, Float b) internal returns (Float) {
        int base_exp = min(a.exp, b.exp);
        int exp_dif = max(a.exp, b.exp) - base_exp;

        if (a.exp == base_exp) {
            b.exp -= exp_dif;
            Float memory k = FP_mul(Float(b.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            b.data = k.data;
        }
        else {
            a.exp -= exp_dif;
            Float memory l = FP_mul(Float(a.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            a.data = l.data;
        }

        return Float(a.data+b.data, base_exp);
    }

    function FP_sub(Float a, Float b) internal returns (Float) {
        int base_exp = min(a.exp, b.exp);
        int exp_dif = max(a.exp, b.exp) - base_exp;

        if (a.exp == base_exp) {
            b.exp -= exp_dif;
            Float memory k = FP_mul(Float(b.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            b.data = k.data;
        }
        else {
            a.exp -= exp_dif;
            Float memory l = FP_mul(Float(a.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            a.data = l.data;
        }

        return Float(a.data-b.data, base_exp);
    }

    function FP_mul(Float a, Float b) internal returns (Float) {
        return Float(a.data * b.data, a.exp + b.exp);
    }

    function FP_div(Float a, Float b) internal returns (Float) {
        return Float(a.data/b.data, a.exp-b.exp);
    }

    // Int Math

    function min(int a, int b) internal constant returns (int) {
        return a < b ? a : b;
    }

    function max(int a, int b) internal constant returns (int) {
        return a > b ? a : b;
    }

    // Helper functions.

    function update_Kparam(int Kparam_data, int Kparam_invroot_data, int Kparam_exp, int Kparam_invroot_exp) onlyIssuer returns(bool) {
        Kparam.data = Kparam_data;
        Kparam_invroot.data = Kparam_invroot_data;
        Kparam.exp = Kparam_exp;
        Kparam_invroot.exp = Kparam_invroot_exp;
        return true;
    }

    function prec_check(Float a, int prec) private returns (Float) {
        if (a.exp < -prec) {
            a.data = int(uint(a.data)/(10**uint(-prec-a.exp)));
            a.exp += -prec-a.exp;
        }
        return a;
    }

    function addPrecision(Float a, int prec) private returns (Float) {
        if (prec < 0) {
            int data = a.data / int((10**uint(-prec)));
        }
        else {
            data = a.data * int((10**uint(prec)));
        }
        return Float(data, a.exp-prec);
    }

    function NR_iter(Float a, Float prev_iter) private returns(Float) {
        Float memory cubed_prev_iter = FP_mul(prev_iter,FP_mul(prev_iter,prev_iter));
        Float memory next_iter = FP_mul(FP_div(prev_iter,Float(3, 0)),(FP_sub(Float(4, 0),FP_mul(a,cubed_prev_iter))));

        return prec_check(next_iter,12);
    }

    function inv_cuberoot(Float a, Float init_guess) private returns(Float) {
        return NR_iter(a,NR_iter(a,NR_iter(a,NR_iter(a,init_guess))));
    }

    function give_guess(Float block_num) private returns (Float) {
        Float memory init_guess = Kparam_invroot;
        Float memory inv_blocknum = FP_div(Float(1000000000000000,-15),block_num);
        Float memory init_guess_chk = prec_check(Kparam_invroot,8);
        Float memory inv_blocknum_chk = prec_check(inv_blocknum,8);

        if (inv_blocknum_chk.data < init_guess_chk.data) {
            init_guess = prec_check(inv_blocknum,14);
        }
        return init_guess;
    }
}
