theory Array_Tuple imports "../Hex" "../AbiTypes" "../AbiDecode" "../AbiEncode" "../WordUtils"
begin

(* solidity *)

(*

 pragma experimental ABIEncoderV2;

 contract C {
    struct uints {
    uint256 i1;
    uint256 i2;
}
    uints [] x;   
    function getEncoding() external returns (bytes memory) {
        
        x.push (uints(uint256(1), uint256(2)));
        x.push (uints(uint256(3), uint256(4)));
        x.push (uints(uint256(21), uint256(22)));

        return abi.encode(x);
    }
}

*)

(* hex output (raw) *)

(*
{
	"0": "bytes: 0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000000016"
}
*)

(* hex output (trimmed) *)



(*
{
	"0": "bytes: 0x0000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000000016"
}
*)

definition test_in :: "8 word list" where
"test_in = hex_splits ''0000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000000016''"

definition test_schema :: abi_type where
"test_schema = Tarray (Ttuple [Tuint 256, Tuint 256])"

definition test_out :: "abi_value" where
"test_out = Varray (Ttuple [Tuint 256, Tuint 256])
            (map (Vtuple [Tuint 256, Tuint 256])
              [(map (Vuint 256) [1, 2])
              ,(map (Vuint 256) [3, 4])
              ,(map (Vuint 256) [21, 22])])"

value "decode test_schema test_in"

value "encode test_out = Some test_in"

value "bytesToEvmWords test_in"

end