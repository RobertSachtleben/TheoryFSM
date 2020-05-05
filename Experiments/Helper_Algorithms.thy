theory Helper_Algorithms
imports R_Distinguishability State_Separator State_Preamble
begin

subsection \<open>Calculating r-distinguishable State Pairs with Separators\<close>

definition r_distinguishable_state_pairs_with_separators :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> (('a \<times> 'a) \<times> (('a \<times> 'a) + 'a,'b,'c) fsm) set" where
  "r_distinguishable_state_pairs_with_separators M = {((q1,q2),Sep) | q1 q2 Sep . q1 \<in> nodes M 
                                                                                \<and> q2 \<in> nodes M 
                                                                                \<and> ((q1 < q2 \<and> state_separator_from_s_states M q1 q2 = Some Sep)
                                                                                  \<or> (q2 < q1 \<and> state_separator_from_s_states M q2 q1 = Some Sep)) }"

lemma r_distinguishable_state_pairs_with_separators_code[code] :
  "r_distinguishable_state_pairs_with_separators M = 
    \<Union> (image (\<lambda> ((q1,q2),A) . {((q1,q2),the A),((q2,q1),the A)}) (Set.filter (\<lambda> (qq,A) . A \<noteq> None) (image (\<lambda> (q1,q2) . ((q1,q2),state_separator_from_s_states M q1 q2)) (Set.filter (\<lambda> (q1,q2) . q1 < q2) (nodes M \<times> nodes M)))))"
  (is "?P1 = ?P2")
proof -
  have "\<And> x . x \<in> ?P1 \<Longrightarrow> x \<in> ?P2"
  proof -
    fix x assume "x \<in> ?P1"
    then obtain q1 q2 A where "x = ((q1,q2),A)"
      by (metis eq_snd_iff)
    then have "((q1,q2),A) \<in> ?P1" using \<open>x \<in> ?P1\<close> by auto
    then have "q1 \<in> nodes M"
         and  "q2 \<in> nodes M" 
         and  "((q1 < q2 \<and> state_separator_from_s_states M q1 q2 = Some A) \<or> (q2 < q1 \<and> state_separator_from_s_states M q2 q1 = Some A))"
      unfolding r_distinguishable_state_pairs_with_separators_def by blast+

    then consider (a) "q1 < q2 \<and> state_separator_from_s_states M q1 q2 = Some A" |
                  (b) "q2 < q1 \<and> state_separator_from_s_states M q2 q1 = Some A" 
      by blast
    then show "x \<in> ?P2" 
      using \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> unfolding \<open>x = ((q1,q2),A)\<close> by (cases; force)
  qed
  moreover have "\<And> x . x \<in> ?P2 \<Longrightarrow> x \<in> ?P1"
  proof -
    fix x assume "x \<in> ?P2"
    then obtain q1 q2 A where "x = ((q1,q2),A)"
      by (metis eq_snd_iff)
    then have "((q1,q2),A) \<in> ?P2" using \<open>x \<in> ?P2\<close> by auto
    then obtain q1' q2' A' where "((q1,q2),A) \<in> {((q1',q2'),the A'),((q2',q1'),the A')}"
                           and   "A' \<noteq> None"
                           and   "((q1',q2'), A') \<in> (image (\<lambda> (q1,q2) . ((q1,q2),state_separator_from_s_states M q1 q2)) (Set.filter (\<lambda> (q1,q2) . q1 < q2) (nodes M \<times> nodes M)))"
      by force
    
    then have "A' = Some A"
      by (metis (no_types, lifting) empty_iff insert_iff old.prod.inject option.collapse)  
    
    moreover have "A' = state_separator_from_s_states M q1' q2'"
             and  "q1' < q2'"
             and  "q1' \<in> nodes M"
             and  "q2' \<in> nodes M"
      using \<open>((q1',q2'), A') \<in> (image (\<lambda> (q1,q2) . ((q1,q2),state_separator_from_s_states M q1 q2)) (Set.filter (\<lambda> (q1,q2) . q1 < q2) (nodes M \<times> nodes M)))\<close> 
      by force+
    ultimately have "state_separator_from_s_states M q1' q2' = Some A" by simp

    consider "((q1',q2'),the A') = ((q1,q2),A)" | "((q1',q2'),the A') = ((q2,q1),A)"
      using \<open>((q1,q2),A) \<in> {((q1',q2'),the A'),((q2',q1'),the A')}\<close>
      by force
    then show "x \<in> ?P1" 
    proof cases
      case 1
      then have *: "q1' = q1" and **: "q2' = q2" by auto

      show ?thesis 
        using \<open>q1' \<in> nodes M\<close> \<open>q2' \<in> nodes M\<close> \<open>q1' < q2'\<close> \<open>state_separator_from_s_states M q1' q2' = Some A\<close>
        unfolding r_distinguishable_state_pairs_with_separators_def
        unfolding * ** \<open>x = ((q1,q2),A)\<close> by blast
    next
      case 2
      then have *: "q1' = q2" and **: "q2' = q1" by auto

      show ?thesis 
        using \<open>q1' \<in> nodes M\<close> \<open>q2' \<in> nodes M\<close> \<open>q1' < q2'\<close> \<open>state_separator_from_s_states M q1' q2' = Some A\<close>
        unfolding r_distinguishable_state_pairs_with_separators_def
        unfolding * ** \<open>x = ((q1,q2),A)\<close> by blast
    qed
  qed
  ultimately show ?thesis by blast
qed



value "r_distinguishable_state_pairs_with_separators m_ex_H"
value "r_distinguishable_state_pairs_with_separators m_ex_9"



lemma r_distinguishable_state_pairs_with_separators_same_pair_same_separator :
  assumes "((q1,q2),A) \<in> r_distinguishable_state_pairs_with_separators M"
  and     "((q1,q2),A') \<in> r_distinguishable_state_pairs_with_separators M"
shows "A = A'"
  using assms unfolding r_distinguishable_state_pairs_with_separators_def
  by force 


lemma r_distinguishable_state_pairs_with_separators_sym_pair_same_separator :
  assumes "((q1,q2),A) \<in> r_distinguishable_state_pairs_with_separators M"
  and     "((q2,q1),A') \<in> r_distinguishable_state_pairs_with_separators M"
shows "A = A'"
  using assms unfolding r_distinguishable_state_pairs_with_separators_def
  by force 

lemma r_distinguishable_state_pairs_with_separators_elem_is_separator:
  assumes "((q1,q2),A) \<in> r_distinguishable_state_pairs_with_separators M"
  and     "observable M"
  and     "completely_specified M"
shows "is_separator M q1 q2 A (Inr q1) (Inr q2)"
proof -
  have *:"q1 \<in> nodes M" and **:"q2 \<in> nodes M" and ***:"q1 \<noteq> q2" and ****: "q2\<noteq>q1" and *****: "state_separator_from_s_states M q1 q2 = Some A \<or> state_separator_from_s_states M q2 q1 = Some A"
    using assms(1) unfolding r_distinguishable_state_pairs_with_separators_def by auto

  from ***** have "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A \<or> is_state_separator_from_canonical_separator (canonical_separator M q2 q1) q2 q1 A"
    using state_separator_from_s_states_soundness[of M q1 q2 A, OF _ * ** assms(3)]
    using state_separator_from_s_states_soundness[of M q2 q1 A, OF _ ** * assms(3)] by auto
  then show ?thesis
    using state_separator_from_canonical_separator_is_separator[of M q1 q2 A, OF _ \<open>observable M\<close> * ** ***] 
    using state_separator_from_canonical_separator_is_separator[of M q2 q1 A, OF _ \<open>observable M\<close> ** * ****] 
    using is_separator_sym[of M q2 q1 A "Inr q2" "Inr q1"] by auto
qed


subsection \<open>Pairwise r-distinguishable Sets of States\<close>


definition pairwise_r_distinguishable_state_sets_from_separators :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> 'a set set" where
  "pairwise_r_distinguishable_state_sets_from_separators M = { S . S \<subseteq> nodes M \<and> (\<forall> q1 \<in> S . \<forall> q2 \<in> S . q1 \<noteq> q2 \<longrightarrow> (q1,q2) \<in> image fst (r_distinguishable_state_pairs_with_separators M))}" 

definition pairwise_r_distinguishable_state_sets_from_separators_list :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> 'a set list" where
  "pairwise_r_distinguishable_state_sets_from_separators_list M = (let RDS = image fst (r_distinguishable_state_pairs_with_separators M)
                                                                    in filter (\<lambda> S . \<forall> q1 \<in> S . \<forall> q2 \<in> S . q1 \<noteq> q2 \<longrightarrow> (q1,q2) \<in> RDS) 
                                                                           (map set (pow_list (nodes_as_list M))))"

(* use a list-based calculation to avoid storing the entire powerset *)
lemma pairwise_r_distinguishable_state_sets_from_separators_code[code] :
  "pairwise_r_distinguishable_state_sets_from_separators M = set (pairwise_r_distinguishable_state_sets_from_separators_list M)"
  using pow_list_set[of "nodes_as_list M"]
  unfolding nodes_as_list_set[of M] pairwise_r_distinguishable_state_sets_from_separators_def pairwise_r_distinguishable_state_sets_from_separators_list_def Let_def
  by auto


value "pairwise_r_distinguishable_state_sets_from_separators m_ex_H"
value "pairwise_r_distinguishable_state_sets_from_separators m_ex_9"


lemma pairwise_r_distinguishable_state_sets_from_separators_cover :
  assumes "q \<in> nodes M"
  shows "\<exists> S \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . q \<in> S"
  unfolding pairwise_r_distinguishable_state_sets_from_separators_def using assms by blast






definition maximal_pairwise_r_distinguishable_state_sets_from_separators :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> 'a set set" where
  "maximal_pairwise_r_distinguishable_state_sets_from_separators M = { S . S \<in> (pairwise_r_distinguishable_state_sets_from_separators M) \<and> (\<nexists> S' . S' \<in> (pairwise_r_distinguishable_state_sets_from_separators M) \<and> S \<subset> S')}"


definition maximal_pairwise_r_distinguishable_state_sets_from_separators_list :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> 'a set list" where
  "maximal_pairwise_r_distinguishable_state_sets_from_separators_list M = remove_subsets (pairwise_r_distinguishable_state_sets_from_separators_list M)"
      
(*
lemma maximal_pairwise_r_distinguishable_state_sets_from_separators_code[code] :
  "maximal_pairwise_r_distinguishable_state_sets_from_separators M = 
    (let PR = (pairwise_r_distinguishable_state_sets_from_separators M) 
      in Set.filter (\<lambda> S . \<not>(\<exists> S' \<in> PR . S \<subset> S')) PR)"
  unfolding maximal_pairwise_r_distinguishable_state_sets_from_separators_def Let_def by auto


value "maximal_pairwise_r_distinguishable_state_sets_from_separators m_ex_H"
value "maximal_pairwise_r_distinguishable_state_sets_from_separators m_ex_9"
*)


lemma maximal_pairwise_r_distinguishable_state_sets_from_separators_code[code] :
  "maximal_pairwise_r_distinguishable_state_sets_from_separators M = set (maximal_pairwise_r_distinguishable_state_sets_from_separators_list M)"
  unfolding maximal_pairwise_r_distinguishable_state_sets_from_separators_list_def Let_def remove_subsets_set pairwise_r_distinguishable_state_sets_from_separators_code[symmetric] maximal_pairwise_r_distinguishable_state_sets_from_separators_def by blast

value "maximal_pairwise_r_distinguishable_state_sets_from_separators m_ex_H"
value "maximal_pairwise_r_distinguishable_state_sets_from_separators m_ex_9"



lemma maximal_pairwise_r_distinguishable_state_sets_from_separators_cover :
  assumes "q \<in> nodes M"
  shows "\<exists> S \<in> (maximal_pairwise_r_distinguishable_state_sets_from_separators M ). q \<in> S"
proof -

  have *: "{q} \<in> (pairwise_r_distinguishable_state_sets_from_separators M)"
    unfolding pairwise_r_distinguishable_state_sets_from_separators_def using assms by blast
  have **: "finite (pairwise_r_distinguishable_state_sets_from_separators M)"
    unfolding pairwise_r_distinguishable_state_sets_from_separators_def by (simp add: fsm_nodes_finite) 

  have "(maximal_pairwise_r_distinguishable_state_sets_from_separators M) = 
        {S \<in> (pairwise_r_distinguishable_state_sets_from_separators M). \<not>(\<exists> S' \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . S \<subset> S')}"
    unfolding maximal_pairwise_r_distinguishable_state_sets_from_separators_def  pairwise_r_distinguishable_state_sets_from_separators_def by metis
  then have "(maximal_pairwise_r_distinguishable_state_sets_from_separators M) = 
        {S \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . (\<forall> S' \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . \<not> S \<subset> S')}"
    by blast 
  moreover have "\<exists> S \<in> {S \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . (\<forall> S' \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . \<not> S \<subset> S')} . q \<in> S"
    using maximal_set_cover[OF ** *] by blast
  ultimately show ?thesis by blast 
qed







subsection \<open>Calculating d-reachable States with Preambles\<close>



(* calculate d-reachable states and a fixed assignment of preambles *)
definition d_reachable_states_with_preambles :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> ('a \<times> ('a,'b,'c::linorder) fsm) set" where
  "d_reachable_states_with_preambles M = image (\<lambda> qp . (fst qp, the (snd qp))) (Set.filter (\<lambda> qp . snd qp \<noteq> None) (image (\<lambda> q . (q, calculate_state_preamble_from_input_choices M q)) (nodes M)))"



lemma d_reachable_states_with_preambles_exhaustiveness :
  assumes "\<exists> P . is_preamble P M q"
  and     "q \<in> nodes M"
shows "\<exists> P . (q,P) \<in> (d_reachable_states_with_preambles M)"
  using calculate_state_preamble_from_input_choices_exhaustiveness[OF assms(1)] assms(2)
  unfolding d_reachable_states_with_preambles_def by force


lemma d_reachable_states_with_preambles_soundness :
  assumes "(q,P) \<in> (d_reachable_states_with_preambles M)"
  and     "observable M"
  shows "is_preamble P M q"
    and "q \<in> nodes M"
  using assms(1) calculate_state_preamble_from_input_choices_soundness[of M q P]
  unfolding d_reachable_states_with_preambles_def
  using imageE by auto

definition maximal_repetition_sets_from_separators :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> ('a set \<times> 'a set) set" where
  "maximal_repetition_sets_from_separators M = {(S, S \<inter> (image fst (d_reachable_states_with_preambles M))) | S . S \<in> (maximal_pairwise_r_distinguishable_state_sets_from_separators M)}"

definition maximal_repetition_sets_from_separators_list_naive :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> ('a set \<times> 'a set) list" where
  "maximal_repetition_sets_from_separators_list_naive M = (let DR = (image fst (d_reachable_states_with_preambles M))
    in  map (\<lambda> S . (S, S \<inter> DR)) (maximal_pairwise_r_distinguishable_state_sets_from_separators_list M))"


lemma maximal_repetition_sets_from_separators_code[code]: 
  "maximal_repetition_sets_from_separators M = (let DR = (image fst (d_reachable_states_with_preambles M))
    in  image (\<lambda> S . (S, S \<inter> DR)) (maximal_pairwise_r_distinguishable_state_sets_from_separators M))" 
  unfolding maximal_repetition_sets_from_separators_def Let_def by force

(* TODO: decide which code equation to use *)
lemma maximal_repetition_sets_from_separators_code_alt: 
  "maximal_repetition_sets_from_separators M = set (maximal_repetition_sets_from_separators_list_naive M)" 
  unfolding maximal_repetition_sets_from_separators_def maximal_repetition_sets_from_separators_list_naive_def Let_def maximal_pairwise_r_distinguishable_state_sets_from_separators_code by force


value "maximal_repetition_sets_from_separators m_ex_H"
value "maximal_repetition_sets_from_separators m_ex_9"






subsubsection \<open>Calculating Sub-Optimal Repetition Sets\<close>

text \<open>Finding maximal pairwise r-distinguishable subsets of the node set of some FSM is likely too expensive
      for FSMs containing a large number of r-distinguishable pairs of states\<close>

fun extend_until_conflict :: "('a \<times> 'a) set \<Rightarrow> 'a list \<Rightarrow> 'a list \<Rightarrow> nat \<Rightarrow> 'a list" where
  "extend_until_conflict non_confl_set candidates xs 0 = xs" |
  "extend_until_conflict non_confl_set candidates xs (Suc k) = (case dropWhile (\<lambda> x . find (\<lambda> y . (x,y) \<notin> non_confl_set) xs \<noteq> None) candidates of
    [] \<Rightarrow> xs |
    (c#cs) \<Rightarrow> extend_until_conflict non_confl_set cs (c#xs) k)"


value "extend_until_conflict {(1::nat,2),(2,1),(1,3),(3,1),(2,4),(4,2)} [3,2,5,4] [1] 5"
value "extend_until_conflict {(1::nat,2),(2,1),(1,3),(3,1),(2,4),(4,2)} [2,3,4,5] [1] 5"

lemma extend_until_conflict_retainment :
  assumes "x \<in> set xs"
  shows "x \<in> set (extend_until_conflict non_confl_set candidates xs k)" 
using assms proof (induction k arbitrary: candidates xs)
  case 0
  then show ?case by auto
next
  case (Suc k)
  then show ?case proof (cases "dropWhile (\<lambda> x . find (\<lambda> y . (x,y) \<notin> non_confl_set) xs \<noteq> None) candidates")
    case Nil
    then show ?thesis
      by (metis Suc.prems extend_until_conflict.simps(2) list.simps(4)) 
  next
    case (Cons c cs)
    then show ?thesis
      by (simp add: Suc.IH Suc.prems) 
  qed
qed

lemma extend_until_conflict_elem :
  assumes "x \<in> set (extend_until_conflict non_confl_set candidates xs k)"
  shows "x \<in> set xs \<or> x \<in> set candidates"
using assms proof (induction k arbitrary: candidates xs)
  case 0
  then show ?case by auto
next
  case (Suc k)
  then show ?case proof (cases "dropWhile (\<lambda> x . find (\<lambda> y . (x,y) \<notin> non_confl_set) xs \<noteq> None) candidates")
    case Nil
    then show ?thesis 
      by (metis Suc.prems extend_until_conflict.simps(2) list.simps(4)) 
  next
    case (Cons c cs)
    then have "extend_until_conflict non_confl_set candidates xs (Suc k) = extend_until_conflict non_confl_set cs (c#xs) k"
      by auto
    then have "x \<in> set (c # xs) \<or> x \<in> set cs"
      using Suc.IH[of cs "(c#xs)"] Suc.prems by auto
    moreover have "set (c#cs) \<subseteq> set candidates"
      using Cons by (metis set_dropWhileD subsetI) 
    ultimately show ?thesis
      using set_ConsD by auto 
  qed
qed

lemma extend_until_conflict_no_conflicts :
  assumes "x \<in> set (extend_until_conflict non_confl_set candidates xs k)"
  and     "y \<in> set (extend_until_conflict non_confl_set candidates xs k)"
  and     "x \<in> set xs \<Longrightarrow> y \<in> set xs \<Longrightarrow> (x,y) \<in> non_confl_set \<or> (y,x) \<in> non_confl_set"  
  and     "x \<noteq> y"  
shows "(x,y) \<in> non_confl_set \<or> (y,x) \<in> non_confl_set" 
using assms proof (induction k arbitrary: candidates xs)
  case 0
  then show ?case by auto
next
  case (Suc k)
  then show ?case proof (cases "dropWhile (\<lambda> x . find (\<lambda> y . (x,y) \<notin> non_confl_set) xs \<noteq> None) candidates")
    case Nil
    then have "extend_until_conflict non_confl_set candidates xs (Suc k) = xs"
      by (metis extend_until_conflict.simps(2) list.simps(4)) 
    then show ?thesis 
      using Suc.prems by auto
  next
    case (Cons c cs)
    then have "extend_until_conflict non_confl_set candidates xs (Suc k) = extend_until_conflict non_confl_set cs (c#xs) k"
      by auto
    then have xk: "x \<in> set (extend_until_conflict non_confl_set cs (c#xs) k)"
         and  yk: "y \<in> set (extend_until_conflict non_confl_set cs (c#xs) k)"
      using Suc.prems by auto

    

    have **: "x \<in> set (c#xs) \<Longrightarrow> y \<in> set (c#xs) \<Longrightarrow> (x,y) \<in> non_confl_set \<or> (y,x) \<in> non_confl_set"
    proof -
      have scheme: "\<And> P xs x xs' . dropWhile P xs = (x#xs') \<Longrightarrow> \<not> P x"
        by (simp add: dropWhile_eq_Cons_conv) 
      have "find (\<lambda> y . (c,y) \<notin> non_confl_set) xs = None" 
        using scheme[OF Cons] by simp
      then have *: "\<And> y . y \<in> set xs \<Longrightarrow> (c,y) \<in> non_confl_set"
        unfolding find_None_iff by blast

      assume "x \<in> set (c#xs)" and "y \<in> set (c#xs)"
      then consider (a1) "x = c \<and> y \<in> set xs" |
                    (a2) "y = c \<and> x \<in> set xs" |
                    (a3) "x \<in> set xs \<and> y \<in> set xs" 
        using \<open>x \<noteq> y\<close> by auto
      then show ?thesis 
        using * Suc.prems(3) by (cases; auto)
    qed

    show ?thesis using Suc.IH[OF xk yk ** Suc.prems(4)] by blast
  qed
qed






(* Greedy algorithm that finds one maximal pairwise r-distinguishable set for each state *)
definition greedy_pairwise_r_distinguishable_state_sets_from_separators :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> 'a set list" where
  "greedy_pairwise_r_distinguishable_state_sets_from_separators M = 
    (let pwrds = image fst (r_distinguishable_state_pairs_with_separators M);
         k     = size M;
         nL    = nodes_as_list M
     in map (\<lambda>q . set (extend_until_conflict pwrds (remove1 q nL) [q] k)) nL)"

definition maximal_repetition_sets_from_separators_list_greedy :: "('a::linorder,'b::linorder,'c::linorder) fsm \<Rightarrow> ('a set \<times> 'a set) list" where
  "maximal_repetition_sets_from_separators_list_greedy M = (let DR = (image fst (d_reachable_states_with_preambles M))
    in remdups (map (\<lambda> S . (S, S \<inter> DR)) (greedy_pairwise_r_distinguishable_state_sets_from_separators M)))"




value "greedy_pairwise_r_distinguishable_state_sets_from_separators m_ex_H"
value "greedy_pairwise_r_distinguishable_state_sets_from_separators m_ex_9"

lemma greedy_pairwise_r_distinguishable_state_sets_from_separators_cover :
  assumes "q \<in> nodes M"
shows "\<exists> S \<in> set (greedy_pairwise_r_distinguishable_state_sets_from_separators M). q \<in> S"
  using assms extend_until_conflict_retainment[of q "[q]"]
  unfolding nodes_as_list_set[symmetric] greedy_pairwise_r_distinguishable_state_sets_from_separators_def Let_def
  by auto

lemma r_distinguishable_state_pairs_with_separators_sym :
  assumes "(q1,q2) \<in> fst ` r_distinguishable_state_pairs_with_separators M"
  shows "(q2,q1) \<in> fst ` r_distinguishable_state_pairs_with_separators M" 
  using assms unfolding r_distinguishable_state_pairs_with_separators_def by force


lemma greedy_pairwise_r_distinguishable_state_sets_from_separators_soundness :
  "set (greedy_pairwise_r_distinguishable_state_sets_from_separators M) \<subseteq> (pairwise_r_distinguishable_state_sets_from_separators M)"
proof 
  fix S assume "S \<in> set (greedy_pairwise_r_distinguishable_state_sets_from_separators M)"
  then obtain q' where "q' \<in> nodes M"
                 and   *: "S = set (extend_until_conflict (image fst (r_distinguishable_state_pairs_with_separators M)) (remove1 q' (nodes_as_list M)) [q'] (size M))"
    unfolding greedy_pairwise_r_distinguishable_state_sets_from_separators_def Let_def nodes_as_list_set[symmetric] by auto


  have "S \<subseteq> nodes M"
  proof 
    fix q assume "q \<in> S"
    then have "q \<in> set (extend_until_conflict (image fst (r_distinguishable_state_pairs_with_separators M)) (remove1 q' (nodes_as_list M)) [q'] (size M))"
      using * by auto
    then show "q \<in> nodes M"
      using extend_until_conflict_elem[of q "image fst (r_distinguishable_state_pairs_with_separators M)" "(remove1 q' (nodes_as_list M))" "[q']" "size M"]
      using nodes_as_list_set \<open>q' \<in> nodes M\<close> by auto
  qed

  moreover have "\<And> q1 q2 . q1 \<in> S \<Longrightarrow> q2 \<in> S \<Longrightarrow> q1 \<noteq> q2 \<Longrightarrow> (q1,q2) \<in> image fst (r_distinguishable_state_pairs_with_separators M)"  
  proof -
    fix q1 q2 assume "q1 \<in> S" and "q2 \<in> S" and "q1 \<noteq> q2"
    then have e1: "q1 \<in> set (extend_until_conflict (image fst (r_distinguishable_state_pairs_with_separators M)) (remove1 q' (nodes_as_list M)) [q'] (size M))"
         and  e2: "q2 \<in> set (extend_until_conflict (image fst (r_distinguishable_state_pairs_with_separators M)) (remove1 q' (nodes_as_list M)) [q'] (size M))"
      unfolding * by simp+
    have e3: "(q1 \<in> set [q'] \<Longrightarrow> q2 \<in> set [q'] \<Longrightarrow> (q1, q2) \<in> fst ` r_distinguishable_state_pairs_with_separators M \<or> (q2, q1) \<in> fst ` r_distinguishable_state_pairs_with_separators M)"
      using \<open>q1 \<noteq> q2\<close> by auto

    show "(q1,q2) \<in> image fst (r_distinguishable_state_pairs_with_separators M)"
      using extend_until_conflict_no_conflicts[OF e1 e2 e3 \<open>q1 \<noteq> q2\<close>]
            r_distinguishable_state_pairs_with_separators_sym[of q2 q1 M] by blast
  qed

  ultimately show "S \<in> (pairwise_r_distinguishable_state_sets_from_separators M)"
    unfolding pairwise_r_distinguishable_state_sets_from_separators_def by blast
qed


end