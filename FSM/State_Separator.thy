theory State_Separator
imports R_Distinguishability IO_Sequence_Set
begin

section \<open>State Separators\<close>

subsection \<open>Definitions\<close>


abbreviation(input) "shift_Inl \<equiv> (\<lambda> t . (Inl (t_source t), t_input t, t_output t, Inl (t_target t)))"

definition shifted_transitions :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) Transition list" where
  "shifted_transitions M q1 q2 = map shift_Inl (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))"

definition distinguishing_transitions_left :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) Transition list" where
  "distinguishing_transitions_left M q1 q2 = (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1 )) (filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))))"

definition distinguishing_transitions_right :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) Transition list" where
  "distinguishing_transitions_right M q1 q2 = (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2 )) (filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))))"

definition canonical_separator :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a,'b) FSM_scheme" where
  "canonical_separator M q1 q2 = 
    \<lparr> initial = Inl (initial (product (from_FSM M q1) (from_FSM M q2))),
        inputs = inputs M,
        outputs = outputs M,
        transitions = 
          shifted_transitions M q1 q2
          @ distinguishing_transitions_left M q1 q2
          @ distinguishing_transitions_right M q1 q2,
        \<dots> = FSM.more M \<rparr>"


value[code] "(canonical_separator M_ex 2 3)"
value[code] "trim_transitions (canonical_separator M_ex 2 3)"


lemma canonical_separator_simps :
  "initial (canonical_separator M q1 q2) = Inl (initial (product (from_FSM M q1) (from_FSM M q2)))" 
  "inputs (canonical_separator M q1 q2) = inputs M" 
  "outputs (canonical_separator M q1 q2) = outputs M"
  "transitions (canonical_separator M q1 q2) =  
          shifted_transitions M q1 q2
          @ distinguishing_transitions_left M q1 q2
          @ distinguishing_transitions_right M q1 q2"
  unfolding canonical_separator_def by fastforce+ 



definition is_state_separator_from_canonical_separator :: "(('a \<times> 'a) + 'a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a,'b) FSM_scheme \<Rightarrow> bool" where
  "is_state_separator_from_canonical_separator CSep q1 q2 S = (
    is_submachine S CSep 
    \<and> single_input S
    \<and> acyclic S
    \<and> deadlock_state S (Inr q1)
    \<and> deadlock_state S (Inr q2)
    \<and> ((Inr q1) \<in> nodes S)
    \<and> ((Inr q2) \<in> nodes S)
    \<and> (\<forall> q \<in> nodes S . (q \<noteq> Inr q1 \<and> q \<noteq> Inr q2) \<longrightarrow> (isl q \<and> \<not> deadlock_state S q))
    \<and> (\<forall> q \<in> nodes S . \<forall> x \<in> set (inputs CSep) . (\<exists> t \<in> h S . t_source t = q \<and> t_input t = x) \<longrightarrow> (\<forall> t' \<in> h CSep . t_source t' = q \<and> t_input t' = x \<longrightarrow> t' \<in> h S))
)"


subsection \<open>Canonical Separator Properties\<close>

lemma path_shift_Inl :
  assumes "(set (map shift_Inl (wf_transitions M))) \<subseteq> set (transitions C)"
      and "\<And> t . t \<in> set (transitions C) \<Longrightarrow> isl (t_target t) \<Longrightarrow> \<exists> t' \<in> set (wf_transitions M) . t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t'))"
      and "initial C = Inl (initial M)"
      and "set (inputs C) = set (inputs M)"
      and "set (outputs C) = set (outputs M)"
    shows "path M (initial M) p = path C (initial C) (map shift_Inl p)"
proof (induction p rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc t p)

  have "path M (initial M) (p@[t]) \<Longrightarrow> path C (initial C) (map shift_Inl (p@[t]))"
  proof -
    assume "path M (initial M) (p@[t])"
    then have "path M (initial M) p" by auto
    then have "path C (initial C) (map shift_Inl p)" using snoc.IH by auto

    have "t_source t = target p (initial M)"
      using \<open>path M (initial M) (p@[t])\<close> by auto
    then have "t_source (shift_Inl t) = target (map shift_Inl p) (Inl (initial M))"
      by (cases p rule: rev_cases; auto)
    then have "t_source (shift_Inl t) = target (map shift_Inl p) (initial C)"
      using assms(3) by auto
    moreover have "target (map shift_Inl p) (initial C) \<in> nodes C"
      using path_target_is_node[OF \<open>path C (initial C) (map shift_Inl p)\<close>] by assumption
    ultimately have "t_source (shift_Inl t) \<in> nodes C"
      by auto
    moreover have "t \<in> h M"
      using \<open>path M (initial M) (p@[t])\<close> by auto
    ultimately have "(shift_Inl t) \<in> h C"
      using assms by auto

    show "path C (initial C) (map shift_Inl (p@[t]))"
      using path_append [OF \<open>path C (initial C) (map shift_Inl p)\<close>, of "[shift_Inl t]"]
      using \<open>(shift_Inl t) \<in> h C\<close> \<open>t_source (shift_Inl t) = target (map shift_Inl p) (initial C)\<close>
      using single_transition_path by force 
  qed

  moreover have "path C (initial C) (map shift_Inl (p@[t])) \<Longrightarrow> path M (initial M) (p@[t])" 
  proof -
    assume "path C (initial C) (map shift_Inl (p@[t]))"
    then have "path C (initial C) (map shift_Inl p)" by auto
    then have "path M (initial M) p" using snoc.IH by auto

    have "t_source (shift_Inl t) = target (map shift_Inl p) (initial C)"
      using \<open>path C (initial C) (map shift_Inl (p@[t]))\<close> by auto
    then have "t_source (shift_Inl t) = target (map shift_Inl p) (Inl (initial M))"
      using assms(3) by (cases p rule: rev_cases; auto)
    then have "t_source t = target p (initial M)"
      by (cases p rule: rev_cases; auto)
    moreover have "target p (initial M) \<in> nodes M"
      using path_target_is_node[OF \<open>path M (initial M) p\<close>] by assumption
    ultimately have "t_source t \<in> nodes M"
      by auto
    moreover have "shift_Inl t \<in> h C"
      using \<open>path C (initial C) (map shift_Inl (p@[t]))\<close> by auto
    moreover have "isl (t_target (shift_Inl t))"
      by auto
    ultimately have "t \<in> h M"
      using assms by fastforce 

    show "path M (initial M) (p@[t])"
      using path_append [OF \<open>path M (initial M) p\<close>, of "[t]"]
            single_transition_path[OF \<open>t \<in> h M\<close>]
            \<open>t_source t = target p (initial M)\<close> by auto
  qed

  ultimately show ?case
    by linarith 
qed




lemma canonical_separator_product_transitions_subset : "(set (map shift_Inl (wf_transitions (product (from_FSM M q1) (from_FSM M q2))))) \<subseteq> set (transitions (canonical_separator M q1 q2))"
proof -
  let ?PM = "(product (from_FSM M q1) (from_FSM M q2))"

  have *: "\<exists> ts2 . transitions (canonical_separator M q1 q2) = (map shift_Inl (wf_transitions ?PM)) @ ts2"
    by (metis (no_types) canonical_separator_simps(4) shifted_transitions_def)
  show ?thesis
    using list_prefix_subset[OF *] by assumption
qed



lemma canonical_separator_product_transitions_isl : 
  assumes "t \<in> set (transitions (canonical_separator M q1 q2))" 
  and "isl (t_target t)" 
shows "\<exists> t' \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))) . t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t'))"
proof -
  let ?PM = "(product (from_FSM M q1) (from_FSM M q2))"

  let ?ts1 = "map shift_Inl (wf_transitions ?PM)"
  let ?ts2 = "distinguishing_transitions_left M q1 q2"
  let ?ts3 = "distinguishing_transitions_right M q1 q2"
  

  have *: "transitions (canonical_separator M q1 q2) = ?ts1 @ ?ts2 @ ?ts3"
    by (metis (no_types) canonical_separator_simps(4) shifted_transitions_def)


  have "\<forall> t' . \<not> isl (t_target ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)) t'))"
    by auto
  have "\<And> t' . t' \<in> set ?ts2 \<Longrightarrow> \<not> isl (t_target t')" 
    using list_map_set_prop[of _ "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))" "(filter
                       (\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                              \<not> (\<exists>t'\<in>set (transitions M).
                                     t_source t' = snd (fst qqt) \<and>
                                     t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                       (concat
                         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                           (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
                  "\<lambda> t . \<not> isl (t_target t)", OF _ \<open>\<forall> t' . \<not> isl (t_target ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)) t'))\<close>] unfolding distinguishing_transitions_left_def by assumption
  then have **: "t \<notin> set ?ts2" using assms(2) by blast


  have "\<forall> t' . \<not> isl (t_target ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)) t'))"
    by auto
  have "\<And> t' . t' \<in> set ?ts3 \<Longrightarrow> \<not> isl (t_target t')" 
    using list_map_set_prop[of _ "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2))" "(filter
                       (\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                              \<not> (\<exists>t'\<in>set (transitions M).
                                     t_source t' = fst (fst qqt) \<and>
                                     t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                       (concat
                         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                           (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
                  "\<lambda> t . \<not> isl (t_target t)", OF _ \<open>\<forall> t' . \<not> isl (t_target ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)) t'))\<close>] unfolding distinguishing_transitions_right_def by assumption
  then have ***: "t \<notin> set ?ts3" using assms(2) by blast

  have ****: "t \<in> set (?ts1 @ (?ts2 @ ?ts3))" 
    using assms(1) * by metis
  have *****: "t \<notin> set (?ts2 @ ?ts3)" using ** *** by auto
  have ******: "t \<in> set ?ts1" using **** *****
    by (metis (no_types, lifting) Un_iff set_append)
  show ?thesis 
    using list_map_source_elem[OF ******] by assumption
qed



lemma canonical_separator_path_shift :
  "path (product (from_FSM M q1) (from_FSM M q2)) (initial (product (from_FSM M q1) (from_FSM M q2))) p 
    = path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) (map shift_Inl p)"
proof -
  let ?C = "(canonical_separator M q1 q2)"
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"

  have "set (inputs ?C) = set (inputs ?P)" 
    using canonical_separator_simps(2)[of M q1 q2] by auto
  have "set (outputs ?C) = set (outputs ?P)" 
    using canonical_separator_simps(3)[of M q1 q2] by auto

  show ?thesis 
    using path_shift_Inl[OF 
            canonical_separator_product_transitions_subset[of M q1 q2]  
            _
            canonical_separator_simps(1)[of M q1 q2] 
            \<open>set (inputs ?C) = set (inputs ?P)\<close>
            \<open>set (outputs ?C) = set (outputs ?P)\<close>, of p]
    using canonical_separator_product_transitions_isl[of _ M q1 q2] by blast
qed

lemma canonical_separator_product_h_isl : 
  assumes "t \<in> h (canonical_separator M q1 q2)" 
  and "isl (t_target t)" 
shows "\<exists> t' \<in> h (product (from_FSM M q1) (from_FSM M q2)) . t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t'))"
  using canonical_separator_product_transitions_isl[OF _ assms(2), of M q1 q2] assms(1) unfolding wf_transitions.simps by (simp del: product.simps from_FSM.simps)

lemma canonical_separator_t_source_isl :
  assumes "t \<in> set (transitions (canonical_separator M q1 q2))"
  shows "isl (t_source t)"
proof -
  let ?PM = "(product (from_FSM M q1) (from_FSM M q2))"

  let ?ts1 = "shifted_transitions M q1 q2"
  let ?ts2 = "distinguishing_transitions_left M q1 q2"
  let ?ts3 = "distinguishing_transitions_right M q1 q2"

  have *: "transitions (canonical_separator M q1 q2) = ?ts1 @ ?ts2 @ ?ts3"
    by (metis (no_types) canonical_separator_simps(4))

  have "\<forall> t' . isl (t_source (shift_Inl t'))"
    by auto
  have "\<forall> t' . isl (t_source ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)) t'))"
    by auto
  have "\<forall> t' . isl (t_source ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)) t'))"
    by auto
  
  have "\<And> t . t \<in> set ?ts1 \<Longrightarrow> isl (t_source t)"
    using list_map_set_prop[of _ shift_Inl "(wf_transitions (product (from_FSM M q1) (from_FSM M q2)))", OF _ \<open>\<forall> t' . isl (t_source (shift_Inl t'))\<close>] unfolding shifted_transitions_def by assumption

  moreover have "\<And> t' . t' \<in> set ?ts2 \<Longrightarrow> isl (t_source t')" 
    using list_map_set_prop[of _ "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))" "(filter
                       (\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                              \<not> (\<exists>t'\<in>set (transitions M).
                                     t_source t' = snd (fst qqt) \<and>
                                     t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                       (concat
                         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                           (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))", OF _ \<open>\<forall> t' . isl (t_source ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)) t'))\<close>] unfolding distinguishing_transitions_left_def by assumption

  moreover have "\<And> t' . t' \<in> set ?ts3 \<Longrightarrow> isl (t_source t')" 
    using list_map_set_prop[of _ "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2))" "(filter
                       (\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                              \<not> (\<exists>t'\<in>set (transitions M).
                                     t_source t' = fst (fst qqt) \<and>
                                     t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                       (concat
                         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                           (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))", OF _ \<open>\<forall> t' . isl (t_source ((\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)) t'))\<close>] unfolding distinguishing_transitions_right_def by assumption

  ultimately show ?thesis using \<open>transitions (canonical_separator M q1 q2) = ?ts1 @ ?ts2 @ ?ts3\<close>
    by (metis assms list_prefix_elem) 
qed
  



lemma canonical_separator_path_from_shift :
  assumes "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p"
      and "isl (target p (initial (canonical_separator M q1 q2)))"
  shows "\<exists> p' . path (product (from_FSM M q1) (from_FSM M q2)) (initial (product (from_FSM M q1) (from_FSM M q2))) p' \<and> p = (map shift_Inl p')"
using assms proof (induction p rule: rev_induct)
  case Nil
  show ?case using canonical_separator_path_shift[of M q1 q2 "[]"] by fast
next
  case (snoc t p)
  then have "isl (t_target t)" by auto

  let ?C = "(canonical_separator M q1 q2)"
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"

  have "t \<in> h ?C" and "t_source t = target p (initial ?C)" 
    using snoc.prems by auto
  then have "isl (t_source t)"
    using canonical_separator_t_source_isl[of t M q1 q2] by auto  
  then have "isl (target p (initial (canonical_separator M q1 q2)))"
    using \<open>t_source t = target p (initial ?C)\<close> by auto

  have "path ?C (initial ?C) p" using snoc.prems by auto
  then obtain p' where "path ?P (initial ?P) p'"
                   and "p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'"
    using snoc.IH[OF _ \<open>isl (target p (initial (canonical_separator M q1 q2)))\<close>] by blast
  then have "target p (initial ?C) = Inl (target p' (initial ?P))"
  proof (cases p rule: rev_cases)
    case Nil
    then show ?thesis 
      unfolding target.simps visited_states.simps using \<open>p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'\<close> canonical_separator_simps(1)[of M q1 q2] by auto
  next
    case (snoc ys y)
    then show ?thesis 
      unfolding target.simps visited_states.simps using \<open>p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'\<close> by (cases p' rule: rev_cases; auto)
  qed
  

  obtain t' where "t' \<in> h ?P" 
              and "t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t'))"
    using canonical_separator_product_h_isl[OF \<open>t \<in> h ?C\<close> \<open>isl (t_target t)\<close>] by blast

  
  have "path ?P (initial ?P) (p'@[t'])"
  proof -
    have "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) (map (\<lambda>p. (Inl (t_source p), t_input p, t_output p, Inl (t_target p))) (p' @ [t']))"
      using \<open>p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'\<close> \<open>t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t'))\<close> snoc.prems(1) by auto
    then show ?thesis
      by (metis (no_types) canonical_separator_path_shift)
  qed

  moreover have "p@[t] = map shift_Inl (p'@[t'])"
    using \<open>p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'\<close> \<open>t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t'))\<close> by auto

  ultimately show ?case by meson
qed
  
  
lemma canonical_separator_h_from_product :
  assumes "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
  shows "shift_Inl t \<in> h (canonical_separator M q1 q2)"
proof -
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"
  let ?C = "(canonical_separator M q1 q2)"

  have "shift_Inl t \<in> set (transitions ?C)"
    using canonical_separator_product_transitions_subset[of M q1 q2] assms
    by (metis (no_types, lifting) image_iff set_map subsetCE) 

  have "t_source t \<in> nodes ?P" 
    using assms by blast 
  obtain p where "path ?P (initial ?P) p" and "target p (initial ?P) = t_source t"
    using path_to_node[OF \<open>t_source t \<in> nodes ?P\<close>] by metis
  then have "path ?P (initial ?P) (p@[t])"
    using assms path_append_last by metis
  then have "path ?C (initial ?C) (map shift_Inl (p@[t]))"
    using canonical_separator_path_shift[of M q1 q2 "p@[t]"] by linarith
  then have "path ?C (initial ?C) ((map shift_Inl p)@[shift_Inl t])"
    by auto
  then show "shift_Inl t \<in> h ?C"
    by blast
qed



subsection \<open>Calculating State Separators\<close>

fun calculate_state_separator_from_canonical_separator_naive :: "('a, 'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a,'b) FSM_scheme option" where
  "calculate_state_separator_from_canonical_separator_naive M q1 q2 = 
    (let CSep = canonical_separator M q1 q2 in
      find 
        (\<lambda> S . is_state_separator_from_canonical_separator CSep q1 q2 S) 
        (map 
          (\<lambda> assn . generate_submachine_from_assignment CSep assn) 
          (generate_choices 
            (map 
              (\<lambda>q . (q, filter 
                          (\<lambda>x . \<exists> t \<in> h CSep . t_source t = q \<and> t_input t = x) 
                          (inputs CSep))) 
              (nodes_from_distinct_paths CSep)))))"

lemma trim_transitions_state_separator_from_canonical_separator : 
  assumes "is_state_separator_from_canonical_separator CSep q1 q2 S"
  shows   "is_state_separator_from_canonical_separator CSep q1 q2 (trim_transitions S)"
  using assms  unfolding is_state_separator_from_canonical_separator_def
  by (metis trim_transitions_acyclic trim_transitions_deadlock_state_nodes trim_transitions_nodes trim_transitions_simps(4) trim_transitions_single_input trim_transitions_submachine)

lemma transition_reorder_is_state_separator_from_canonical_separator : 
  assumes "is_state_separator_from_canonical_separator CSep q1 q2 S"
  and     "initial S' = initial S"
  and     "inputs S' = inputs S"
  and     "outputs S' = outputs S"
  and     "set (transitions S') = set (transitions S)"
shows "is_state_separator_from_canonical_separator CSep q1 q2 S'"
proof -
  have "is_submachine S CSep"
        and "single_input S"
        and "acyclic S"
        and "deadlock_state S (Inr q1)"
        and "deadlock_state S (Inr q2)"
        and "Inr q1 \<in> nodes S"
        and "Inr q2 \<in> nodes S"
        and "(\<forall>q\<in>nodes S. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state S q)"
        and "(\<forall>q\<in>nodes S.
              \<forall>x\<in>set (inputs CSep).
                 (\<exists>t\<in>h S. t_source t = q \<and> t_input t = x) \<longrightarrow>
                 (\<forall>t'\<in>h CSep. t_source t' = q \<and> t_input t' = x \<longrightarrow> t' \<in> h S))"
    using assms(1) unfolding is_state_separator_from_canonical_separator_def by linarith+

  note transitions_reorder[OF assms(2-5)]

  have "is_submachine S' CSep"
    using \<open>is_submachine S CSep\<close> \<open>h S' = h S\<close> assms(2-4) by auto 
  moreover have "single_input S' " 
    using \<open>single_input S\<close>  unfolding single_input.simps \<open>h S' = h S\<close> \<open>nodes S' = nodes S\<close> by blast
  moreover have "acyclic S'"
    using \<open>acyclic S\<close> assms(2) transitions_reorder(2)[OF assms(2-5)] unfolding acyclic.simps by simp
  moreover have "deadlock_state S' (Inr q1)"
    using \<open>deadlock_state S (Inr q1)\<close> \<open>nodes S' = nodes S\<close> \<open>h S' = h S\<close> by auto
  moreover have "deadlock_state S' (Inr q2)"
    using \<open>deadlock_state S (Inr q2)\<close> \<open>nodes S' = nodes S\<close> \<open>h S' = h S\<close> by auto
  moreover have "Inr q1 \<in> nodes S'" and "Inr q2 \<in> nodes S'"
    using \<open>Inr q1 \<in> nodes S\<close> \<open>Inr q2 \<in> nodes S\<close> \<open>nodes S' = nodes S\<close> by blast+
  moreover have "(\<forall>q\<in>nodes S'. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state S' q)"
    using \<open>(\<forall>q\<in>nodes S. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state S q)\<close> \<open>nodes S' = nodes S\<close> \<open>h S' = h S\<close> unfolding deadlock_state.simps by blast
  moreover have "(\<forall>q\<in>nodes S'.
              \<forall>x\<in>set (inputs CSep).
                 (\<exists>t\<in>h S'. t_source t = q \<and> t_input t = x) \<longrightarrow>
                 (\<forall>t'\<in>h CSep. t_source t' = q \<and> t_input t' = x \<longrightarrow> t' \<in> h S'))"
    using \<open>(\<forall>q\<in>nodes S.
              \<forall>x\<in>set (inputs CSep).
                 (\<exists>t\<in>h S. t_source t = q \<and> t_input t = x) \<longrightarrow>
                 (\<forall>t'\<in>h CSep. t_source t' = q \<and> t_input t' = x \<longrightarrow> t' \<in> h S))\<close> 
          \<open>h S' = h S\<close> \<open>nodes S' = nodes S\<close> by blast
  ultimately show ?thesis unfolding is_state_separator_from_canonical_separator_def by linarith
qed


lemma calculate_state_separator_from_canonical_separator_naive_soundness :
  assumes "calculate_state_separator_from_canonical_separator_naive M q1 q2 = Some S"
shows "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
  using assms unfolding calculate_state_separator_from_canonical_separator_naive.simps 
  using find_condition[of "(is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2)"
                          "(map (generate_submachine_from_assignment (canonical_separator M q1 q2))
                             (generate_choices
                               (map (\<lambda>q. (q, filter (\<lambda>x. \<exists>t\<in>h (canonical_separator M q1 q2). t_source t = q \<and> t_input t = x) (inputs (canonical_separator M q1 q2))))
                                 (nodes_from_distinct_paths (canonical_separator M q1 q2)))))", of S] 
  by metis 


lemma calculate_state_separator_from_canonical_separator_naive_exhaustiveness :
  assumes "\<exists> S . is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
  shows "\<exists> S' . calculate_state_separator_from_canonical_separator_naive M q1 q2 = Some S'"
proof -
  let ?CSep = "(canonical_separator M q1 q2)"
  from assms obtain S where "is_state_separator_from_canonical_separator ?CSep q1 q2 S" by blast
  let ?S = "trim_transitions S"

  have "is_state_separator_from_canonical_separator ?CSep q1 q2 ?S"
    using trim_transitions_state_separator_from_canonical_separator[OF \<open>is_state_separator_from_canonical_separator ?CSep q1 q2 S\<close>] by assumption

  then have "is_submachine ?S ?CSep"
        and "single_input ?S"
        and "acyclic ?S"
        and "deadlock_state ?S (Inr q1)"
        and "deadlock_state ?S (Inr q2)"
        and "Inr q1 \<in> nodes ?S"
        and "Inr q2 \<in> nodes ?S"
        and "(\<forall>q\<in>nodes ?S. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state ?S q)"
        and "(\<forall>q\<in>nodes ?S.
              \<forall>x\<in>set (inputs ?CSep).
                 (\<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x) \<longrightarrow>
                 (\<forall>t'\<in>h ?CSep. t_source t' = q \<and> t_input t' = x \<longrightarrow> t' \<in> h ?S))"
    unfolding is_state_separator_from_canonical_separator_def by linarith+

  have "finite (nodes ?S)"
    by (simp add: nodes_finite) 
  moreover have "nodes ?S \<subseteq> nodes ?CSep"
    using submachine_nodes[OF \<open>is_submachine ?S ?CSep\<close>] by assumption
  moreover have "\<And> NS . finite NS \<Longrightarrow> NS \<subseteq> nodes ?CSep 
        \<Longrightarrow> \<exists> f . (\<forall> q . (q \<notin> NS \<longrightarrow> f q = None) \<and> (q \<in> NS \<longrightarrow> ((q \<notin> nodes ?S \<and> f q = None) \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> f q = None) \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
  proof -
    fix NS assume "finite NS" and "NS \<subseteq> nodes ?CSep"
    then show "\<exists> f . (\<forall> q . (q \<notin> NS \<longrightarrow> f q = None) \<and> (q \<in> NS \<longrightarrow> ((q \<notin> nodes ?S \<and> f q = None) \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> f q = None) \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
    proof (induction)
      case empty
      then show ?case by auto
    next
      case (insert s NS)
      then have "NS \<subseteq> nodes (canonical_separator M q1 q2)" by auto
      then obtain f where f_def : "(\<forall> q . (q \<notin> NS \<longrightarrow> f q = None) \<and> (q \<in> NS \<longrightarrow> ((q \<notin> nodes ?S \<and> f q = None) \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> f q = None) \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
        using insert.IH by blast
      
      show ?case proof (cases "s \<in> nodes ?S")
        case True
        then show ?thesis proof (cases "deadlock_state ?S s")
          case True
          let ?f = "f( s := None)"
          have "(\<forall> q . (q \<notin> (insert s NS) \<longrightarrow> f q = None) \<and> (q \<in> (insert s NS) \<longrightarrow> ((q \<notin> nodes ?S \<and> f q = None) \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> f q = None) \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
            by (metis (no_types, lifting) True f_def insert_iff)
          then show ?thesis by blast
        next
          case False
          then obtain t where "t\<in>h ?S" and "t_source t = s"
            by (meson True deadlock_state.elims(3))
          then have theEx: "\<exists>t'\<in>h ?S. t_source t' = s \<and> t_input t' = t_input t" 
            using \<open>t_source t = s\<close> \<open>s \<in> nodes ?S\<close> by blast
          
          have "\<forall> t' \<in> h ?S . (t_source t' = s) \<longrightarrow> t_input t' = t_input t"
            using \<open>single_input ?S\<close> \<open>t_source t = s\<close> \<open>s \<in> nodes ?S\<close> unfolding single_input.simps
            by (metis \<open>t \<in> h ?S\<close>) 
          then have theAll: "\<And>x . (\<exists>t'\<in>h ?S. t_source t' = s \<and> t_input t' = x) \<Longrightarrow> x = t_input t"
            by blast


          let ?f = "f( s := Some (t_input t))"
          have "t_input t = (THE x .  \<exists>t'\<in>h ?S. t_source t' = s \<and> t_input t' = x)"
            using the_equality[of "\<lambda> x . \<exists>t'\<in>h ?S. t_source t' = s \<and> t_input t' = x" "t_input t", OF theEx theAll] by simp


          then have "(\<forall> q . (q \<notin> (insert s NS) \<longrightarrow> ?f q = None) \<and> (q \<in> (insert s NS) \<longrightarrow> ((q \<notin> nodes ?S \<and> ?f q = None) \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> ?f q = None) \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> ?f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
            using \<open>s \<in> nodes ?S\<close> False f_def by auto
          then show ?thesis by blast
        qed
      next
        case False
        let ?f = "f( s := None)"
        have "(\<forall> q . (q \<notin> (insert s NS) \<longrightarrow> ?f q = None) \<and> (q \<in> (insert s NS) \<longrightarrow> ((q \<notin> nodes ?S \<and> ?f q = None) \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> ?f q = None) \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> ?f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
            using False f_def by auto
        then show ?thesis by blast
      qed
    qed
  qed

  ultimately obtain f where f_def : "(\<forall> q . 
                                        (q \<notin> nodes ?S \<longrightarrow> f q = None) 
                                        \<and> (q \<in> nodes ?S \<longrightarrow> ((q \<notin> nodes ?S \<and> f q = None) 
                                                            \<or> (q \<in> nodes ?S \<and> deadlock_state ?S q \<and> f q = None) 
                                                            \<or> (q \<in> nodes ?S \<and> \<not> deadlock_state ?S q \<and> f q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = q \<and> t_input t = x)))))"
    by blast

  let ?assn = "map (\<lambda>q . (q,f q)) (nodes_from_distinct_paths ?CSep)"
  let ?possible_choices = "(map 
              (\<lambda>q . (q, filter 
                          (\<lambda>x . \<exists> t \<in> h ?CSep . t_source t = q \<and> t_input t = x) 
                          (inputs ?CSep))) 
              (nodes_from_distinct_paths ?CSep))"
  let ?filtered_transitions = "filter
        (\<lambda>t. (t_source t, Some (t_input t))
             \<in> set (map (\<lambda>q. (q, f q)) (nodes_from_distinct_paths ?CSep)))
        (wf_transitions ?CSep)"


  (* FSM equivalent to S but possibly with a different order of transitions *)
  let ?S' = "generate_submachine_from_assignment ?CSep ?assn"
  
  have p1: "length ?assn = length ?possible_choices" by auto

  have p2a: "(\<forall> i < length ?assn . (fst (?assn ! i)) = (fst (?possible_choices ! i)))"
    by auto
  have p2b: "(\<And> i . i < length ?assn \<Longrightarrow> ((snd (?assn ! i)) = None \<or> ((snd (?assn ! i)) \<noteq> None \<and> the (snd (?assn ! i)) \<in> set (snd (?possible_choices ! i)))))"
  proof -
    fix i assume "i < length ?assn"
    let ?q = "(fst (?assn ! i))"
    have "(fst (?possible_choices ! i)) = ?q" using p2a \<open>i < length ?assn\<close> by auto
    
    have "snd (?assn ! i) = f ?q"
      using \<open>i < length ?assn\<close> by auto 
    have "snd (?possible_choices ! i) = filter (\<lambda>x . \<exists> t \<in> h ?CSep . t_source t = ?q \<and> t_input t = x) (inputs ?CSep)"
       using \<open>i < length ?assn\<close> p2a by auto 
    
     show "((snd (?assn ! i)) = None \<or> ((snd (?assn ! i)) \<noteq> None \<and> the (snd (?assn ! i)) \<in> set (snd (?possible_choices ! i))))" 
     proof (cases "?q \<in> nodes ?S")
      case True
      then show ?thesis proof (cases "deadlock_state ?S ?q")
        case True
        then have "f ?q = None" using f_def \<open>?q \<in> nodes ?S\<close> by blast
        then have "snd (?assn ! i) = None" using \<open>snd (?assn ! i) = f ?q\<close> by auto
        then show ?thesis by blast
      next
        case False
        then obtain x where "\<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x"
          by (metis (no_types, lifting) deadlock_state.elims(3))
        then have "\<exists>! x . \<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x"
          using \<open>single_input ?S\<close> unfolding single_input.simps
          by (metis (mono_tags, lifting)) 
        then have "(THE x .  \<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x) = x"
          using the1_equality[of "\<lambda> x . \<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x"] \<open>\<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x\<close> by blast
        moreover have "f ?q = Some (THE x .  \<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x)"
          using False \<open>?q \<in> nodes ?S\<close> f_def by blast
        ultimately have *: "f ?q = Some x" 
          by auto

        have "h ?S \<subseteq> h ?CSep" using \<open>is_submachine ?S ?CSep\<close> by auto
        then have "\<exists> t \<in> h ?CSep . t_source t = ?q \<and> t_input t = x"
          using \<open>\<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x\<close> by blast
        moreover have "x \<in> set (inputs ?CSep)"
          using \<open>\<exists>t\<in>h ?S. t_source t = ?q \<and> t_input t = x\<close> \<open>is_submachine ?S ?CSep\<close> by auto
        ultimately have **: "x \<in> set (filter (\<lambda>x . \<exists> t \<in> h ?CSep . t_source t = ?q \<and> t_input t = x) (inputs ?CSep))"
          by auto

        have "the (snd (?assn ! i)) \<in> set (snd (?possible_choices ! i))"
          using * ** \<open>snd (?possible_choices ! i) = filter (\<lambda>x . \<exists> t \<in> h ?CSep . t_source t = ?q \<and> t_input t = x) (inputs ?CSep)\<close> \<open>snd (?assn ! i) = f ?q\<close> by fastforce 

        then show ?thesis by auto
      qed
    next
      case False
      then have "snd (?assn ! i) = None" using \<open>snd (?assn ! i) = f ?q\<close> f_def by auto
      then show ?thesis by auto
    qed
  qed

  then have "?assn \<in> set (generate_choices ?possible_choices)"    
    using generate_choices_idx[of ?assn ?possible_choices] by auto

  have "set (transitions ?S) = set ?filtered_transitions"
  proof -
    have "\<And> t . t \<in> set (transitions ?S) \<Longrightarrow> t \<in> set (?filtered_transitions)"
    proof -
      fix t assume "t \<in> set (transitions ?S)"
      then have "t \<in> set (wf_transitions ?CSep)"
        by (metis (no_types, hide_lams) \<open>is_submachine (trim_transitions S) (canonical_separator M q1 q2)\<close> contra_subsetD submachine_h trim_transitions_transitions)
        

      have "t \<in> h ?S"
        using trim_transitions_transitions \<open>t \<in> set (transitions ?S)\<close> by auto

      have "t_source t \<in> nodes ?S"
        using trim_transitions_t_source[OF \<open>t \<in> set (transitions ?S)\<close>] by assumption
      have "\<not> deadlock_state ?S (t_source t)"
        unfolding deadlock_state.simps using \<open>t \<in> h ?S\<close> by blast
      
      have the1: "\<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = t_input t"
        using \<open>t \<in> h ?S\<close> by blast
      then have the2: "\<exists>! x . \<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x"
        using \<open>single_input ?S\<close> unfolding single_input.simps by metis

      
      have "f (t_source t) = Some (t_input t)"
        using f_def \<open>t_source t \<in> nodes ?S\<close> \<open>\<not> deadlock_state ?S (t_source t)\<close> the1_equality[OF the2 the1] by fastforce 
      moreover have "t_source t \<in> nodes ?CSep"
        using \<open>t_source t \<in> nodes ?S\<close> submachine_nodes[OF \<open>is_submachine ?S ?CSep\<close>] by blast
      ultimately have "(t_source t, Some (t_input t)) \<in> set (map (\<lambda>q. (q, f q)) (nodes_from_distinct_paths ?CSep))"
        using nodes_code[of ?CSep] by fastforce
      
      then show "t \<in> set (?filtered_transitions)"
        using filter_list_set[OF \<open>t \<in> set (wf_transitions ?CSep)\<close>, of "(\<lambda> t . (t_source t, Some (t_input t)) \<in> set (map (\<lambda>q. (q, f q)) (nodes_from_distinct_paths ?CSep)))"] by blast
    qed

    moreover have "\<And> t . t \<in> set (?filtered_transitions) \<Longrightarrow> t \<in> set (transitions ?S)"
    proof -
      fix t assume a: "t\<in>set (?filtered_transitions)"
      then have "t \<in> set (wf_transitions ?CSep)" 
            and "(t_source t, Some (t_input t))
                        \<in> set (map (\<lambda>q. (q, f q)) (nodes_from_distinct_paths ?CSep))"
        by auto
      then have "f (t_source t) = Some (t_input t)" by auto 
      then have "f (t_source t) \<noteq> None" by auto
      moreover have "t_source t \<in> nodes ?S"
        using calculation f_def by auto
      moreover have "\<not>deadlock_state ?S (t_source t)"
      proof -
        show ?thesis
          by (meson calculation(1) f_def)
      qed
      ultimately have "f (t_source t) = Some (THE x. \<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x)"
        using f_def by auto
      then have "t_input t = (THE x. \<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x)"
        using \<open>f (t_source t) = Some (t_input t)\<close> by auto


      have "\<exists> x . \<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x"
        using \<open>\<not>deadlock_state ?S (t_source t)\<close> unfolding deadlock_state.simps
        using \<open>t_source t \<in> nodes (trim_transitions S)\<close> by blast 

      then obtain x where the1: \<open>\<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x\<close> by blast
      then have the2: "\<exists>! x . \<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x"
        using \<open>single_input ?S\<close> unfolding single_input.simps by metis

      have "x = t_input t"
        using \<open>t_input t = (THE x. \<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = x)\<close> the1_equality[OF the2 the1] by auto
      then have "(\<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = t_input t)"
        using the1 by blast

      have "t_input t \<in> set (inputs ?CSep)"
        using \<open>t \<in> set (wf_transitions ?CSep)\<close> by auto
      
      have "(\<forall>t'\<in>h ?CSep. t_source t' = t_source t \<and> t_input t' = t_input t \<longrightarrow> t' \<in> h ?S)"
        using \<open>is_state_separator_from_canonical_separator ?CSep q1 q2 ?S\<close> unfolding is_state_separator_from_canonical_separator_def
        using \<open>t_source t \<in> nodes ?S\<close>
              \<open>t_input t \<in> set (inputs ?CSep)\<close>
              \<open>\<exists>t'\<in>h ?S. t_source t' = t_source t \<and> t_input t' = t_input t\<close> by blast
      then have "t \<in> h ?S"
        using \<open>t \<in> set (wf_transitions ?CSep)\<close> by blast
      then show "t \<in> set (transitions ?S)"
        using trim_transitions_transitions[of S] by blast
    qed

    ultimately show ?thesis by blast
  qed

  moreover have "set (transitions ?S') = set (?filtered_transitions)" 
    unfolding generate_submachine_from_assignment.simps by fastforce
  ultimately have "set (transitions ?S') = set (transitions ?S)"
    by blast

  have "initial ?S' = initial ?S \<and> inputs ?S' = inputs ?S \<and> outputs ?S' = outputs ?S"
    using \<open>is_submachine ?S ?CSep\<close> by auto
  then have "is_state_separator_from_canonical_separator ?CSep q1 q2 ?S'"
    using transition_reorder_is_state_separator_from_canonical_separator[OF \<open>is_state_separator_from_canonical_separator ?CSep q1 q2 ?S\<close> _ _ _ \<open>set (transitions ?S') = set (transitions ?S)\<close>] by metis
  moreover have "?S' \<in> set (map (\<lambda> assn . generate_submachine_from_assignment ?CSep assn) (generate_choices ?possible_choices))"
    using generate_submachine_for_contained_assn[OF \<open>?assn \<in> set (generate_choices ?possible_choices)\<close>] by assumption
  ultimately have "calculate_state_separator_from_canonical_separator_naive M q1 q2 \<noteq> None"
    unfolding calculate_state_separator_from_canonical_separator_naive.simps
    using find_None_iff[of "(is_state_separator_from_canonical_separator ?CSep q1 q2)" "(map (generate_submachine_from_assignment ?CSep) (generate_choices ?possible_choices))"]
    by meson
  then show "\<exists> S' . calculate_state_separator_from_canonical_separator_naive M q1 q2 = Some S'"
    by blast
qed

lemma calculate_state_separator_from_canonical_separator_naive_ex :
  "(\<exists>S. is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S) 
    = (\<exists> S' . calculate_state_separator_from_canonical_separator_naive M q1 q2 = Some S')"
  using calculate_state_separator_from_canonical_separator_naive_soundness
        calculate_state_separator_from_canonical_separator_naive_exhaustiveness
  by metis


value[code] "image (\<lambda> qq . (qq, (case calculate_state_separator_from_canonical_separator_naive M_ex_9 (fst qq) (snd qq) of None \<Rightarrow> None | Some wt \<Rightarrow> Some (transitions wt)))) {qq \<in> {(q1,q2) | q1 q2 . q1 \<in> nodes M_ex_H \<and> q2 \<in> nodes M_ex_H} . fst qq < snd qq}"
value[code] "image (\<lambda> qq . (qq, (case calculate_state_separator_from_canonical_separator_naive M_ex_9 (fst qq) (snd qq) of None \<Rightarrow> None | Some wt \<Rightarrow> Some (transitions wt)))) {qq \<in> {(q1,q2) | q1 q2 . q1 \<in> nodes M_ex_9 \<and> q2 \<in> nodes M_ex_9} . fst qq < snd qq}"





subsection \<open>State Separators and R-Distinguishability\<close>


lemma state_separator_r_distinguishes_k :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
  shows "\<exists> k . r_distinguishable_k M q1 q2 k"
proof -
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"
  let ?C = "(canonical_separator M q1 q2)"
  
  have "is_submachine S ?C"
        and "single_input S"
        and "acyclic S"
        and "deadlock_state S (Inr q1)"
        and "deadlock_state S (Inr q2)"
        and "Inr q1 \<in> nodes S"
        and "Inr q2 \<in> nodes S"
        and "(\<forall>q\<in>nodes S. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state S q)"
        and tc: "(\<forall>q\<in>nodes S.
              \<forall>x\<in>set (inputs ?C).
                 (\<exists>t\<in>h S. t_source t = q \<and> t_input t = x) \<longrightarrow>
                 (\<forall>t'\<in>h ?C. t_source t' = q \<and> t_input t' = x \<longrightarrow> t' \<in> h S))"
    using assms(1) unfolding is_state_separator_from_canonical_separator_def by linarith+

  let ?Prop = "(\<lambda> q . case q of 
                    (Inl (q1',q2')) \<Rightarrow> (\<exists> k . r_distinguishable_k M q1' q2' k) |
                    (Inr qr) \<Rightarrow> True)"
  have rprop: "\<forall> q \<in> nodes S . ?Prop q"
  using \<open>acyclic S\<close> proof (induction rule: acyclic_induction)
  case (node q)
    then show ?case proof (cases "\<not> isl q")
      case True
      then have "q = Inr q1 \<or> q = Inr q2"
        using \<open>(\<forall>q\<in>nodes S. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state S q)\<close> node(1) by blast
      then show ?thesis by auto
    next
      case False
      then obtain q1' q2' where "q = Inl (q1',q2')" 
        using isl_def prod.collapse by metis
      then have "\<not> deadlock_state S q"
        using \<open>(\<forall>q\<in>nodes S. q \<noteq> Inr q1 \<and> q \<noteq> Inr q2 \<longrightarrow> isl q \<and> \<not> deadlock_state S q)\<close> node(1) by blast

      then obtain t where "t \<in> h S" and "t_source t = q"
        unfolding deadlock_state.simps by blast
      then have "(\<forall>t'\<in>h ?C. t_source t' = q \<and> t_input t' = t_input t \<longrightarrow> t' \<in> h S)"
        using node(1) tc by (metis wf_transition_simp) 


      have "Inl (q1',q2') \<in> nodes ?C"
        using node(1) \<open>q = Inl (q1',q2')\<close> submachine_nodes[OF \<open>is_submachine S ?C\<close>] by auto
      then obtain p where "path ?C (initial ?C) p"
                      and "target p (initial ?C) = Inl (q1',q2')"
        by (metis path_to_node)
      then have "isl (target p (initial ?C))" by auto
      then obtain p' where "path ?P (initial ?P) p'"
                       and "p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'"
        using canonical_separator_path_from_shift[OF \<open>path ?C (initial ?C) p\<close>] by blast


      have "path (from_FSM M q1) (initial (from_FSM M q1)) (left_path p')"
          and "path (from_FSM M q2) (initial (from_FSM M q2)) (right_path p')"
        using product_path[of "from_FSM M q1" "from_FSM M q2" q1 q2 p'] \<open>path ?P (initial ?P) p'\<close> by auto
      moreover have "target (left_path p') (initial (from_FSM M q1)) = q1'"
        using \<open>p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'\<close> \<open>target p (initial ?C) = Inl (q1',q2')\<close> canonical_separator_simps(1)[of M q1 q2] 
        unfolding target.simps visited_states.simps by (cases p' rule: rev_cases; auto)
      moreover have "target (right_path p') (initial (from_FSM M q2)) = q2'"
        using \<open>p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'\<close> \<open>target p (initial ?C) = Inl (q1',q2')\<close> canonical_separator_simps(1)[of M q1 q2] 
        unfolding target.simps visited_states.simps by (cases p' rule: rev_cases; auto)
      moreover have "p_io (left_path p') = p_io (right_path p')" by auto
      ultimately have p12' : "\<exists>p1 p2.
               path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
               path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
               target p1 (initial (from_FSM M q1)) = q1' \<and>
               target p2 (initial (from_FSM M q2)) = q2' \<and> p_io p1 = p_io p2"
        by blast

      have "q1' \<in> nodes (from_FSM M q1)"
        using path_target_is_node[OF \<open>path (from_FSM M q1) (initial (from_FSM M q1)) (left_path p')\<close>] \<open>target (left_path p') (initial (from_FSM M q1)) = q1'\<close> by auto
      have "q2' \<in> nodes (from_FSM M q2)"
        using path_target_is_node[OF \<open>path (from_FSM M q2) (initial (from_FSM M q2)) (right_path p')\<close>] \<open>target (right_path p') (initial (from_FSM M q2)) = q2'\<close> by auto

      have "t_input t \<in> set (inputs S)"
        using \<open>t \<in> h S\<close> by auto
      then have "t_input t \<in> set (inputs ?C)"
        using \<open>is_submachine S ?C\<close> by auto
      then have "t_input t \<in> set (inputs M)"
        using canonical_separator_simps(2) by metis

      have *: "\<And> t1 t2 . t1 \<in> h M \<Longrightarrow> t2 \<in> h M \<Longrightarrow> t_source t1 = q1' \<Longrightarrow> t_source t2 = q2' \<Longrightarrow> t_input t1 = t_input t \<Longrightarrow> t_input t2 = t_input t \<Longrightarrow> t_output t1 = t_output t2 \<Longrightarrow> (\<exists> k . r_distinguishable_k M (t_target t1) (t_target t2) k)"
      proof -
        fix t1 t2 assume "t1 \<in> h M" 
                     and "t2 \<in> h M" 
                     and "t_source t1 = q1'" 
                     and "t_source t2 = q2'" 
                     and "t_input t1 = t_input t" 
                     and "t_input t2 = t_input t" 
                     and "t_output t1 = t_output t2"
        then have "t_input t1 = t_input t2" by auto

        have "t1 \<in> h (from_FSM M q1)" 
          using \<open>t_source t1 = q1'\<close> \<open>q1' \<in> nodes (from_FSM M q1)\<close> \<open>t1 \<in> h M\<close> by auto
        have "t2 \<in> h (from_FSM M q2)"
          using \<open>t_source t2 = q2'\<close> \<open>q2' \<in> nodes (from_FSM M q2)\<close> \<open>t2 \<in> h M\<close> by auto

        let ?t = "((t_source t1, t_source t2), t_input t1, t_output t1, t_target t1, t_target t2)"

        have "\<exists>p1 p2.
               path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
               path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
               target p1 (initial (from_FSM M q1)) = t_source t1 \<and>
               target p2 (initial (from_FSM M q2)) = t_source t2 \<and> p_io p1 = p_io p2"
          using p12' \<open>t_source t1 = q1'\<close> \<open>t_source t2 = q2'\<close> by auto
        
        then have "?t \<in> h ?P"
          using product_transition_from_transitions[OF \<open>t1 \<in> h (from_FSM M q1)\<close> \<open>t2 \<in> h (from_FSM M q2)\<close> \<open>t_input t1 = t_input t2\<close> \<open>t_output t1 = t_output t2\<close>] by presburger

        then have "shift_Inl ?t \<in> h ?C"
          using canonical_separator_h_from_product[of _ M q1 q2] by blast
        moreover have "t_source (shift_Inl ?t) = q"
          using \<open>t_source t1 = q1'\<close> \<open>t_source t2 = q2'\<close> \<open>q = Inl (q1',q2')\<close> by auto
        ultimately have "shift_Inl ?t \<in> h S"
          using \<open>(\<forall>t'\<in>h ?C. t_source t' = q \<and> t_input t' = t_input t \<longrightarrow> t' \<in> h S)\<close> \<open>t_input t1 = t_input t\<close> by auto

        
        have "case t_target (shift_Inl ?t) of Inl (q1', q2') \<Rightarrow> \<exists>k. r_distinguishable_k M q1' q2' k | Inr qr \<Rightarrow> True"
          using node.IH(2)[OF \<open>shift_Inl ?t \<in> h S\<close> \<open>t_source (shift_Inl ?t) = q\<close>] by (cases q; auto)
        moreover have "t_target (shift_Inl ?t) = Inl (t_target t1, t_target t2)" 
          by auto
        ultimately show "\<exists>k. r_distinguishable_k M (t_target t1) (t_target t2) k"
          by auto
      qed

      (* TODO: extract *)

      let ?hs = "{(t1,t2) | t1 t2 . t1 \<in> h M \<and> t2 \<in> h M \<and> t_source t1 = q1' \<and> t_source t2 = q2' \<and> t_input t1 = t_input t \<and> t_input t2 = t_input t \<and> t_output t1 = t_output t2}"
      have "finite ?hs"
      proof -
        have "?hs \<subseteq> (h M \<times> h M)" by blast
        moreover have "finite (h M \<times> h M)" by blast
        ultimately show ?thesis
          by (simp add: finite_subset) 
      qed
      obtain fk where fk_def : "\<And> tt . tt \<in> ?hs \<Longrightarrow> r_distinguishable_k M (t_target (fst tt)) (t_target (snd tt)) (fk tt)"
      proof 
        let ?fk = "\<lambda> tt . SOME k . r_distinguishable_k M (t_target (fst tt)) (t_target (snd tt)) k"
        show "\<And> tt . tt \<in> ?hs \<Longrightarrow> r_distinguishable_k M (t_target (fst tt)) (t_target (snd tt)) (?fk tt)"
        proof -
          fix tt assume "tt \<in> ?hs"
          then have "(fst tt) \<in> h M \<and> (snd tt) \<in> h M \<and> t_source (fst tt) = q1' \<and> t_source (snd tt) = q2' \<and> t_input (fst tt) = t_input t \<and> t_input (snd tt) = t_input t \<and> t_output (fst tt) = t_output (snd tt)"
            by force 
          then have "\<exists> k . r_distinguishable_k M (t_target (fst tt)) (t_target (snd tt)) k"
            using * by blast
          then show "r_distinguishable_k M (t_target (fst tt)) (t_target (snd tt)) (?fk tt)"
            by (simp add: someI_ex)
        qed
      qed

      let ?k = "Max (image fk ?hs)"
      have "\<And> t1 t2 . t1 \<in> h M \<Longrightarrow> t2 \<in> h M \<Longrightarrow> t_source t1 = q1' \<Longrightarrow> t_source t2 = q2' \<Longrightarrow> t_input t1 = t_input t \<Longrightarrow> t_input t2 = t_input t \<Longrightarrow> t_output t1 = t_output t2 \<Longrightarrow> r_distinguishable_k M (t_target t1) (t_target t2) ?k"
      proof -
        fix t1 t2 assume "t1 \<in> h M" 
                     and "t2 \<in> h M" 
                     and "t_source t1 = q1'" 
                     and "t_source t2 = q2'" 
                     and "t_input t1 = t_input t" 
                     and "t_input t2 = t_input t" 
                     and "t_output t1 = t_output t2"   
        then have "(t1,t2) \<in> ?hs"
          by force
        then have "r_distinguishable_k M (t_target t1) (t_target t2) (fk (t1,t2))"
          using fk_def by force
        have "fk (t1,t2) \<le> ?k"
          using \<open>(t1,t2) \<in> ?hs\<close> \<open>finite ?hs\<close> by auto
        show "r_distinguishable_k M (t_target t1) (t_target t2) ?k" 
          using r_distinguishable_k_by_larger[OF \<open>r_distinguishable_k M (t_target t1) (t_target t2) (fk (t1,t2))\<close> \<open>fk (t1,t2) \<le> ?k\<close>] by assumption
      qed


      then have "r_distinguishable_k M q1' q2' (Suc ?k)"
        unfolding r_distinguishable_k.simps 
        using \<open>t_input t \<in> set (inputs M)\<close> by blast
      then show "?Prop q"
        using \<open>q = Inl (q1',q2')\<close>
        by (metis (no_types, lifting) case_prodI old.sum.simps(5)) 
    qed
  qed

          


  moreover have "Inl (q1,q2) \<in> nodes S" 
    using \<open>is_submachine S ?C\<close> canonical_separator_simps(1)[of M q1 q2] nodes.initial[of S] by auto
  ultimately show "\<exists>k. r_distinguishable_k M q1 q2 k"
    by auto 
qed




    






subsection \<open>State Separation Sets\<close>

(* TODO: move *)
definition fault_domain :: "('a,'b) FSM_scheme \<Rightarrow> nat \<Rightarrow> ('a,'b) FSM_scheme set" where
  "fault_domain M m = { M' . inputs M' = inputs M \<and> outputs M' = outputs M \<and> size M' \<le> size M + m \<and> observable M' \<and> completely_specified M'}"

(* TODO: relax completely_specified M' to the easier requirement that the LSin on M' are non-empty? *)
(*definition is_state_separation_set :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> Input list set \<Rightarrow> bool" where
  "is_state_separation_set M q1 q2 S = (
    finite S
    \<and> (\<forall> s \<in> S . set s \<subseteq> set (inputs M))
    \<and> (\<forall> M'::('a,'b) FSM_scheme . ((\<forall> s \<in> S . set s \<subseteq> set (inputs M')) \<and> completely_specified M') \<longrightarrow> (*(inputs M' = inputs M \<and> outputs M' = outputs M \<and> completely_specified M') \<longrightarrow> *)
        (\<forall> q1' \<in> nodes M' . \<forall> q2' \<in> nodes M' .  ((LS\<^sub>i\<^sub>n M' q1' S \<subseteq> LS\<^sub>i\<^sub>n M q1 S) \<and> (LS\<^sub>i\<^sub>n M' q2' S \<subseteq> LS\<^sub>i\<^sub>n M q2 S)) \<longrightarrow> q1' \<noteq> q2'))
  )"
*)
(* TODO: LSin is incorrect, as it ignores adaptivity *)
(*
definition is_state_separation_set :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> Input list set \<Rightarrow> bool" where
  "is_state_separation_set M q1 q2 S = (
    finite S
    \<and> (\<forall> M'::('a,'b) FSM_scheme . 
        (\<forall> q1' \<in> nodes M' . \<forall> q2' \<in> nodes M' .  ((LS\<^sub>i\<^sub>n M' q1' S \<noteq> {}) \<and> (LS\<^sub>i\<^sub>n M' q2' S \<noteq> {}) \<and> (LS\<^sub>i\<^sub>n M' q1' S \<subseteq> LS\<^sub>i\<^sub>n M q1 S) \<and> (LS\<^sub>i\<^sub>n M' q2' S \<subseteq> LS\<^sub>i\<^sub>n M q2 S)) \<longrightarrow> q1' \<noteq> q2'))
  )"
*)

definition is_state_separation_set :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (Input \<times> Output) list set \<Rightarrow> bool" where
  "is_state_separation_set M q1 q2 S = (
    finite S
    \<and> ((LS M q1 \<inter> S) \<inter> (LS M q2 \<inter> S) = {})
    \<and> (\<forall> M'::('a,'b) FSM_scheme . 
        (\<forall> q1' \<in> nodes M' . \<forall> q2' \<in> nodes M' .  (((LS M' q1' \<inter> S \<noteq> {}) \<or> (LS M' q2' \<inter> S \<noteq> {})) \<and> (LS M' q1' \<inter> S \<subseteq> LS M q1 \<inter> S) \<and> (LS M' q2' \<inter> S \<subseteq> LS M q2 \<inter> S)) \<longrightarrow> LS M' q1' \<noteq> LS M' q2'))
  )"


definition state_separation_set_from_state_separator :: "('a + 'b, 'c) FSM_scheme \<Rightarrow> (Input \<times> Output) list set" where
  (*"state_separation_set_from_state_separator S = {map t_input p | p .path S (initial S) p \<and> \<not> isl (target p (initial S)) }"*)
  "state_separation_set_from_state_separator S = {p_io p | p .path S (initial S) p \<and> \<not> isl (target p (initial S)) }"

(*
lemma state_separation_set_from_state_separator_inputs :
  "(\<forall> s \<in> state_separation_set_from_state_separator S . set s \<subseteq> set (inputs S))"
proof 
  fix s assume "s \<in> state_separation_set_from_state_separator S"
  then obtain p where "path S (initial S) p" and "s = map t_input p"
    unfolding state_separation_set_from_state_separator_def by blast
  have "set (map t_input p) \<subseteq> set (inputs S)"
    using \<open>path S (initial S) p\<close> by (induction p; auto)
  then show "set s \<subseteq> set (inputs S)"
    using \<open>s = map t_input p\<close> by auto
qed
*)

lemma state_separation_set_from_state_separator_finite :
  assumes "acyclic S"
  shows "finite (state_separation_set_from_state_separator S)"
  using acyclic_finite_paths[OF assms] unfolding state_separation_set_from_state_separator_def
  by simp 



(* TODO: move *)
lemma filter_map_elem : "t \<in> set (map g (filter f xs)) \<Longrightarrow> \<exists> x \<in> set xs . f x \<and> t = g x" by auto

(* TODO: move *)
lemma observable_path_language_step :
  assumes "observable M"
      and "path M q p"
      and "\<not> (\<exists>t\<in>h M.
               t_source t = target p q \<and>
               t_input t = x \<and> t_output t = y)"
    shows "(p_io p)@[(x,y)] \<notin> LS M q"
using assms proof (induction p rule: rev_induct)
  case Nil
  show ?case proof
    assume "p_io [] @ [(x, y)] \<in> LS M q"
    then obtain p' where "path M q p'" and "p_io p' = [(x,y)]" unfolding LS.simps
      by force 
    then obtain t where "p' = [t]" by blast
    
    have "t\<in>h M" and "t_source t = target [] q"
      using \<open>path M q p'\<close> \<open>p' = [t]\<close> by auto
    moreover have "t_input t = x \<and> t_output t = y"
      using \<open>p_io p' = [(x,y)]\<close> \<open>p' = [t]\<close> by auto
    ultimately show "False"
      using Nil.prems(3) by blast
  qed
next
  case (snoc t p)
  then have "path M q p" and "t_source t = target p q" and "t \<in> h M" by auto

  show ?case proof
    assume "p_io (p @ [t]) @ [(x, y)] \<in> LS M q"
    then obtain p' where "path M q p'" and "p_io p' = p_io (p @ [t]) @ [(x, y)]"
      by auto
    then obtain p'' t' t'' where "p' = p''@[t']@[t'']"
      by (metis (no_types, lifting) append.assoc map_butlast map_is_Nil_conv snoc_eq_iff_butlast)
    then have "path M q p''" 
      using \<open>path M q p'\<close> by blast
    
    
    have "p_io p'' = p_io p"
      using \<open>p' = p''@[t']@[t'']\<close> \<open>p_io p' = p_io (p @ [t]) @ [(x, y)]\<close> by auto
    then have "p'' = p"
      using observable_path_unique[OF assms(1) \<open>path M q p''\<close> \<open>path M q p\<close>] by blast

    have "t_source t' = target p'' q" and "t' \<in> h M"
      using \<open>path M q p'\<close> \<open>p' = p''@[t']@[t'']\<close> by auto
    then have "t_source t' = t_source t"
      using \<open>p'' = p\<close> \<open>t_source t = target p q\<close> by auto 
    moreover have "t_input t' = t_input t \<and> t_output t' = t_output t"
      using \<open>p_io p' = p_io (p @ [t]) @ [(x, y)]\<close> \<open>p' = p''@[t']@[t'']\<close> \<open>p'' = p\<close> by auto
    ultimately have "t' = t"
      using \<open>t \<in> h M\<close> \<open>t' \<in> h M\<close> assms(1) unfolding observable.simps by (meson prod.expand) 

    have "t''\<in>h M" and "t_source t'' = target (p@[t]) q"
      using \<open>path M q p'\<close> \<open>p' = p''@[t']@[t'']\<close> \<open>p'' = p\<close> \<open>t' = t\<close> by auto
    moreover have "t_input t'' = x \<and> t_output t'' = y"
      using \<open>p_io p' = p_io (p @ [t]) @ [(x, y)]\<close> \<open>p' = p''@[t']@[t'']\<close> by auto
    ultimately show "False"
      using snoc.prems(3) by blast
  qed
qed


lemma shifted_transitions_targets :
  assumes "t \<in> set (shifted_transitions M q1 q2)"
  shows "isl (t_target t)"
  using assms unfolding shifted_transitions_def
  by (metis (no_types, lifting) list_map_source_elem snd_conv sum.disc(1)) 

lemma distinguishing_transitions_left_sources_targets :
  assumes "t \<in> set (distinguishing_transitions_left M q1 q2)"
      and "q1 \<in> nodes M" and "q2 \<in> nodes M"
  shows "\<exists> q1' q2' t' . t_source t = Inl (q1',q2') \<and> q1' \<in> nodes M \<and> q2' \<in> nodes M \<and> t' \<in> h M \<and> t_source t' = q1' \<and> t_input t' = t_input t \<and> t_output t' = t_output t \<and> \<not> (\<exists>t''\<in>h M.
                             t_source t'' = q2' \<and>
                             t_input t'' = t_input t \<and> t_output t'' = t_output t)" 
    and "t_target t = Inr q1"
proof -
  obtain qqt where *: "qqt \<in> set (concat
                 (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                   (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
          and **: "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                      \<not> (\<exists>t'\<in>set (transitions M).
                             t_source t' = snd (fst qqt) \<and>
                             t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) qqt"
          and ***: "t = (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)) qqt" 
    using filter_map_elem[of t "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))"
                               "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                                        \<not> (\<exists>t'\<in>set (transitions M).
                                               t_source t' = snd (fst qqt) \<and>
                                                t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))"
                               "(concat
                                   (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"] 
    using assms unfolding distinguishing_transitions_left_def by blast

  obtain qq where "qq \<in> set (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))"
                  "qqt \<in> set (map (Pair qq) (wf_transitions M))"
    using concat_map_elem[OF *] by blast

  have "qq = fst qqt" and "snd qqt \<in> h M"
    using \<open>qqt \<in> set (map (Pair qq) (wf_transitions M))\<close>  by auto

  then have "t_source t = Inl (fst qq, snd qq)"
   and "t_input (snd qqt) = t_input t"
   and "t_output (snd qqt) = t_output t"
   and "t_target t = Inr q1"
    using *** by auto


  have "qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
    using \<open>qq \<in> set (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))\<close> nodes_code[of "product (from_FSM M q1) (from_FSM M q2)"] by blast
  
  have "fst qq \<in> nodes (from_FSM M q1)"
    by (metis (no_types) \<open>qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))\<close> mem_Sigma_iff prod.exhaust_sel product_nodes subsetCE)
  then have "fst qq \<in> nodes M"
    using from_FSM_nodes[OF assms(2)] by blast

  have "snd qq \<in> nodes (from_FSM M q2)"
    by (metis (no_types) \<open>qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))\<close> mem_Sigma_iff prod.exhaust_sel product_nodes subsetCE)
  then have "snd qq \<in> nodes M"
    using from_FSM_nodes[OF assms(3)] by blast

  have "\<not> (\<exists>t'\<in>h M.
             t_source t' = snd qq \<and>
             t_input t' = t_input t \<and> t_output t' = t_output t)"
    using ** \<open>qq = fst qqt\<close> \<open>t_input (snd qqt) = t_input t\<close> \<open>t_output (snd qqt) = t_output t\<close> by auto

  then show "\<exists> q1' q2' t' . t_source t = Inl (q1',q2') \<and> q1' \<in> nodes M \<and> q2' \<in> nodes M \<and> t' \<in> h M \<and> t_source t' = q1' \<and> t_input t' = t_input t \<and> t_output t' = t_output t \<and> \<not> (\<exists>t'\<in>h M.
                             t_source t' = q2' \<and>
                             t_input t' = t_input t \<and> t_output t' = t_output t)"
    using \<open>t_source t = Inl (fst qq, snd qq)\<close> \<open>fst qq \<in> nodes M\<close> \<open>snd qq \<in> nodes M\<close> \<open>snd qqt \<in> h M\<close> ** \<open>qq = fst qqt\<close> \<open>t_input (snd qqt) = t_input t\<close> \<open>t_output (snd qqt) = t_output t\<close> by blast 
  
  show "t_target t = Inr q1"
    using \<open>t_target t = Inr q1\<close> by assumption
qed

lemma distinguishing_transitions_right_sources_targets :
  assumes "t \<in> set (distinguishing_transitions_right M q1 q2)"
      and "q1 \<in> nodes M" and "q2 \<in> nodes M"
  shows "\<exists> q1' q2' t' . t_source t = Inl (q1',q2') \<and> q1' \<in> nodes M \<and> q2' \<in> nodes M \<and> t' \<in> h M \<and> t_source t' = q2' \<and> t_input t' = t_input t \<and> t_output t' = t_output t \<and> \<not> (\<exists>t''\<in>h M.
                             t_source t'' = q1' \<and>
                             t_input t'' = t_input t \<and> t_output t'' = t_output t)" 
    and "t_target t = Inr q2"
proof -
  obtain qqt where *: "qqt \<in> set (concat
                 (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                   (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
          and **: "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                      \<not> (\<exists>t'\<in>set (transitions M).
                             t_source t' = fst (fst qqt) \<and>
                             t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) qqt"
          and ***: "t = (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)) qqt" 
    using filter_map_elem[of t "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2))"
                               "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                                        \<not> (\<exists>t'\<in>set (transitions M).
                                               t_source t' = fst (fst qqt) \<and>
                                                t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))"
                               "(concat
                                   (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"] 
    using assms(1) unfolding distinguishing_transitions_right_def by blast

  obtain qq where "qq \<in> set (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))"
                  "qqt \<in> set (map (Pair qq) (wf_transitions M))"
    using concat_map_elem[OF *] by blast

  have "qq = fst qqt" and "snd qqt \<in> h M"
    using \<open>qqt \<in> set (map (Pair qq) (wf_transitions M))\<close>  by auto

  then have "t_source t = Inl (fst qq, snd qq)"
   and "t_input (snd qqt) = t_input t"
   and "t_output (snd qqt) = t_output t"
   and "t_target t = Inr q2"
    using *** by auto


  have "qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
    using \<open>qq \<in> set (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))\<close> nodes_code[of "product (from_FSM M q1) (from_FSM M q2)"] by blast
  
  have "fst qq \<in> nodes (from_FSM M q1)"
    by (metis (no_types) \<open>qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))\<close> mem_Sigma_iff prod.exhaust_sel product_nodes subsetCE)
  then have "fst qq \<in> nodes M"
    using from_FSM_nodes[OF assms(2)] by blast

  have "snd qq \<in> nodes (from_FSM M q2)"
    by (metis (no_types) \<open>qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))\<close> mem_Sigma_iff prod.exhaust_sel product_nodes subsetCE)
  then have "snd qq \<in> nodes M"
    using from_FSM_nodes[OF assms(3)] by blast

  have "\<not> (\<exists>t'\<in>h M.
             t_source t' = fst qq \<and>
             t_input t' = t_input t \<and> t_output t' = t_output t)"
    using ** \<open>qq = fst qqt\<close> \<open>t_input (snd qqt) = t_input t\<close> \<open>t_output (snd qqt) = t_output t\<close> by auto

  then show "\<exists> q1' q2' t' . t_source t = Inl (q1',q2') \<and> q1' \<in> nodes M \<and> q2' \<in> nodes M \<and> t' \<in> h M \<and> t_source t' = q2' \<and> t_input t' = t_input t \<and> t_output t' = t_output t \<and> \<not> (\<exists>t'\<in>h M.
                             t_source t' = q1' \<and>
                             t_input t' = t_input t \<and> t_output t' = t_output t)"
    using \<open>t_source t = Inl (fst qq, snd qq)\<close> \<open>fst qq \<in> nodes M\<close> \<open>snd qq \<in> nodes M\<close> \<open>snd qqt \<in> h M\<close> ** \<open>qq = fst qqt\<close> \<open>t_input (snd qqt) = t_input t\<close> \<open>t_output (snd qqt) = t_output t\<close> by blast 
  
  show "t_target t = Inr q2"
    using \<open>t_target t = Inr q2\<close> by assumption
qed


lemma canonical_separator_targets :
  assumes "t \<in> h (canonical_separator M q1 q2)" 
      and "q1 \<in> nodes M" and "q2 \<in> nodes M" and "q1 \<noteq> q2"
  shows "isl (t_target t) \<Longrightarrow> t \<in> set (shifted_transitions M q1 q2)"
    and "t_target t = Inr q1 \<Longrightarrow> t \<in> set (distinguishing_transitions_left M q1 q2)"
    and "t_target t = Inr q2 \<Longrightarrow> t \<in> set (distinguishing_transitions_right M q1 q2)"
proof -
  let ?C = "(canonical_separator M q1 q2)"
  have *: "set (transitions ?C) = (set (shifted_transitions M q1 q2)) \<union> (set (distinguishing_transitions_left M q1 q2)) \<union> (set (distinguishing_transitions_right M q1 q2))"
    using canonical_separator_simps(4)[of M q1 q2] by auto

  
  
  show "isl (t_target t) \<Longrightarrow> t \<in> set (shifted_transitions M q1 q2)"
    using shifted_transitions_targets[of t M q1 q2] 
          distinguishing_transitions_left_sources_targets(2)[OF _ assms(2,3), of t]
          distinguishing_transitions_right_sources_targets(2)[OF _ assms(2,3), of t]
    using * assms(1) by force

  show "t_target t = Inr q1 \<Longrightarrow> t \<in> set (distinguishing_transitions_left M q1 q2)"
    using shifted_transitions_targets[of t M q1 q2] 
          distinguishing_transitions_left_sources_targets(2)[OF _ assms(2,3), of t]
          distinguishing_transitions_right_sources_targets(2)[OF _ assms(2,3), of t]
    using "*" assms(1) assms(4) by auto

  show "t_target t = Inr q2 \<Longrightarrow> t \<in> set (distinguishing_transitions_right M q1 q2)"
    using shifted_transitions_targets[of t M q1 q2] 
          distinguishing_transitions_left_sources_targets(2)[OF _ assms(2,3), of t]
          distinguishing_transitions_right_sources_targets(2)[OF _ assms(2,3), of t]
    using "*" assms(1) assms(4) by auto
qed
    
  


lemma canonical_separator_maximal_path_distinguishes_left :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S" (is "is_state_separator_from_canonical_separator ?C q1 q2 S")
      and "path S (initial S) p"
      and "target p (initial S) = Inr q1"  
      and "observable M"
      and "q1 \<in> nodes M" and "q2 \<in> nodes M" and "q1 \<noteq> q2"
shows "p_io p \<in> LS M q1 - LS M q2"
proof (cases p rule: rev_cases)
  case Nil
  then have "initial S = Inr q1" using assms(3) by auto
  then have "initial ?C = Inr q1" using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] is_submachine.simps[of S ?C] canonical_separator_simps(1)[of M q1 q2] by metis
  then show ?thesis using canonical_separator_simps(1) Inr_Inl_False by metis
next
  case (snoc p' t) 
  then have "path S (initial S) (p'@[t])"
    using assms(2) by auto
  then have "t \<in> h S" and "t_source t = target p' (initial S)" by auto


  have "path ?C (initial ?C) (p'@[t])"
    using \<open>path S (initial S) (p'@[t])\<close> assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] by (meson submachine_path_initial)
  then have "path ?C (initial ?C) (p')" and "t \<in> h ?C"
    by auto

  have "isl (target p' (initial S))"
  proof (rule ccontr)
    assume "\<not> isl (target p' (initial S))"
    moreover have "target p' (initial S) \<in> nodes S"
      using \<open>path S (initial S) (p'@[t])\<close> by auto
    ultimately have "target p' (initial S) = Inr q1 \<or> target p' (initial S) = Inr q2"
      using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] by blast 
    moreover have "deadlock_state S (Inr q1)" and "deadlock_state S (Inr q2)"
      using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] by presburger+
    ultimately show "False" 
      using \<open>t \<in> h S\<close> \<open>t_source t = target p' (initial S)\<close> unfolding deadlock_state.simps
      by metis 
  qed
  then obtain q1' q2' where "target p' (initial S) = Inl (q1',q2')" using isl_def prod.collapse by metis
  then have "isl (target p' (initial ?C))"
     using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S]
     by (metis (no_types, lifting) Nil_is_append_conv assms(2) isl_def list.distinct(1) list.sel(1) path.cases snoc submachine_path_initial) 

  

  obtain pC where "path (product (from_FSM M q1) (from_FSM M q2)) (initial (product (from_FSM M q1) (from_FSM M q2))) pC"
              and "p' = map shift_Inl pC"
    using canonical_separator_path_from_shift[OF \<open>path ?C (initial ?C) (p')\<close> \<open>isl (target p' (initial ?C))\<close>] by blast
  then have "path (product (from_FSM M q1) (from_FSM M q2)) (q1,q2) pC"
    by force

  then have "path (from_FSM M q1) q1 (left_path pC)" and "path (from_FSM M q2) q2 (right_path pC)"
    using product_path[of "from_FSM M q1" "from_FSM M q2" q1 q2 pC] by presburger+


  have "path M q1 (left_path pC)"
    using from_FSM_path[OF assms(5) \<open>path (from_FSM M q1) q1 (left_path pC)\<close>] by assumption
  have "path M q2 (right_path pC)"
    using from_FSM_path[OF assms(6) \<open>path (from_FSM M q2) q2 (right_path pC)\<close>] by assumption
  
  have "t_target t = Inr q1"
    using \<open>path S (initial S) (p'@[t])\<close> snoc assms(3) by auto
  then have "t \<in> set (distinguishing_transitions_left M q1 q2)"
    using canonical_separator_targets(2)[OF \<open>t \<in> h ?C\<close> assms(5,6,7)] by auto

  have "t_source t = Inl (q1',q2')"
    using \<open>target p' (initial S) = Inl (q1',q2')\<close> \<open>t_source t = target p' (initial S)\<close> by auto

  obtain t' where "q1' \<in> nodes M"
                        and "q2' \<in> nodes M"
                        and "t' \<in> h M"
                        and "t_input t' = t_input t"
                        and "t_output t' = t_output t"
                        and "t_source t' = q1'"
                        and "\<not> (\<exists>t''\<in>h M. t_source t'' = q2' \<and> t_input t'' = t_input t \<and> t_output t'' = t_output t)"
    using distinguishing_transitions_left_sources_targets(1)[OF \<open>t \<in> set (distinguishing_transitions_left M q1 q2)\<close> assms(5,6)]
          \<open>t_source t = Inl (q1',q2')\<close>
    by force 

  

  have "initial S = Inl (q1,q2)"
    using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] is_submachine.simps[of S ?C] canonical_separator_simps(1)[of M q1 q2]
    by (metis from_FSM_simps(1) product_simps(1))
  have "length p' = length pC"
    using \<open>p' = map shift_Inl pC\<close> by auto
  then have "target p' (initial S) = Inl (target pC (q1,q2))"
    using \<open>p' = map shift_Inl pC\<close> \<open>initial S = Inl (q1,q2)\<close> unfolding target.simps visited_states.simps by (induction p' pC rule: list_induct2; auto)
  then have "target pC (q1,q2) = (q1',q2')"
     using \<open>target p' (initial S) = Inl (q1',q2')\<close> by auto 
  then have "target (right_path pC) q2 = q2'"
    using product_target_split(2) by fastforce
  then have "\<not> (\<exists>t'\<in>h M. t_source t' = target (right_path pC) q2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
    using \<open>\<not> (\<exists>t'\<in>h M. t_source t' = q2' \<and> t_input t' = t_input t \<and> t_output t' = t_output t)\<close> by blast

  have "target (left_path pC) q1 = q1'"
    using \<open>target pC (q1,q2) = (q1',q2')\<close> product_target_split(1) by fastforce
  then have "path M q1 ((left_path pC)@[t'])"
    using \<open>path M q1 (left_path pC)\<close> \<open>t' \<in> h M\<close> \<open>t_source t' = q1'\<close>
    by (simp add: path_append_last) 
  then have "p_io ((left_path pC)@[t']) \<in> LS M q1" 
    unfolding LS.simps by force 
  moreover have "p_io p' = p_io (left_path pC)"
    using \<open>p' = map shift_Inl pC\<close> by auto
  ultimately have "p_io (p'@[t]) \<in> LS M q1"
    using \<open>t_input t' = t_input t\<close> \<open>t_output t' = t_output t\<close> by auto
    


  have "p_io (right_path pC) @  [(t_input t, t_output t)] \<notin> LS M q2"
    using observable_path_language_step[OF assms(4) \<open>path M q2 (right_path pC)\<close> \<open>\<not> (\<exists>t'\<in>h M. t_source t' = target (right_path pC) q2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)\<close>] by assumption
  moreover have "p_io p' = p_io (right_path pC)"
    using \<open>p' = map shift_Inl pC\<close> by auto
  ultimately have "p_io (p'@[t]) \<notin> LS M q2"
    by auto
  
  

  show ?thesis 
    using \<open>p_io (p'@[t]) \<in> LS M q1\<close> \<open>p_io (p'@[t]) \<notin> LS M q2\<close> snoc by blast
qed




lemma canonical_separator_maximal_path_distinguishes_right :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S" (is "is_state_separator_from_canonical_separator ?C q1 q2 S")
      and "path S (initial S) p"
      and "target p (initial S) = Inr q2"  
      and "observable M"
      and "q1 \<in> nodes M" and "q2 \<in> nodes M" and "q1 \<noteq> q2"
shows "p_io p \<in> LS M q2 - LS M q1"
proof (cases p rule: rev_cases)
  case Nil
  then have "initial S = Inr q2" using assms(3) by auto
  then have "initial ?C = Inr q2" using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] is_submachine.simps[of S ?C] canonical_separator_simps(1)[of M q1 q2] by metis
  then show ?thesis using canonical_separator_simps(1) Inr_Inl_False by metis
next
  case (snoc p' t) 
  then have "path S (initial S) (p'@[t])"
    using assms(2) by auto
  then have "t \<in> h S" and "t_source t = target p' (initial S)" by auto


  have "path ?C (initial ?C) (p'@[t])"
    using \<open>path S (initial S) (p'@[t])\<close> assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] by (meson submachine_path_initial)
  then have "path ?C (initial ?C) (p')" and "t \<in> h ?C"
    by auto

  have "isl (target p' (initial S))"
  proof (rule ccontr)
    assume "\<not> isl (target p' (initial S))"
    moreover have "target p' (initial S) \<in> nodes S"
      using \<open>path S (initial S) (p'@[t])\<close> by auto
    ultimately have "target p' (initial S) = Inr q1 \<or> target p' (initial S) = Inr q2"
      using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] by blast 
    moreover have "deadlock_state S (Inr q1)" and "deadlock_state S (Inr q2)"
      using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] by presburger+
    ultimately show "False" 
      using \<open>t \<in> h S\<close> \<open>t_source t = target p' (initial S)\<close> unfolding deadlock_state.simps
      by metis 
  qed
  then obtain q1' q2' where "target p' (initial S) = Inl (q1',q2')" using isl_def prod.collapse by metis
  then have "isl (target p' (initial ?C))"
     using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S]
     by (metis (no_types, lifting) Nil_is_append_conv assms(2) isl_def list.distinct(1) list.sel(1) path.cases snoc submachine_path_initial) 

  

  obtain pC where "path (product (from_FSM M q1) (from_FSM M q2)) (initial (product (from_FSM M q1) (from_FSM M q2))) pC"
              and "p' = map shift_Inl pC"
    using canonical_separator_path_from_shift[OF \<open>path ?C (initial ?C) (p')\<close> \<open>isl (target p' (initial ?C))\<close>] by blast
  then have "path (product (from_FSM M q1) (from_FSM M q2)) (q1,q2) pC"
    by force

  then have "path (from_FSM M q1) q1 (left_path pC)" and "path (from_FSM M q2) q2 (right_path pC)"
    using product_path[of "from_FSM M q1" "from_FSM M q2" q1 q2 pC] by presburger+


  have "path M q1 (left_path pC)"
    using from_FSM_path[OF assms(5) \<open>path (from_FSM M q1) q1 (left_path pC)\<close>] by assumption
  have "path M q2 (right_path pC)"
    using from_FSM_path[OF assms(6) \<open>path (from_FSM M q2) q2 (right_path pC)\<close>] by assumption
  
  have "t_target t = Inr q2"
    using \<open>path S (initial S) (p'@[t])\<close> snoc assms(3) by auto
  then have "t \<in> set (distinguishing_transitions_right M q1 q2)"
    using canonical_separator_targets(3)[OF \<open>t \<in> h ?C\<close> assms(5,6,7)] by auto

  have "t_source t = Inl (q1',q2')"
    using \<open>target p' (initial S) = Inl (q1',q2')\<close> \<open>t_source t = target p' (initial S)\<close> by auto

  obtain t' where "q1' \<in> nodes M"
                        and "q2' \<in> nodes M"
                        and "t' \<in> h M"
                        and "t_input t' = t_input t"
                        and "t_output t' = t_output t"
                        and "t_source t' = q2'"
                        and "\<not> (\<exists>t''\<in>h M. t_source t'' = q1' \<and> t_input t'' = t_input t \<and> t_output t'' = t_output t)"
    using distinguishing_transitions_right_sources_targets(1)[OF \<open>t \<in> set (distinguishing_transitions_right M q1 q2)\<close> assms(5,6)]
          \<open>t_source t = Inl (q1',q2')\<close>
    by force 

  

  have "initial S = Inl (q1,q2)"
    using assms(1) is_state_separator_from_canonical_separator_def[of ?C q1 q2 S] is_submachine.simps[of S ?C] canonical_separator_simps(1)[of M q1 q2]
    by (metis from_FSM_simps(1) product_simps(1))
  have "length p' = length pC"
    using \<open>p' = map shift_Inl pC\<close> by auto
  then have "target p' (initial S) = Inl (target pC (q1,q2))"
    using \<open>p' = map shift_Inl pC\<close> \<open>initial S = Inl (q1,q2)\<close> unfolding target.simps visited_states.simps by (induction p' pC rule: list_induct2; auto)
  then have "target pC (q1,q2) = (q1',q2')"
     using \<open>target p' (initial S) = Inl (q1',q2')\<close> by auto 
  then have "target (left_path pC) q1 = q1'"
    using product_target_split(1) by fastforce
  then have "\<not> (\<exists>t'\<in>h M. t_source t' = target (left_path pC) q1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
    using \<open>\<not> (\<exists>t'\<in>h M. t_source t' = q1' \<and> t_input t' = t_input t \<and> t_output t' = t_output t)\<close> by blast

  have "target (right_path pC) q2 = q2'"
    using \<open>target pC (q1,q2) = (q1',q2')\<close> product_target_split(2) by fastforce
  then have "path M q2 ((right_path pC)@[t'])"
    using \<open>path M q2 (right_path pC)\<close> \<open>t' \<in> h M\<close> \<open>t_source t' = q2'\<close>
    by (simp add: path_append_last) 
  then have "p_io ((right_path pC)@[t']) \<in> LS M q2" 
    unfolding LS.simps by force 
  moreover have "p_io p' = p_io (right_path pC)"
    using \<open>p' = map shift_Inl pC\<close> by auto
  ultimately have "p_io (p'@[t]) \<in> LS M q2"
    using \<open>t_input t' = t_input t\<close> \<open>t_output t' = t_output t\<close> by auto
    


  have "p_io (left_path pC) @  [(t_input t, t_output t)] \<notin> LS M q1"
    using observable_path_language_step[OF assms(4) \<open>path M q1 (left_path pC)\<close> \<open>\<not> (\<exists>t'\<in>h M. t_source t' = target (left_path pC) q1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)\<close>] by assumption
  moreover have "p_io p' = p_io (left_path pC)"
    using \<open>p' = map shift_Inl pC\<close> by auto
  ultimately have "p_io (p'@[t]) \<notin> LS M q1"
    by auto
  
  

  show ?thesis 
    using \<open>p_io (p'@[t]) \<in> LS M q2\<close> \<open>p_io (p'@[t]) \<notin> LS M q1\<close> snoc by blast
qed




lemma state_separation_set_from_state_separator :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
      and "observable M"
      and "q1 \<in> nodes M"
      and "q2 \<in> nodes M"
      and "q1 \<noteq> q2"
  shows "is_state_separation_set M q1 q2 (state_separation_set_from_state_separator S)" (is "is_state_separation_set M q1 q2 ?SS")
proof -

  have "acyclic S"
    using assms(1) is_state_separator_from_canonical_separator_def by metis 

  have "(LS M q1 \<inter> ?SS) \<inter> (LS M q2 \<inter> ?SS) = {}"
  proof -
    have "\<And> io . io \<in> ?SS \<Longrightarrow> \<not>(io \<in> LS M q1 \<and> io \<in> LS M q2)"
    proof -
      fix io assume "io \<in> ?SS"
      then obtain p where "path S (initial S) p" and  "\<not> isl (target p (initial S))" and "p_io p = io"
        unfolding state_separation_set_from_state_separator_def by blast

      have "target p (initial S) \<in> nodes S"
        using \<open>path S (initial S) p\<close> path_target_is_node by metis
      then consider "target p (initial S) = Inr q1" | 
                    "target p (initial S) = Inr q2"
        using \<open>\<not> isl (target p (initial S))\<close> assms(1) unfolding is_state_separator_from_canonical_separator_def
        by blast 
      then show "\<not>(io \<in> LS M q1 \<and> io \<in> LS M q2)" 
      proof (cases)
        case 1
        have "p_io p \<in> LS M q1 - LS M q2"
          using canonical_separator_maximal_path_distinguishes_left[OF assms(1) \<open>path S (initial S) p\<close> 1 assms(2,3,4,5)] by assumption
        then show ?thesis using \<open>p_io p = io\<close> by blast
      next
        case 2
        have "p_io p \<in> LS M q2 - LS M q1"
          using canonical_separator_maximal_path_distinguishes_right[OF assms(1) \<open>path S (initial S) p\<close> 2 assms(2,3,4,5)] by assumption
        then show ?thesis using \<open>p_io p = io\<close> by blast
      qed
    qed
    then show ?thesis by blast
  qed

      
  

  have "finite ?SS"
    using state_separation_set_from_state_separator_finite[OF \<open>acyclic S\<close>] by assumption
  moreover have "(\<And> M'::('a,'b) FSM_scheme . \<And> q1' q2' . 
        q1' \<in> nodes M' \<Longrightarrow> q2' \<in> nodes M' \<Longrightarrow> (LS M' q1' \<inter> ?SS \<noteq> {} \<or> LS M' q2' \<inter> ?SS \<noteq> {}) \<Longrightarrow> (LS M' q1' \<inter> ?SS \<subseteq> LS M q1 \<inter> ?SS) \<Longrightarrow> (LS M' q2' \<inter> ?SS \<subseteq> LS M q2 \<inter> ?SS) \<Longrightarrow> LS M' q1' \<noteq> LS M' q2')"
  proof -
    fix M'::"('a,'b) FSM_scheme"
    fix q1' q2' assume "(LS M' q1' \<inter> ?SS \<noteq> {}) \<or> (LS M' q2' \<inter> ?SS \<noteq> {})"
                   and "(LS M' q1' \<inter> ?SS \<subseteq> LS M q1 \<inter> ?SS)" 
                   and "(LS M' q2' \<inter> ?SS \<subseteq> LS M q2 \<inter> ?SS)"

    show "LS M' q1' \<noteq> LS M' q2'"
    proof (cases "(LS M' q1' \<inter> ?SS \<noteq> {})")
      case True
      then obtain io1 where "io1 \<in> (LS M' q1' \<inter> ?SS)" by blast
      then have "io1 \<in> LS M q1 \<inter> ?SS"
        using \<open>(LS M' q1' \<inter> ?SS \<subseteq> LS M q1 \<inter> ?SS)\<close> by blast
      then have "io1 \<notin> LS M q2 \<inter> ?SS"
        using \<open>(LS M q1 \<inter> ?SS) \<inter> (LS M q2 \<inter> ?SS) = {}\<close> by blast
      then have "io1 \<notin> LS M' q2' \<inter> ?SS"
        using \<open>(LS M' q2' \<inter> ?SS \<subseteq> LS M q2 \<inter> ?SS)\<close> by blast
      then have "io1 \<notin> LS M' q2'"
        using \<open>io1 \<in> (LS M' q1' \<inter> ?SS)\<close> by blast
      moreover have "io1 \<in> LS M' q1'" 
        using \<open>io1 \<in> (LS M' q1' \<inter> ?SS)\<close> by blast
      ultimately show ?thesis by blast
    next
      case False
      then have "LS M' q2' \<inter> ?SS \<noteq> {}"
        using \<open>(LS M' q1' \<inter> ?SS \<noteq> {}) \<or> (LS M' q2' \<inter> ?SS \<noteq> {})\<close> by blast
      then obtain io2 where "io2 \<in> (LS M' q2' \<inter> ?SS)" by blast
      then have "io2 \<in> LS M q2 \<inter> ?SS"
        using \<open>(LS M' q2' \<inter> ?SS \<subseteq> LS M q2 \<inter> ?SS)\<close> by blast
      then have "io2 \<notin> LS M q1 \<inter> ?SS"
        using \<open>(LS M q1 \<inter> ?SS) \<inter> (LS M q2 \<inter> ?SS) = {}\<close> by blast
      then have "io2 \<notin> LS M' q1' \<inter> ?SS"
        using \<open>(LS M' q1' \<inter> ?SS \<subseteq> LS M q1 \<inter> ?SS)\<close> by blast
      then have "io2 \<notin> LS M' q1'"
        using \<open>io2 \<in> (LS M' q2' \<inter> ?SS)\<close> by blast
      moreover have "io2 \<in> LS M' q2'" 
        using \<open>io2 \<in> (LS M' q2' \<inter> ?SS)\<close> by blast
      ultimately show ?thesis by blast
    qed
  qed

  ultimately show ?thesis 
    unfolding is_state_separation_set_def using \<open>(LS M q1 \<inter> ?SS) \<inter> (LS M q2 \<inter> ?SS) = {}\<close> by blast
qed

  




subsection \<open>State Separation Sets as Test Cases\<close>

(* TODO: introduce Petrenko's notion of test cases? *)

lemma state_separation_set_sym : "is_state_separation_set M q1 q2 = is_state_separation_set M q2 q1"
  unfolding is_state_separation_set_def by blast

(* note that no handling of pass traces is required, as Petrenko's pass relies only on the reachability of Fail states *)
(* TODO: incorporate fault_model ? *)
definition fail_sequence_set :: "('a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> (Input \<times> Output) list set \<Rightarrow> bool" where
  "fail_sequence_set M q Fail = (LS M q \<inter> Fail = {})"

lemma fail_sequence_set_application : 
  assumes "fail_sequence_set M q Fail"
      and "LS M' q' \<inter> Fail \<noteq> {}"      
shows "\<exists> io \<in> Fail . io \<in> (LS M' q' - LS M q)"
  using assms unfolding fail_sequence_set_def by blast



definition state_separation_fail_sequence_set_from_state_separator :: "('a, 'c) FSM_scheme \<Rightarrow> 'a \<Rightarrow> ('b + 'a, 'c) FSM_scheme \<Rightarrow> (Input \<times> Output) list set" where
  "state_separation_fail_sequence_set_from_state_separator M q1 S = 
      output_completion_for_FSM M (L S) - {io | io p . path S (initial S) p \<and> target p (initial S) = Inr q1 \<and> (\<exists> io' . p_io p = io@io')}"
(*      output_completion_for_FSM M {p_io p | p . path S (initial S) p \<and> (\<exists> p' . path S (initial S) (p@p') \<and> target (p@p') (initial S) = Inr q2)}" *)
(*    output_completion_for_FSM M (prefix_completion {p_io p | p . path S (initial S) p \<and> target p (initial S) = Inr q2})" *)

lemma state_separation_fail_sequence_set_from_state_separator :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
      and "observable M"
      and "q1 \<in> nodes M"
      and "q2 \<in> nodes M"
      and "q1 \<noteq> q2"
    shows "fail_sequence_set M q1 (state_separation_fail_sequence_set_from_state_separator M q1 S)" (is "fail_sequence_set M q1 ?SS")
  sorry
  
lemma x :
  assumes "completely_specified M'"
      and "inputs M' = inputs M"
      and "outputs M' = outputs M"
      and "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S" 
      and "q1' \<in> nodes M'"
    shows "LS M' q1' \<inter> output_completion_for_FSM M (L S) \<noteq> {}" 

lemma y :
  "path S (initial S) p \<and> target p (initial S) = Inr q1 \<and> (\<exists> io' . p_io p = io@io') \<Longrightarrow> io \<in> LS M q1"
    
     



(* TODO: prove that for completely_specified machines and applicable inputs the LSin of M' in are non-empty *)





(* TODO:
 - r_dist \<Longrightarrow> EX SSep 

 - Rethink effort required here: Algorithm likely relies on some distinction property only 
    - formulate basic requirements:  
        - finite 
        - subset of L q1 UN L q2
        - sequences in L q1 IN L q2 are not maximal
        - prefix-closed (?)
        - maximal sequences are marked q1/q2, depending on containment in L q1 or L q2
        - output completed / transition completed (?)

 - State Separator (general def)
 - State Separator vs State Separator from CSep
 - State Separator Set
*)






end