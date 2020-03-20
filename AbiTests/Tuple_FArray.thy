theory Tuple_FArray imports "../AbiTypes" "../Hex" "../AbiTypesSyntax" "../AbiDecode" "../AbiEncode"

begin

(* solidity *)

(*
pragma experimental ABIEncoderV2;

struct uints {
    uint256[3] i1;
    uint256[3] i2;
}

 
 contract C {
    function getEncoding() external returns (bytes memory) {
        uint256 [3] memory x1 = [uint256(42), uint256(43), uint256(44)];
        uint256 [3] memory x2 = [uint256(50), uint256(51), uint256(52)];
        uints memory x = uints (x1, x2);
        return abi.encode(x);
    }
}

*)

(* hex output *)

(*
0x000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000002b000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000034

*)

definition test_in :: "8 word list" where
"test_in = hex_splits
''000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000002b000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000034''"

definition test_schema :: abi_type where
"test_schema = ABI_TYPE\<guillemotleft>(uint256 [3], uint256 [3])\<guillemotright>"

definition test_out :: abi_value where
"test_out = Vtuple [Tfarray (Tuint 256) 3, Tfarray (Tuint 256) 3]
            [Vfarray (Tuint 256) 3 (map (Vuint 256) [42, 43, 44]),
             Vfarray (Tuint 256) 3 (map (Vuint 256) [50, 51, 52])]"

value "test_out"

value "abi_get_type test_out = test_schema"
value "decode test_schema test_in = Ok test_out"
value "encode test_out = Ok test_in"
end
