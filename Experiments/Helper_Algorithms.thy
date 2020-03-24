theory Helper_Algorithms
imports R_Distinguishability State_Separator State_Preamble
begin

subsection \<open>Calculating r-distinguishable State Pairs with Separators\<close>

definition r_distinguishable_state_pairs_with_separators :: "('a::linorder,'b::linorder,'c) fsm \<Rightarrow> (('a \<times> 'a) \<times> (('a \<times> 'a) + 'a,'b,'c) fsm) set" where
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



subsection \<open>Pairwise r-distinguishable Sets of States\<close>


definition pairwise_r_distinguishable_state_sets_from_separators :: "('a::linorder,'b::linorder,'c) fsm \<Rightarrow> 'a set set" where
  "pairwise_r_distinguishable_state_sets_from_separators M = { S . S \<subseteq> nodes M \<and> (\<forall> q1 \<in> S . \<forall> q2 \<in> S . q1 \<noteq> q2 \<longrightarrow> (q1,q2) \<in> image fst (r_distinguishable_state_pairs_with_separators M))}" 


(* use a list-based calculation to avoid storing the entire powerset *)
lemma pairwise_r_distinguishable_state_sets_from_separators_code[code] :
  "pairwise_r_distinguishable_state_sets_from_separators M = set (let RDS = image fst (r_distinguishable_state_pairs_with_separators M)
                                                                    in filter (\<lambda> S . \<forall> q1 \<in> S . \<forall> q2 \<in> S . q1 \<noteq> q2 \<longrightarrow> (q1,q2) \<in> RDS) 
                                                                           (map set (pow_list (nodes_as_list M))))"
  using pow_list_set[of "nodes_as_list M"]
  unfolding nodes_as_list_set[of M] pairwise_r_distinguishable_state_sets_from_separators_def Let_def
  by auto


value "pairwise_r_distinguishable_state_sets_from_separators m_ex_H"
value "pairwise_r_distinguishable_state_sets_from_separators m_ex_9"


lemma pairwise_r_distinguishable_state_sets_from_separators_cover :
  assumes "q \<in> nodes M"
  shows "\<exists> S \<in> (pairwise_r_distinguishable_state_sets_from_separators M) . q \<in> S"
  unfolding pairwise_r_distinguishable_state_sets_from_separators_def using assms by blast






definition maximal_pairwise_r_distinguishable_state_sets_from_separators :: "('a::linorder,'b::linorder,'c) fsm \<Rightarrow> 'a set set" where
  "maximal_pairwise_r_distinguishable_state_sets_from_separators M = { S . S \<in> (pairwise_r_distinguishable_state_sets_from_separators M) \<and> (\<nexists> S' . S' \<in> (pairwise_r_distinguishable_state_sets_from_separators M) \<and> S \<subset> S')}"

lemma maximal_pairwise_r_distinguishable_state_sets_from_separators_code[code] :
  "maximal_pairwise_r_distinguishable_state_sets_from_separators M = 
    (let PR = (pairwise_r_distinguishable_state_sets_from_separators M) 
      in Set.filter (\<lambda> S . \<not>(\<exists> S' \<in> PR . S \<subset> S')) PR)"
  unfolding maximal_pairwise_r_distinguishable_state_sets_from_separators_def Let_def by auto


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
definition d_reachable_states_with_preambles :: "('a::linorder,'b::linorder,'c) fsm \<Rightarrow> ('a \<times> ('a,'b,'c) fsm) set" where
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






definition maximal_repetition_sets_from_separators :: "('a::linorder,'b::linorder,'c) fsm \<Rightarrow> ('a set \<times> 'a set) set" where
  "maximal_repetition_sets_from_separators M = {(S, S \<inter> (image fst (d_reachable_states_with_preambles M))) | S . S \<in> (maximal_pairwise_r_distinguishable_state_sets_from_separators M)}"


lemma maximal_repetition_sets_from_separators_code[code]: 
  "maximal_repetition_sets_from_separators M = (let DR = (image fst (d_reachable_states_with_preambles M))
    in  image (\<lambda> S . (S, S \<inter> DR)) (maximal_pairwise_r_distinguishable_state_sets_from_separators M))" 
  unfolding maximal_repetition_sets_from_separators_def Let_def by force

value "maximal_repetition_sets_from_separators m_ex_H"
value "maximal_repetition_sets_from_separators m_ex_9"


end