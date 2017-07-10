pragma solidity ^0.4.11;

contract ProofOfStake {
    // variables

    Float Kparam = Float(0,0);
    Float Kparam_invroot = Float(0,0);

    // constructor
    function ProofOfStake() {
    }


    struct Float {
        int data;
        int exp;
    }

    modifier onlyIssuer() { if (msg.sender == issuer) _; }

    /*Float block_target = Float(36500000,-5);
    Float bias = Float(10100000,-7);
    Float init_reward = Float(2,-1);
    Float target_reward = Float(8,-1);*/

    //Float test0 = sub(target_reward,init_reward);

    //Float Kparam = Kparam_calc(Float(185505800,-2),Float(101,-2),Float(2,-1),Float(8,-1));
    //Float Kparam = Float(71013837700,-3);
    //Float test_reward = reward(Float(4*185505800,-2),Float(101,-2),Kparam,Float(2,-1));
    //Float invcube = inv_cuberoot(Float(50,1),Float(12,-2));
    // baked in floatmath

    // baked in safemath

    function update_Kparam(int Kparam_data, int Kparam_exp, int Kparam_invroot_data, int Kparam_invroot_exp) onlyIssuer returns(bool) {
        Kparam.data = Kparam_data;
        Kparam.exp = Kparam_exp;
        Kparam_invroot.data = Kparam_invroot_data;
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

    function mul(Float a, Float b) internal returns (Float) {
        return Float(a.data * b.data, a.exp + b.exp);
    }

    function div(Float a, Float b) internal returns (Float) {
        return Float(a.data/b.data, a.exp-b.exp);
    }

    function sub(Float a, Float b) internal returns (Float) {
        int base_exp = min(a.exp, b.exp);
        int exp_dif = max(a.exp, b.exp) - base_exp;

        if (a.exp == base_exp) {
            b.exp -= exp_dif;
            Float memory k = mul(Float(b.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            b.data = k.data;
        }
        else {
            a.exp -= exp_dif;
            Float memory l = mul(Float(a.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            a.data = l.data;
        }

        return Float(a.data-b.data, base_exp);
    }

    function add(Float a, Float b) internal returns (Float) {
        int base_exp = min(a.exp, b.exp);
        int exp_dif = max(a.exp, b.exp) - base_exp;

        if (a.exp == base_exp) {
            b.exp -= exp_dif;
            Float memory k = mul(Float(b.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            b.data = k.data;
        }
        else {
            a.exp -= exp_dif;
            Float memory l = mul(Float(a.data,0), Float(int(10**uint(exp_dif)),exp_dif));

            a.data = l.data;
        }

        return Float(a.data+b.data, base_exp);
    }


    // function floatToInt(Float a) internal returns (int) {
    //     return a.data*(10**a.exp);
    // }

    function min(int a, int b) internal constant returns (int) {
        return a < b ? a : b;
    }

    function max(int a, int b) internal constant returns (int) {
        return a > b ? a : b;
    }

    function NR_iter(Float a, Float prev_iter) private returns(Float) {
        Float memory cubed_prev_iter = mul(prev_iter,mul(prev_iter,prev_iter));
        Float memory next_iter = mul(div(prev_iter,Float(3, 0)),(sub(Float(4, 0),mul(a,cubed_prev_iter))));

        return prec_check(next_iter,12);
    }

    function inv_cuberoot(Float a, Float init_guess) private returns(Float) {
        return NR_iter(a,NR_iter(a,NR_iter(a,NR_iter(a,init_guess))));
    }

    /*function Kparam_calc(Float block_target, Float bias, Float init_reward, Float target_reward) private returns(Float) {
        Float memory numerator = mul(sub(bias,init_reward),block_target);
        Float memory denominator = sub(target_reward,init_reward);
        Float memory fraction = div(numerator,denominator);

        Float memory cubed_fraction = mul(fraction,mul(fraction,fraction));
        Float memory cubed_block_target = mul(block_target,mul(block_target,block_target));
        return sub(cubed_fraction,cubed_block_target);
    }*/

    function give_guess(Float block_num) private returns (Float) {
        //Float memory init_guess = Float(47513939800,-17);
        Float memory inv_blocknum = div(Float(1000000000000000,-15),block_num);
        //Float memory init_guess_chk = prec_check(init_guess,8);
        Float memory init_guess_chk = prec_check(Kparam_invroot,8)
        Float memory inv_blocknum_chk = prec_check(inv_blocknum,8);
        
        if (inv_blocknum_chk.data < init_guess_chk.data) {
            init_guess = prec_check(inv_blocknum,12);
        }
        return init_guess;
    }

    function reward(Float block_num, Float bias, Float Kparam, Float init_reward) private returns(Float) {
        //if (floatToInt(bias) < 1 && floatToInt(Kparam) < 0) throw;
        //if (0 > floatToInt(init_reward) && floatToInt(init_reward) > 1) throw;

        Float memory inv_root = inv_cuberoot(add(mul(block_num,mul(block_num,block_num)),Kparam),give_guess(block_num));
        Float memory reward = add(mul(mul(sub(bias,init_reward),block_num),inv_root),init_reward);

        if (reward.data > int(10**uint(-reward.exp))) {reward = Float(1,0);}
        return reward;
    }

    /*function Kparam_investor_update(Float curr_amount, Float new_amount, Float curr_Kparam, Float block_num, Float init_reward, Float bias) private returns (Float) {
        //if (floatToInt(curr_amount) >= floatToInt(new_amount)) throw;
        Float memory curr_reward = reward(block_num,bias,curr_Kparam,init_reward);
        Float memory new_reward = mul(curr_reward,div(new_amount,curr_amount));
        Float memory new_Kparam = Kparam_calc(block_num,bias,init_reward,new_reward);
        return new_Kparam;
    }*/
}
