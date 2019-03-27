theory ASC_Suite
imports ASC_LB
begin

(* maximum length contained prefix *)
fun mcp :: "'a list \<Rightarrow> 'a list set \<Rightarrow> 'a list \<Rightarrow> bool" where
  "mcp z W p = (prefix p z \<and> p \<in> W \<and> 
                 (\<forall> p' . (prefix p' z \<and> p' \<in> W) \<longrightarrow> length p' \<le> length p))"

(* def. for contained common prefix :
  "mcp z W p = (p \<in> {p . prefix p z \<and> (\<exists> w \<in> W . prefix p w)}
                \<and> (\<forall> p' \<in> {p . prefix p z \<and> (\<exists> w \<in> W . prefix p w)} .
                  length p' \<le> length p))"
*)

lemma mcp_ex :
  assumes "[] \<in> W"
  and     "finite W"
obtains p
where "mcp z W p"  
proof -
  let ?P = "{p . prefix p z \<and> p \<in> W}"
  let ?maxP = "arg_max length (\<lambda> p . p \<in> ?P)"

  have "finite {p . prefix p z}" 
  proof -
    have "{p . prefix p z} \<subseteq> image (\<lambda> i . take i z) (set [0 ..< Suc (length z)])"
    proof 
      fix p assume "p \<in> {p . prefix p z}"
      then obtain i where "i \<le> length z \<and> p = take i z"
        by (metis append_eq_conv_conj mem_Collect_eq prefix_def prefix_length_le) 
      then have "i < Suc (length z) \<and> p = take i z" by simp
      then show "p \<in> image (\<lambda> i . take i z) (set [0 ..< Suc (length z)])" 
        using atLeast_upt by blast  
    qed
    then show ?thesis using finite_surj by blast 
  qed
  then have "finite ?P" by simp 

  have "?P \<noteq> {}"
    using Nil_prefix assms(1) by blast 

  have "\<exists> maxP \<in> ?P . \<forall> p \<in> ?P . length p \<le> length maxP" 
  proof (rule ccontr)
    assume "\<not>(\<exists> maxP \<in> ?P . \<forall> p \<in> ?P . length p \<le> length maxP)" 
    then have "\<forall> p \<in> ?P . \<exists> p' \<in> ?P . length p < length p'" by (meson not_less) 
    then have "\<forall> l \<in> (image length ?P) . \<exists> l' \<in> (image length ?P) . l < l'" by auto 
    
    then have "infinite (image length ?P)" by (metis (no_types, lifting) \<open>?P \<noteq> {}\<close> image_is_empty infinite_growing) 
    then have "infinite ?P" by blast 
    then show "False" using \<open>finite ?P\<close> by simp
  qed 

  then obtain maxP where "maxP \<in> ?P" "\<forall> p \<in> ?P . length p \<le> length maxP" by blast

  then have "mcp z W maxP" unfolding mcp.simps by blast 
  then show ?thesis using that by auto
qed


lemma mcp_unique :
  assumes "mcp z W p" 
  and     "mcp z W p'"
shows "p = p'"
proof -
  have "length p' \<le> length p" using assms(1) assms(2) by auto 
  moreover have "length p \<le> length p'" using assms(1) assms(2) by auto
  ultimately have "length p' = length p" by simp

  moreover have "prefix p z" using assms(1) by auto
  moreover have "prefix p' z" using assms(2) by auto
  ultimately show ?thesis by (metis append_eq_conv_conj prefixE)
qed

fun mcp' :: "'a list \<Rightarrow> 'a list set \<Rightarrow> 'a list" where
  "mcp' z W = (THE p . mcp z W p)"

lemma mcp'_intro : 
  assumes "mcp z W p"
shows "mcp' z W = p"
using assms mcp_unique by (metis mcp'.elims theI_unique) 


fun N :: "('in \<times> 'out) list \<Rightarrow> ('in, 'out, 'state) FSM \<Rightarrow> 'in list set \<Rightarrow> ('in \<times> 'out) list set set" where
  "N io M V = { V'' \<in> Perm V M . (map fst (mcp' io V'')) = (mcp' (map fst io) V) }"
(*
  "N io M V = { V'' \<in> Perm V M . \<exists> vs \<in> V'' . (mcp' (map fst io) V) = map fst vs 
                                              \<and> prefix vs io }"
*)
(*
  "N io M V = { V'' \<in> Perm V M . \<exists> v . prefix v (map fst io) \<and> 
                            (\<forall> w . prefix w (map fst io) \<longrightarrow> (length w > length v \<longrightarrow> w \<notin> V))
                            \<and> (\<exists> v' . length v' = length v \<and> (v || v') \<in> V'' \<and> prefix (v || v') io)}"
*)

(* TODO - show that construction is nonempty
lemma N_nonempty :
  assumes "[] \<in> V"
  shows "N io M V \<noteq> {}"
*)

(* Corollary 7.1.2 *)
lemma x :
  assumes "map fst vs = mcp' (map fst (vs@xs)) V"
  and     "V'' \<in> N (vs@xs) M1 V"
  and     "is_det_state_cover M2 V"
  and     "well_formed M2"
  and     "finite V"
shows "vs \<in> V'' \<and> vs = mcp' (vs@xs) V''" 
proof 
  have "map fst (mcp' (vs@xs) V'') = mcp' (map fst (vs@xs)) V" using assms(2) by auto
  then have "map fst (mcp' (vs@xs) V'') = map fst vs" using assms(1) by presburger
  then have "length (mcp' (vs@xs) V'') = length vs" by (metis length_map) 

  have "[] \<in> V''" using perm_empty[OF assms(3)] N.simps assms(2) by blast 
  moreover have "finite V''" using perm_elem_finite[OF assms(3,4)] N.simps assms(2) by blast
  ultimately obtain p where "mcp (vs@xs) V'' p" using mcp_ex by auto 
  then have "mcp' (vs@xs) V'' = p" using mcp'_intro by simp
  

  then have "prefix (mcp' (vs@xs) V'') (vs@xs)" unfolding mcp'.simps mcp.simps
    using \<open>mcp (vs @ xs) V'' p\<close> mcp.elims(2) by blast 
  then show "vs = mcp' (vs@xs) V''"
    by (metis \<open>length (mcp' (vs @ xs) V'') = length vs\<close> append_eq_append_conv prefix_def) 

  show "vs \<in> V''"
    using \<open>mcp (vs @ xs) V'' p\<close> \<open>mcp' (vs @ xs) V'' = p\<close> \<open>vs = mcp' (vs @ xs) V''\<close> by auto 
qed


abbreviation append_set :: "'a list set \<Rightarrow> 'a set \<Rightarrow> 'a list set" where
  "append_set T X \<equiv> {xs @ [x] | xs x . xs \<in> T \<and> x \<in> X}"

abbreviation append_sets :: "'a list set \<Rightarrow> 'a list set \<Rightarrow> 'a list set" where
  "append_sets T X \<equiv> {xs @ xs' | xs xs' . xs \<in> T \<and> xs' \<in> X}"

(* sets for generating the test suite :
   TS = Test Suite
   C  = currently considered sequences
   RM = sequences to remove
*)
fun TS :: "('in, 'out, 'state1) FSM \<Rightarrow> ('in, 'out, 'state2) FSM \<Rightarrow> 'in list set \<Rightarrow> 'state1 set \<Rightarrow> ('in, 'out) ATC set \<Rightarrow> 'in list set \<Rightarrow> nat \<Rightarrow> 'in list set" 
and C  :: "('in, 'out, 'state1) FSM \<Rightarrow> ('in, 'out, 'state2) FSM \<Rightarrow> 'in list set \<Rightarrow> 'state1 set \<Rightarrow> ('in, 'out) ATC set \<Rightarrow> 'in list set \<Rightarrow> nat \<Rightarrow> 'in list set"   
and RM :: "('in, 'out, 'state1) FSM \<Rightarrow> ('in, 'out, 'state2) FSM \<Rightarrow> 'in list set \<Rightarrow> 'state1 set \<Rightarrow> ('in, 'out) ATC set \<Rightarrow> 'in list set \<Rightarrow> nat \<Rightarrow> 'in list set"   
where
  "RM M2 M1 T S \<Omega> V 0 = {}" |
  "TS M2 M1 T S \<Omega> V 0 = {}" |
  "TS M2 M1 T S \<Omega> V (Suc 0) = V" |
  "C M2 M1 T S \<Omega> V 0 = {}" |
  "C M2 M1 T S \<Omega> V (Suc 0) = V" |
  "RM M2 M1 T S \<Omega> V (Suc n) = 
    {xs' \<in> C M2 M1 T S \<Omega> V (Suc n) .
      (\<exists> vs xs . (vs@xs) \<in> language_state_in M1 (initial M1) {xs'}
        \<and> (\<exists> S1 . S1 \<subseteq> S
          \<and> (\<exists> V'' \<in> N (vs@xs) M1 V . 
            vs = mcp' (vs@xs) V''
            \<and> (\<forall> s1 \<in> S1 . \<forall> s2 \<in> S1 .
              s1 \<noteq> s2 \<longrightarrow> 
                (\<forall> io1 \<in> RP M2 s1 vs xs V'' .
                   \<forall> io2 \<in> RP M2 s2 vs xs V'' .
                     B M1 io1 \<Omega> \<noteq> B M1 io2 \<Omega> )))))}" |
  "C M2 M1 T S \<Omega> V (Suc n) = (append_set ((C M2 M1 T S \<Omega> V n) - (RM M2 M1 T S \<Omega> V n)) (inputs M2)) - (TS M2 M1 T S \<Omega> V n)" |
  "TS M2 M1 T S \<Omega> V (Suc n) = (TS M2 M1 T S \<Omega> V n) \<union> (C M2 M1 T S \<Omega> V (Suc n))" 
    
    


(* Properties of the generated sets *)
abbreviation lists_of_length :: "'a set \<Rightarrow> nat \<Rightarrow> 'a list set" where 
  "lists_of_length X n \<equiv> {xs . length xs = n \<and> set xs \<subseteq> X}"

lemma append_lists_of_length_alt_def :
  "append_sets T (lists_of_length X (Suc n)) = append_set (append_sets T (lists_of_length X n)) X"
proof 
  show "append_sets T (lists_of_length X (Suc n)) \<subseteq> append_set (append_sets T (lists_of_length X n)) X"
  proof 
    fix tx assume "tx \<in> append_sets T (lists_of_length X (Suc n))"
    then obtain t x where "t@x = tx" "t \<in> T" "length x = Suc n" "set x \<subseteq> X" by blast
    then have "x \<noteq> []" "length (butlast x) = n" by auto
    moreover have "set (butlast x) \<subseteq> X" using \<open>set x \<subseteq> X\<close> by (meson dual_order.trans prefixeq_butlast set_mono_prefix) 
    ultimately have "butlast x \<in> lists_of_length X n" by auto
    then have "t@(butlast x) \<in> append_sets T (lists_of_length X n)" using \<open>t \<in> T\<close> by blast
    moreover have "last x \<in> X" using \<open>set x \<subseteq> X\<close> \<open>x \<noteq> []\<close> by auto
    ultimately have "t@(butlast x)@[last x] \<in> append_set (append_sets T (lists_of_length X n)) X" by auto
    then show "tx \<in> append_set (append_sets T (lists_of_length X n)) X" using \<open>t@x = tx\<close> by (simp add: \<open>x \<noteq> []\<close>) 
  qed
  show "append_set (append_sets T (lists_of_length X n)) X \<subseteq> append_sets T (lists_of_length X (Suc n))"
  proof 
    fix tx assume "tx \<in> append_set (append_sets T (lists_of_length X n)) X"
    then obtain tx' x where "tx = tx' @ [x]" "tx' \<in> append_sets T (lists_of_length X n)" "x \<in> X" by blast
    then obtain tx'' x' where "tx''@x' = tx'" "tx'' \<in> T" "length x' = n" "set x' \<subseteq> X" by blast
    then have "tx''@x'@[x] = tx" "tx'' \<in> T" "length (x'@[x]) = Suc n" "set (x'@[x]) \<subseteq> X" 
      apply (simp add: \<open>tx = tx' @ [x]\<close>)
      apply (meson \<open>tx'' \<in> T\<close>)
      apply (simp add: \<open>length x' = n\<close>)+
      by (simp add: \<open>set x' \<subseteq> X\<close> \<open>x \<in> X\<close>)
    then show "tx \<in> append_sets T (lists_of_length X (Suc n))" by blast
  qed
qed

lemma C_step : 
  assumes "n > 0"
  shows "C M2 M1 T S \<Omega> V (Suc n) \<subseteq> (append_set (C M2 M1 T S \<Omega> V n) (inputs M2)) - C M2 M1 T S \<Omega> V n"
proof -
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  obtain k where n_def[simp] : "n = Suc k" using assms
    using not0_implies_Suc by blast 

  have "?C (Suc n) = (append_set (?C n - ?RM n) (inputs M2)) - ?TS n" using n_def using C.simps(3) by blast
  moreover have "?C n \<subseteq> ?TS n" using n_def by (metis C.simps(2) TS.elims UnCI assms neq0_conv subsetI)  
  ultimately show "?C (Suc n) \<subseteq> append_set (?C n) (inputs M2) - ?C n" by blast
qed


lemma C_extension : 
  "C M2 M1 T S \<Omega> V (Suc n) \<subseteq> append_sets V (lists_of_length (inputs M2) n)"
proof (induction n)
  case 0
  then show ?case by auto
next
  case (Suc k)

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  have "0 < Suc k" by simp
  have "?C (Suc (Suc k)) \<subseteq> (append_set (?C (Suc k)) (inputs M2)) - ?C (Suc k)" using C_step[OF \<open>0 < Suc k\<close>] by blast

  then have "?C (Suc (Suc k)) \<subseteq> append_set (?C (Suc k)) (inputs M2)" by blast
  moreover have "append_set (?C (Suc k)) (inputs M2) \<subseteq> append_set (append_sets V (lists_of_length (inputs M2) k)) (inputs M2)"
    using Suc.IH by auto 
  ultimately have I_Step : "?C (Suc (Suc k)) \<subseteq> append_set (append_sets V (lists_of_length (inputs M2) k)) (inputs M2)"
    by (meson order_trans) 

  show ?case using append_lists_of_length_alt_def[symmetric, of V k "inputs M2"] I_Step by presburger  
qed

lemma TS_union : 
shows "TS M2 M1 T S \<Omega> V i = (\<Union> j \<in> (set [0..<Suc i]) . C M2 M1 T S \<Omega> V j)" 
proof (induction i)
  case 0
  then show ?case by auto
next
  case (Suc i)

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  have "?TS (Suc i) = ?TS i \<union> ?C (Suc i)"
    by (metis (no_types) C.simps(2) TS.simps(1) TS.simps(2) TS.simps(3) not0_implies_Suc sup_bot.right_neutral sup_commute)
  then have "?TS (Suc i) = (\<Union> j \<in> (set [0..<Suc i]) . ?C j) \<union> ?C (Suc i)" using Suc.IH by simp
  then show ?case by auto 
qed




lemma C_disj_le_gz : 
  assumes "i \<le> j"
  and    "0 < i"
shows "C M2 M1 T S \<Omega> V i \<inter> C M2 M1 T S \<Omega> V (Suc j) = {}"
proof -
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  have "Suc 0 < Suc j" using assms(1-2) by auto
  then obtain k where "Suc j = Suc (Suc k)" using not0_implies_Suc by blast 
  then have "?C (Suc j) = (append_set (?C j - ?RM j) (inputs M2))  - ?TS j" using C.simps(3) by blast
  then have "?C (Suc j) \<inter> ?TS j = {}" by blast
  moreover have "?C i \<subseteq> ?TS j" using assms(1) TS_union[of M2 M1 T S \<Omega> V j] by fastforce  
  ultimately show ?thesis by blast
qed

lemma C_disj_lt : 
  assumes "i < j"
shows "C M2 M1 T S \<Omega> V i \<inter> C M2 M1 T S \<Omega> V j = {}"
proof (cases i)
  case 0
  then show ?thesis by auto
next
  case (Suc k)
  then show ?thesis using C_disj_le_gz
    by (metis assms gr_implies_not0 less_Suc_eq_le old.nat.exhaust zero_less_Suc)
qed 

lemma C_disj :
  assumes "i \<noteq> j"
shows "C M2 M1 T S \<Omega> V i \<inter> C M2 M1 T S \<Omega> V j = {}"
  by (metis C_disj_lt Int_commute antisym_conv3 assms)
  



lemma RM_subset : "RM M2 M1 T S \<Omega> V i \<subseteq> C M2 M1 T S \<Omega> V i" 
proof (cases i)
  case 0
  then show ?thesis by auto
next
  case (Suc n)
  then show ?thesis using RM.simps(2) by blast
qed


lemma RM_disj : 
  assumes "i \<le> j"
  and    "0 < i"
shows "RM M2 M1 T S \<Omega> V i \<inter> RM M2 M1 T S \<Omega> V (Suc j) = {}"
proof -
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  have "?RM i \<subseteq> ?C i" "?RM (Suc j) \<subseteq> ?C (Suc j)" using RM_subset by blast+
  moreover have "?C i \<inter> ?C (Suc j) = {}" using C_disj_le_gz[OF assms] by assumption
  ultimately show ?thesis by blast
qed



lemma T_extension : 
  assumes "n > 0"
  shows "TS M2 M1 T S \<Omega> V (Suc n) - TS M2 M1 T S \<Omega> V n \<subseteq> (append_set (TS M2 M1 T S \<Omega> V n) (inputs M2)) - TS M2 M1 T S \<Omega> V n"
proof -
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  obtain k where n_def[simp] : "n = Suc k" using assms
    using not0_implies_Suc by blast 

  have "?C (Suc n) = (append_set (?C n - ?RM n) (inputs M2)) - ?TS n" using n_def using C.simps(3) by blast
  then have "?C (Suc n) \<subseteq> append_set (?C n) (inputs M2) - ?TS n" by blast
  moreover have "?C n \<subseteq> ?TS n" using TS_union[of M2 M1 T S \<Omega> V n] by fastforce
  ultimately have "?C (Suc n) \<subseteq> append_set (?TS n) (inputs M2) - ?TS n" by blast
  moreover have "?TS (Suc n) - ?TS n \<subseteq> ?C (Suc n) " using TS.simps(3)[of M2 M1 T S \<Omega> V k] using n_def by blast
  ultimately show ?thesis by blast
qed


lemma append_set_prefix :
  assumes "xs \<in> append_set T X"
  shows "butlast xs \<in> T"
  using assms by auto 


lemma C_subset : "C M2 M1 T S \<Omega> V i \<subseteq> TS M2 M1 T S \<Omega> V i"
  by (simp add: TS_union) 
  

lemma TS_subset :
  assumes "i \<le> j"
  shows "TS M2 M1 T S \<Omega> V i \<subseteq> TS M2 M1 T S \<Omega> V j"
proof -
  have "TS M2 M1 T S \<Omega> V i = (\<Union> k \<in> (set [0..<Suc i]) . C M2 M1 T S \<Omega> V k)" 
       "TS M2 M1 T S \<Omega> V j = (\<Union> k \<in> (set [0..<Suc j]) . C M2 M1 T S \<Omega> V k)" using TS_union by assumption+
  moreover have "set [0..<Suc i] \<subseteq> set [0..<Suc j]" using assms by auto
  ultimately show ?thesis by blast
qed
  
  



lemma C_immediate_prefix_containment :
  assumes "vs@xs \<in> C M2 M1 T S \<Omega> V (Suc (Suc i))"
  and     "xs \<noteq> []"
shows "vs@(butlast xs) \<in> C M2 M1 T S \<Omega> V (Suc i) - RM M2 M1 T S \<Omega> V (Suc i)"
proof (rule ccontr)
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  assume "vs @ butlast xs \<notin> C M2 M1 T S \<Omega> V (Suc i) - RM M2 M1 T S \<Omega> V (Suc i)"

  have "?C (Suc (Suc i)) \<subseteq> append_set (?C (Suc i) - ?RM (Suc i)) (inputs M2)"
    using C.simps(3) by blast 
  then have "?C (Suc (Suc i)) \<subseteq> append_set (?C (Suc i) - ?RM (Suc i)) UNIV" by blast
  moreover have "vs @ xs \<notin> append_set (?C (Suc i) - ?RM (Suc i)) UNIV"
  proof -
    have "\<forall>as a. vs @ xs \<noteq> as @ [a] \<or> as \<notin> C M2 M1 T S \<Omega> V (Suc i) - RM M2 M1 T S \<Omega> V (Suc i) \<or> a \<notin> UNIV"
      by (metis \<open>vs @ butlast xs \<notin> C M2 M1 T S \<Omega> V (Suc i) - RM M2 M1 T S \<Omega> V (Suc i)\<close> assms(2) butlast_append butlast_snoc)
    then show ?thesis
      by blast
  qed
  ultimately have "vs @ xs \<notin> ?C (Suc (Suc i))" by blast
  then show "False" using assms(1) by blast
qed



  
  
(* Lemma 5.5.5 *)
lemma TS_immediate_prefix_containment :
  assumes "vs@xs \<in> TS M2 M1 T S \<Omega> V i"
  and     "mcp (vs@xs) V vs"
  and     "0 < i"
shows "vs@(butlast xs) \<in> TS M2 M1 T S \<Omega> V i"
proof -
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  obtain j where j_def : "j \<le> i \<and> vs@xs \<in> ?C j" using assms(1)  TS_union[where i=i]
  proof -
    assume a1: "\<And>j. j \<le> i \<and> vs @ xs \<in> C M2 M1 T S \<Omega> V j \<Longrightarrow> thesis"
    obtain nn :: "nat set \<Rightarrow> (nat \<Rightarrow> 'a list set) \<Rightarrow> 'a list \<Rightarrow> nat" where
      f2: "\<forall>x0 x1 x2. (\<exists>v3. v3 \<in> x0 \<and> x2 \<in> x1 v3) = (nn x0 x1 x2 \<in> x0 \<and> x2 \<in> x1 (nn x0 x1 x2))"
      by moura
    have "vs @ xs \<in> UNION (set [0..<Suc i]) (C M2 M1 T S \<Omega> V)"
      by (metis \<open>\<And>\<Omega> V T S M2 M1. TS M2 M1 T S \<Omega> V i = (\<Union>j\<in>set [0..<Suc i]. C M2 M1 T S \<Omega> V j)\<close> \<open>vs @ xs \<in> TS M2 M1 T S \<Omega> V i\<close>)
    then have "nn (set [0..<Suc i]) (C M2 M1 T S \<Omega> V) (vs @ xs) \<in> set [0..<Suc i] \<and> vs @ xs \<in> C M2 M1 T S \<Omega> V (nn (set [0..<Suc i]) (C M2 M1 T S \<Omega> V) (vs @ xs))"
      using f2 by blast
    then show ?thesis
      using a1 by (metis (no_types) atLeastLessThan_iff leD not_less_eq_eq set_upt)
  qed 

  show ?thesis
  proof (cases j)
    case 0
    then have "?C j = {}" by auto
    moreover have "vs@xs \<in> {}" using j_def 0 by auto
    ultimately show ?thesis by auto  
  next
    case (Suc k)
    then show ?thesis 
    proof (cases k)
      case 0
      then have "?C j = V" using Suc by auto 
      then have "vs@xs \<in> V" using j_def by auto
      then have "mcp (vs@xs) V (vs@xs)" using assms(2) by auto
      then have "vs@xs = vs" using assms(2) mcp_unique by auto
      then have "butlast xs = []" by auto
      then show ?thesis using \<open>vs @ xs = vs\<close> assms(1) by auto
    next
      case (Suc m)
      assume j_assms : "j = Suc k" "k = Suc m"
      then have "?C (Suc (Suc m)) = append_set (?C (Suc m) - ?RM (Suc m)) (inputs M2) - ?TS (Suc m)"
        using C.simps(3) by blast 
      then have "?C (Suc (Suc m)) \<subseteq> append_set (?C (Suc m)) (inputs M2)" by blast
      
      have "vs@xs \<in> ?C (Suc (Suc m))" using j_assms j_def by blast
      
      have "butlast (vs@xs) \<in> ?C (Suc m)"
      proof -
        show ?thesis
          by (meson \<open>?C (Suc (Suc m)) \<subseteq> append_set (?C (Suc m)) (inputs M2)\<close> \<open>vs @ xs \<in> ?C (Suc (Suc m))\<close> append_set_prefix subsetCE)
      qed

      moreover have "xs \<noteq> []"
      proof -
        have "1 \<le> k" using j_assms by auto
        then have "?C j \<inter> ?C 1 = {}" using C_disj_le_gz[of 1 k] j_assms(1)
          using less_numeral_extra(1) by blast 
        then have "?C j \<inter> V = {}" by auto
        then have "vs@xs \<notin> V" using j_def by auto
        then show ?thesis using assms(2) by auto 
      qed

      ultimately have "vs@(butlast xs) \<in> ?C (Suc m)"
        by (simp add: butlast_append)

      have "Suc m < Suc j" using j_assms by auto
      have "?C (Suc m) \<subseteq> ?TS j" using TS_union[of M2 M1 T S \<Omega> V j] \<open>Suc m < Suc j\<close>
        by (metis UN_upper atLeast_upt lessThan_iff)
      

      have "vs @ butlast xs \<in> TS M2 M1 T S \<Omega> V j" using \<open>vs@(butlast xs) \<in> ?C (Suc m)\<close> \<open>?C (Suc m) \<subseteq> ?TS j\<close> j_def by auto
      then show ?thesis using j_def TS_subset[of j i] by blast 
    qed
  qed
qed


(* corollary 5.5.6 *)
lemma TS_prefix_containment :
  assumes "vs@xs \<in> TS M2 M1 T S \<Omega> V i"
  and     "mcp (vs@xs) V vs"
  and     "prefix xs' xs"
shows "vs@xs' \<in> TS M2 M1 T S \<Omega> V i"
(* Perform induction on length difference, as from each prefix we can deduce the 
   desired property for the prefix one element smaller than it via 5.5.5 *)
using assms proof (induction "length xs - length xs'" arbitrary: xs')
  case 0
  then have "xs = xs'"
    by (metis append_Nil2 append_eq_conv_conj gr_implies_not0 length_drop length_greater_0_conv prefixE)
  then show ?case using 0 by auto
next
  case (Suc k)
  have "0 < i" using assms(1) using Suc.hyps(2) append_eq_append_conv assms(2) by auto 

  show ?case using Suc
  proof (cases xs')
    case Nil
    then show ?thesis
      by (metis (no_types, hide_lams) \<open>0 < i\<close> TS.simps(2) TS_subset append_Nil2 assms(2) contra_subsetD leD mcp.elims(2) not_less_eq_eq)
  next
    case (Cons a list)
    then show ?thesis
    proof (cases "xs = xs'")
      case True
      then show ?thesis using assms(1) by simp
    next
      case False 
      then obtain xs'' where "xs = xs'@xs''" using Suc.prems(3) using prefixE by blast 
      then have "xs'' \<noteq> []" using False by auto
      then have "k = length xs - length (xs' @ [hd xs''])" using \<open>xs = xs'@xs''\<close> Suc.hyps(2) by auto
      moreover have "prefix (xs' @ [hd xs'']) xs" using \<open>xs = xs'@xs''\<close> \<open>xs'' \<noteq> []\<close>
        by (metis Cons_prefix_Cons list.exhaust_sel prefix_code(1) same_prefix_prefix) 
      ultimately have "vs @ (xs' @ [hd xs'']) \<in> TS M2 M1 T S \<Omega> V i" using Suc.hyps(1)[OF _ Suc.prems(1,2)] by simp
      
      
      have "mcp (vs @ xs' @ [hd xs'']) V vs" using \<open>xs = xs'@xs''\<close> \<open>xs'' \<noteq> []\<close> assms(2)
      proof -
        obtain aas :: "'a list \<Rightarrow> 'a list set \<Rightarrow> 'a list \<Rightarrow> 'a list" where
          "\<forall>x0 x1 x2. (\<exists>v3. (prefix v3 x2 \<and> v3 \<in> x1) \<and> \<not> length v3 \<le> length x0) = ((prefix (aas x0 x1 x2) x2 \<and> aas x0 x1 x2 \<in> x1) \<and> \<not> length (aas x0 x1 x2) \<le> length x0)"
          by moura
        then have f1: "\<forall>as A asa. (\<not> mcp as A asa \<or> prefix asa as \<and> asa \<in> A \<and> (\<forall>asb. (\<not> prefix asb as \<or> asb \<notin> A) \<or> length asb \<le> length asa)) \<and> (mcp as A asa \<or> \<not> prefix asa as \<or> asa \<notin> A \<or> (prefix (aas asa A as) as \<and> aas asa A as \<in> A) \<and> \<not> length (aas asa A as) \<le> length asa)"
          by auto
        obtain aasa :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
          f2: "\<forall>x0 x1. (\<exists>v2. x0 = x1 @ v2) = (x0 = x1 @ aasa x0 x1)"
          by moura
        then have f3: "([] @ [hd xs'']) @ aasa (xs' @ xs'') (xs' @ [hd xs'']) = ([] @ [hd xs'']) @ aasa (([] @ [hd xs'']) @ aasa (xs' @ xs'') (xs' @ [hd xs''])) ([] @ [hd xs''])"
          by (meson prefixE prefixI)
        have "xs' @ xs'' = (xs' @ [hd xs'']) @ aasa (xs' @ xs'') (xs' @ [hd xs''])"
          using f2 by (metis (no_types) \<open>prefix (xs' @ [hd xs'']) xs\<close> \<open>xs = xs' @ xs''\<close> prefixE)
        then have "(vs @ (a # list) @ [hd xs'']) @ aasa (([] @ [hd xs'']) @ aasa (xs' @ xs'') (xs' @ [hd xs''])) ([] @ [hd xs'']) = vs @ xs"
          using f3 by (simp add: \<open>xs = xs' @ xs''\<close> local.Cons)
        then have "\<not> prefix (aas vs V (vs @ xs' @ [hd xs''])) (vs @ xs' @ [hd xs'']) \<or> aas vs V (vs @ xs' @ [hd xs'']) \<notin> V \<or> length (aas vs V (vs @ xs' @ [hd xs''])) \<le> length vs"
          using f1 by (metis (no_types) \<open>mcp (vs @ xs) V vs\<close> local.Cons prefix_append)
        then show ?thesis
          using f1 by (meson \<open>mcp (vs @ xs) V vs\<close> prefixI)
      qed 
      
      
      then have "vs @ butlast (xs' @ [hd xs'']) \<in> TS M2 M1 T S \<Omega> V i" using TS_immediate_prefix_containment[OF \<open>vs @ (xs' @ [hd xs'']) \<in> TS M2 M1 T S \<Omega> V i\<close> _ \<open>0 < i\<close>] by simp

      moreover have "xs' = butlast (xs' @ [hd xs''])" using \<open>xs'' \<noteq> []\<close> by simp

      ultimately show ?thesis by simp
    qed
  qed
qed



lemma mcp_prefix_of_suffix :
  assumes "mcp (vs@xs) V vs"
  and     "prefix xs' xs"
shows "mcp (vs@xs') V vs" 
proof (rule ccontr)
  assume "\<not> mcp (vs @ xs') V vs"
  then have "\<not> (prefix vs (vs @ xs') \<and> vs \<in> V \<and> 
                 (\<forall> p' . (prefix p' (vs @ xs') \<and> p' \<in> V) \<longrightarrow> length p' \<le> length vs))" by auto
  then have "\<not> (\<forall> p' . (prefix p' (vs @ xs') \<and> p' \<in> V) \<longrightarrow> length p' \<le> length vs)" using assms(1) by auto
  then obtain vs' where "vs' \<in> V \<and> prefix vs' (vs@xs) \<and> length vs < length vs'"
    by (meson assms(2) leI prefix_append prefix_order.dual_order.trans) 
  then have "\<not> (mcp (vs@xs) V vs)" by auto
  then show "False" using assms(1) by auto
qed



lemma C_index :
  assumes "vs @ xs \<in> C M2 M1 T S \<Omega> V i"
  and     "mcp (vs@xs) V vs"
shows "Suc (length xs) = i"
using assms proof (induction xs arbitrary: i rule: rev_induct)
  case Nil 
  then have "vs @ [] \<in> C M2 M1 T S \<Omega> V 1" by auto
  then have "vs @ [] \<in> C M2 M1 T S \<Omega> V (Suc (length []))" by simp
  
  show ?case
  proof (rule ccontr)
    assume "Suc (length []) \<noteq> i"
    moreover have "vs @ [] \<in> C M2 M1 T S \<Omega> V i \<inter> C M2 M1 T S \<Omega> V (Suc (length []))" using Nil.prems(1) \<open>vs @ [] \<in> C M2 M1 T S \<Omega> V (Suc (length []))\<close> by auto
    ultimately show "False" using C_disj by blast
  qed
next
  case (snoc x xs')

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  have "vs @ xs' @ [x] \<notin> V" using snoc.prems(2) by auto  
  then have "vs @ xs' @ [x] \<notin> ?C 1" by auto
  moreover have "vs @ xs' @ [x] \<notin> ?C 0" by auto
  ultimately have "1 < i" using snoc.prems(1) by (metis less_one linorder_neqE_nat) 

  then have "vs @ butlast (xs' @ [x]) \<in> C M2 M1 T S \<Omega> V (i-1)" 
  proof -
    have "Suc 0 < i"
      using \<open>1 < i\<close> by auto
    then have f1: "Suc (i - Suc (Suc 0)) = i - Suc 0"
      using Suc_diff_Suc by presburger
    have "0 < i"
      by (metis (no_types) One_nat_def Suc_lessD \<open>1 < i\<close>)
    then show ?thesis
      using f1 by (metis C_immediate_prefix_containment DiffD1 One_nat_def Suc_pred' snoc.prems(1) snoc_eq_iff_butlast)
  qed

  moreover have "mcp (vs @ butlast (xs' @ [x])) V vs" by (meson mcp_prefix_of_suffix prefixeq_butlast snoc.prems(2)) 

  ultimately have "Suc (length xs') = i-1" using snoc.IH by simp 

  then show ?case by auto 
qed

lemma T_index :
  assumes "vs @ xs \<in> TS M2 M1 T S \<Omega> V i"
  and     "mcp (vs@xs) V vs"
shows "Suc (length xs) \<le> i"
proof -
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  obtain j where "j < Suc i" "vs@xs \<in> ?C j" using TS_union[of M2 M1 T S \<Omega> V i]
    by (metis (full_types) UN_iff assms(1) atLeastLessThan_iff set_upt) 
  then have "Suc (length xs) = j" using C_index
    using assms(2) by blast
  then show ?thesis using \<open>j < Suc i\<close> by auto
qed


lemma C_extension_options :
  assumes "vs @ xs \<in> C M2 M1 T S \<Omega> V i"
  and     "mcp (vs @ xs @ [x]) V vs"
  and     "x \<in> inputs M2"
  and     "0 < i"
shows "vs@xs@[x] \<in> C M2 M1 T S \<Omega> V (Suc i) \<or> vs@xs \<in> RM M2 M1 T S \<Omega> V i"
proof (cases "vs@xs \<in> RM M2 M1 T S \<Omega> V i")
  case True
  then show ?thesis by auto
next
  case False

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  obtain k where "i = Suc k" using assms(4) using gr0_implies_Suc by blast 
  then have "?C (Suc i) = append_set (?C i - ?RM i) (inputs M2) - ?TS i" using C.simps(3) by blast

  moreover have "vs@xs \<in> ?C i - ?RM i" using assms(1) False by blast

  ultimately have "vs@xs@[x] \<in> append_set (?C i - ?RM i) (inputs M2)" by (simp add: assms(3))

  moreover have "vs@xs@[x] \<notin> ?TS i"
  proof (rule ccontr)
    assume "\<not> vs @ xs @ [x] \<notin> ?TS i"
    then obtain j where "j < Suc i" "vs@xs@[x] \<in> ?C j" using TS_union[of M2 M1 T S \<Omega> V i] by fastforce
    then have "Suc (length (xs@[x])) = j" using C_index assms(2) by blast 

    then have "Suc (length (xs@[x])) < Suc i" using \<open>j < Suc i\<close> by auto
    moreover have "Suc (length xs) = i" using C_index
      by (metis assms(1) assms(2) mcp_prefix_of_suffix prefixI)
    ultimately have "Suc (length (xs@[x])) < Suc (Suc (length xs))" by auto
    then show "False" by auto
  qed

  ultimately show ?thesis
    by (simp add: \<open>?C (Suc i) = append_set (?C i - ?RM i) (inputs M2) - ?TS i\<close>) 
qed

  



(* Lemma 5.5.7 *)
lemma TS_non_containment_causes :
  assumes "vs@xs \<notin> TS M2 M1 T S \<Omega> V i" 
  and     "mcp (vs@xs) V vs"
  and     "set xs \<subseteq> inputs M2"
  and     "0 < i"
shows "(\<exists> xr j . xr \<noteq> xs \<and> prefix xr xs \<and> j \<le> i \<and> vs@xr \<in> RM M2 M1 T S \<Omega> V j)
       \<or> (\<exists> xc . xc \<noteq> xs \<and> prefix xc xs \<and> vs@xc \<in> (C M2 M1 T S \<Omega> V i) - (RM M2 M1 T S \<Omega> V i))"
  (is "?PrefPreviouslyRemoved \<or> ?PrefJustContained")
      "\<not> ((\<exists> xr j . xr \<noteq> xs \<and> prefix xr xs \<and> j \<le> i \<and> vs@xr \<in> RM M2 M1 T S \<Omega> V j)
         \<and> (\<exists> xc . xc \<noteq> xs \<and> prefix xc xs \<and> vs@xc \<in> (C M2 M1 T S \<Omega> V i) - (RM M2 M1 T S \<Omega> V i)))"
  
proof -

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  show "?PrefPreviouslyRemoved \<or> ?PrefJustContained"
  proof (rule ccontr)
    assume "\<not> (?PrefPreviouslyRemoved \<or> ?PrefJustContained)"
    then have "\<not> ?PrefPreviouslyRemoved" "\<not> ?PrefJustContained" by auto

    have "\<nexists>xr j. prefix xr xs \<and> j \<le> i \<and> vs @ xr \<in> ?RM j" 
    proof 
      assume "\<exists>xr j. prefix xr xs \<and> j \<le> i \<and> vs @ xr \<in> RM M2 M1 T S \<Omega> V j"
      then obtain xr j where "prefix xr xs" "j \<le> i" "vs @ xr \<in> ?RM j" by blast
      then show "False"
      proof (cases "xr = xs")
        case True
        then have "vs @ xs \<in> ?RM j" using \<open>vs @ xr \<in> ?RM j\<close> by auto
        then have "vs @ xs \<in> ?TS j"
          using C_subset RM_subset \<open>vs @ xr \<in> ?RM j\<close> by blast 
        then have "vs @ xs \<in> ?TS i"
          using TS_subset \<open>j \<le> i\<close> by blast 
        then show ?thesis using assms(1) by blast
      next
        case False
        then show ?thesis using \<open>\<not> ?PrefPreviouslyRemoved\<close> \<open>prefix xr xs\<close> \<open>j \<le> i\<close> \<open>vs @ xr \<in> ?RM j\<close> by blast
      qed
    qed
      

    have "vs \<in> V" using assms(2) by auto
    then have "vs \<in> ?C 1" by auto

    have "\<And> k . (1 \<le> Suc k \<and> Suc k \<le> i) \<longrightarrow> vs @ (take k xs) \<in> ?C (Suc k) - ?RM (Suc k)" 
    proof 
      fix k assume "1 \<le> Suc k \<and> Suc k \<le> i"
      then show "vs @ (take k xs) \<in> ?C (Suc k) - ?RM (Suc k)" 
      proof (induction k)
        case 0
        show ?case using \<open>vs \<in> ?C 1\<close>
          by (metis "0.prems" DiffI One_nat_def \<open>\<nexists>xr j. prefix xr xs \<and> j \<le> i \<and> vs @ xr \<in> RM M2 M1 T S \<Omega> V j\<close> append_Nil2 take_0 take_is_prefix)  
      next
        case (Suc k)

        have "1 \<le> Suc k \<and> Suc k \<le> i" using Suc.prems by auto
        then have "vs @ take k xs \<in> ?C (Suc k)" using Suc.IH by simp

        moreover have "vs @ take k xs \<notin> ?RM (Suc k)" 
          using \<open>1 \<le> Suc k \<and> Suc k \<le> i\<close> \<open>\<not> ?PrefPreviouslyRemoved\<close> take_is_prefix
          using Suc.IH by blast 

        ultimately have "vs @ take k xs \<in> (?C (Suc k)) - (?RM (Suc k))" by blast

        have "k < length xs" 
        proof (rule ccontr)
          assume "\<not> k < length xs"
          then have "vs @ xs \<in> ?C (Suc k)" using \<open>vs @ take k xs \<in> ?C (Suc k)\<close> by simp 
          have "vs @ xs \<in> ?TS i" 
            by (metis C_subset TS_subset \<open>1 \<le> Suc k \<and> Suc k \<le> i\<close> \<open>vs @ xs \<in> ?C (Suc k)\<close> contra_subsetD) 
          then show "False" using assms(1) by simp
        qed
        moreover have "set xs \<subseteq> inputs M2" using assms(3) by auto
        ultimately have "last (take (Suc k) xs) \<in> inputs M2"
          by (simp add: subset_eq take_Suc_conv_app_nth)  

        have "vs @ take (Suc k) xs \<in> append_set ((?C (Suc k)) - (?RM (Suc k))) (inputs M2)"
        proof -
          have f1: "xs ! k \<in> inputs M2"
            by (meson \<open>k < length xs\<close> \<open>set xs \<subseteq> inputs M2\<close> nth_mem subset_iff)
          have "vs @ take (Suc k) xs = (vs @ take k xs) @ [xs ! k]"
            by (simp add: \<open>k < length xs\<close> take_Suc_conv_app_nth)
          then show ?thesis
            using f1 \<open>vs @ take k xs \<in> C M2 M1 T S \<Omega> V (Suc k) - RM M2 M1 T S \<Omega> V (Suc k)\<close> by blast
        qed 

        moreover have "vs @ take (Suc k) xs \<notin> ?TS (Suc k)" 
        proof 
          assume "vs @ take (Suc k) xs \<in> ?TS (Suc k)"
          then have "Suc (length (take (Suc k) xs)) \<le> Suc k" 
            using T_index assms(2) mcp_prefix_of_suffix take_is_prefix by blast 
          moreover have "Suc (length (take k xs)) = Suc k" using C_index \<open>vs @ take k xs \<in> ?C (Suc k)\<close>
            by (metis assms(2) mcp_prefix_of_suffix take_is_prefix) 
          ultimately show "False" using \<open>k < length xs\<close>
            by simp 
        qed

        ultimately show "vs @ take (Suc k) xs \<in> ?C (Suc (Suc k)) - ?RM (Suc (Suc k))"
          using C.simps(3)
          by (smt C_extension_options DiffI Suc.prems \<open>\<nexists>xr j. prefix xr xs \<and> j \<le> i \<and> vs @ xr \<in> RM M2 M1 T S \<Omega> V j\<close> \<open>k < length xs\<close> \<open>last (take (Suc k) xs) \<in> inputs M2\<close> \<open>vs @ take k xs \<in> C M2 M1 T S \<Omega> V (Suc k)\<close> \<open>vs @ take k xs \<notin> RM M2 M1 T S \<Omega> V (Suc k)\<close> assms(2) last_snoc mcp_prefix_of_suffix take_Suc_conv_app_nth take_is_prefix zero_less_Suc) 
      qed
    qed

    then have "vs @ take (i-1) xs \<in> C M2 M1 T S \<Omega> V i - RM M2 M1 T S \<Omega> V i" using assms(4)
      by (metis One_nat_def Suc_diff_1 Suc_leI le_less) 
    then have "?PrefJustContained"
      by (metis C_subset DiffD1 assms(1) subsetCE take_is_prefix)
    then show "False" using \<open>\<not> ?PrefJustContained\<close> by simp
  qed




  show "\<not> (?PrefPreviouslyRemoved \<and> ?PrefJustContained)"
  proof 
    assume "?PrefPreviouslyRemoved \<and> ?PrefJustContained"
    then have "?PrefPreviouslyRemoved" "?PrefJustContained" by auto

    obtain xr j where "prefix xr xs" "j \<le> i" "vs@xr \<in> ?RM j" using \<open>?PrefPreviouslyRemoved\<close> by blast
    obtain xc where "prefix xc xs" "vs@xc \<in> ?C i - ?RM i" using \<open>?PrefJustContained\<close> by blast

    then have "Suc (length xc) = i" using C_index
      by (metis Diff_iff assms(2) mcp_prefix_of_suffix)
    moreover have "length xc \<le> length xs" using \<open>prefix xc xs\<close> by (simp add: prefix_length_le) 
    moreover have "xc \<noteq> xs"
    proof 
      assume "xc = xs"
      then have "vs@xs \<in> ?C i" using \<open>vs@xc \<in> ?C i - ?RM i\<close> by auto
      then have "vs@xs \<in> ?TS i" using C_subset by blast 
      then show "False" using assms(1) by blast
    qed
    ultimately have "i \<le> length xs"
      using \<open>prefix xc xs\<close> not_less_eq_eq prefix_length_prefix prefix_order.antisym by blast 




    have "\<And> n . (n < i) \<Longrightarrow> vs@(take n xs) \<in> ?C (Suc n)"
    proof -    
      fix n assume "n < i"
      show "vs @ take n xs \<in> C M2 M1 T S \<Omega> V (Suc n)"
      proof -
        have "n \<le> length xc"
          using \<open>n < i\<close> \<open>Suc (length xc) = i\<close> less_Suc_eq_le by blast 
        then have "prefix (vs @ (take n xs)) (vs @ xc)"
        proof -
          have "n \<le> length xs"
            using \<open>length xc \<le> length xs\<close> \<open>n \<le> length xc\<close> order_trans by blast
          then have "prefix (take n xs) xc"
            by (metis (no_types) \<open>n \<le> length xc\<close> \<open>prefix xc xs\<close> length_take min.absorb2 prefix_length_prefix take_is_prefix)
          then show ?thesis
            by simp
        qed 
        then have "vs @ take n xs \<in> ?TS i"
          by (meson C_subset DiffD1 TS_prefix_containment \<open>prefix xc xs\<close> \<open>vs @ xc \<in> C M2 M1 T S \<Omega> V i - RM M2 M1 T S \<Omega> V i\<close> assms(2) contra_subsetD mcp_prefix_of_suffix same_prefix_prefix)
        then obtain jn where "jn < Suc i" "vs@(take n xs) \<in> ?C jn" using TS_union[of M2 M1 T S \<Omega> V i]
          by (metis UN_iff atLeast_upt lessThan_iff)
        moreover have "mcp (vs @ take n xs) V vs"
          by (meson assms(2) mcp_prefix_of_suffix take_is_prefix) 
        ultimately have "jn = Suc (length (take n xs))" using C_index[of vs "take n xs" M2 M1 T S \<Omega> V jn] by auto
        then have "jn = Suc n"
          using \<open>length xc \<le> length xs\<close> \<open>n \<le> length xc\<close> by auto 
        then show "vs@(take n xs) \<in> ?C (Suc n)" using \<open>vs@(take n xs) \<in> ?C jn\<close> by auto
      qed
    qed


    have "\<And> n . (n < i) \<Longrightarrow> vs@(take n xs) \<notin> ?RM (Suc n)"
    proof -    
      fix n assume "n < i"
      show "vs @ take n xs \<notin> RM M2 M1 T S \<Omega> V (Suc n)"
      proof (cases "n = length xc")
        case True
        then show ?thesis using \<open>vs@xc \<in> ?C i - ?RM i\<close>
          by (metis DiffD2 \<open>Suc (length xc) = i\<close> \<open>prefix xc xs\<close> append_eq_conv_conj prefixE) 
      next
        case False
        then have "n < length xc"
          using \<open>n < i\<close> \<open>Suc (length xc) = i\<close> by linarith 

        (* show property via immediate prefix for C sets, performing a case analysis on
           whether (take (Suc n) xc) is xc or a proper prefix of it *)

        show ?thesis 
        proof (cases "Suc n < length xc")
          case True
          then have "Suc n < i"
            using \<open>Suc (length xc) = i\<close> \<open>n < length xc\<close> by blast 
          then have "vs @ (take (Suc n) xs) \<in> ?C (Suc (Suc n))" 
            using \<open>\<And> n . (n < i) \<Longrightarrow> vs@(take n xs) \<in> ?C (Suc n)\<close> by blast
          then have "vs @ butlast (take (Suc n) xs) \<in> ?C (Suc n) - ?RM (Suc n)" 
            using True C_immediate_prefix_containment[of vs "take (Suc n) xs" M2 M1 T S \<Omega> V n]
            by (metis Suc_neq_Zero \<open>prefix xc xs\<close> \<open>xc \<noteq> xs\<close> prefix_Nil take_eq_Nil)
          then show ?thesis
            by (metis DiffD2 Suc_lessD True \<open>length xc \<le> length xs\<close> butlast_snoc less_le_trans take_Suc_conv_app_nth)
        next
          case False
          then have "Suc n = length xc"
            using Suc_lessI \<open>n < length xc\<close> by blast
          then have "vs @ (take (Suc n) xs) \<in> ?C (Suc (Suc n))"
            using \<open>Suc (length xc) = i\<close> \<open>\<And>n. n < i \<Longrightarrow> vs @ take n xs \<in> C M2 M1 T S \<Omega> V (Suc n)\<close> 
            by auto 
          then have "vs @ butlast (take (Suc n) xs) \<in> ?C (Suc n) - ?RM (Suc n)" 
            using False C_immediate_prefix_containment[of vs "take (Suc n) xs" M2 M1 T S \<Omega> V n]
            by (metis Suc_neq_Zero \<open>prefix xc xs\<close> \<open>xc \<noteq> xs\<close> prefix_Nil take_eq_Nil)
          then show ?thesis
            by (metis Diff_iff \<open>Suc n = length xc\<close> \<open>length xc \<le> length xs\<close> butlast_take diff_Suc_1)
        qed
      qed
    qed


    have "xr = take j xs"
    proof -
      have "vs@xr \<in> ?C j" using \<open>vs@xr \<in> ?RM j\<close> RM_subset by blast 
      then show ?thesis using C_index
        by (metis Suc_le_lessD \<open>\<And>n. n < i \<Longrightarrow> vs @ take n xs \<notin> RM M2 M1 T S \<Omega> V (Suc n)\<close> \<open>j \<le> i\<close> \<open>prefix xr xs\<close> \<open>vs @ xr \<in> RM M2 M1 T S \<Omega> V j\<close> append_eq_conv_conj assms(2) mcp_prefix_of_suffix prefix_def) 
    qed
 
    have "vs@xr \<notin> ?RM j"
      by (metis (no_types) C_index RM_subset \<open>i \<le> length xs\<close> \<open>j \<le> i\<close> \<open>prefix xr xs\<close> \<open>xr = take j xs\<close> assms(2) contra_subsetD dual_order.trans length_take lessI less_irrefl mcp_prefix_of_suffix min.absorb2) 
    
    then show "False" using \<open>vs@xr \<in> ?RM j\<close> by simp    
  qed
qed

  

(* lemma 5.5.8 *)
lemma TS_non_containment_causes_rev : 
  assumes "mcp (vs@xs) V vs"
  and "(\<exists> xr j . xr \<noteq> xs \<and> prefix xr xs \<and> j \<le> i \<and> vs@xr \<in> RM M2 M1 T S \<Omega> V j)
       \<or> (\<exists> xc . xc \<noteq> xs \<and> prefix xc xs \<and> vs@xc \<in> (C M2 M1 T S \<Omega> V i) - (RM M2 M1 T S \<Omega> V i))"
      (is "?PrefPreviouslyRemoved \<or> ?PrefJustContained")

shows "vs@xs \<notin> TS M2 M1 T S \<Omega> V i"

  
proof 
  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  assume "vs @ xs \<in> TS M2 M1 T S \<Omega> V i" 

  have "?PrefPreviouslyRemoved \<Longrightarrow> False"
  proof -
    assume ?PrefPreviouslyRemoved
    then obtain xr j where "xr \<noteq> xs" "prefix xr xs" "j \<le> i" "vs@xr \<in> ?RM j" by blast
    then have "vs@xr \<notin> ?C j - ?RM j" by blast 

     
    
    have "vs@(take (Suc (length xr)) xs) \<notin> ?C (Suc j)" 
    proof -
      have "vs@(take (length xr) xs) \<notin> ?C j - ?RM j"
        by (metis \<open>prefix xr xs\<close> \<open>vs @ xr \<notin> C M2 M1 T S \<Omega> V j - RM M2 M1 T S \<Omega> V j\<close> append_eq_conv_conj prefix_def) 
      show ?thesis
        by (smt C_immediate_prefix_containment C_index RM_subset Suc_neq_Zero \<open>prefix xr xs\<close> \<open>vs @ take (length xr) xs \<notin> C M2 M1 T S \<Omega> V j - RM M2 M1 T S \<Omega> V j\<close> \<open>vs @ xr \<in> RM M2 M1 T S \<Omega> V j\<close> assms(1) butlast_take diff_Suc_1 list.size(3) mcp_prefix_of_suffix nat_le_linear subsetCE take_all take_is_prefix)

      (* TODO: replace smt call ?
        have "\<forall> x \<in> inputs M2 . vs@(take (length xr) xs)@[x] \<notin> append_set (?C j -?RM j) (inputs M2)"
          by simp 
        obtain x where x_def : "take (Suc (length xr)) xs = xr@[x]"
        proof -
          assume a1: "\<And>x. take (Suc (length xr)) xs = xr @ [x] \<Longrightarrow> thesis"
          have "take (length xr) xs = xr"
            by (metis (no_types) \<open>prefix xr xs\<close> append_eq_conv_conj prefix_def)
          then show ?thesis
            using a1 by (metis (no_types) \<open>prefix xr xs\<close> \<open>xr \<noteq> xs\<close> nat_less_le prefix_length_le take_Suc_conv_app_nth take_all)
        qed
        then have "x \<in> inputs M2" using assms(2)
          by (metis contra_subsetD in_set_takeD last_in_set snoc_eq_iff_butlast) 
        moreover have "vs@(take (length xr) xs) \<notin> ?C j - ?RM j"
          by (metis \<open>prefix xr xs\<close> \<open>vs @ xr \<notin> C M2 M1 T S \<Omega> V j - RM M2 M1 T S \<Omega> V j\<close> append_eq_conv_conj prefix_def) 
        ultimately have "vs@(take (length xr) xs)@[x] \<notin> append_set (?C j -?RM j) (inputs M2)" by simp
        moreover have "take (length xr) xs = xr"
          by (metis (no_types) \<open>prefix xr xs\<close> append_eq_conv_conj prefix_def)
        ultimately have "vs@xr@[x] \<notin> append_set (?C j -?RM j) (inputs M2)" by simp
        then have "vs@(take (Suc (length xr)) xs) \<notin> append_set (?C j -?RM j) (inputs M2)" using x_def by auto
      *)   
    qed
    
    have "prefix (take (Suc (length xr)) xs) xs"
      by (simp add: take_is_prefix) 
    then have "vs@(take (Suc (length xr)) xs) \<in> ?TS i" using TS_prefix_containment[OF \<open>vs @ xs \<in> TS M2 M1 T S \<Omega> V i\<close> assms(1)] by simp
    then obtain j' where "j' < Suc i \<and> vs@(take (Suc (length xr)) xs) \<in> ?C j'" using TS_union[of M2 M1 T S \<Omega> V i] by fastforce
    then have "Suc (Suc (length xr)) = j'" using C_index[of vs "take (Suc (length xr)) xs"]
    proof -
      have "\<not> length xs \<le> length xr"
        by (metis (no_types) \<open>prefix xr xs\<close> \<open>xr \<noteq> xs\<close> append_Nil2 append_eq_conv_conj leD nat_less_le prefix_def prefix_length_le)
      then show ?thesis
        by (metis (no_types) \<open>\<And>i \<Omega> V T S M2 M1. \<lbrakk>vs @ take (Suc (length xr)) xs \<in> C M2 M1 T S \<Omega> V i; mcp (vs @ take (Suc (length xr)) xs) V vs\<rbrakk> \<Longrightarrow> Suc (length (take (Suc (length xr)) xs)) = i\<close> \<open>j' < Suc i \<and> vs @ take (Suc (length xr)) xs \<in> C M2 M1 T S \<Omega> V j'\<close> append_eq_conv_conj assms(1) length_take mcp_prefix_of_suffix min.absorb2 not_less_eq_eq prefix_def)
    qed
    moreover have "Suc (length xr) = j" 
      using \<open>vs@xr \<in> ?RM j\<close> RM_subset C_index
      by (metis \<open>prefix xr xs\<close> assms(1) mcp_prefix_of_suffix subsetCE)
    ultimately have "j' = Suc j" by auto

    then have "vs@(take (Suc (length xr)) xs) \<in> ?C (Suc j)" using \<open>j' < Suc i \<and> vs@(take (Suc (length xr)) xs) \<in> ?C j'\<close> by auto
    then show "False" using \<open>vs@(take (Suc (length xr)) xs) \<notin> ?C (Suc j)\<close> by blast
  qed

    
  moreover have "?PrefJustContained \<Longrightarrow> False"
  proof -
    assume ?PrefJustContained
    then obtain xc where "xc \<noteq> xs" "prefix xc xs" "vs @ xc \<in> ?C i - ?RM i" by blast
    (* only possible if xc = xs *)
    then show "False"
      by (metis C_index DiffD1 Suc_less_eq T_index \<open>vs @ xs \<in> ?TS i\<close> assms(1) leD le_neq_trans mcp_prefix_of_suffix prefix_length_le prefix_length_prefix prefix_order.dual_order.antisym prefix_order.order_refl) 
  qed

  ultimately show "False" using assms(2) by auto
qed






lemma TS_finite :
  assumes "finite V"
  and     "finite (inputs M2)"
shows "finite (TS M2 M1 T S \<Omega> V n)"
using assms proof (induction n)
  case 0
  then show ?case by auto
next
  case (Suc n)

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"

  show ?case
  proof (cases "n=0")
    case True
    then have "?TS (Suc n) = V" by auto
    then show ?thesis using \<open>finite V\<close> by auto
  next
    case False
    then have "?TS (Suc n) = ?TS n \<union> ?C (Suc n)"
      by (metis TS.simps(3) gr0_implies_Suc neq0_conv) 
    moreover have "finite (?TS n)" using Suc.IH[OF Suc.prems] by assumption
    moreover have "finite (?C (Suc n))"
    proof -
      have "?C (Suc n) \<subseteq> append_set (?C n) (inputs M2)"
        using C_step False by blast 
      moreover have "?C n \<subseteq> ?TS n"
        by (simp add: C_subset) 
      ultimately have "?C (Suc n) \<subseteq> append_set (?TS n) (inputs M2)"
        by blast
      moreover have "finite (append_set (?TS n) (inputs M2))"
        by (simp add: \<open>finite (TS M2 M1 T S \<Omega> V n)\<close> assms(2) finite_image_set2) 
      ultimately show ?thesis
        using infinite_subset by auto 
    qed
    ultimately show ?thesis
      by auto 
  qed
qed

lemma C_finite :
  assumes "finite V"
  and     "finite (inputs M2)"
shows "finite (C M2 M1 T S \<Omega> V n)"
proof -
  have "C M2 M1 T S \<Omega> V n \<subseteq> TS M2 M1 T S \<Omega> V n"
    by (simp add: C_subset) 
  then show ?thesis using TS_finite[OF assms]
    using Finite_Set.finite_subset by blast 
qed



lemma R_union_card_is_suffix_length :
  assumes "OFSM M"
  and     "xs \<in> L M"
shows "sum (\<lambda> q . card (R M q [] xs)) (nodes M) = length xs"
using assms proof (induction xs rule: rev_induct)
  case Nil
  have "\<forall> q \<in> nodes M . card (R M q [] []) = 0" by auto
  show ?case
    by (simp add: sum.neutral)
next
  case (snoc x xs)

  have "finite (nodes M)" using assms by auto

  have R_update : "\<And> q . R M q [] (xs@[x]) = (if (q \<in> io_targets M (initial M) (xs @ [x])) 
                                    then insert (xs@[x]) (R M q [] xs)   
                                    else R M q [] xs)" by (auto; presburger)

  obtain q where "io_targets M (initial M) (xs @ [x]) = {q}"
    by (meson assms(1) io_targets_observable_singleton_ex snoc.prems(2)) 

  then have "R M q [] (xs@[x]) = insert (xs@[x]) (R M q [] xs)" using R_update by auto
  moreover have "(xs@[x]) \<notin> (R M q [] xs)" by auto
  ultimately have "card (R M q [] (xs@[x])) = Suc (card (R M q [] xs))"
    by (metis card_insert_disjoint finite_R) 

  have "q \<in> nodes M"
    by (metis (full_types) FSM.nodes.initial \<open>io_targets M (initial M) (xs @ [x]) = {q}\<close> insertI1 io_targets_nodes) 

  have "\<forall> q' . q' \<noteq> q \<longrightarrow> R M q' [] (xs@[x]) = R M q' [] xs" 
    using \<open>io_targets M (initial M) (xs @ [x]) = {q}\<close> R_update
    by auto  
  then have "\<forall> q' . q' \<noteq> q \<longrightarrow> card (R M q' [] (xs@[x])) = card (R M q' [] xs)" 
    by auto

  then have "(\<Sum>q\<in>(nodes M - {q}). card (R M q [] (xs@[x]))) = (\<Sum>q\<in>(nodes M - {q}). card (R M q [] xs))"
    by auto
  moreover have "(\<Sum>q\<in>nodes M. card (R M q [] (xs@[x]))) = (\<Sum>q\<in>(nodes M - {q}). card (R M q [] (xs@[x]))) + (card (R M q [] (xs@[x])))" 
                "(\<Sum>q\<in>nodes M. card (R M q [] xs)) = (\<Sum>q\<in>(nodes M - {q}). card (R M q [] xs)) + (card (R M q [] xs))"
  proof -
    have "\<forall>C c f. (infinite C \<or> (c::'c) \<notin> C) \<or> sum f C = (f c::nat) + sum f (C - {c})"
      by (meson sum.remove)
    then show "(\<Sum>q\<in>nodes M. card (R M q [] (xs@[x]))) = (\<Sum>q\<in>(nodes M - {q}). card (R M q [] (xs@[x]))) + (card (R M q [] (xs@[x])))"
              "(\<Sum>q\<in>nodes M. card (R M q [] xs)) = (\<Sum>q\<in>(nodes M - {q}). card (R M q [] xs)) + (card (R M q [] xs))"
      using \<open>finite (nodes M)\<close> \<open>q \<in> nodes M\<close> by presburger+
  qed 
  ultimately have "(\<Sum>q\<in>nodes M. card (R M q [] (xs@[x]))) = Suc (\<Sum>q\<in>nodes M. card (R M q [] xs))" 
    using \<open>card (R M q [] (xs@[x])) = Suc (card (R M q [] xs))\<close> by presburger

  have "(\<Sum>q\<in>nodes M. card (R M q [] xs)) = length xs" using snoc.IH snoc.prems
    by (meson language_state_prefix)
  
  show ?case
  proof -
    show ?thesis
      by (metis (no_types) \<open>(\<Sum>q\<in>nodes M. card (R M q [] (xs @ [x]))) = Suc (\<Sum>q\<in>nodes M. card (R M q [] xs))\<close> \<open>(\<Sum>q\<in>nodes M. card (R M q [] xs)) = length xs\<close> length_append_singleton)
  qed   

qed 


lemma state_repetition_via_long_sequence :
  assumes "OFSM M"
  and     "card (nodes M) \<le> m"
  and     "Suc (m * m) \<le> length xs"
  and     "xs \<in> L M"
shows "\<exists> q \<in> nodes M . card (R M q [] xs) > m"
proof (rule ccontr)
  assume "\<not> (\<exists>q\<in>nodes M. m < card (R M q [] xs))"
  then have "\<forall> q \<in> nodes M . card (R M q [] xs) \<le> m" by auto
  then have "sum (\<lambda> q . card (R M q [] xs)) (nodes M) \<le> sum (\<lambda> q . m) (nodes M)"
    by (meson sum_mono) 
  moreover have "sum (\<lambda> q . m) (nodes M) \<le> m * m" 
    using assms(2) by auto 
  ultimately have "sum (\<lambda> q . card (R M q [] xs)) (nodes M) \<le> m * m" 
    by presburger

  moreover have "Suc (m*m) \<le> sum (\<lambda> q . card (R M q [] xs)) (nodes M)" 
    using R_union_card_is_suffix_length[OF assms(1,4)] assms(3) by auto
  ultimately show "False" by simp
qed
  



abbreviation "final_iteration M2 M1 T S \<Omega> V i \<equiv> TS M2 M1 T S \<Omega> V i = TS M2 M1 T S \<Omega> V (Suc i)"


(* lemma 5.5.9 *)
lemma final_iteration_ex :
  assumes "OFSM M1"
  and     "OFSM M2"
  and     "fault_model M2 M1 m"
  and     "test_tools M2 M1 FAIL PM V V'' \<Omega>"
  shows "\<exists> i . final_iteration M2 M1 T S \<Omega> V i"
proof 
  let ?i = "Suc (Suc (m * m))"

  let ?TS = "\<lambda> n . TS M2 M1 T S \<Omega> V n"
  let ?C = "\<lambda> n . C M2 M1 T S \<Omega> V n"
  let ?RM = "\<lambda> n . RM M2 M1 T S \<Omega> V n"


  (* TODO: extract for reuse if necessary *)
  have "is_det_state_cover M2 V" using assms by auto
  moreover have "finite (nodes M2)" using assms(2) by auto
  moreover have "d_reachable M2 (initial M2) \<subseteq> nodes M2"
    by auto 
  ultimately have "finite V" using det_state_cover_card[of M2 V]
    by (metis finite_if_finite_subsets_card_bdd infinite_subset is_det_state_cover.elims(2) surj_card_le)


  have "\<forall> seq \<in> ?C ?i . seq \<in> ?RM ?i"
  proof  
    fix seq assume "seq \<in> ?C ?i"

    have "[] \<in> V" using \<open>is_det_state_cover M2 V\<close>
      using det_state_cover_empty by blast 
    then obtain vs where "mcp seq V vs" 
      using mcp_ex[OF _ \<open>finite V\<close>] by blast   
    then obtain xs where "seq = vs@xs"
      using prefixE by auto 

    
    then have "Suc (length xs) = ?i" using C_index
      using \<open>mcp seq V vs\<close> \<open>seq \<in> C M2 M1 T S \<Omega> V (Suc (Suc (m * m)))\<close> by blast
    then have "length xs = Suc (m * m)"

    







  
  
  moreover have "finite (inputs M2)" using assms by auto
  ultimately have "finite (?C ?i)" using C_finite by blast
 
  then show "final_iteration M2 M1 T S \<Omega> V ?i"
  proof (cases "C M2 M1 T S \<Omega> V ?i")
    case emptyI
    moreover have "?C (Suc ?i) \<subseteq> append_set (?C ?i) (inputs M2)"
      using C_step by blast
    ultimately have "?C (Suc ?i) = {}"
      by blast 
    then have "?TS (Suc ?i) = ?TS ?i"
      using TS.simps(3) by blast 
    then show ?thesis by blast
   
  next
    case (insertI CS seq)
    then have "seq \<in> ?C ?i" by blast
    
    have "[] \<in> V" using \<open>is_det_state_cover M2 V\<close>
      using det_state_cover_empty by blast 
    then obtain vs where "mcp seq V vs" 
      using mcp_ex[OF _ \<open>finite V\<close>] by blast   
    then obtain xs where "seq = vs@xs"
      using prefixE by auto 

    
    then have "Suc (length xs) = ?i" using C_index
      using \<open>mcp seq V vs\<close> \<open>seq \<in> C M2 M1 T S \<Omega> V (Suc (Suc (m * m)))\<close> by blast
    then have "length xs = Suc (m * m)"

    then show ?thesis sorry
  qed


end