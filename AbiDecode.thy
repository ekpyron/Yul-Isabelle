theory AbiDecode imports AbiTypes
begin
(* NB the caller of these functions will pass in a long
   enough list *)
fun decode_uint :: "8 word list \<Rightarrow> int" where
"decode_uint l =
  (Word.uint (Word.word_rcat (take 32 l) :: 256 word))"

lemma decode_uint_max :
"\<And> (x :: 256 word) . Word.uint x \<le>  max_u256"
  apply(cut_tac x = "x :: 256 word" in Word.uint_range')
  apply(auto simp add:max_u256_def)
  done

fun decode_sint :: "8 word list \<Rightarrow> int" where
"decode_sint l =
  (Word.sint (Word.word_rcat (take 32 l) :: 256 word))"

fun decode_bool :: "8 word list \<Rightarrow> bool option" where
"decode_bool l =
  (let i = decode_uint l in
   (if i = 0 then Some False
              else if i = 1 then Some True
              else None))"

fun decode_ufixed :: "nat \<Rightarrow> 8 word list \<Rightarrow> rat" where
"decode_ufixed n l =
  (let i = decode_uint l in (Rat.of_int i / (10 ^ n)))"

fun decode_fixed :: "nat \<Rightarrow> 8 word list \<Rightarrow> rat" where
"decode_fixed n l =
  (let i = decode_sint l in (Rat.of_int i / (10 ^ n)))"

(* extract byte strings of known length *)
fun decode_fbytes :: "nat \<Rightarrow> 8 word list \<Rightarrow> 8 word list" where
"decode_fbytes n l = (take n l)"


(* for dynamic types we need to use the input list to calculate size *)
(*
fun abi_type_measure_dyn :: "abi_type \<Rightarrow> int"
and abi_type_list_measure_dyn :: "abi_type list \<Rightarrow> nat" where
"abi_type_measure_dyn (Ttuple ts) = 
  1 + abi_type_list_measure_dyn ts"
| "abi_type_measure_dyn (Tfarray t n) = 1 + n + (abi_type_measure_dyn t)"
| "abi_type_measure_dyn (Tarray t) = 
    1 + (2 ^ 256) + abi_type_measure_dyn t" (* curious about this one *)
| "abi_type_measure_dyn _ _ = 1"

| "abi_type_list_measure_dyn [] l = 1"
| "abi_type_list_measure_dyn (th#tt) l =
    abi_type_measure_dyn th + 
    abi_type_list_measure_dyn + 1"
*)
(* here, again, we assume we have been passed a correct length byte string
   other than booleans, we aren't doing value checks here *)
(* TODO: enforce that correct size word list was passed in?
   otherwise we risk discarding data *)
function (sequential) decode_static_nocheck :: "abi_type \<Rightarrow> 8 word list \<Rightarrow> abi_value option" 
and decode_static_nocheck_arr :: "abi_type \<Rightarrow> nat \<Rightarrow> 8 word list \<Rightarrow> abi_value list option"
and decode_static_nocheck_tup :: "abi_type list \<Rightarrow> 8 word list \<Rightarrow> abi_value list option" where
"decode_static_nocheck (Tuint n) l =
   Some (Vuint n (decode_uint l))"
| "decode_static_nocheck (Tsint n) l =
   Some (Vsint n (decode_sint l))"
| "decode_static_nocheck Taddr l =
   Some (Vaddr (decode_uint l))"
| "decode_static_nocheck Tbool l =
   (case decode_bool l of
      None \<Rightarrow> None
      | Some b \<Rightarrow> Some (Vbool b))"
| "decode_static_nocheck (Tfixed m n) l =
    Some (Vfixed m n (decode_fixed m l))"
| "decode_static_nocheck (Tufixed m n) l =
    Some (Vufixed m n (decode_ufixed m l))"
| "decode_static_nocheck (Tfbytes n) l =
    Some (Vfbytes n (decode_fbytes n l))"
| "decode_static_nocheck (Tfarray t n) l =
  (case decode_static_nocheck_arr t n l of
    None \<Rightarrow> None
    | Some vs \<Rightarrow> Some (Vfarray t n vs))"
| "decode_static_nocheck (Ttuple ts) l = 
  (case decode_static_nocheck_tup ts l of
    None \<Rightarrow> None
    | Some vs \<Rightarrow> Some (Vtuple ts vs))"
| "decode_static_nocheck _ _ = None"

| "decode_static_nocheck_arr t 0 l = Some []"
| "decode_static_nocheck_arr t (Suc n) l =
    (case decode_static_nocheck t 
                   (take (nat (abi_static_size t)) l) of
      None \<Rightarrow> None
      | Some v \<Rightarrow> (case decode_static_nocheck_arr t n
                       (drop (nat (abi_static_size t)) l) of
          None \<Rightarrow> None
          | Some vs \<Rightarrow> Some (v#vs)))"

| "decode_static_nocheck_tup [] l = Some []"
| "decode_static_nocheck_tup (t#ts) l =
    (case decode_static_nocheck t 
                   (take (nat (abi_static_size t)) l) of
      None \<Rightarrow> None
      | Some v \<Rightarrow> (case decode_static_nocheck_tup ts 
                       (drop (nat (abi_static_size t)) l) of
          None \<Rightarrow> None
          | Some vs \<Rightarrow> Some (v#vs)))"
  by pat_completeness auto

termination
apply(relation 
"measure (\<lambda> x .
    (case x of
      Inl (t, l) \<Rightarrow> abi_type_measure t + length l
      | Inr (Inl (t, n, l)) \<Rightarrow> abi_type_measure t + n + length l
      | Inr (Inr (ts, l)) \<Rightarrow> abi_type_list_measure ts + length l))")
        apply(auto)
  done
(*
termination
  apply(relation
    "

  apply(relation 
"measure (\<lambda> x .
    (case x of
      Inl (t, l) \<Rightarrow> abi_type_empties t + length l
      | Inr (Inl (t, n, l)) \<Rightarrow> (n * abi_type_empties t) + length l
      | Inr (Inr (ts, l)) \<Rightarrow> abi_type_list_empties ts + length l))")       
        apply(fastforce)
       apply(fastforce) apply(clarsimp)
  apply(case_tac ts) apply(clarsimp) apply(clarsimp)
     apply(clarsimp)
  apply(case_tac t, auto)
  apply(case_tac n) apply(auto)
     apply(case_tac l, auto)
  done
*)

fun bytes_to_string :: "8 word list \<Rightarrow> char list" where
"bytes_to_string bs =
  List.map (\<lambda> b . char_of_integer (integer_of_int (Word.uint b))) bs"

fun tails_measure :: "(abi_value + (abi_type * nat)) list \<Rightarrow> nat" where
"tails_measure [] = 1"
| "tails_measure ((Inl _)#ts) = 1 + tails_measure ts"
| "tails_measure ((Inr (t, _))#ts) =
    abi_type_measure t + tails_measure ts"

(* TODO: need to deal with padding bytes to 256-words *)
fun skip_padding :: "nat \<Rightarrow> nat" where
"skip_padding n =
  (case divmod_nat n 32 of
    (_, 0) \<Rightarrow> n
    | (_, rem) \<Rightarrow> n + rem)"

(* TODO: consider returning a nat everywhere to make it easier to keep track
   of how much we have read, for the purposes of tuple indexing *)
function (sequential) decode_nocheck :: "abi_type \<Rightarrow> 8 word list \<Rightarrow> (abi_value * nat) option"
and decode_dyn_nocheck_array :: "abi_type \<Rightarrow> nat \<Rightarrow> 8 word list \<Rightarrow> (abi_value list * nat) option"
(* first returned nat is the length of all the heads (used for computing offsets); 
   second returned nat is number of bytes consumed;
   input nat is running count of head length. *)
and decode_dyn_nocheck_tuple_heads :: "abi_type list \<Rightarrow> nat \<Rightarrow> 8 word list \<Rightarrow> 
                (abi_value option list *  (nat option) list * nat * nat) option"
(* list parameter gives an offset for each field that still needs to be parsed
   the nat parameter is an index of how many bytes into our overall tuple encoding we are *)
and decode_dyn_nocheck_tuple_tails :: "(nat option) list \<Rightarrow> abi_type list \<Rightarrow> abi_value option list \<Rightarrow> nat \<Rightarrow> 8 word list \<Rightarrow> 
                (abi_value list * nat) option"
where
(* we need to zip earlier. *)
"decode_nocheck t l =
  (if abi_type_isstatic t
    then
      if length l < nat (abi_static_size t) then None
      else (case decode_static_nocheck t l of
            None \<Rightarrow> None
            | Some v \<Rightarrow> Some (v, nat (abi_static_size t)))
   else
    (case t of
      Tfarray t n \<Rightarrow>
        (case decode_dyn_nocheck_array t n l of
          None \<Rightarrow> None
          | Some (vs, bytes_parsed) \<Rightarrow> Some (Vfarray t n vs, bytes_parsed))
      | Tarray t \<Rightarrow>
       if length l < 32 then None
        else let n = nat (decode_uint (take 32 l)) in
        (case decode_dyn_nocheck_array t n (drop 32 l) of
          None \<Rightarrow> None
          | Some (vs, bytes_parsed) \<Rightarrow> Some (Varray t vs, bytes_parsed + 32))
      | Ttuple ts \<Rightarrow>
        (case decode_dyn_nocheck_tuple_heads ts 0 l of
          None \<Rightarrow> None
          | Some (vos, idxs, byteoffset, bytes_parsed) \<Rightarrow>
            (case decode_dyn_nocheck_tuple_tails idxs ts vos byteoffset (drop bytes_parsed l) of
              None \<Rightarrow> None
              | Some (vs, bytes_parsed') \<Rightarrow> Some (Vtuple ts vs, bytes_parsed + bytes_parsed')))
      | Tbytes \<Rightarrow>
        if length l < 32 then None
        else let sz = nat (decode_uint (take 32 l)) in
             if length l - 32 < sz then None
             else Some (Vbytes (take sz (drop 32 l)), skip_padding sz + 32)
      | Tstring \<Rightarrow> 
        if length l < 32 then None
        else let sz = nat (decode_uint (take 32 l)) in
             if length l - 32 < sz then None
             else Some (Vstring (bytes_to_string (take sz (drop 32 l))), skip_padding sz + 32)
      | _ \<Rightarrow> None))"

(*| "decode_dyn_nocheck_array t 0 [] = Some ([], [])"
| "decode_dyn_nocheck_array t n [] = None" *)
| "decode_dyn_nocheck_array t 0 l = Some ([], 0)"
| "decode_dyn_nocheck_array t (Suc n') l =
    (case decode_nocheck t l of
      None \<Rightarrow> None
      | Some (v, bytes_parsed) \<Rightarrow> (case decode_dyn_nocheck_array t n' (drop bytes_parsed l) of
                          None \<Rightarrow> None
                          | Some (vt, bytes_parsed') \<Rightarrow> Some (v#vt, bytes_parsed + bytes_parsed')))"

(* need to do something with updating indices here *)
(* Also. how do we deal with ill-formed data such that the tails
and heads overlap? *)
| "decode_dyn_nocheck_tuple_heads [] n l = Some ([], [], n, 0)"
| "decode_dyn_nocheck_tuple_heads (th#tt) n l =
    (if abi_type_isstatic th
      then (case decode_nocheck th l of
        None \<Rightarrow> None
        | Some (v, bytes_parsed) \<Rightarrow>
          (case decode_dyn_nocheck_tuple_heads tt (n + nat (abi_static_size th)) (drop bytes_parsed l) of
            None \<Rightarrow> None
            | Some (vos, idxs, n', bytes_parsed') \<Rightarrow> Some (Some v # vos, None#idxs, n', bytes_parsed + bytes_parsed')))
    else
      (if length l < 32 then None
       else let sz = nat (decode_uint (take 32 l)) in
            (case decode_dyn_nocheck_tuple_heads tt (n + 32) (drop 32 l) of
              None \<Rightarrow> None
              | Some (vos, idxs, n', bytes_parsed) \<Rightarrow> Some (None # vos, (Some n)#idxs, n', bytes_parsed + 32))))"

| "decode_dyn_nocheck_tuple_tails [] [] []  _ l = Some ([], 0)"
(* now we need to change the way we deal with value lists *)
| "decode_dyn_nocheck_tuple_tails (None#t) (th#tt) (Some vh#vt) offset l = 
   (case decode_dyn_nocheck_tuple_tails t tt vt offset l of
    None \<Rightarrow> None
    | Some (vs, bytes_parsed) \<Rightarrow> Some (vh#vs, bytes_parsed))"
| "decode_dyn_nocheck_tuple_tails ((Some toffset)#t) (th#tt) (None#vt) offset l =
   (if toffset \<noteq> offset then None
      else
       (case decode_nocheck th l of
              None \<Rightarrow> None
              | Some (v, bytes_parsed) \<Rightarrow>
                     let offset' = offset + bytes_parsed in
                     (case decode_dyn_nocheck_tuple_tails t tt vt offset' (drop bytes_parsed l) of
                           None \<Rightarrow> None
                           | Some (vs, bytes_parsed') \<Rightarrow> Some (v#vs, bytes_parsed + bytes_parsed'))))
                          
      "
| "decode_dyn_nocheck_tuple_tails _ _ _ _ _ = None"
(*
| "decode_dyn_nocheck_tuple_tails (Inl v # t) n l =
   (case decode_dyn_nocheck_tuple_tails t n l of
      None \<Rightarrow> None
      | Some (vs, bytes_parsed) \<Rightarrow> Some (v#vs, bytes_parsed))"
(* is it too strict to force offset to equal n? *)
| "decode_dyn_nocheck_tuple_tails (Inr (typ, offset) # t) n l =
  (if offset \<noteq> n then None
   else (case decode_nocheck typ l of
          None \<Rightarrow> None
          | Some (v, bytes_parsed) \<Rightarrow>
            let n' = n + (length l - bytes_parsed) in
            (case decode_dyn_nocheck_tuple_tails t n' (drop bytes_parsed l) of
              None \<Rightarrow> None
              | Some (vs, bytes_parsed') \<Rightarrow> Some (v#vs, bytes_parsed + bytes_parsed'))))"
*)
  by pat_completeness auto

(*
abbreviation decode_nocheck_dom where
"decode_nocheck_dom \<equiv>
decode_nocheck_decode_dyn_nocheck_array_decode_dyn_nocheck_tuple_heads_decode_dyn_nocheck_tuple_tails_dom"

lemma decode_dyn_suffix :
  fixes t
  shows "\<And> l v l' . 
          decode_nocheck_dom (Inl (Inl (t, l))) \<Longrightarrow>
          decode_nocheck t l = Some (v, l') \<Longrightarrow>
          \<exists> n . l' = drop n l"
  apply(induction t)
              apply(auto simp add: decode_nocheck.psimps split:if_splits option.splits)
      apply(case_tac t, auto split:option.splits)
  
  apply(case_tac l, auto)
*)
(*
lemma tails_measure_bound [rule_format] :
fixes x
shows "\<forall> n l a aa b .
      (decode_dyn_nocheck_tuple_heads x n l = Some (a, aa, b) \<longrightarrow>
       decode_nocheck_decode_dyn_nocheck_array_decode_dyn_nocheck_tuple_heads_decode_dyn_nocheck_tuple_tails_dom
        (Inr (Inl (x, n, l))) \<longrightarrow>
      tails_measure a \<le> abi_type_list_measure x)" 
  apply(induction x)
   apply(auto simp add:decode_dyn_nocheck_tuple_heads.psimps)
  apply(auto split: if_splits option.splits prod.splits)
   apply(drule_tac x = "(n + nat (abi_static_size a))" in spec)
   apply(drule_tac x = "(drop x2a l)" in spec)
   apply(drule_tac x = x1a in spec)
   apply(auto)
  apply(case_tac n)
apply(frule_tac decode_dyn_nocheck_tuple_heads.psimps) apply(auto)
*)

fun somes :: "'a option list \<Rightarrow> 'a list" where
"somes [] = []"
| "somes (None#t) = somes t"
| "somes (Some h#t) = h # somes t"

termination decode_nocheck

  apply(relation 
"measure (\<lambda> x .
    (case x of
       Inl (Inl (t, l)) \<Rightarrow> abi_type_measure t + length l 
      | Inl (Inr (t, n, l)) \<Rightarrow> abi_type_measure t + n + length l
      | Inr (Inl (ts,  n, l)) \<Rightarrow> abi_type_list_measure ts + length l
      | Inr (Inr (idxs, ts, vs, n, l)) \<Rightarrow> abi_type_list_measure ts + length l))")     apply(fastforce)
             apply(auto)
  (* array case: length < 2^256 - 1 *)
  apply(cut_tac w = "(word_rcat (take 32 l) :: 256 word)" in Word.uint_lt)
  apply(simp add:max_u256_def)
  done

fun decode :: "abi_type \<Rightarrow> 8 word list \<Rightarrow> abi_value option" where
"decode t l =
  (case decode_nocheck t l of
    None \<Rightarrow> None
    | Some (v, _) \<Rightarrow>
    (if abi_value_valid v then Some v else None))"

(* head = offset at which tail can be found
   tail = encoding of dynamic object *)

(* functions: TODO *)

(* fun abi_encode ::
    abi_value \<Rightarrow> 8 word list option *)
(* fun abi_decode ::
    8 word list \<Rightarrow> abi_value option *)

(* need an ABI types data type*)
(* do we represent these here as words, or
   as abstract types? *)

(*
datatype AbiValueWord =
  Uint "nat" "256 word"
  | Sint "nat" "256 word"
  | Addr "160 word"
  (* uint, sint : synonyms for uint256/sint256 *)
  | Bl "8 word"
  | Fixed "nat" "nat" "256 word"
  | Ufixed "nat" "nat" "256 word"
  | Bytes "nat" "256 word"
  | Function "160 word" "32 word"
*)

(* encoder *)
(* encode :: abi_value \<Rightarrow> 8 word list *)

end