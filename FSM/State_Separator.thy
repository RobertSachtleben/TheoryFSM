theory State_Separator
imports R_Distinguishability IO_Sequence_Set
begin

section \<open>State Separators\<close>

subsection \<open>Definitions\<close>


abbreviation(input) "shift_Inl \<equiv> (\<lambda> t . (Inl (t_source t), t_input t, t_output t, Inl (t_target t)))"

definition shifted_transitions :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) Transition list" where
  "shifted_transitions M q1 q2 = map shift_Inl (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))"

definition distinguishing_transitions_left :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) Transition list" where
  "distinguishing_transitions_left M q1 q2 = (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1 )) (filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))))"

definition distinguishing_transitions_right :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) Transition list" where
  "distinguishing_transitions_right M q1 q2 = (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2 )) (filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))))"

definition canonical_separator :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) FSM" where
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



definition is_state_separator_from_canonical_separator :: "(('a \<times> 'a) + 'a) FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) FSM \<Rightarrow> bool" where
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

lemma is_state_separator_from_canonical_separator_simps :
  assumes "is_state_separator_from_canonical_separator CSep q1 q2 S"
  shows "is_submachine S CSep" 
  and   "single_input S"
  and   "acyclic S"
  and   "deadlock_state S (Inr q1)"
  and   "deadlock_state S (Inr q2)"
  and   "((Inr q1) \<in> nodes S)"
  and   "((Inr q2) \<in> nodes S)"
  and   "\<And> q . q \<in> nodes S \<Longrightarrow> q \<noteq> Inr q1 \<Longrightarrow> q \<noteq> Inr q2 \<Longrightarrow> (isl q \<and> \<not> deadlock_state S q)"
  and   "\<And> q x t . q \<in> nodes S \<Longrightarrow> x \<in> set (inputs CSep) \<Longrightarrow> (\<exists> t \<in> h S . t_source t = q \<and> t_input t = x) \<Longrightarrow> t \<in> h CSep \<Longrightarrow> t_source t = q \<Longrightarrow> t_input t = x \<Longrightarrow> t \<in> h S"
  using assms unfolding is_state_separator_from_canonical_separator_def by blast+

lemma is_state_separator_from_canonical_separator_initial :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  shows "initial A = initial (canonical_separator M q1 q2)"
  using is_state_separator_from_canonical_separator_simps(1)[OF assms]  by auto




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


(* TODO remove *)
lemma product_from_transition_split :
  assumes "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows   "(\<exists>t'\<in> h M. t_source t' = fst (t_source t) \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
and     "(\<exists>t'\<in> h M. t_source t' = snd (t_source t) \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
proof -
  have "(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> h M"
    using product_transition_split(1)[OF assms(1)] from_FSM_h[OF assms(2)] by blast
  then show "(\<exists>t'\<in> h M. t_source t' = fst (t_source t) \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
    by auto
  have "(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> h M"
    using product_transition_split(2)[OF assms(1)] from_FSM_h[OF assms(3)] by blast
  then show "(\<exists>t'\<in> h M. t_source t' = snd (t_source t) \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
    by auto
qed



lemma shifted_transitions_underlying_transition' :
  assumes "tS \<in> set (shifted_transitions M q1 q2)"
  obtains t where "tS = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))"
            and   "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
  using assms unfolding shifted_transitions_def
  by (meson list_map_source_elem)

lemma shifted_transitions_underlying_transition :
  assumes "tS \<in> set (shifted_transitions M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  obtains t where "tS = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))"
            and   "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
            and   "(\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (t_source t) \<and>
                            t_input t' = t_input t \<and> t_output t' = t_output t)"
            and   "(\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (t_source t) \<and>
                            t_input t' = t_input t \<and> t_output t' = t_output t)"
proof -
  obtain t where "tS = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))"
           and   "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
    using shifted_transitions_underlying_transition'[OF assms(1)] by blast
  moreover have "(\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (t_source t) \<and>
                            t_input t' = t_input t \<and> t_output t' = t_output t)"
    using product_from_transition_split(1)[OF \<open>t \<in> h (product (from_FSM M q1) (from_FSM M q2))\<close> assms(2,3)] by blast
  moreover have "(\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (t_source t) \<and>
                            t_input t' = t_input t \<and> t_output t' = t_output t)"
    using product_from_transition_split(2)[OF \<open>t \<in> h (product (from_FSM M q1) (from_FSM M q2))\<close> assms(2,3)] by blast
  ultimately show ?thesis
    using that by blast 
qed
     

lemma distinguishing_transitions_left_underlying_data :
  assumes "tS \<in> set (distinguishing_transitions_left M q1 q2)"
  obtains qqt where "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
              and   "tS = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)"
              and   "t_source (snd qqt) = fst (fst qqt)"
              and   "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using assms unfolding distinguishing_transitions_left_def 
    using filter_map_elem[of tS "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))" 
                                "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))" 
                                "(concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"] 
    by blast


lemma distinguishing_transitions_right_underlying_data :
  assumes "tS \<in> set (distinguishing_transitions_right M q1 q2)"
  obtains qqt where "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
              and   "tS = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)"
              and   "t_source (snd qqt) = snd (fst qqt)"
              and   "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using assms unfolding distinguishing_transitions_right_def 
    using filter_map_elem[of tS "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2))" 
                                "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))" 
                                "(concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"] 
    by blast


lemma shifted_transitions_observable_against_distinguishing_transitions_left :
  assumes "t1 \<in> set (shifted_transitions M q1 q2)"
  and     "t2 \<in> set (distinguishing_transitions_left M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "\<not> (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2)"
proof 
  assume *: "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"

  obtain t where "t1 = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))"
           and   "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
           and   "(\<exists>t'\<in>set (transitions M).
                           t_source t' = fst (t_source t) \<and>
                           t_input t' = t_input t \<and> t_output t' = t_output t)"
           and   **: "(\<exists>t'\<in>set (transitions M).
                           t_source t' = snd (t_source t) \<and>
                           t_input t' = t_input t \<and> t_output t' = t_output t)"
    using shifted_transitions_underlying_transition[OF assms(1,3,4)] by blast

  obtain qqt where "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
             and   "t2 = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)"
             and   ***: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using distinguishing_transitions_left_underlying_data[OF assms(2)] by blast

  have "t_source t = fst qqt" and "t_input t = t_input (snd qqt)" and "t_output t = t_output (snd qqt)"
    using \<open>t1 = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))\<close>
          \<open>t2 = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)\<close>
          * 
    by auto
  then show "False"
    using ** *** by auto
qed

lemma shifted_transitions_observable_against_distinguishing_transitions_right :
  assumes "t1 \<in> set (shifted_transitions M q1 q2)"
  and     "t2 \<in> set (distinguishing_transitions_right M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "\<not> (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2)"
proof 
  assume *: "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"

  obtain t where "t1 = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))"
           and   "t \<in> h (product (from_FSM M q1) (from_FSM M q2))"
           and   **: "(\<exists>t'\<in>set (transitions M).
                           t_source t' = fst (t_source t) \<and>
                           t_input t' = t_input t \<and> t_output t' = t_output t)"
           and   "(\<exists>t'\<in>set (transitions M).
                           t_source t' = snd (t_source t) \<and>
                           t_input t' = t_input t \<and> t_output t' = t_output t)"
    using shifted_transitions_underlying_transition[OF assms(1,3,4)] by blast

  obtain qqt where "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
             and   "t2 = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)"
             and   ***: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using distinguishing_transitions_right_underlying_data[OF assms(2)] by blast

  have "t_source t = fst qqt" and "t_input t = t_input (snd qqt)" and "t_output t = t_output (snd qqt)"
    using \<open>t1 = (Inl (t_source t), t_input t, t_output t, Inl (t_target t))\<close>
          \<open>t2 = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)\<close>
          * 
    by auto
  then show "False"
    using ** *** by auto
qed

lemma distinguishing_transitions_left_observable_against_distinguishing_transitions_right :
  assumes "t1 \<in> set (distinguishing_transitions_left M q1 q2)"
  and     "t2 \<in> set (distinguishing_transitions_right M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "\<not> (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2)"
proof 
  assume *: "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"

  obtain qqtL where **: "qqtL \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
             and   "t1 = (Inl (fst qqtL), t_input (snd qqtL), t_output (snd qqtL), Inr q1)"
             and   ***: "t_source (snd qqtL) = fst (fst qqtL)"
             and   "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (fst qqtL) \<and>
                            t_input t' = t_input (snd qqtL) \<and> t_output t' = t_output (snd qqtL))"
    using distinguishing_transitions_left_underlying_data[OF assms(1)] by blast

  have "snd qqtL \<in> h M"
    using ** concat_pair_set by blast
  then have ****: "snd qqtL \<in> set (transitions M) \<and> t_source (snd qqtL) = fst (fst qqtL) \<and> t_input (snd qqtL) = t_input (snd qqtL) \<and> t_output (snd qqtL) = t_output (snd qqtL)"
    using *** by auto
  

  obtain qqtR where "qqtR \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
             and   "t2 = (Inl (fst qqtR), t_input (snd qqtR), t_output (snd qqtR), Inr q2)"
             and   "t_source (snd qqtR) = snd (fst qqtR)"
             and   *****: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (fst qqtR) \<and>
                            t_input t' = t_input (snd qqtR) \<and> t_output t' = t_output (snd qqtR))"
    using distinguishing_transitions_right_underlying_data[OF assms(2)] by blast

  have "fst qqtL = fst qqtR" and "t_input (snd qqtL) = t_input (snd qqtR)" and "t_output (snd qqtL) = t_output (snd qqtR)"
    using \<open>t1 = (Inl (fst qqtL), t_input (snd qqtL), t_output (snd qqtL), Inr q1)\<close>
          \<open>t2 = (Inl (fst qqtR), t_input (snd qqtR), t_output (snd qqtR), Inr q2)\<close>
          * 
    by auto
  then show "False"
    using **** ***** by auto
qed

lemma distinguishing_transitions_left_observable_against_distinguishing_transitions_left :
  assumes "t1 \<in> set (distinguishing_transitions_left M q1 q2)"
  and     "t2 \<in> set (distinguishing_transitions_left M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"
shows "t1 = t2"
  using distinguishing_transitions_left_sources_targets(2)[OF assms(1,3,4)]
        distinguishing_transitions_left_sources_targets(2)[OF assms(2,3,4)]
        \<open>t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<close>
  by (simp add: prod_eqI) 


lemma distinguishing_transitions_right_observable_against_distinguishing_transitions_right :
  assumes "t1 \<in> set (distinguishing_transitions_right M q1 q2)"
  and     "t2 \<in> set (distinguishing_transitions_right M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"
shows "t1 = t2"
  using distinguishing_transitions_right_sources_targets(2)[OF assms(1,3,4)]
        distinguishing_transitions_right_sources_targets(2)[OF assms(2,3,4)]
        \<open>t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<close>
  by (simp add: prod_eqI) 







lemma shifted_transitions_observable_against_shifted_transitions :
  assumes "t1 \<in> set (shifted_transitions M q1 q2)"
  and     "t2 \<in> set (shifted_transitions M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "observable M"
  and     "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"
shows "t1 = t2"
proof -
  obtain t1' where d1: "t1 = (Inl (t_source t1'), t_input t1', t_output t1', Inl (t_target t1'))"
             and   h1: "t1' \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))"
    using shifted_transitions_underlying_transition[OF assms(1,3,4)] by blast

  obtain t2' where d2: "t2 = (Inl (t_source t2'), t_input t2', t_output t2', Inl (t_target t2'))"
             and   h2: "t2' \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))"
    using shifted_transitions_underlying_transition[OF assms(2,3,4)] by blast

  have "observable (product (from_FSM M q1) (from_FSM M q2))"
    using from_FSM_observable[OF assms(5,3)] from_FSM_observable[OF assms(5,4)] 
          product_observable 
    by metis
  
  then have "t1' = t2'"
    using d1 d2 h1 h2 \<open>t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<close>
    by (metis fst_conv observable.elims(2) prod.expand snd_conv sum.inject(1)) 
  then show ?thesis using d1 d2 by auto
qed
  




lemma canonical_separator_observable :
  assumes "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "observable (canonical_separator M q1 q2)" (is "observable ?CSep")
proof -

  

  have  "\<And> t1 t2 . t1 \<in> set (transitions ?CSep) \<Longrightarrow> 
                             t2 \<in> set (transitions ?CSep) \<Longrightarrow> 
                    t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2 \<Longrightarrow> t_target t1 = t_target t2" 
  proof -
    fix t1 t2 assume "t1 \<in> set (transitions ?CSep)" 
              and    "t2 \<in> set (transitions ?CSep)"
              and    "t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2"
    
    moreover have "transitions ?CSep = shifted_transitions M q1 q2 @
                                       distinguishing_transitions_left M q1 q2 @ 
                                       distinguishing_transitions_right M q1 q2"
      unfolding canonical_separator_def by auto
    moreover note shifted_transitions_observable_against_distinguishing_transitions_left[OF _ _ assms(2,3)]
    moreover note shifted_transitions_observable_against_distinguishing_transitions_right[OF _ _ assms(2,3)]
    moreover note distinguishing_transitions_left_observable_against_distinguishing_transitions_right[OF _ _ assms(2,3)]
    moreover note shifted_transitions_observable_against_shifted_transitions[OF _ _ assms(2,3)]
    moreover note distinguishing_transitions_left_observable_against_distinguishing_transitions_left[OF _ _ assms(2,3)]
    moreover note distinguishing_transitions_right_observable_against_distinguishing_transitions_right[OF _ _ assms(2,3)]
    ultimately show "t_target t1 = t_target t2"
    proof -
      have "\<forall>p. (p \<in> set (distinguishing_transitions_left M q1 q2 @ distinguishing_transitions_right M q1 q2) \<or> p \<in> set (shifted_transitions M q1 q2)) \<or> p \<notin> set (transitions (canonical_separator M q1 q2))"
        by (metis \<open>transitions (canonical_separator M q1 q2) = shifted_transitions M q1 q2 @ distinguishing_transitions_left M q1 q2 @ distinguishing_transitions_right M q1 q2\<close> list_concat_non_elem)
      then have "t1 = t2"
        by (metis (no_types) \<open>\<And>t2 t1. \<lbrakk>t1 \<in> set (distinguishing_transitions_left M q1 q2); t2 \<in> set (distinguishing_transitions_left M q1 q2); t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<rbrakk> \<Longrightarrow> t1 = t2\<close> \<open>\<And>t2 t1. \<lbrakk>t1 \<in> set (distinguishing_transitions_left M q1 q2); t2 \<in> set (distinguishing_transitions_right M q1 q2)\<rbrakk> \<Longrightarrow> \<not> (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2)\<close> \<open>\<And>t2 t1. \<lbrakk>t1 \<in> set (distinguishing_transitions_right M q1 q2); t2 \<in> set (distinguishing_transitions_right M q1 q2); t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<rbrakk> \<Longrightarrow> t1 = t2\<close> \<open>\<And>t2 t1. \<lbrakk>t1 \<in> set (shifted_transitions M q1 q2); t2 \<in> set (distinguishing_transitions_left M q1 q2)\<rbrakk> \<Longrightarrow> \<not> (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2)\<close> \<open>\<And>t2 t1. \<lbrakk>t1 \<in> set (shifted_transitions M q1 q2); t2 \<in> set (distinguishing_transitions_right M q1 q2)\<rbrakk> \<Longrightarrow> \<not> (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2)\<close> \<open>\<And>t2 t1. \<lbrakk>t1 \<in> set (shifted_transitions M q1 q2); t2 \<in> set (shifted_transitions M q1 q2); observable M; t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<rbrakk> \<Longrightarrow> t1 = t2\<close> \<open>t1 \<in> set (transitions (canonical_separator M q1 q2))\<close> \<open>t2 \<in> set (transitions (canonical_separator M q1 q2))\<close> \<open>t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2\<close> assms(1) list_concat_non_elem)
      then show ?thesis
        by meson
    qed 
  qed
  then show ?thesis unfolding observable.simps by blast
qed








lemma distinguishing_transitions_left_empty : 
  assumes "observable M"
  and     "q \<in> nodes M"
  shows   "distinguishing_transitions_left M q q = []"
proof (rule ccontr)
  assume "distinguishing_transitions_left M q q \<noteq> []"
  then obtain t where "t \<in> set (distinguishing_transitions_left M q q)"
    using last_in_set by blast


  obtain qqt where *: "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q) (from_FSM M q)))))"
             and   "t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q)"
             and   **: "t_source (snd qqt) = fst (fst qqt)"
             and   ***: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using distinguishing_transitions_left_underlying_data[OF \<open>t \<in> set (distinguishing_transitions_left M q q)\<close>] by blast

  have "fst qqt \<in> nodes (product (from_FSM M q) (from_FSM M q))" and "snd qqt \<in> h M"
    using * concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q) (from_FSM M q))"] nodes_code[of "product (from_FSM M q) (from_FSM M q)"] by blast+
  then have "fst (fst qqt) = snd (fst qqt)"
    using product_observable_self_transitions[OF _ from_FSM_observable[OF assms]] by blast
  then have "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = t_source (snd qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using ** *** by auto
  then show "False"
    using \<open>snd qqt \<in> h M\<close> by blast
qed


lemma distinguishing_transitions_right_empty : 
  assumes "observable M"
  and     "q \<in> nodes M"
  shows   "distinguishing_transitions_right M q q = []"
proof (rule ccontr)
  assume "distinguishing_transitions_right M q q \<noteq> []"
  then obtain t where "t \<in> set (distinguishing_transitions_right M q q)"
    using last_in_set by blast


  obtain qqt where *: "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q) (from_FSM M q)))))"
             and   "t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q)"
             and   **: "t_source (snd qqt) = snd (fst qqt)"
             and   ***: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using distinguishing_transitions_right_underlying_data[OF \<open>t \<in> set (distinguishing_transitions_right M q q)\<close>] by blast

  have "fst qqt \<in> nodes (product (from_FSM M q) (from_FSM M q))" and "snd qqt \<in> h M"
    using * concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q) (from_FSM M q))"] nodes_code[of "product (from_FSM M q) (from_FSM M q)"] by blast+
  then have "fst (fst qqt) = snd (fst qqt)"
    using product_observable_self_transitions[OF _ from_FSM_observable[OF assms]] by blast
  then have "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = t_source (snd qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using ** *** by auto
  then show "False"
    using \<open>snd qqt \<in> h M\<close> by blast
qed
  


lemma canonical_separator_targets_observable_eq :
  assumes "observable M"
      and "q \<in> nodes M"
      and "t \<in> h (canonical_separator M q q)"
shows "t \<in> set (shifted_transitions M q q)"
and   "isl (t_target t)"    
proof -
  show "t \<in> set (shifted_transitions M q q)"
  using canonical_separator_simps(4)[of M q q] 
        distinguishing_transitions_left_empty[OF assms(1,2)]
        distinguishing_transitions_right_empty[OF assms(1,2)] 
        assms(3) by auto
  
  show "isl (t_target t)" unfolding shifted_transitions_def
    by (meson \<open>t \<in> set (shifted_transitions M q q)\<close> shifted_transitions_targets) 
qed



lemma canonical_separator_targets_ineq :
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
    using "*" assms(1) using assms(4) by auto

  show "t_target t = Inr q2 \<Longrightarrow> t \<in> set (distinguishing_transitions_right M q1 q2)"
    using shifted_transitions_targets[of t M q1 q2] 
          distinguishing_transitions_left_sources_targets(2)[OF _ assms(2,3), of t]
          distinguishing_transitions_right_sources_targets(2)[OF _ assms(2,3), of t]
    using "*" assms(1) assms(4) by auto
qed



lemma canonical_separator_targets_observable :
  assumes "t \<in> h (canonical_separator M q1 q2)" 
      and "observable M" and "q1 \<in> nodes M" and "q2 \<in> nodes M"
  shows "isl (t_target t) \<Longrightarrow> t \<in> set (shifted_transitions M q1 q2)"
    and "t_target t = Inr q1 \<Longrightarrow> t \<in> set (distinguishing_transitions_left M q1 q2)"
    and "t_target t = Inr q2 \<Longrightarrow> t \<in> set (distinguishing_transitions_right M q1 q2)"
proof -
  have "(isl (t_target t) \<longrightarrow> t \<in> set (shifted_transitions M q1 q2)) \<and> (t_target t = Inr q1 \<longrightarrow> t \<in> set (distinguishing_transitions_left M q1 q2)) \<and> (t_target t = Inr q2 \<longrightarrow> t \<in> set (distinguishing_transitions_right M q1 q2))"
  proof (cases "q1 = q2")
    case True
    then have "t \<in> h (canonical_separator M q1 q1)"
      using assms(1) by simp
    
    show ?thesis using canonical_separator_targets_observable_eq[OF assms(2,3) \<open>t \<in> h (canonical_separator M q1 q1)\<close>]
      using True by auto 
  next
    case False
    show ?thesis using canonical_separator_targets_ineq[OF assms(1,3,4) False] by blast
  qed
  then show "isl (t_target t) \<Longrightarrow> t \<in> set (shifted_transitions M q1 q2)"
       and  "t_target t = Inr q1 \<Longrightarrow> t \<in> set (distinguishing_transitions_left M q1 q2)"
       and  "t_target t = Inr q2 \<Longrightarrow> t \<in> set (distinguishing_transitions_right M q1 q2)"
    by blast+
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
    using canonical_separator_targets_ineq(2)[OF \<open>t \<in> h ?C\<close> assms(5,6,7)] by auto

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
    using canonical_separator_targets_ineq(3)[OF \<open>t \<in> h ?C\<close> assms(5,6,7)] by auto

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


lemma state_separator_from_canonical_separator_observable :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "observable A"
  using submachine_observable[OF _ canonical_separator_observable[OF assms(2,3,4)]]
  using assms(1) unfolding is_state_separator_from_canonical_separator_def 
  by metis



lemma canonical_separator_initial :
  shows "initial (canonical_separator M q1 q2) = Inl (q1,q2)" 
    unfolding canonical_separator_def 
    using from_FSM_simps(1) product_simps(1)
    by (metis (no_types, lifting) select_convs(1))


lemma state_separator_from_canonical_separator_initial :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
shows "initial A = Inl (q1,q2)"
    using assms unfolding is_state_separator_from_canonical_separator_def canonical_separator_def 
    using is_submachine.simps from_FSM_simps(1) product_simps(1)
    by (metis (no_types, lifting) select_convs(1))


lemma canonical_separator_target_possibilities :
  assumes "t \<in> h (canonical_separator M q1 q2)" (is "t \<in> h ?C")
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "isl (t_target t) \<or> t_target t = Inr q1 \<or> t_target t = Inr q2"
proof -
  have *: "set (transitions ?C) = (set (shifted_transitions M q1 q2)) \<union> (set (distinguishing_transitions_left M q1 q2)) \<union> (set (distinguishing_transitions_right M q1 q2))"
    using canonical_separator_simps(4)[of M q1 q2] by auto
  then consider  (a) "t \<in> set (shifted_transitions M q1 q2)" |
                 (b) "t \<in> set (distinguishing_transitions_left M q1 q2)" |
                 (c) "t \<in> set (distinguishing_transitions_right M q1 q2)"
    using assms(1) by blast
  then show ?thesis proof cases
    case a
    then show ?thesis unfolding shifted_transitions_def by auto
  next
    case b
    then show ?thesis unfolding distinguishing_transitions_left_def
      by (meson assms(2) assms(3) b distinguishing_transitions_left_sources_targets(2)) 
  next
    case c
    then show ?thesis unfolding distinguishing_transitions_right_def
      by (meson assms(2) assms(3) c distinguishing_transitions_right_sources_targets(2)) 
  qed
qed
                      

lemma canonical_separator_nodes :
  assumes "Inl (s1,s2) \<in> nodes (canonical_separator M q1 q2)"
  shows "(s1,s2) \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
proof -
  let ?C = "(canonical_separator M q1 q2)"
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"
  consider (a) "Inl (s1,s2) = initial ?C" |
           (b) "\<exists> t \<in> h ?C . t_target t = Inl (s1,s2)"
    using nodes_initial_or_target[OF assms] by blast
  then show ?thesis proof cases
    case a
    then have "(s1,s2) = (q1,q2)"
      unfolding canonical_separator_def product_simps(1) from_FSM_simps(1) by auto
    then show ?thesis 
      using nodes.initial[of ?P] unfolding product_simps(1) from_FSM_simps(1) by auto
  next
    case b
    then obtain t where "t \<in> h ?C" and "t_target t = Inl (s1,s2)"
      by blast
    then have "isl (t_target t)"
      by auto

    note State_Separator.canonical_separator_product_h_isl[OF \<open>t \<in> h ?C\<close> \<open>isl (t_target t)\<close>]

    show ?thesis 
      using State_Separator.canonical_separator_product_h_isl[OF \<open>t \<in> h ?C\<close> \<open>isl (t_target t)\<close>]
      using \<open>t_target t = Inl (s1, s2)\<close> wf_transition_target
      by (metis Inl_inject snd_conv) 
  qed
qed


lemma canonical_separator_transition :
  assumes "t \<in> h (canonical_separator M q1 q2)" (is "t \<in> h ?C")
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "t_source t = Inl (s1,s2)"
  and     "observable M"
shows "\<And> s1' s2' . t_target t = Inl (s1',s2') \<Longrightarrow> (s1, t_input t, t_output t, s1') \<in> h M \<and> (s2, t_input t, t_output t, s2') \<in> h M"
and   "t_target t = Inr q1 \<Longrightarrow> (\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t) 
                                \<and> (\<not>(\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t))"
and   "t_target t = Inr q2 \<Longrightarrow> (\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t) 
                                \<and> (\<not>(\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t))"
and   "(\<exists> s1' s2' . t_target t = Inl (s1',s2')) \<or> t_target t = Inr q1 \<or> t_target t = Inr q2"
proof -           

  let ?P1 = "\<forall> s1' s2' . t_target t = Inl (s1',s2') \<longrightarrow> (s1, t_input t, t_output t, s1') \<in> h M \<and> (s2, t_input t, t_output t, s2') \<in> h M"
  let ?P2 = "t_target t = Inr q1 \<longrightarrow> (\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t) 
                                        \<and> (\<not>(\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t))"
  let ?P3 = "t_target t = Inr q2 \<longrightarrow> (\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t) 
                                        \<and> (\<not>(\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t))"

  have "t_source t \<in> nodes ?C"
    using assms(1) by auto

  have *: "set (transitions ?C) = (set (shifted_transitions M q1 q2)) \<union> (set (distinguishing_transitions_left M q1 q2)) \<union> (set (distinguishing_transitions_right M q1 q2))"
    using canonical_separator_simps(4)[of M q1 q2] by auto
  then consider  (a) "t \<in> set (shifted_transitions M q1 q2)" |
                 (b) "t \<in> set (distinguishing_transitions_left M q1 q2)" |
                 (c) "t \<in> set (distinguishing_transitions_right M q1 q2)"
    using assms(1) by blast
  then have "?P1 \<and> ?P2 \<and> ?P3" proof cases
    case a
    then obtain ta where **: "t = (Inl (t_source ta), t_input ta, t_output ta, Inl (t_target ta))"
                   and   ***: "ta \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))"
                   and   "\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (t_source ta) \<and> t_input t' = t_input ta \<and> t_output t' = t_output ta"
                   and   "\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (t_source ta) \<and> t_input t' = t_input ta \<and> t_output t' = t_output ta"
      using shifted_transitions_underlying_transition[OF a assms(2,3)] by blast

    obtain s1' s2' where "t_target t = Inl (s1',s2')"
      using ** by fastforce 
    then have "t_target ta = (s1',s2')"
      using ** by auto
    moreover have "t_source ta = (s1,s2)" and "t_input ta = t_input t" and "t_output ta = t_output t"
      using assms(4) ** by auto
    ultimately have "ta = ((s1,s2),t_input t, t_output t, (s1',s2'))"
      using prod.collapse by metis
    then have ****: "((s1,s2),t_input t, t_output t, (s1',s2')) \<in> h (product (from_FSM M q1) (from_FSM M q2))"
      using *** by simp
        

    
    have "(s1, t_input t, t_output t, s1') \<in> h M"  
      using product_transition_split(1)[OF ****] from_FSM_h[OF \<open>q1 \<in> nodes M\<close>] by auto
    moreover have "(s2, t_input t, t_output t, s2') \<in> h M"  
      using product_transition_split(2)[OF ****] from_FSM_h[OF \<open>q2 \<in> nodes M\<close>] by auto
    ultimately show ?thesis 
      using \<open>t_target t = Inl (s1',s2')\<close>
      by simp 
  next
    case b

    obtain qqt where **: "qqt \<in> set (concat
                                  (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
               and   ***:"t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)"
               and   ****:"t_source (snd qqt) = fst (fst qqt)"
               and   *****: "\<not> (\<exists>t'\<in>set (transitions M).
                              t_source t' = snd (fst qqt) \<and>
                              t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
      using distinguishing_transitions_left_underlying_data[OF b] by blast

    have "t_target t = Inr q1"
      using *** by simp
    have "snd (fst qqt) = s2"
      using assms(4) *** by auto

    let ?t = "snd qqt"
    have "?t \<in> h M"
      using concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] ** by blast
    moreover have "t_source ?t = s1"
      using *** **** \<open>t_source t = Inl (s1,s2)\<close> by auto
    moreover have "t_input ?t = t_input t" and "t_output ?t = t_output t" 
      using *** by auto
    ultimately have "\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t"
      by blast
    then have ?P2
      using ***** unfolding \<open>snd (fst qqt) = s2\<close> \<open>t_input ?t = t_input t\<close> \<open>t_output ?t = t_output t\<close> by blast
    moreover have ?P1
      using \<open>t_target t = Inr q1\<close> by auto
    moreover have ?P3
    proof (cases "q1 = q2")
      case True
      then have "isl (t_target t)"
        using canonical_separator_targets_observable_eq(2)[OF \<open>observable M\<close> \<open>q1 \<in> nodes M\<close>, of t] \<open>t \<in> h ?C\<close> by auto
      then show ?thesis using \<open>t_target t = Inr q1\<close> by auto
    next
      case False
      then show ?thesis using \<open>t_target t = Inr q1\<close> by auto
    qed 
    ultimately show ?thesis by blast 
  next
    case c
    obtain qqt where **: "qqt \<in> set (concat
                                  (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
               and   ***:"t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)"
               and   ****:"t_source (snd qqt) = snd (fst qqt)"
               and   *****: "\<not> (\<exists>t'\<in>set (transitions M).
                              t_source t' = fst (fst qqt) \<and>
                              t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
      using distinguishing_transitions_right_underlying_data[OF c] by blast

    have "t_target t = Inr q2"
      using *** by simp
    have "fst (fst qqt) = s1"
      using assms(4) *** by auto

    let ?t = "snd qqt"
    have "?t \<in> h M"
      using concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] ** by blast
    moreover have "t_source ?t = s2"
      using *** **** \<open>t_source t = Inl (s1,s2)\<close> by auto
    moreover have "t_input ?t = t_input t" and "t_output ?t = t_output t" 
      using *** by auto
    ultimately have "\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t"
      by blast
    then have ?P3
      using ***** unfolding \<open>fst (fst qqt) = s1\<close> \<open>t_input ?t = t_input t\<close> \<open>t_output ?t = t_output t\<close> by blast
    moreover have ?P1
      using \<open>t_target t = Inr q2\<close> by auto
    moreover have ?P2
    proof (cases "q1 = q2")
      case True
      then have "isl (t_target t)"
        using canonical_separator_targets_observable_eq(2)[OF \<open>observable M\<close> \<open>q1 \<in> nodes M\<close>, of t] \<open>t \<in> h ?C\<close> by auto
      then show ?thesis using \<open>t_target t = Inr q2\<close> by auto
    next
      case False
      then show ?thesis using \<open>t_target t = Inr q2\<close> by auto
    qed 
    ultimately show ?thesis by blast
  qed 

  moreover have "(\<exists> s1' s2' . t_target t = Inl (s1',s2')) \<or> t_target t = Inr q1 \<or> t_target t = Inr q2"
    using canonical_separator_target_possibilities[OF assms(1,2,3)] by (simp add: isl_def)


  ultimately show  "\<And> s1' s2' . t_target t = Inl (s1',s2') \<Longrightarrow> (s1, t_input t, t_output t, s1') \<in> h M \<and> (s2, t_input t, t_output t, s2') \<in> h M"
       and   "t_target t = Inr q1 \<Longrightarrow> (\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t) 
                                       \<and> (\<not>(\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t))"
       and   "t_target t = Inr q2 \<Longrightarrow> (\<exists> t'\<in> h M . t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t) 
                                       \<and> (\<not>(\<exists> t'\<in> h M . t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t))"
       and   "(\<exists> s1' s2' . t_target t = Inl (s1',s2')) \<or> t_target t = Inr q1 \<or> t_target t = Inr q2"
    by blast+  
qed



(* currently does not require observability on M, but could be derived from canonical_separator_transition under that additional assumption *)
lemma canonical_separator_transition_ex :
  assumes "t \<in> h (canonical_separator M q1 q2)" (is "t \<in> h ?C")
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "t_source t = Inl (s1,s2)"
shows "(\<exists> t1 \<in> h M . t_source t1 = s1 \<and> t_input t1 = t_input t \<and> t_output t1 = t_output t) \<or>
       (\<exists> t2 \<in> h M . t_source t2 = s2 \<and> t_input t2 = t_input t \<and> t_output t2 = t_output t)"
proof -           

  have "t_source t \<in> nodes ?C"
    using assms(1) by auto

  have *: "set (transitions ?C) = (set (shifted_transitions M q1 q2)) \<union> (set (distinguishing_transitions_left M q1 q2)) \<union> (set (distinguishing_transitions_right M q1 q2))"
    using canonical_separator_simps(4)[of M q1 q2] by auto
  then consider  (a) "t \<in> set (shifted_transitions M q1 q2)" |
                 (b) "t \<in> set (distinguishing_transitions_left M q1 q2)" |
                 (c) "t \<in> set (distinguishing_transitions_right M q1 q2)"
    using assms(1) by blast
  then show ?thesis proof cases
    case a
    then obtain ta where **: "t = (Inl (t_source ta), t_input ta, t_output ta, Inl (t_target ta))"
                   and   ***: "ta \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))"
                   and   "\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (t_source ta) \<and> t_input t' = t_input ta \<and> t_output t' = t_output ta"
                   and   "\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (t_source ta) \<and> t_input t' = t_input ta \<and> t_output t' = t_output ta"
      using shifted_transitions_underlying_transition[OF a assms(2,3)] by blast
    

    let ?t = "(fst (t_source ta), t_input ta, t_output ta, fst (t_target ta))"
    have "?t \<in> h M"
      using product_transition_split(1)[OF ***] from_FSM_h[OF \<open>q1 \<in> nodes M\<close>] by blast
    then show ?thesis
      using ** \<open>t_source t = Inl (s1,s2)\<close> by auto 
  next
    case b

    obtain qqt where **: "qqt \<in> set (concat
                                  (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
               and   ***:"t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)"
               and   ****:"t_source (snd qqt) = fst (fst qqt)"
               and   "\<not> (\<exists>t'\<in>set (transitions M).
                              t_source t' = snd (fst qqt) \<and>
                              t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
      using distinguishing_transitions_left_underlying_data[OF b] by blast

    let ?t = "snd qqt"
    have "?t \<in> h M"
      using concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] ** by blast
    moreover have "t_source ?t = s1"
      using *** **** \<open>t_source t = Inl (s1,s2)\<close> by auto
    moreover have "t_input ?t = t_input t" and "t_output ?t = t_output t"
      using *** by auto
    ultimately show ?thesis by blast
  next
    case c
    obtain qqt where **: "qqt \<in> set (concat
                                  (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
               and   ***:"t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)"
               and   ****:"t_source (snd qqt) = snd (fst qqt)"
               and   "\<not> (\<exists>t'\<in>set (transitions M).
                              t_source t' = fst (fst qqt) \<and>
                              t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
      using distinguishing_transitions_right_underlying_data[OF c] by blast

    let ?t = "snd qqt"
    have "?t \<in> h M"
      using concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] ** by blast
    moreover have "t_source ?t = s2"
      using *** **** \<open>t_source t = Inl (s1,s2)\<close> by auto
    moreover have "t_input ?t = t_input t" and "t_output ?t = t_output t"
      using *** by auto
    ultimately show ?thesis by blast
  qed 
qed


lemma canonical_separator_path_split_target_isl :
  assumes "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) (p@[t])"
  shows "isl (target p (initial (canonical_separator M q1 q2)))"
proof -
  let ?C = "(canonical_separator M q1 q2)"
  have "t \<in> h ?C"
    using assms by auto
  have "\<not> deadlock_state ?C (t_source t)"
    using assms unfolding deadlock_state.simps by blast
  then show ?thesis 
    using canonical_separator_t_source_isl[of t] \<open>t \<in> h ?C\<close> assms
    by fastforce
qed




lemma canonical_separator_path_initial :
  assumes "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p" (is "path ?C (initial ?C) p")
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "observable M"
shows "\<And> s1' s2' . target p (initial (canonical_separator M q1 q2)) = Inl (s1',s2') \<Longrightarrow> (\<exists> p1 p2 . path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = p_io p2 \<and> p_io p1 = p_io p \<and> target p1 q1 = s1' \<and> target p2 q2 = s2')"
and   "target p (initial (canonical_separator M q1 q2)) = Inr q1 \<Longrightarrow> (\<exists> p1 p2 t . path M q1 (p1@[t]) \<and> path M q2 p2 \<and> p_io (p1@[t]) = p_io p \<and> p_io p2 = butlast (p_io p)) \<and> (\<not>(\<exists> p2 . path M q2 p2 \<and> p_io p2 = p_io p))"
and   "target p (initial (canonical_separator M q1 q2)) = Inr q2 \<Longrightarrow> (\<exists> p1 p2 t . path M q1 p1 \<and> path M q2 (p2@[t]) \<and> p_io p1 = butlast (p_io p) \<and> p_io (p2@[t]) = p_io p) \<and> (\<not>(\<exists> p1 . path M q1 p1 \<and> p_io p1 = p_io p))"
and   "(\<exists> s1' s2' . target p (initial (canonical_separator M q1 q2)) = Inl (s1',s2')) \<or> target p (initial (canonical_separator M q1 q2)) = Inr q1 \<or> target p (initial (canonical_separator M q1 q2)) = Inr q2"
proof -

  let ?P1 = "\<forall> s1' s2' . target p (initial (canonical_separator M q1 q2)) = Inl (s1',s2') \<longrightarrow> (\<exists> p1 p2 . path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = p_io p2 \<and> p_io p1 = p_io p \<and> target p1 q1 = s1' \<and> target p2 q2 = s2')"
  let ?P2 = "target p (initial (canonical_separator M q1 q2)) = Inr q1 \<longrightarrow> (\<exists> p1 p2 t . path M q1 (p1@[t]) \<and> path M q2 p2 \<and> p_io (p1@[t]) = p_io p \<and> p_io p2 = butlast (p_io p)) \<and> (\<not>(\<exists> p2 . path M q2 p2 \<and> p_io p2 = p_io p))"
  let ?P3 = "target p (initial (canonical_separator M q1 q2)) = Inr q2 \<longrightarrow> (\<exists> p1 p2 t . path M q1 p1 \<and> path M q2 (p2@[t]) \<and> p_io p1 = butlast (p_io p) \<and> p_io (p2@[t]) = p_io p) \<and> (\<not>(\<exists> p1 . path M q1 p1 \<and> p_io p1 = p_io p))"

  have "?P1 \<and> ?P2 \<and> ?P3"
  using assms proof (induction p rule: rev_induct) 
    case Nil 
    then show ?case unfolding canonical_separator_simps(1) product_simps(1) from_FSM_simps(1) target.simps visited_states.simps
      by auto       
  next
    case (snoc t p)
    then have "path ?C (initial ?C) p" and "t \<in> h ?C" and "t_source t = target p (initial ?C)"
      by auto


    let ?P1' = "(\<forall>s1' s2'. target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inl (s1', s2') \<longrightarrow> (\<exists>p1 p2. path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = p_io p2 \<and> p_io p1 = p_io (p @ [t]) \<and> target p1 q1 = s1' \<and> target p2 q2 = s2'))"
    let ?P2' = "(target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inr q1 \<longrightarrow> (\<exists>p1 p2 ta. path M q1 (p1 @ [ta]) \<and> path M q2 p2 \<and> p_io (p1 @ [ta]) = p_io (p @ [t]) \<and> p_io p2 = butlast (p_io (p @ [t]))) \<and> (\<nexists>p2. path M q2 p2 \<and> p_io p2 = p_io (p @ [t])))"
    let ?P3' = "(target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inr q2 \<longrightarrow> (\<exists>p1 p2 ta. path M q1 p1 \<and> path M q2 (p2 @ [ta]) \<and> p_io p1 = butlast (p_io (p @ [t])) \<and> p_io (p2 @ [ta]) = p_io (p @ [t])) \<and> (\<nexists>p1. path M q1 p1 \<and> p_io p1 = p_io (p @ [t])))"


    let ?P = "(product (from_FSM M q1) (from_FSM M q2))"
    
    obtain p' where "path ?P (initial ?P) p'"
              and   *:"p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'"
      using canonical_separator_path_from_shift[OF \<open>path ?C (initial ?C) p\<close> canonical_separator_path_split_target_isl[OF snoc.prems(1)]]
      by blast
  
    let ?pL = "(map (\<lambda>t. (fst (t_source t), t_input t, t_output t, fst (t_target t))) p')"
    let ?pR = "(map (\<lambda>t. (snd (t_source t), t_input t, t_output t, snd (t_target t))) p')"
  
    have "path ?P (q1,q2) p'"
      using \<open>path ?P (initial ?P) p'\<close> unfolding product_simps(1) from_FSM_simps(1) by assumption
  
    then have pL: "path (from_FSM M q1) q1 ?pL"
         and  pR: "path (from_FSM M q2) q2 ?pR"
         and  pN: "(\<exists>p1 p2.
                     path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
                     path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
                     target p1 (initial (from_FSM M q1)) = q1 \<and> target p2 (initial (from_FSM M q2)) = q2 \<and> p_io p1 = p_io p2)"
      using product_path[of "from_FSM M q1" "from_FSM M q2" q1 q2 p'] by auto


    have "p_io ?pL = p_io p" and "p_io ?pR = p_io p"
      using * by auto

    have pf1: "path (from_FSM M q1) (initial (from_FSM M q1)) ?pL"
      using pL unfolding from_FSM_simps(1) by auto
    have pf2: "path (from_FSM M q2) (initial (from_FSM M q2)) ?pR"
      using pR unfolding from_FSM_simps(1) by auto
    have pio: "p_io ?pL = p_io ?pR"
      by auto
    
    have "p_io (zip_path ?pL ?pR) = p_io ?pL"
      by (induction p'; auto)

    have zip1: "path ?P (initial ?P) (zip_path ?pL ?pR)"
    and  "target (zip_path ?pL ?pR) (initial ?P) = (target ?pL q1, target ?pR q2)"
      using product_path_from_paths[OF pf1 pf2 pio]
      unfolding from_FSM_simps(1) by simp+

    
      
    have "p_io (zip_path ?pL ?pR) = p_io p"
      using \<open>p_io ?pL = p_io p\<close> \<open>p_io (zip_path ?pL ?pR) = p_io ?pL\<close> by auto 
    have "observable ?P"
      using product_observable[OF from_FSM_observable[OF assms(4,2)] from_FSM_observable[OF assms(4,3)]] by assumption
    
    have "p_io p' = p_io p"
      using * by auto

    (* TODO: add product_observable_io_targets and sth like "io_targets P12 io = io_targets M1 io \<inter> io_targets M2 io *)




    
    obtain s1 s2 where "t_source t = Inl (s1,s2)"
      using canonical_separator_path_split_target_isl[OF snoc.prems(1)] 
      by (metis \<open>t_source t = target p (initial (canonical_separator M q1 q2))\<close> isl_def old.prod.exhaust)
  
    have "map t_target p = map (Inl o t_target) p'"
      using * by auto
    then have "target p (initial ?C) = Inl (target p' (q1,q2))"
      unfolding target.simps visited_states.simps canonical_separator_simps(1) product_simps(1) from_FSM_simps(1)
      by (simp add: last_map) 
    then have "target p' (q1,q2)= (s1,s2)"
      using \<open>t_source t = target p (initial ?C)\<close> \<open>t_source t = Inl (s1,s2)\<close>
      by auto 
      
    have "target ?pL q1 = s1" and "target ?pR q2 = s2"  
      using product_target_split[OF \<open>target p' (q1,q2)= (s1,s2)\<close>] by auto


    consider (a) "(\<exists>s1' s2'. t_target t = Inl (s1', s2'))" |
             (b) "t_target t = Inr q1" |
             (c) "t_target t = Inr q2"
      using canonical_separator_transition(4)[OF \<open>t \<in> h ?C\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>t_source t = Inl (s1,s2)\<close> \<open>observable M\<close>]
      by blast
    then show "?P1' \<and> ?P2' \<and> ?P3'" proof cases
      case a
      then obtain s1' s2' where "t_target t = Inl (s1',s2')"
        by blast

      let ?t1 = "(s1, t_input t, t_output t, s1')"
      let ?t2 = "(s2, t_input t, t_output t, s2')"

      have "?t1 \<in> h M" 
      and  "?t2 \<in> h M"
        using canonical_separator_transition(1)[OF \<open>t \<in> h ?C\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>t_source t = Inl (s1,s2)\<close> \<open>observable M\<close> \<open>t_target t = Inl (s1',s2')\<close>] 
        by auto

      have "target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inl (s1', s2')"
        using \<open>t_target t = Inl (s1',s2')\<close> by auto

      have "path M q1 (?pL@[?t1])"
        using path_append_last[OF from_FSM_path[OF \<open>q1 \<in> nodes M\<close> pL] \<open>?t1 \<in> h M\<close>] \<open>target ?pL q1 = s1\<close> by auto
      moreover have "path M q2 (?pR@[?t2])"
        using path_append_last[OF from_FSM_path[OF \<open>q2 \<in> nodes M\<close> pR] \<open>?t2 \<in> h M\<close>] \<open>target ?pR q2 = s2\<close> by auto
      moreover have "p_io (?pL@[?t1]) = p_io (?pR@[?t2])"
        by auto
      moreover have "p_io (?pL@[?t1]) = p_io (p@[t])"
        using \<open>p_io ?pL = p_io p\<close> by auto
      moreover have "target (?pL@[?t1]) q1 = s1'" and "target (?pR@[?t2]) q2 = s2'"
        by auto 
      ultimately have "path M q1 (?pL@[?t1]) \<and> path M q2 (?pR@[?t2]) \<and> p_io (?pL@[?t1]) = p_io (?pR@[?t2]) \<and> p_io (?pL@[?t1]) = p_io (p@[t]) \<and> target (?pL@[?t1]) q1 = s1' \<and> target (?pR@[?t2]) q2 = s2'"
        by presburger
      then have "(\<exists>p1 p2. path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = p_io p2 \<and> p_io p1 = p_io (p @ [t]) \<and> target p1 q1 = s1' \<and> target p2 q2 = s2')"
        by meson
      then have ?P1'
        using \<open>target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inl (s1', s2')\<close> by auto
      then show ?thesis using \<open>target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inl (s1', s2')\<close> 
        by auto
    next
      case b
      then have "target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inr q1"
        by auto

      have "(\<exists>t'\<in>set (wf_transitions M). t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
      and  "\<not> (\<exists>t'\<in>set (wf_transitions M). t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
        using canonical_separator_transition(2)[OF \<open>t \<in> h ?C\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>t_source t = Inl (s1,s2)\<close> \<open>observable M\<close> b] by blast+

      then obtain t' where "t' \<in> h M" and "t_source t' = s1" and "t_input t' = t_input t" and "t_output t' = t_output t"
        by blast

      have "path M q1 (?pL@[t'])"
        using path_append_last[OF from_FSM_path[OF \<open>q1 \<in> nodes M\<close> pL] \<open>t' \<in> h M\<close>] \<open>target ?pL q1 = s1\<close> \<open>t_source t' = s1\<close> by auto
      moreover have "p_io (?pL@[t']) = p_io (p@[t])"
        using \<open>p_io ?pL = p_io p\<close> \<open>t_input t' = t_input t\<close> \<open>t_output t' = t_output t\<close> by auto
      moreover have "p_io ?pR = butlast (p_io (p @ [t]))"
        using \<open>p_io ?pR = p_io p\<close> by auto
      ultimately have "path M q1 (?pL@[t']) \<and> path M q2 ?pR \<and> p_io (?pL@[t']) = p_io (p @ [t]) \<and> p_io ?pR = butlast (p_io (p @ [t]))"
        using from_FSM_path[OF \<open>q2 \<in> nodes M\<close> pR] by linarith
      then have "(\<exists>p1 p2 ta. path M q1 (p1 @ [ta]) \<and> path M q2 p2 \<and> p_io (p1 @ [ta]) = p_io (p @ [t]) \<and> p_io p2 = butlast (p_io (p @ [t])))"
        by meson
      
      
      moreover have "(\<nexists>p2. path M q2 p2 \<and> p_io p2 = p_io (p @ [t]))"
      proof 
        assume "\<exists>p2. path M q2 p2 \<and> p_io p2 = p_io (p @ [t])"
        then obtain p'' where "path M q2 p'' \<and> p_io p'' = p_io (p @ [t])"
          by blast
        then have "p'' \<noteq> []" by auto
        then obtain p2 t2 where "p'' = p2@[t2]"
          using rev_exhaust by blast
        then have "path M q2 (p2@[t2])" and "p_io (p2@[t2]) = p_io (p @ [t])"
          using \<open>path M q2 p'' \<and> p_io p'' = p_io (p @ [t])\<close> by auto
        then have "path M q2 p2" by auto


        then have pf2': "path (from_FSM M q2) (initial (from_FSM M q2)) p2"
          using from_FSM_path_initial[OF \<open>q2 \<in> nodes M\<close>, of p2] by simp
        have pio': "p_io ?pL = p_io p2"
          using \<open>p_io (?pL@[t']) = p_io (p@[t])\<close> \<open>p_io (p2@[t2]) = p_io (p @ [t])\<close> by auto

        have zip2: "path ?P (initial ?P) (zip_path ?pL p2)"
        and  "target (zip_path ?pL p2) (initial ?P) = (target ?pL q1, target p2 q2)"
          using product_path_from_paths[OF pf1 pf2' pio']
          unfolding from_FSM_simps(1) by simp+

        have "length p' = length p2"
          using \<open>p_io (p2@[t2]) = p_io (p @ [t])\<close> 
          by (metis (no_types, lifting) length_map pio') 
        then have "p_io (zip_path ?pL p2) = p_io p'"
          by (induction p' p2 rule: list_induct2; auto)
        then have "p_io (zip_path ?pL p2) = p_io p"
          using * by auto
        then have "p_io (zip_path ?pL ?pR) = p_io (zip_path ?pL p2)" 
          using \<open>p_io (zip_path ?pL ?pR) = p_io p\<close> by simp

        have "p_io ?pR = p_io p2"
          using \<open>p_io ?pL = p_io p2\<close> pio by auto 


        have l1: "length ?pL = length ?pR" by auto
        have l2: "length ?pR = length ?pL" by auto 
        have l3: "length ?pL = length p2" using \<open>length p' = length p2\<close> by auto
        
        have "p2 = ?pR"
          using zip_path_eq_right[OF l1 l2 l3 \<open>p_io ?pR = p_io p2\<close> observable_path_unique[OF \<open>observable ?P\<close> zip1 zip2 \<open>p_io (zip_path ?pL ?pR) = p_io (zip_path ?pL p2)\<close>]] by simp
        then have "target p2 q2 = s2"
          using \<open>target ?pR q2 = s2\<close> by auto
        then have "t2 \<in> h M" and "t_source t2 = s2"
          using \<open>path M q2 (p2@[t2])\<close> by auto
        moreover have "t_input t2 = t_input t \<and> t_output t2 = t_output t"
          using \<open>p_io (p2@[t2]) = p_io (p @ [t])\<close> by auto
        ultimately show "False"
          using \<open>\<not> (\<exists>t'\<in>set (wf_transitions M). t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)\<close> by blast
      qed

      ultimately have ?P2' 
        by blast
      moreover have ?P3' proof (cases "q1 = q2")
        case True
        then have "isl (t_target t)"
          using canonical_separator_targets_observable_eq(2)[OF \<open>observable M\<close> \<open>q1 \<in> nodes M\<close>, of t] \<open>t \<in> h ?C\<close> by auto
        then show ?thesis using \<open>t_target t = Inr q1\<close> by auto
      next
        case False
        then show ?thesis using \<open>t_target t = Inr q1\<close> by auto
      qed
      moreover have ?P1'
       using \<open>target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inr q1\<close> by auto
     ultimately show ?thesis
       by blast
    next
      case c
      then have "target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inr q2"
        by auto

      have "(\<exists>t'\<in>set (wf_transitions M). t_source t' = s2 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
      and  "\<not> (\<exists>t'\<in>set (wf_transitions M). t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
        using canonical_separator_transition(3)[OF \<open>t \<in> h ?C\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>t_source t = Inl (s1,s2)\<close> \<open>observable M\<close> c] by blast+

      then obtain t' where "t' \<in> h M" and "t_source t' = s2" and "t_input t' = t_input t" and "t_output t' = t_output t"
        by blast

      have "path M q2 (?pR@[t'])"
        using path_append_last[OF from_FSM_path[OF \<open>q2 \<in> nodes M\<close> pR] \<open>t' \<in> h M\<close>] \<open>target ?pR q2 = s2\<close> \<open>t_source t' = s2\<close> by auto
      moreover have "p_io (?pR@[t']) = p_io (p@[t])"
        using \<open>p_io ?pR = p_io p\<close> \<open>t_input t' = t_input t\<close> \<open>t_output t' = t_output t\<close> by auto
      moreover have "p_io ?pL = butlast (p_io (p @ [t]))"
        using \<open>p_io ?pL = p_io p\<close> by auto
      ultimately have "path M q2 (?pR@[t']) \<and> path M q1 ?pL \<and> p_io (?pR@[t']) = p_io (p @ [t]) \<and> p_io ?pL = butlast (p_io (p @ [t]))"
        using from_FSM_path[OF \<open>q1 \<in> nodes M\<close> pL] by linarith
      then have "(\<exists>p1 p2 ta. path M q1 p1 \<and> path M q2 (p2 @ [ta]) \<and> p_io p1 = butlast (p_io (p @ [t])) \<and> p_io (p2 @ [ta]) = p_io (p @ [t]))"
        by meson
      
      
      moreover have "(\<nexists>p1. path M q1 p1 \<and> p_io p1 = p_io (p @ [t]))"
      proof 
        assume "\<exists>p1. path M q1 p1 \<and> p_io p1 = p_io (p @ [t])"
        then obtain p'' where "path M q1 p'' \<and> p_io p'' = p_io (p @ [t])"
          by blast
        then have "p'' \<noteq> []" by auto
        then obtain p1 t1 where "p'' = p1@[t1]"
          using rev_exhaust by blast
        then have "path M q1 (p1@[t1])" and "p_io (p1@[t1]) = p_io (p @ [t])"
          using \<open>path M q1 p'' \<and> p_io p'' = p_io (p @ [t])\<close> by auto
        then have "path M q1 p1" by auto


        then have pf1': "path (from_FSM M q1) (initial (from_FSM M q1)) p1"
          using from_FSM_path_initial[OF \<open>q1 \<in> nodes M\<close>, of p1] by simp
        have pio': "p_io p1 = p_io ?pR"
          using \<open>p_io (?pR@[t']) = p_io (p@[t])\<close> \<open>p_io (p1@[t1]) = p_io (p @ [t])\<close> by auto

        have zip2: "path ?P (initial ?P) (zip_path p1 ?pR)"
          using product_path_from_paths[OF pf1' pf2 pio']
          unfolding from_FSM_simps(1) by simp

        have "length p' = length p1"
          using \<open>p_io (p1@[t1]) = p_io (p @ [t])\<close> 
          by (metis (no_types, lifting) length_map pio') 
        then have "p_io (zip_path p1 ?pR) = p_io p'"
          using \<open>p_io p1 = p_io ?pR\<close> by (induction p' p1 rule: list_induct2; auto)
        then have "p_io (zip_path p1 ?pR) = p_io p"
          using * by auto
        then have "p_io (zip_path ?pL ?pR) = p_io (zip_path p1 ?pR)" 
          using \<open>p_io (zip_path ?pL ?pR) = p_io p\<close> by simp

        
        have l1: "length ?pL = length ?pR" by auto
        have l2: "length ?pR = length p1" using \<open>length p' = length p1\<close> by auto
        have l3: "length p1 = length ?pR" using l2 by auto
        
        have "?pL = p1"
          using zip_path_eq_left[OF l1 l2 l3 observable_path_unique[OF \<open>observable ?P\<close> zip1 zip2 \<open>p_io (zip_path ?pL ?pR) = p_io (zip_path p1 ?pR)\<close>]] by simp
        then have "target p1 q1 = s1"
          using \<open>target ?pL q1 = s1\<close> by auto
        then have "t1 \<in> h M" and "t_source t1 = s1"
          using \<open>path M q1 (p1@[t1])\<close> by auto
        moreover have "t_input t1 = t_input t \<and> t_output t1 = t_output t"
          using \<open>p_io (p1@[t1]) = p_io (p @ [t])\<close> by auto
        ultimately show "False"
          using \<open>\<not> (\<exists>t'\<in>set (wf_transitions M). t_source t' = s1 \<and> t_input t' = t_input t \<and> t_output t' = t_output t)\<close> by blast
      qed

      ultimately have ?P3' 
        by blast
      moreover have ?P2' proof (cases "q1 = q2")
        case True
        then have "isl (t_target t)"
          using canonical_separator_targets_observable_eq(2)[OF \<open>observable M\<close> \<open>q1 \<in> nodes M\<close>, of t] \<open>t \<in> h ?C\<close> by auto
        then show ?thesis using \<open>t_target t = Inr q2\<close> by auto
      next
        case False
        then show ?thesis using \<open>t_target t = Inr q2\<close> by auto
      qed
      moreover have ?P1'
        using \<open>target (p @ [t]) (initial (canonical_separator M q1 q2)) = Inr q2\<close> by auto
      ultimately show ?thesis
        by blast
    qed 
  qed

  then show  "\<And> s1' s2' . target p (initial (canonical_separator M q1 q2)) = Inl (s1',s2') \<Longrightarrow> (\<exists> p1 p2 . path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = p_io p2 \<and> p_io p1 = p_io p \<and> target p1 q1 = s1' \<and> target p2 q2 = s2')"
       and   "target p (initial (canonical_separator M q1 q2)) = Inr q1 \<Longrightarrow> (\<exists> p1 p2 t . path M q1 (p1@[t]) \<and> path M q2 p2 \<and> p_io (p1@[t]) = p_io p \<and> p_io p2 = butlast (p_io p)) \<and> (\<not>(\<exists> p2 . path M q2 p2 \<and> p_io p2 = p_io p))"
       and   "target p (initial (canonical_separator M q1 q2)) = Inr q2 \<Longrightarrow> (\<exists> p1 p2 t . path M q1 p1 \<and> path M q2 (p2@[t]) \<and> p_io p1 = butlast (p_io p) \<and> p_io (p2@[t]) = p_io p) \<and> (\<not>(\<exists> p1 . path M q1 p1 \<and> p_io p1 = p_io p))"
    by blast+


  show   "(\<exists> s1' s2' . target p (initial (canonical_separator M q1 q2)) = Inl (s1',s2')) \<or> target p (initial (canonical_separator M q1 q2)) = Inr q1 \<or> target p (initial (canonical_separator M q1 q2)) = Inr q2"
    
    
  proof (cases p rule: rev_cases)
    case Nil
    then show ?thesis unfolding canonical_separator_simps(1) product_simps(1) from_FSM_simps(1) by auto
  next
    case (snoc p' t)
    then have "t \<in> h ?C" and "target p (initial (canonical_separator M q1 q2)) = t_target t"
      using assms(1) by auto
    then have "t \<in> set (transitions ?C)"
      by auto
    obtain s1 s2 where "t_source t = Inl (s1,s2)"
      using canonical_separator_t_source_isl[OF \<open>t \<in> set (transitions ?C)\<close>]
      by (metis sum.collapse(1) surjective_pairing) 
    show ?thesis
      using canonical_separator_transition(4)[OF \<open>t \<in> h ?C\<close> assms(2,3) \<open>t_source t = Inl (s1,s2)\<close> assms(4)] 
            \<open>target p (initial (canonical_separator M q1 q2)) = t_target t\<close>
      by simp 
  qed 
qed



(* does not assume observability of M (in contrast to the much stronger canonical_separator_path_initial) *)
lemma canonical_separator_path_initial_ex :
  assumes "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p" (is "path ?C (initial ?C) p")
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "(\<exists> p1 . path M q1 p1 \<and> p_io p1 = p_io p) \<or> (\<exists> p2 . path M q2 p2 \<and> p_io p2 = p_io p)"
and   "(\<exists> p1 p2 . path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = butlast (p_io p) \<and> p_io p2 = butlast (p_io p))"
proof -
  have "((\<exists> p1 . path M q1 p1 \<and> p_io p1 = p_io p) \<or> (\<exists> p2 . path M q2 p2 \<and> p_io p2 = p_io p))
         \<and> (\<exists> p1 p2 . path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = butlast (p_io p) \<and> p_io p2 = butlast (p_io p))"
  using assms proof (induction p rule: rev_induct) 
    case Nil
    then show ?case by auto
  next
    case (snoc t p)
    then have "path ?C (initial ?C) p" and "t \<in> h ?C" and "t_source t = target p (initial ?C)"
      by auto
  
    let ?P = "(product (from_FSM M q1) (from_FSM M q2))"
    
    obtain p' where "path ?P (initial ?P) p'"
              and   *:"p = map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p'"
      using canonical_separator_path_from_shift[OF \<open>path ?C (initial ?C) p\<close> canonical_separator_path_split_target_isl[OF snoc.prems(1)]]
      by blast
  
    let ?pL = "(map (\<lambda>t. (fst (t_source t), t_input t, t_output t, fst (t_target t))) p')"
    let ?pR = "(map (\<lambda>t. (snd (t_source t), t_input t, t_output t, snd (t_target t))) p')"
  
    have "path ?P (q1,q2) p'"
      using \<open>path ?P (initial ?P) p'\<close> unfolding product_simps(1) from_FSM_simps(1) by assumption
  
    then have pL: "path (from_FSM M q1) q1 ?pL"
         and  pR: "path (from_FSM M q2) q2 ?pR"
         and  pN: "(\<exists>p1 p2.
                     path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
                     path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
                     target p1 (initial (from_FSM M q1)) = q1 \<and> target p2 (initial (from_FSM M q2)) = q2 \<and> p_io p1 = p_io p2)"
      using product_path[of "from_FSM M q1" "from_FSM M q2" q1 q2 p'] by auto

    have "p_io ?pL = butlast (p_io (p@[t]))" and "p_io ?pR = butlast (p_io (p@[t]))"
      using * by auto
    then have "path M q1 ?pL \<and> path M q2 ?pR \<and> p_io ?pL = butlast (p_io (p@[t])) \<and> p_io ?pR = butlast (p_io (p@[t]))"
      using from_FSM_path[OF \<open>q1 \<in> nodes M\<close> pL] from_FSM_path[OF \<open>q2 \<in> nodes M\<close> pR] by auto
    then have "(\<exists>p1 p2. path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = butlast (p_io (p @ [t])) \<and> p_io p2 = butlast (p_io (p @ [t])))"
      by blast
    
    obtain s1 s2 where "t_source t = Inl (s1,s2)"
      using canonical_separator_path_split_target_isl[OF snoc.prems(1)] 
      by (metis \<open>t_source t = target p (initial (canonical_separator M q1 q2))\<close> isl_def old.prod.exhaust)
  
    have "map t_target p = map (Inl o t_target) p'"
      using * by auto
    then have "target p (initial ?C) = Inl (target p' (q1,q2))"
      unfolding target.simps visited_states.simps canonical_separator_simps(1) product_simps(1) from_FSM_simps(1)
      by (simp add: last_map) 
    then have "target p' (q1,q2)= (s1,s2)"
      using \<open>t_source t = target p (initial ?C)\<close> \<open>t_source t = Inl (s1,s2)\<close>
      by auto 
      
    have "target ?pL q1 = s1" and "target ?pR q2 = s2"  
      using product_target_split[OF \<open>target p' (q1,q2)= (s1,s2)\<close>] by auto
  
    consider (a) "(\<exists>t1\<in>set (wf_transitions M). t_source t1 = s1 \<and> t_input t1 = t_input t \<and> t_output t1 = t_output t)" |
             (b) "(\<exists>t2\<in>set (wf_transitions M). t_source t2 = s2 \<and> t_input t2 = t_input t \<and> t_output t2 = t_output t)"
      using canonical_separator_transition_ex[OF \<open>t \<in> h ?C\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>t_source t = Inl (s1,s2)\<close>] by blast
    then show ?case proof cases
      case a
      then obtain t1 where "t1 \<in> h M" and "t_source t1 = s1" and "t_input t1 = t_input t" and "t_output t1 = t_output t" 
        by blast
  
      have "t_source t1 = target ?pL q1"
        using \<open>target ?pL q1 = s1\<close> \<open>t_source t1 = s1\<close> by auto
      then have "path M q1 (?pL@[t1])"
        using pL \<open>t1 \<in> h M\<close>
        by (meson from_FSM_path path_append_last snoc.prems(2))
      moreover have "p_io (?pL@[t1]) = p_io (p@[t])"
        using * \<open>t_input t1 = t_input t\<close> \<open>t_output t1 = t_output t\<close> by auto
      ultimately show ?thesis
        using \<open>(\<exists>p1 p2. path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = butlast (p_io (p @ [t])) \<and> p_io p2 = butlast (p_io (p @ [t])))\<close>
        by meson
    next
      case b
      then obtain t2 where "t2 \<in> h M" and "t_source t2 = s2" and "t_input t2 = t_input t" and "t_output t2 = t_output t" 
        by blast
  
      have "t_source t2 = target ?pR q2"
        using \<open>target ?pR q2 = s2\<close> \<open>t_source t2 = s2\<close> by auto
      then have "path M q2 (?pR@[t2])"
        using pR \<open>t2 \<in> h M\<close>
        by (meson from_FSM_path path_append_last snoc.prems(3))
      moreover have "p_io (?pR@[t2]) = p_io (p@[t])"
        using * \<open>t_input t2 = t_input t\<close> \<open>t_output t2 = t_output t\<close> by auto
      ultimately show ?thesis
        using \<open>(\<exists>p1 p2. path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = butlast (p_io (p @ [t])) \<and> p_io p2 = butlast (p_io (p @ [t])))\<close>
        by meson
    qed
  qed
  then show "(\<exists> p1 . path M q1 p1 \<and> p_io p1 = p_io p) \<or> (\<exists> p2 . path M q2 p2 \<and> p_io p2 = p_io p)"
       and  "(\<exists> p1 p2 . path M q1 p1 \<and> path M q2 p2 \<and> p_io p1 = butlast (p_io p) \<and> p_io p2 = butlast (p_io p))"
    by blast+
qed



lemma canonical_separator_language :
  assumes "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "L (canonical_separator M q1 q2) \<subseteq> L (from_FSM M q1) \<union> L (from_FSM M q2)" (is "L ?C \<subseteq> L ?M1 \<union> L ?M2")
proof 
  fix io assume "io \<in> L (canonical_separator M q1 q2)"
  then obtain p where *: "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p" and **: "p_io p = io"
    by auto
  
  show "io \<in> L (from_FSM M q1) \<union> L (from_FSM M q2)"
    using canonical_separator_path_initial_ex[OF * assms] unfolding ** 
    using from_FSM_path_initial[OF assms(1)] from_FSM_path_initial[OF assms(2)]  
    unfolding LS.simps by blast
qed



lemma canonical_separator_language_prefix :
  assumes "io@[xy] \<in> L (canonical_separator M q1 q2)"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "observable M"
shows "io \<in> LS M q1"
and   "io \<in> LS M q2"
proof -
  let ?C = "(canonical_separator M q1 q2)"
  obtain p where "path ?C (initial ?C) p" and "p_io p = io@[xy]"
    using assms(1) by auto

  (* TODO: find out how to write case own case rules *)
  consider (a) "(\<exists>s1' s2'. target p (initial (canonical_separator M q1 q2)) = Inl (s1', s2'))" |
           (b) "target p (initial (canonical_separator M q1 q2)) = Inr q1" | 
           (c) "target p (initial (canonical_separator M q1 q2)) = Inr q2"
    using canonical_separator_path_initial(4)[OF \<open>path ?C (initial ?C) p\<close> assms(2,3,4)] by blast
  then have "io \<in> LS M q1 \<and> io \<in> LS M q2"
  proof cases
    case a
    then obtain s1 s2 where *: "target p (initial (canonical_separator M q1 q2)) = Inl (s1, s2)"
      by blast
    show ?thesis using canonical_separator_path_initial(1)[OF \<open>path ?C (initial ?C) p\<close> assms(2,3,4) *] language_prefix
      by (metis (mono_tags, lifting) LS.simps \<open>p_io p = io @ [xy]\<close> mem_Collect_eq)
  next
    case b
    show ?thesis using canonical_separator_path_initial(2)[OF \<open>path ?C (initial ?C) p\<close> assms(2,3,4) b]
      using \<open>p_io p = io @ [xy]\<close> by fastforce      
  next
    case c
    show ?thesis using canonical_separator_path_initial(3)[OF \<open>path ?C (initial ?C) p\<close> assms(2,3,4) c]
      using \<open>p_io p = io @ [xy]\<close> by fastforce
  qed
  then show "io \<in> LS M q1" and   "io \<in> LS M q2"
    by auto
qed







lemma canonical_separator_distinguishing_transitions_left_h :
  assumes "t \<in> set (distinguishing_transitions_left M q1 q2)"
  shows "t \<in> h (canonical_separator M q1 q2)" (is "t \<in> h ?C")
proof -
  have x1: "t \<in> set (transitions ?C)"
    unfolding canonical_separator_simps using assms by auto

  obtain qqt where *: "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
             and   **: "t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1)"
             and   ***: "t_source (snd qqt) = fst (fst qqt)"
             and   ****: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = snd (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using distinguishing_transitions_left_underlying_data[OF assms] by blast

  let ?qq = "fst qqt"
  let ?t  = "snd qqt"
  let ?P  = "(product (from_FSM M q1) (from_FSM M q2))"

  have "?t \<in> h M" and "?qq \<in> nodes ?P"
    using * unfolding concat_pair_set nodes_code by blast+

  then have x2: "t_input t \<in> set (inputs ?C)" and x3: "t_output t \<in> set (outputs ?C)"
    unfolding canonical_separator_simps ** by auto

  obtain pp where "path ?P (initial ?P) pp" and "target pp (initial ?P) = ?qq"
    using path_to_node[OF \<open>?qq \<in> nodes ?P\<close>] by auto

  let ?pc = "map shift_Inl pp"
  have pt1: "path ?C (initial ?C) ?pc"
    using \<open>path ?P (initial ?P) pp\<close> unfolding canonical_separator_path_shift by assumption
  have pt2: "target ?pc (initial ?C) = Inl ?qq"
    using \<open>target pp (initial ?P) = ?qq\<close> unfolding canonical_separator_simps product_simps from_FSM_simps by (induction pp; auto)
  
  have "t_source t \<in> nodes ?C"
    unfolding ** fst_conv snd_conv using path_target_is_node[OF pt1] unfolding pt2 by assumption

  then show ?thesis
    using x1 x2 x3 by auto
qed


lemma canonical_separator_distinguishing_transitions_right_h :
  assumes "t \<in> set (distinguishing_transitions_right M q1 q2)"
  shows "t \<in> h (canonical_separator M q1 q2)" (is "t \<in> h ?C")
proof -
  have x1: "t \<in> set (transitions ?C)"
    unfolding canonical_separator_simps using assms by auto

  obtain qqt where *: "qqt \<in> set (concat
                                (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
             and   **: "t = (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2)"
             and   ***: "t_source (snd qqt) = snd (fst qqt)"
             and   ****: "\<not> (\<exists>t'\<in>set (transitions M).
                            t_source t' = fst (fst qqt) \<and>
                            t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
    using distinguishing_transitions_right_underlying_data[OF assms] by blast

  let ?qq = "fst qqt"
  let ?t  = "snd qqt"
  let ?P  = "(product (from_FSM M q1) (from_FSM M q2))"

  have "?t \<in> h M" and "?qq \<in> nodes ?P"
    using * unfolding concat_pair_set nodes_code by blast+

  then have x2: "t_input t \<in> set (inputs ?C)" and x3: "t_output t \<in> set (outputs ?C)"
    unfolding canonical_separator_simps ** by auto

  obtain pp where "path ?P (initial ?P) pp" and "target pp (initial ?P) = ?qq"
    using path_to_node[OF \<open>?qq \<in> nodes ?P\<close>] by auto

  let ?pc = "map shift_Inl pp"
  have pt1: "path ?C (initial ?C) ?pc"
    using \<open>path ?P (initial ?P) pp\<close> unfolding canonical_separator_path_shift by assumption
  have pt2: "target ?pc (initial ?C) = Inl ?qq"
    using \<open>target pp (initial ?P) = ?qq\<close> unfolding canonical_separator_simps product_simps from_FSM_simps by (induction pp; auto)
  
  have "t_source t \<in> nodes ?C"
    unfolding ** fst_conv snd_conv using path_target_is_node[OF pt1] unfolding pt2 by assumption

  then show ?thesis
    using x1 x2 x3 by auto
qed



(*TODO: add _right version *)
lemma canonical_separator_io_from_prefix_left :
  assumes "io @ [io1] \<in> LS M q1"
  and     "io \<in> LS M q2"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "observable M"
shows "io @ [io1] \<in> L (canonical_separator M q1 q2)"
proof -
  let ?C = "canonical_separator M q1 q2"

  obtain p1 where "path M q1 p1" and "p_io p1 = io @ [io1]"
    using \<open>io @ [io1] \<in> LS M q1\<close> by auto
  then have "p1 \<noteq> []"
    by auto
  then obtain pL tL where "p1 = pL @ [tL]"
    using rev_exhaust by blast
  then have "path M q1 (pL@[tL])" and "path M q1 pL" and "p_io pL = io" and "tL \<in> h M" and "t_input tL = fst io1" and "t_output tL = snd io1" and "p_io (pL@[tL]) = io @ [io1]"
    using \<open>path M q1 p1\<close> \<open>p_io p1 = io @ [io1]\<close> by auto
  then have pLf: "path (from_FSM M q1) (initial (from_FSM M q1)) pL" and pLf': "path (from_FSM M q1) (initial (from_FSM M q1)) (pL@[tL])"
    using from_FSM_path_initial[OF \<open>q1 \<in> nodes M\<close>] by auto

  obtain pR where "path M q2 pR" and "p_io pR = io"
    using \<open>io \<in> LS M q2\<close> by auto
  then have pRf: "path (from_FSM M q2) (initial (from_FSM M q2)) pR"
    using from_FSM_path_initial[OF \<open>q2 \<in> nodes M\<close>] by auto

  have "p_io pL = p_io pR"
    using \<open>p_io pL = io\<close> \<open>p_io pR = io\<close> by auto

  let ?pLR = "zip_path pL pR"
  let ?pCLR = "map shift_Inl ?pLR"
  let ?P = "product (from_FSM M q1) (from_FSM M q2)"

  have "path ?P (initial ?P) ?pLR"
  and  "target ?pLR (initial ?P) = (target pL q1, target pR q2)"
    using product_path_from_paths[OF pLf pRf \<open>p_io pL = p_io pR\<close>]
    unfolding from_FSM_simps(1) by linarith+

  have "path ?C (initial ?C) ?pCLR"
    using canonical_separator_path_shift[of M q1 q2 ?pLR] \<open>path ?P (initial ?P) ?pLR\<close> by simp 
  

  have "isl (target ?pCLR (initial ?C))" 
    unfolding canonical_separator_simps(1) product_simps(1) from_FSM_simps target.simps visited_states.simps by (cases ?pLR rule: rev_cases; auto)
  then obtain s1 s2 where "target ?pCLR (initial ?C) = Inl (s1,s2)"
    by (metis (no_types, lifting) \<open>path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) (map (\<lambda>t. ((t_source (fst t), t_source (snd t)), t_input (fst t), t_output (fst t), t_target (fst t), t_target (snd t))) (zip pL pR)))\<close> assms(3) assms(4) assms(5) canonical_separator_path_initial(4) sum.discI(2))
  then have "Inl (s1,s2) \<in> nodes ?C"
    using path_target_is_node[OF \<open>path ?C (initial ?C) ?pCLR\<close>] by simp
  then have "(s1,s2) \<in> nodes ?P"
    using canonical_separator_nodes by force

  have "target ?pLR (initial ?P) = (s1,s2)"
    using \<open>target ?pCLR (initial ?C) = Inl (s1,s2)\<close> unfolding canonical_separator_simps(1) product_simps(1) from_FSM_simps target.simps visited_states.simps by (cases ?pLR rule: rev_cases; auto)
  then have "target pL q1 = s1" and "target pR q2 = s2"
    using \<open>target ?pLR (initial ?P) = (target pL q1, target pR q2)\<close> by auto
  then have "t_source tL = s1"
    using \<open>path M q1 (pL@[tL])\<close> by auto



  show ?thesis proof (cases "\<exists> tR \<in> set (transitions M) . t_source tR = target pR q2 \<and> t_input tR = t_input tL \<and> t_output tR = t_output tL")
    case True
    then obtain tR where "tR \<in> set (transitions M)" and "t_source tR = target pR q2" and "t_input tR = t_input tL" and "t_output tR = t_output tL"
      by blast
    
    have "t_source tR \<in> nodes M"
      unfolding \<open>t_source tR = target pR q2\<close> \<open>target pR q2 = s2\<close> 
      using \<open>(s1,s2) \<in> nodes ?P\<close> product_nodes from_FSM_nodes[OF \<open>q2 \<in> nodes M\<close>] by blast

    then have "tR \<in> h M"
      using \<open>tR \<in> set (transitions M)\<close> \<open>t_input tR = t_input tL\<close> \<open>t_output tR = t_output tL\<close> \<open>tL \<in> h M\<close> by auto

    then have "path M q2 (pR@[tR])" 
      using \<open>path M q2 pR\<close> \<open>t_source tR = target pR q2\<close> path_append_last by metis
    then have pRf': "path (from_FSM M q2) (initial (from_FSM M q2)) (pR@[tR])"
      using from_FSM_path_initial[OF \<open>q2 \<in> nodes M\<close>] by auto

    
    let ?PP = "(zip_path (pL@[tL]) (pR@[tR]))"
    let ?PC = "map shift_Inl ?PP"

    have "length pL = length pR"
      using \<open>p_io pL = p_io pR\<close> map_eq_imp_length_eq by blast
    moreover have "p_io (pL@[tL]) = p_io (pR@[tR])"
      using \<open>p_io pR = io\<close> \<open>t_input tL = fst io1\<close> \<open>t_output tL = snd io1\<close> \<open>t_input tR = t_input tL\<close> \<open>t_output tR = t_output tL\<close> \<open>p_io (pL@[tL]) = io@[io1]\<close> by auto
    ultimately have "p_io ?PP = p_io (pL@[tL])"
      by (induction pL pR rule: list_induct2; auto)

    have "p_io ?PC = p_io ?PP"
      by auto
       
    
    have "path ?P (initial ?P) ?PP"
      using product_path_from_paths(1)[OF pLf' pRf' \<open>p_io (pL@[tL]) = p_io (pR@[tR])\<close>] by assumption

    then have "path ?C (initial ?C) ?PC"
      using canonical_separator_path_shift[of M q1 q2 ?PP] by simp
    
    moreover have "p_io ?PC = io@[io1]"
      using \<open>p_io (pL@[tL]) = io@[io1]\<close>  \<open>p_io ?PP = p_io (pL@[tL])\<close>  \<open>p_io ?PC = p_io ?PP\<close> by simp
    ultimately have "\<exists> p . path ?C (initial ?C) p \<and> p_io p = io@[io1]"
      by blast
    then show ?thesis unfolding LS.simps by force
  next
    case False

    have f1: "((s1,s2),tL) \<in> set (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
      using \<open>(s1,s2) \<in> nodes ?P\<close> \<open>tL \<in> h M\<close> concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] unfolding nodes_code 
      by (metis (no_types, lifting) fst_conv mem_Collect_eq snd_conv)
    have f2: "(\<lambda> qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) ((s1,s2),tL)"
    proof 
      show "t_source (snd ((s1, s2), tL)) = fst (fst ((s1, s2), tL))"
        using \<open>t_source tL = s1\<close> by auto 
      show "\<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst ((s1, s2), tL)) \<and> t_input t' = t_input (snd ((s1, s2), tL)) \<and> t_output t' = t_output (snd ((s1, s2), tL)))"
        using False unfolding fst_conv snd_conv \<open>target pR q2 = s2\<close> by assumption
    qed
    
    have m1: "((s1,s2),tL) \<in> set (filter (\<lambda> qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                                                (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
      using filter_list_set[OF f1, of "(\<lambda> qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))", OF f2]
      by assumption


    (*thm canonical_separator_path_initial(1)[OF \<open>path ?C (initial ?C) ?pCLR\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> \<open>target ?pCLR (initial ?C) = Inl (s1,s2)\<close>]*)

    let ?t = "(Inl (s1,s2), t_input tL, t_output tL, Inr q1)"
    have "?t \<in> set (distinguishing_transitions_left M q1 q2)"
      using map_set[OF m1, of " (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))"] 
      unfolding distinguishing_transitions_left_def fst_conv snd_conv by assumption
    then have "?t \<in> h ?C" 
      using canonical_separator_distinguishing_transitions_left_h by metis
    then have "path ?C (initial ?C) (?pCLR@[?t])"
      using \<open>path ?C (initial ?C) ?pCLR\<close> \<open>target ?pCLR (initial ?C) = Inl (s1,s2)\<close> 
      by (simp add: path_append_last)

    have "length pL = length pR"
      using \<open>p_io pL = p_io pR\<close> 
      using map_eq_imp_length_eq by blast
    then have "p_io ?pCLR = p_io pL" 
      by (induction pL pR rule: list_induct2; auto)
    then have "p_io (?pCLR@[?t]) = io @ [io1]"
      using \<open>p_io pL = io\<close> \<open>t_input tL = fst io1\<close> \<open>t_output tL = snd io1\<close>
      by auto

    then have "\<exists> p . path ?C (initial ?C) p \<and> p_io p = io@[io1]"
      using \<open>path ?C (initial ?C) (?pCLR@[?t])\<close> by meson
    then show ?thesis 
      unfolding LS.simps by force
  qed
qed


lemma state_separator_language_intersections_nonempty :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "q1 \<noteq> q2"
shows "\<exists> io . io \<in> (L A \<inter> LS M q1) - LS M q2" and "\<exists> io . io \<in> (L A \<inter> LS M q2) - LS M q1"
proof -
  have "Inr q1 \<in> nodes A"
    using is_state_separator_from_canonical_separator_simps(6)[OF assms(1)] by assumption
  then obtain p where "path A (initial A) p" and "target p (initial A) = Inr q1"
    using path_to_node by metis
  then have "p_io p \<in> LS M q1 - LS M q2"
    using canonical_separator_maximal_path_distinguishes_left[OF assms(1) _ _ assms(2,3,4,5)] by blast
  moreover have "p_io p \<in> L A"
    using \<open>path A (initial A) p\<close> by auto
  ultimately show "\<exists> io . io \<in> (L A \<inter> LS M q1) - LS M q2" by blast

  have "Inr q2 \<in> nodes A"
    using is_state_separator_from_canonical_separator_simps(7)[OF assms(1)] by assumption
  then obtain p' where "path A (initial A) p'" and "target p' (initial A) = Inr q2"
    using path_to_node by metis
  then have "p_io p' \<in> LS M q2 - LS M q1"
    using canonical_separator_maximal_path_distinguishes_right[OF assms(1) _ _ assms(2,3,4,5)] by blast
  moreover have "p_io p' \<in> L A"
    using \<open>path A (initial A) p'\<close> by auto
  ultimately show "\<exists> io . io \<in> (L A \<inter> LS M q2) - LS M q1" by blast
qed





lemma state_separator_language_inclusion :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "L A \<subseteq> LS M q1 \<union> LS M q2"
  using canonical_separator_language[OF assms(2,3)]
  using submachine_language[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)]] 
  unfolding from_FSM_language[OF assms(2)] from_FSM_language[OF assms(3)] by blast


lemma state_separator_from_canonical_separator_targets_left_inclusion :
  assumes "observable T" 
  and     "observable M"
  and     "t1 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "path A (initial A) p"
  and     "p_io p \<in> LS M q1"
shows "target p (initial A) \<noteq> Inr q2"
and   "target p (initial A) = Inr q1 \<or> isl (target p (initial A))"
proof -

  let ?C = "canonical_separator M q1 q2"
  have c_path: "\<And> p . path A (initial A) p \<Longrightarrow> path ?C (initial ?C) p"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] submachine_path_initial by metis
  have "path ?C (initial ?C) p"
    using assms(8) c_path by auto

  show "target p (initial A) \<noteq> Inr q2"
  proof 
    assume "target p (initial A) = Inr q2"
    then have "target p (initial ?C) = Inr q2"
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] by auto

    have "(\<nexists>p1. path M q1 p1 \<and> p_io p1 = p_io p)"
      using canonical_separator_path_initial(3)[OF \<open>path ?C (initial ?C) p\<close> assms(4,5,2) \<open>target p (initial ?C) = Inr q2\<close>] by blast
    then have "p_io p \<notin> LS M q1"
      unfolding LS.simps by force
    then show "False"
      using \<open>p_io p \<in> LS M q1\<close> by blast
  qed

  then have "target p (initial ?C) \<noteq> Inr q2"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] unfolding is_submachine.simps by simp
  then have "target p (initial ?C) = Inr q1 \<or> isl (target p (initial ?C))"
  proof (cases p rule: rev_cases)
    case Nil
    then show ?thesis unfolding canonical_separator_simps target.simps visited_states.simps by simp
  next
    case (snoc ys y)
    then show ?thesis using canonical_separator_target_possibilities[OF _ assms(4,5)] 
      by (metis \<open>path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p\<close> \<open>target p (initial (canonical_separator M q1 q2)) \<noteq> Inr q2\<close> assms(2) assms(4) assms(5) canonical_separator_path_initial(4) isl_def)
  qed
  then show "target p (initial A) = Inr q1 \<or> isl (target p (initial A))"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] unfolding is_submachine.simps by simp
qed


lemma state_separator_from_canonical_separator_targets_right_inclusion :
  assumes "observable T" 
  and     "observable M"
  and     "t1 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "path A (initial A) p"
  and     "p_io p \<in> LS M q2"
shows "target p (initial A) \<noteq> Inr q1"
and   "target p (initial A) = Inr q2 \<or> isl (target p (initial A))"
proof -

  let ?C = "canonical_separator M q1 q2"
  have c_path: "\<And> p . path A (initial A) p \<Longrightarrow> path ?C (initial ?C) p"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] submachine_path_initial by metis
  have "path ?C (initial ?C) p"
    using assms(8) c_path by auto

  show "target p (initial A) \<noteq> Inr q1"
  proof 
    assume "target p (initial A) = Inr q1"
    then have "target p (initial ?C) = Inr q1"
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] by auto

    have "(\<nexists>p1. path M q2 p1 \<and> p_io p1 = p_io p)"
      using canonical_separator_path_initial(2)[OF \<open>path ?C (initial ?C) p\<close> assms(4,5,2) \<open>target p (initial ?C) = Inr q1\<close>] by blast
    then have "p_io p \<notin> LS M q2"
      unfolding LS.simps by force
    then show "False"
      using \<open>p_io p \<in> LS M q2\<close> by blast
  qed

  then have "target p (initial ?C) \<noteq> Inr q1"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] unfolding is_submachine.simps by simp
  then have "target p (initial ?C) = Inr q2 \<or> isl (target p (initial ?C))"
  proof (cases p rule: rev_cases)
    case Nil
    then show ?thesis unfolding canonical_separator_simps target.simps visited_states.simps by simp
  next
    case (snoc ys y)
    then show ?thesis using canonical_separator_target_possibilities[OF _ assms(4,5)] 
      by (metis \<open>path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p\<close> \<open>target p (initial (canonical_separator M q1 q2)) \<noteq> Inr q1\<close> assms(2) assms(4) assms(5) canonical_separator_path_initial(4) isl_def)
  qed
  then show "target p (initial A) = Inr q2 \<or> isl (target p (initial A))"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] unfolding is_submachine.simps by simp
qed



subsection \<open>Calculating State Separators\<close>

fun calculate_state_separator_from_canonical_separator_naive :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) FSM option" where
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






subsection \<open>Sufficient Condition to Induce a State Separator\<close>


definition induces_state_separator :: "'a FSM \<Rightarrow> ('a \<times> 'a) FSM \<Rightarrow> bool" where
  "induces_state_separator M S = (
    
    is_submachine S (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))
    \<and> single_input S
    \<and> acyclic S
    \<and> (\<forall> qq \<in> nodes S . deadlock_state S qq \<longrightarrow> (\<exists> x \<in> set (inputs M) . \<not> (\<exists> t1 \<in> h M . \<exists> t2 \<in> h M . t_source t1 = fst qq \<and> t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)) )
    \<and> retains_outputs_for_states_and_inputs (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))) S
)"

(* restriction to a given product machine *)
definition induces_state_separator_for_prod :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> ('a \<times> 'a) FSM \<Rightarrow> bool" where
  "induces_state_separator_for_prod M q1 q2 S = (
    is_submachine S (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))
    \<and> single_input S
    \<and> acyclic S
    \<and> (\<forall> qq \<in> nodes S . deadlock_state S qq \<longrightarrow> (\<exists> x \<in> set (inputs M) . \<not> (\<exists> t1 \<in> h M . \<exists> t2 \<in> h M . t_source t1 = fst qq \<and> t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)) )
    \<and> retains_outputs_for_states_and_inputs (product (from_FSM M q1) (from_FSM M q2)) S
)"

definition choose_state_separator_deadlock_input :: "'a FSM \<Rightarrow> ('a \<times> 'a) FSM \<Rightarrow> ('a \<times> 'a) \<Rightarrow> Input option" where
  "choose_state_separator_deadlock_input M S qq = (if (qq \<in> nodes S \<and> deadlock_state S qq) 
    then (find (\<lambda> x . \<not> (\<exists> t1 \<in> h M . \<exists> t2 \<in> h M . t_source t1 = fst qq \<and> t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)) (inputs M))
    else None)"




definition state_separator_from_product_submachine :: "'a FSM \<Rightarrow> ('a \<times> 'a) FSM \<Rightarrow> (('a \<times> 'a) + 'a) FSM" where
  "state_separator_from_product_submachine M S =
    \<lparr> initial = Inl (initial S),
      inputs = inputs M,
      outputs = outputs M,
      transitions = (let
                        t_old = (map shift_Inl (wf_transitions S));
                    t_left = (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))
                                   (filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                           (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                        (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))));
                    t_right = (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))
                                     (filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                             (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                          (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))))
        in (t_old 
            @ t_left 
            @ t_right 
            @ (filter (\<lambda>t . t \<notin> set t_old \<union> set t_left \<union> set t_right \<and>
                              (\<exists> t' \<in> set t_old . t_source t = t_source t' \<and> t_input t = t_input t'))
                       (distinguishing_transitions_left M (fst (initial S)) (snd (initial S))))     
            @ (filter (\<lambda>t . t \<notin> set t_old \<union> set t_left \<union> set t_right \<and>
                              (\<exists> t' \<in> set t_old . t_source t = t_source t' \<and> t_input t = t_input t'))
                       (distinguishing_transitions_right M (fst (initial S)) (snd (initial S)))))), 
                                        
      \<dots> = more M \<rparr>"


(* TODO: check *)
declare from_FSM.simps[simp del]
declare product.simps[simp del]
declare from_FSM_simps[simp del]
declare product_simps[simp del]

lemma state_separator_from_induces_state_separator :
  fixes M :: "'a FSM"
  assumes "induces_state_separator M S"
  and "fst (initial S) \<in> nodes M"
  and "snd (initial S) \<in> nodes M"
  and "fst (initial S) \<noteq> snd (initial S)"
  and "completely_specified M"
  shows "is_state_separator_from_canonical_separator
            (canonical_separator M (fst (initial S)) (snd (initial S)))
            (fst (initial S))
            (snd (initial S))
            (state_separator_from_product_submachine M S)"

proof -

  let ?q1 = "fst (initial S)"
  let ?q2 = "snd (initial S)"
  let ?CSep = "canonical_separator M ?q1 ?q2"
  let ?SSep = "state_separator_from_product_submachine M S"
  let ?PM = "(product (from_FSM M ?q1) (from_FSM M ?q2))"


  
  obtain SSep where ssep_var: "SSep = ?SSep" by blast
  obtain CSep where csep_var: "CSep = ?CSep" by blast

  have "is_submachine S ?PM"
   and "single_input S"
   and "acyclic S"
   and dl: "\<And> qq . qq \<in> nodes S \<Longrightarrow>
          deadlock_state S qq \<Longrightarrow>
          (\<exists>x\<in>set (inputs M).
              \<not> (\<exists>t1\<in>set (wf_transitions M).
                     \<exists>t2\<in>set (wf_transitions M).
                        t_source t1 = fst qq \<and>
                        t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))"
   and "retains_outputs_for_states_and_inputs ?PM S"
    using assms unfolding induces_state_separator_def by blast+

  have "initial S = initial ?PM"
       "inputs S = inputs ?PM"
       "outputs S = outputs ?PM"
       "h S \<subseteq> h ?PM"
    using \<open>is_submachine S ?PM\<close> unfolding is_submachine.simps by blast+

  have "set (map shift_Inl (wf_transitions S)) \<subseteq> set (transitions ?SSep)"
    unfolding state_separator_from_product_submachine_def
    by (metis list_prefix_subset select_convs(4)) 
  moreover have "set (map shift_Inl (wf_transitions S)) \<subseteq> set (map shift_Inl (wf_transitions ?PM))"
    using \<open>h S \<subseteq> h ?PM\<close> by auto
  moreover have "set (map shift_Inl (wf_transitions ?PM)) \<subseteq> set (transitions ?CSep)"
    unfolding canonical_separator_def
    by (metis canonical_separator_product_transitions_subset canonical_separator_simps(4) select_convs(4))
  ultimately have subset_shift: "set (map shift_Inl (wf_transitions S)) \<subseteq> set (transitions ?CSep)"
    by blast


  have subset_left: "set (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))
                           (filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                   (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))))
       \<subseteq> set (distinguishing_transitions_left M ?q1 ?q2)"
  proof -
    have *: "\<And> qq t . qq \<in> nodes ?PM \<Longrightarrow> t \<in> h M \<Longrightarrow> t_source t = fst qq \<Longrightarrow> choose_state_separator_deadlock_input M S qq = Some (t_input t) 
            \<Longrightarrow> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd qq \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
    proof -
      fix qq t assume "qq \<in> nodes ?PM" and "t \<in> h M" and "t_source t = fst qq" and "choose_state_separator_deadlock_input M S qq = Some (t_input t)"


      have "qq \<in> nodes S" and "deadlock_state S qq" and f: "find
         (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                     \<exists>t2\<in>set (wf_transitions M).
                        t_source t1 = fst qq \<and>
                        t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
         (inputs M) = Some (t_input t)"
        using \<open>choose_state_separator_deadlock_input M S qq = Some (t_input t)\<close> unfolding choose_state_separator_deadlock_input_def
        
        by (meson option.distinct(1))+

      have "qq \<in> nodes S" and "deadlock_state S qq" and f: "find
         (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                     \<exists>t2\<in>set (wf_transitions M).
                        t_source t1 = fst qq \<and>
                        t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
         (inputs M) = Some (t_input t)"
        using \<open>choose_state_separator_deadlock_input M S qq = Some (t_input t)\<close> unfolding choose_state_separator_deadlock_input_def
        
        by (meson option.distinct(1))+
      have "\<not> (\<exists>t1\<in>set (wf_transitions M).
                     \<exists>t2\<in>set (wf_transitions M).
                        t_source t1 = fst qq \<and>
                        t_source t2 = snd qq \<and> t_input t1 = t_input t \<and> t_input t2 = t_input t \<and> t_output t1 = t_output t2)"
        using find_condition[OF f] by blast
      then have "\<not> (\<exists>t2\<in>set (wf_transitions M).
                        t_source t2 = snd qq \<and> t_input t2 = t_input t \<and> t_output t = t_output t2)"
        using \<open>t \<in> h M\<close> \<open>t_source t = fst qq\<close> by blast
      moreover have "\<And> t' . t' \<in> set (transitions M) \<Longrightarrow> t_source t' = snd qq \<Longrightarrow> t_input t' = t_input t \<Longrightarrow> t_output t' = t_output t\<Longrightarrow> t' \<in> h M"
      proof -
        fix t' assume "t' \<in> set (transitions M)" and "t_source t' = snd qq" and "t_input t' = t_input t" and "t_output t' = t_output t"        

        have "snd qq \<in> nodes M"
          using \<open>qq \<in> nodes ?PM\<close>  product_nodes[of "from_FSM M ?q1" "from_FSM M ?q2"] from_FSM_nodes[OF assms(3)] by force
        then have "t_source t' \<in> nodes M"
          using \<open>t_source t' = snd qq\<close> by auto
        then show "t' \<in> h M"
          using \<open>t_input t' = t_input t\<close> \<open>t_output t' = t_output t\<close> \<open>t \<in> h M\<close>
          by (simp add: \<open>t' \<in> set (transitions M)\<close>) 
      qed

      ultimately show "\<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd qq \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
        by auto
    qed

    moreover have "\<And> qqt . qqt \<in> set (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))
                    \<Longrightarrow> fst qqt \<in> nodes ?PM \<and> snd qqt \<in> h M"
      using concat_pair_set[of "wf_transitions M" "(nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))"]
            nodes_code[of ?PM]
      by blast 
    ultimately have **: "\<And> qqt . qqt \<in> set (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))
                  \<Longrightarrow> t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))
                  \<Longrightarrow> t_source (snd qqt) = fst (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
      by blast
            
    
    have filter_strengthening:  "\<And> xs f1 f2 . (\<And> x .x \<in> set xs \<Longrightarrow> f1 x \<Longrightarrow> f2 x) \<Longrightarrow> set (filter f1 xs) \<subseteq> set (filter f2 xs)"
      by auto

    have ***: "set ((filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                   (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))))
                    \<subseteq> set (filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M ?q1) (from_FSM M ?q2))))))"
      using filter_strengthening[of "(concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))"
                                    "\<lambda>qqt . t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))"
                                    "\<lambda>qqt . t_source (snd qqt) = fst (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))", OF **] by blast
    
    have map_subset: "\<And> xs xs' f . set xs \<subseteq> set xs' \<Longrightarrow> set (map f xs) \<subseteq> set (map f xs')"
      by auto

    show ?thesis 
      using map_subset[OF ***, of "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))"]
      unfolding distinguishing_transitions_left_def  by blast
  qed


  have subset_right: "set (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))
                           (filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                   (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))))
       \<subseteq> set (distinguishing_transitions_right M ?q1 ?q2)"
  proof -
    have *: "\<And> qq t . qq \<in> nodes ?PM \<Longrightarrow> t \<in> h M \<Longrightarrow> t_source t = snd qq \<Longrightarrow> choose_state_separator_deadlock_input M S qq = Some (t_input t) 
            \<Longrightarrow> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst qq \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
    proof -
      fix qq t assume "qq \<in> nodes ?PM" and "t \<in> h M" and "t_source t = snd qq" and "choose_state_separator_deadlock_input M S qq = Some (t_input t)"

      have "qq \<in> nodes S" and "deadlock_state S qq" and f: "find
         (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                     \<exists>t2\<in>set (wf_transitions M).
                        t_source t1 = fst qq \<and>
                        t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
         (inputs M) = Some (t_input t)"
        using \<open>choose_state_separator_deadlock_input M S qq = Some (t_input t)\<close> unfolding choose_state_separator_deadlock_input_def
        by (meson option.distinct(1))+
      have "\<not> (\<exists>t1\<in>set (wf_transitions M).
                     \<exists>t2\<in>set (wf_transitions M).
                        t_source t1 = fst qq \<and>
                        t_source t2 = snd qq \<and> t_input t1 = t_input t \<and> t_input t2 = t_input t \<and> t_output t1 = t_output t2)"
        using find_condition[OF f] by blast
      then have "\<not> (\<exists>t2\<in>set (wf_transitions M).
                        t_source t2 = fst qq \<and> t_input t2 = t_input t \<and> t_output t = t_output t2)"
        using \<open>t \<in> h M\<close> \<open>t_source t = snd qq\<close>
        by metis 
      moreover have "\<And> t' . t' \<in> set (transitions M) \<Longrightarrow> t_source t' = fst qq \<Longrightarrow> t_input t' = t_input t \<Longrightarrow> t_output t' = t_output t\<Longrightarrow> t' \<in> h M"
      proof -
        fix t' assume "t' \<in> set (transitions M)" and "t_source t' = fst qq" and "t_input t' = t_input t" and "t_output t' = t_output t"        

        have "fst qq \<in> nodes M"
          using \<open>qq \<in> nodes ?PM\<close>  product_nodes[of "from_FSM M ?q1" "from_FSM M ?q2"] from_FSM_nodes[OF assms(2)] by force
        then have "t_source t' \<in> nodes M"
          using \<open>t_source t' = fst qq\<close> by auto
        then show "t' \<in> h M"
          using \<open>t_input t' = t_input t\<close> \<open>t_output t' = t_output t\<close> \<open>t \<in> h M\<close>
          by (simp add: \<open>t' \<in> set (transitions M)\<close>) 
      qed

      ultimately show "\<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst qq \<and> t_input t' = t_input t \<and> t_output t' = t_output t)"
        by auto
    qed

    moreover have "\<And> qqt . qqt \<in> set (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))
                    \<Longrightarrow> fst qqt \<in> nodes ?PM \<and> snd qqt \<in> h M"
      using concat_pair_set[of "wf_transitions M" "(nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))"]
            nodes_code[of ?PM]
      by blast 
    ultimately have **: "\<And> qqt . qqt \<in> set (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))
                  \<Longrightarrow> t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))
                  \<Longrightarrow> t_source (snd qqt) = snd (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))"
      by blast
            
    
    have filter_strengthening:  "\<And> xs f1 f2 . (\<And> x .x \<in> set xs \<Longrightarrow> f1 x \<Longrightarrow> f2 x) \<Longrightarrow> set (filter f1 xs) \<subseteq> set (filter f2 xs)"
      by auto

    have ***: "set ((filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                   (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))))
                    \<subseteq> set (filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M ?q1) (from_FSM M ?q2))))))"
      using filter_strengthening[of "(concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))"
                                    "\<lambda>qqt . t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))"
                                    "\<lambda>qqt . t_source (snd qqt) = snd (fst qqt) \<and> \<not>(\<exists> t' \<in> set (transitions M) . t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))", OF **] by blast
    
    have map_subset: "\<And> xs xs' f . set xs \<subseteq> set xs' \<Longrightarrow> set (map f xs) \<subseteq> set (map f xs')"
      by auto

    show ?thesis 
      using map_subset[OF ***, of "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))"]
      unfolding distinguishing_transitions_right_def  by blast
  qed
        
  


  let ?d_old = "map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) (wf_transitions S)"
  let ?d_left = "map (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))
                   (filter
                     (\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                            choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))
                     (concat
                       (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                         (nodes_from_distinct_paths
                           (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))"
  let ?d_right = "map (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))
                   (filter
                     (\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                            choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))
                     (concat
                       (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                         (nodes_from_distinct_paths
                           (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))"

  let ?d_old_dist_left = "(filter (\<lambda>t . t \<notin> set ?d_old \<union> set ?d_left \<union> set ?d_right \<and>
                                          (\<exists> t' \<in> set ?d_old . t_source t = t_source t' \<and> t_input t = t_input t'))
                                   (distinguishing_transitions_left M (fst (initial S)) (snd (initial S))))"

  let ?d_old_dist_right = "(filter (\<lambda>t . t \<notin> set ?d_old \<union> set ?d_left \<union> set ?d_right \<and>
                                          (\<exists> t' \<in> set ?d_old . t_source t = t_source t' \<and> t_input t = t_input t'))
                                   (distinguishing_transitions_right M (fst (initial S)) (snd (initial S))))"

  
  
  obtain d_right::"(('a \<times> 'a) + 'a) Transition list"  where d_right_var: "d_right = ?d_right" by blast
  obtain d_left::"(('a \<times> 'a) + 'a) Transition list"  where d_left_var: "d_left = ?d_left" by blast
  obtain d_old::"(('a \<times> 'a) + 'a) Transition list"  where d_old_var: "d_old = ?d_old" by blast
  obtain d_old_dist_left::"(('a \<times> 'a) + 'a) Transition list" where d_old_dist_left_var: "d_old_dist_left = (filter (\<lambda>t . t \<notin> set d_old \<union> set d_left \<union> set d_right \<and>
                                          (\<exists> t' \<in> set d_old . t_source t = t_source t' \<and> t_input t = t_input t'))
                                   (distinguishing_transitions_left M (fst (initial S)) (snd (initial S))))" by blast
  obtain d_old_dist_right::"(('a \<times> 'a) + 'a) Transition list" where d_old_dist_right_var: "d_old_dist_right = (filter (\<lambda>t . t \<notin> set d_old \<union> set d_left \<union> set d_right \<and>
                                          (\<exists> t' \<in> set d_old . t_source t = t_source t' \<and> t_input t = t_input t'))
                                   (distinguishing_transitions_right M (fst (initial S)) (snd (initial S))))" by blast

  
      



  have "set ((map shift_Inl (wf_transitions S))
                    @ (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))
                           (filter (\<lambda> qqt . t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                   (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))))
                    @ (map (\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))
                           (filter (\<lambda> qqt . t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) 
                                   (concat (map (\<lambda> qq' . map (\<lambda> t . (qq',t)) (wf_transitions M)) 
                                                (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))))
        \<subseteq> set (shifted_transitions M ?q1 ?q2
                @ distinguishing_transitions_left M ?q1 ?q2
                @ distinguishing_transitions_right M ?q1 ?q2)"
    using subset_shift subset_right subset_left
  proof -
    have "set (map (\<lambda>p. (Inl (t_source p), t_input p, t_output p, Inl (t_target p))) (wf_transitions S)) \<subseteq> set (shifted_transitions M (fst (initial S)) (snd (initial S)))"
      by (metis (no_types) \<open>set (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) (wf_transitions S)) \<subseteq> set (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) (wf_transitions (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))\<close> shifted_transitions_def)
    then show ?thesis
      using list_append_subset3 subset_left subset_right by blast
  qed 
  then have "set (d_old @ d_left @ d_right) \<subseteq> set (shifted_transitions M ?q1 ?q2
                @ distinguishing_transitions_left M ?q1 ?q2
                @ distinguishing_transitions_right M ?q1 ?q2)"
    using d_old_var d_left_var d_right_var by blast
  then have "set (d_old @ d_left @ d_right) \<subseteq> set (transitions ?CSep)"
    unfolding canonical_separator_def by auto
  
  have "set ?d_old_dist_left \<subseteq> set (transitions ?CSep)"
  proof 
    fix t assume "t \<in> set ?d_old_dist_left"
    have *: "\<And> f xs x . x \<in> set (filter f xs) \<Longrightarrow> x \<in> set xs" by auto
    show "t \<in> set (transitions ?CSep)" using *[OF \<open>t \<in> set ?d_old_dist_left\<close>] unfolding canonical_separator_def by auto
  qed
  then have "set d_old_dist_left \<subseteq> set (transitions ?CSep)"
    using d_old_dist_left_var d_old_var d_left_var d_right_var by blast
  then have "set (d_old @ d_left @ d_right @ d_old_dist_left) \<subseteq> set (transitions ?CSep)"
    using \<open>set (d_old @ d_left @ d_right) \<subseteq> set (transitions ?CSep)\<close> by force

  have "set ?d_old_dist_right \<subseteq> set (transitions ?CSep)"
  proof 
    fix t assume "t \<in> set ?d_old_dist_right"
    have *: "\<And> f xs x . x \<in> set (filter f xs) \<Longrightarrow> x \<in> set xs" by auto
    show "t \<in> set (transitions ?CSep)" using *[OF \<open>t \<in> set ?d_old_dist_right\<close>] unfolding canonical_separator_def by auto
  qed
  then have "set d_old_dist_right \<subseteq> set (transitions ?CSep)"
    using d_old_dist_right_var d_old_var d_left_var d_right_var by blast
  then have "set (d_old @ d_left @ d_right @ d_old_dist_left @ d_old_dist_right) \<subseteq> set (transitions ?CSep)"
    using \<open>set (d_old @ d_left @ d_right @ d_old_dist_left) \<subseteq> set (transitions ?CSep)\<close> by force

  have "set (transitions ?SSep) = set (?d_old @ ?d_left @ ?d_right @ ?d_old_dist_left @ ?d_old_dist_right)"
    unfolding Let_def state_separator_from_product_submachine_def by (simp only: select_convs)
  then have "set (transitions ?SSep) = set (d_old @ d_left @ d_right @ d_old_dist_left @ d_old_dist_right)"
    using d_old_dist_left_var d_old_dist_right_var d_old_var d_left_var d_right_var by blast
  then have "set (transitions ?SSep) \<subseteq> set (transitions ?CSep)"
    using \<open>set (d_old @ d_left @ d_right @ d_old_dist_left @ d_old_dist_right) \<subseteq> set (transitions ?CSep)\<close> by blast
  

  

  (* is_submachine *)

  have "inputs S = inputs ?PM"
    using assms(1) unfolding induces_state_separator_def is_submachine.simps
    by (simp only: from_FSM_simps(2) product_simps(2))

  have "initial ?SSep = initial ?CSep"
    unfolding canonical_separator_def state_separator_from_product_submachine_def
    by (simp only: from_FSM_simps(1) product_simps(1) select_convs prod.collapse) 
  moreover have "inputs ?SSep = inputs ?CSep"
    unfolding canonical_separator_def state_separator_from_product_submachine_def
    by (simp only: from_FSM_simps(2) product_simps(2)  select_convs)  
  moreover have "outputs ?SSep = outputs ?CSep"
    unfolding canonical_separator_def state_separator_from_product_submachine_def
    by (simp only: from_FSM_simps(3) product_simps(3)  select_convs) 
  moreover have "h ?SSep \<subseteq> h ?CSep"
    using \<open>set (transitions ?SSep) \<subseteq> set (transitions ?CSep)\<close> calculation
    by (metis nodes.initial transition_subset_h) 
  ultimately have is_sub: "is_submachine ?SSep ?CSep"
    unfolding is_submachine.simps by blast


  (* has deadlock states *)

  have isl_source: "\<And> t . t \<in> h ?SSep \<Longrightarrow> isl (t_source t)"
    using \<open>set (transitions ?SSep) \<subseteq> set (transitions ?CSep)\<close> 
    using canonical_separator_t_source_isl
    by (metis (no_types, hide_lams) subset_iff wf_transition_simp) 

  have has_deadlock_left: "deadlock_state ?SSep (Inr ?q1)" 
    using isl_source unfolding deadlock_state.simps
    by (metis sum.disc(2)) 

  have has_deadlock_right: "deadlock_state ?SSep (Inr ?q2)" 
    using isl_source unfolding deadlock_state.simps
    by (metis sum.disc(2)) 

  

  have d_left_targets: "\<And> t . t \<in> set d_left \<Longrightarrow> t_target t = Inr ?q1" 
  and  d_right_targets: "\<And> t . t \<in> set d_right \<Longrightarrow> t_target t = Inr ?q2"
  and  d_old_dist_left_targets: "\<And> t . t \<in> set d_old_dist_left \<Longrightarrow> t_target t = Inr ?q1"
  and  d_old_dist_right_targets: "\<And> t . t \<in> set d_old_dist_right \<Longrightarrow> t_target t = Inr ?q2"
  proof -
    have *: "\<And> xs t q . t \<in> set (map (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), q)) xs) \<Longrightarrow> t_target t = q" by auto
    show "\<And> t . t \<in> set d_left \<Longrightarrow> t_target t = Inr ?q1"
      using * d_left_var by blast
    show "\<And> t . t \<in> set d_right \<Longrightarrow> t_target t = Inr ?q2"
      using * d_right_var by blast

    have **: "\<And> xs t q f . t \<in> set (filter f (map (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), q)) xs)) \<Longrightarrow> t_target t = q" by auto
    show "\<And> t . t \<in> set d_old_dist_left \<Longrightarrow> t_target t = Inr ?q1"
      using ** d_old_dist_left_var unfolding distinguishing_transitions_left_def by blast
    show "\<And> t . t \<in> set d_old_dist_right \<Longrightarrow> t_target t = Inr ?q2"
      using ** d_old_dist_right_var unfolding distinguishing_transitions_right_def by blast
  qed

  

  have d_old_targets : "\<And> t . t \<in> set d_old \<Longrightarrow> isl (t_target t) \<and> (\<exists> t' \<in> h S . t = (Inl (t_source t'), t_input t', t_output t', Inl (t_target t')))"
    using d_old_var by auto

  
      
  
    
  have d_containment_var : "set (transitions SSep) = set d_old \<union> set d_left \<union> set d_right \<union> set d_old_dist_left \<union> set d_old_dist_right"
    using \<open>set (transitions ?SSep) = set (d_old @ d_left @ d_right @ d_old_dist_left @ d_old_dist_right)\<close>
    using ssep_var by auto
  then have d_containment : "set (transitions ?SSep) = set ?d_old \<union> set ?d_left \<union> set ?d_right \<union> set ?d_old_dist_left \<union> set ?d_old_dist_right"
    using ssep_var d_old_dist_left_var d_old_dist_right_var d_old_var d_left_var d_right_var by blast

  have "\<And> qs x y qt . (Inl qs,x,y,Inl qt) \<in> set d_old \<Longrightarrow> (qs,x,y,qt) \<in> h S"
    using d_old_targets
    by auto 
  moreover have "\<And> qs x y qt . (Inl qs,x,y,Inl qt) \<in> set (transitions SSep) \<Longrightarrow> (Inl qs,x,y,Inl qt) \<in> set d_old"
    using d_containment_var d_left_targets d_right_targets d_old_dist_left_targets d_old_dist_right_targets
    by fastforce 
  ultimately have d_old_origins: "\<And> qs x y qt . (Inl qs,x,y,Inl qt) \<in> h SSep \<Longrightarrow> (qs,x,y,qt) \<in> h S"
    by blast

  

  have "initial SSep = Inl (initial S)"
    using ssep_var unfolding state_separator_from_product_submachine_def
    by (simp only: select_convs)
  have "inputs SSep = inputs M"
    using ssep_var unfolding state_separator_from_product_submachine_def
    by (simp only: select_convs)
  then have "set (inputs SSep) = set (inputs S)"
    using \<open>inputs S = inputs ?PM\<close>
    by (simp add: from_FSM_product_inputs) 
  have "outputs SSep = outputs M"
    using ssep_var unfolding state_separator_from_product_submachine_def
    by (simp only: select_convs)
  then have "set (outputs SSep) = set (outputs S)"
    using \<open>outputs S = outputs ?PM\<close>
    by (simp add: from_FSM_product_outputs)   
    

  have ssep_path_from_old : "\<And> p . path S (initial S) p \<Longrightarrow> path SSep (initial SSep) (map shift_Inl p)"
  proof - 
    fix p assume "path S (initial S) p"
    then show "path SSep (initial SSep) (map shift_Inl p)" proof (induction p rule: rev_induct)
      case Nil
      then show ?case by auto 
    next
      case (snoc t p) 
      then have "path S (initial S) p" and "t \<in> h S" and "t_source t = target p (initial S)"
        by auto

      have "shift_Inl t \<in> set d_old"
        using d_old_var \<open>t \<in> h S\<close> by auto

      have "target (map shift_Inl p) (Inl (initial S)) \<in> nodes SSep"
        using snoc.IH[OF \<open>path S (initial S) p\<close>] \<open>initial SSep = Inl (initial S)\<close>
        using path_target_is_node by fastforce 
      moreover have "target (map shift_Inl p) (Inl (initial S)) = Inl (t_source t)"
        using \<open>t_source t = target p (initial S)\<close> by (cases p rule: rev_cases; auto) 
      ultimately have "Inl (t_source t) \<in> nodes SSep" 
        using \<open>t_source t = target p (initial S)\<close>
        by (metis \<open>target (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p) (Inl (initial S)) = Inl (t_source t)\<close> \<open>target (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p) (Inl (initial S)) \<in> nodes SSep\<close>)
      then have "t_source (shift_Inl t) \<in> nodes SSep"
        by auto
      moreover have "t_input (shift_Inl t) \<in> set (inputs SSep)"
        using \<open>t \<in> h S\<close> \<open>set (inputs SSep) = set (inputs S)\<close> by auto
      moreover have "t_output (shift_Inl t) \<in> set (outputs SSep)"
        using \<open>t \<in> h S\<close> \<open>set (outputs SSep) = set (outputs S)\<close> by auto
      ultimately have "shift_Inl t \<in> h SSep"
        using \<open>shift_Inl t \<in> set d_old\<close> d_containment_var by auto
      
      then show ?case 
        using snoc.IH[OF \<open>path S (initial S) p\<close>]  \<open>target (map shift_Inl p) (Inl (initial S)) = Inl (t_source t)\<close> \<open>initial SSep = Inl (initial S)\<close>
      proof -
        have f1: "path SSep (Inl (t_source t)) [(Inl (t_source t), t_input t, t_output t, Inl (t_target t))]"
          by (meson \<open>(Inl (t_source t), t_input t, t_output t, Inl (t_target t)) \<in> set (wf_transitions SSep)\<close> single_transitions_path)
        have "map (\<lambda>p. (Inl (t_source p)::'a \<times> 'a + 'a, t_input p, t_output p, Inl (t_target p)::'a \<times> 'a + 'a)) [t] = [(Inl (t_source t), t_input t, t_output t, Inl (t_target t))]"
          by auto
        then have "path SSep (target (map (\<lambda>p. (Inl (t_source p), t_input p, t_output p, Inl (t_target p))) p) (Inl (initial S))) (map (\<lambda>p. (Inl (t_source p), t_input p, t_output p, Inl (t_target p))) [t])"
          using f1 by (metis (no_types) \<open>target (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p) (Inl (initial S)) = Inl (t_source t)\<close>)
        then have "path SSep (Inl (initial S)) (map (\<lambda>p. (Inl (t_source p), t_input p, t_output p, Inl (t_target p))) p @ map (\<lambda>p. (Inl (t_source p), t_input p, t_output p, Inl (t_target p))) [t])"
          using \<open>initial SSep = Inl (initial S)\<close> \<open>path SSep (initial SSep) (map (\<lambda>t. (Inl (t_source t), t_input t, t_output t, Inl (t_target t))) p)\<close> by force
        then show ?thesis
          using \<open>initial SSep = Inl (initial S)\<close> by auto
      qed 
    qed
  qed

  have ssep_transitions_from_old : "\<And> t . t \<in> h S \<Longrightarrow> shift_Inl t \<in> h SSep"
  proof -
    fix t assume "t \<in> h S"
    then obtain p where "path S (initial S) p" and "target p (initial S) = t_source t"
      using path_to_node by force
    then have "path S (initial S) (p@[t])"
      using \<open>t \<in> h S\<close> by auto
    
    show "shift_Inl t \<in> h SSep" using ssep_path_from_old[OF \<open>path S (initial S) (p@[t])\<close>]
      using \<open>path S (initial S) p\<close> by auto 
  qed
  then have ssep_transitions_from_old' : "set (map shift_Inl (wf_transitions S)) \<subseteq> h SSep"
    using d_old_targets d_old_var by blast

  have ssep_nodes_from_old : "\<And> qq . qq \<in> nodes S \<Longrightarrow> Inl qq \<in> nodes SSep"
    using nodes_initial_or_target \<open>initial SSep = Inl (initial S)\<close> ssep_transitions_from_old
    by (metis nodes.initial snd_conv wf_transition_target) 

  

  have s_deadlock_transitions_left: "\<And> qq . qq \<in> nodes S \<Longrightarrow> deadlock_state S qq \<Longrightarrow> (\<exists> x y . (Inl qq, x, y, Inr (fst (initial S))) \<in> h SSep)"
  proof -
    fix qq assume "qq \<in> nodes S"
              and "deadlock_state S qq"
    then have "qq \<in> nodes S \<and> deadlock_state S qq" by simp
    then have *: "\<exists>x\<in>set (inputs M).
                 \<not> (\<exists>t1\<in>set (wf_transitions M).
                        \<exists>t2\<in>set (wf_transitions M).
                           t_source t1 = fst qq \<and>
                           t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)"
      using dl by blast


    have "choose_state_separator_deadlock_input M S qq \<noteq> None"
      unfolding choose_state_separator_deadlock_input_def using \<open>qq \<in> nodes S \<and> deadlock_state S qq\<close> using find_from[OF *] by force
    then obtain x where "choose_state_separator_deadlock_input M S qq = Some x"
      by auto
    then have "x \<in> set (inputs M)"
      unfolding choose_state_separator_deadlock_input_def
      by (meson \<open>deadlock_state S qq\<close> \<open>qq \<in> nodes S\<close> find_set)
    then have "x \<in> set (inputs S)"
      using \<open>inputs S = inputs ?PM\<close>
      using \<open>inputs SSep = inputs M\<close> \<open>set (inputs SSep) = set (inputs S)\<close> by auto 

    have "qq \<in> nodes ?PM"
      using \<open>qq \<in> nodes S\<close> submachine_nodes[OF \<open>is_submachine S ?PM\<close>] by blast
    then have "fst qq \<in> nodes M"
      using product_nodes[of "from_FSM M ?q1" "from_FSM M ?q2"] from_FSM_nodes[OF \<open>fst (initial S) \<in> nodes M\<close>]
      by (meson \<open>nodes (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))) \<subseteq> nodes (from_FSM M (fst (initial S))) \<times> nodes (from_FSM M (snd (initial S)))\<close> \<open>qq \<in> nodes (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))\<close> in_mono mem_Times_iff)
    
      

    obtain t where "t \<in> h M" 
               and "t_source t = fst qq"
               and "t_input t = x"
      using \<open>completely_specified M\<close> unfolding completely_specified.simps 
      using \<open>x \<in> set (inputs M)\<close> \<open>fst qq \<in> nodes M\<close> by blast
    then have "t_output t \<in> set (outputs M)"
      by auto

    have p1: "(qq,t) \<in> set (concat
                         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) 
                         (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))"
      using \<open>qq \<in> nodes ?PM\<close> nodes_code[of ?PM] \<open>t \<in> h M\<close> by auto
    have p2: "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) (qq,t)"
      using \<open>t_source t = fst qq\<close> \<open>choose_state_separator_deadlock_input M S qq = Some x\<close> \<open>t_input t = x\<close>
      by auto

    have l1: "\<And> x f xs . x \<in> set xs \<Longrightarrow> f x \<Longrightarrow> x \<in> set (filter f xs)" by auto

    have p3: "(qq,t) \<in> set (filter (\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))
       (concat
         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
           (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))" 
      using l1[OF p1, of "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))", OF p2] by assumption
    
    have l2: "\<And> f xs x . x \<in> set xs \<Longrightarrow> (f x) \<in> set (map f xs)"
      by auto

    let ?t = "(Inl (fst (qq, t)), t_input (snd (qq, t)), t_output (snd (qq, t)), Inr (fst (initial S)))"
    have "?t \<in> set ?d_left"
      using l2[OF p3, of "(\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))"] by assumption
      
    then have "?t \<in> set d_left"
      using d_left_var by meson
    



    then have "?t \<in> set (transitions SSep)"
      using d_containment_var by blast
    then have "(Inl qq, x, t_output t, Inr (fst (initial S))) \<in> set (transitions SSep)"
      using \<open>t_input t = x\<close> by auto
    moreover have "Inl qq \<in> nodes SSep"
      using ssep_nodes_from_old[OF \<open>qq \<in> nodes S\<close>] by assumption
    moreover have "x \<in> set (inputs SSep)"
      using \<open>x \<in> set (inputs S)\<close> \<open>set (inputs SSep) = set (inputs S)\<close> by blast
    moreover have "t_output t \<in> set (outputs SSep)"
      using \<open>t_output t \<in> set (outputs M)\<close> \<open>outputs SSep = outputs M\<close>
      by simp 
    ultimately have "(Inl qq, x, t_output t, Inr ?q1) \<in> h SSep"
      by auto
    then show "(\<exists> x y . (Inl qq, x, y, Inr ?q1) \<in> h SSep)" 
      by blast
  qed


  have s_deadlock_transitions_right: "\<And> qq . qq \<in> nodes S \<Longrightarrow> deadlock_state S qq \<Longrightarrow> (\<exists> x y . (Inl qq, x, y, Inr ?q2) \<in> h SSep)"
  proof -
    fix qq assume "qq \<in> nodes S"
              and "deadlock_state S qq"
    then have "qq \<in> nodes S \<and> deadlock_state S qq" by simp
    then have *: "\<exists>x\<in>set (inputs M).
                 \<not> (\<exists>t1\<in>set (wf_transitions M).
                        \<exists>t2\<in>set (wf_transitions M).
                           t_source t1 = fst qq \<and>
                           t_source t2 = snd qq \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)"
      using dl by blast


    have "choose_state_separator_deadlock_input M S qq \<noteq> None"
      unfolding choose_state_separator_deadlock_input_def using \<open>qq \<in> nodes S \<and> deadlock_state S qq\<close> using find_from[OF *] by force
    then obtain x where "choose_state_separator_deadlock_input M S qq = Some x"
      by auto
    then have "x \<in> set (inputs M)"
      unfolding choose_state_separator_deadlock_input_def
      by (meson \<open>deadlock_state S qq\<close> \<open>qq \<in> nodes S\<close> find_set)
    then have "x \<in> set (inputs S)"
      using \<open>inputs S = inputs ?PM\<close>
      using \<open>inputs SSep = inputs M\<close> \<open>set (inputs SSep) = set (inputs S)\<close> by auto 

    have "qq \<in> nodes ?PM"
      using \<open>qq \<in> nodes S\<close> submachine_nodes[OF \<open>is_submachine S ?PM\<close>] by blast
    then have "snd qq \<in> nodes M"
      using product_nodes[of "from_FSM M ?q1" "from_FSM M ?q2"] from_FSM_nodes[OF \<open>snd (initial S) \<in> nodes M\<close>]
      by (meson \<open>nodes (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))) \<subseteq> nodes (from_FSM M (fst (initial S))) \<times> nodes (from_FSM M (snd (initial S)))\<close> \<open>qq \<in> nodes (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))\<close> in_mono mem_Times_iff)
    
      

    obtain t where "t \<in> h M" 
               and "t_source t = snd qq"
               and "t_input t = x"
      using \<open>completely_specified M\<close> unfolding completely_specified.simps 
      using \<open>x \<in> set (inputs M)\<close> \<open>snd qq \<in> nodes M\<close> by blast
    then have "t_output t \<in> set (outputs M)"
      by auto

    have p1: "(qq,t) \<in> set (concat
                         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) 
                         (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))"
      using \<open>qq \<in> nodes ?PM\<close> nodes_code[of ?PM] \<open>t \<in> h M\<close> by auto
    have p2: "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) (qq,t)"
      using \<open>t_source t = snd qq\<close> \<open>choose_state_separator_deadlock_input M S qq = Some x\<close> \<open>t_input t = x\<close>
      by auto

    have l1: "\<And> x f xs . x \<in> set xs \<Longrightarrow> f x \<Longrightarrow> x \<in> set (filter f xs)" by auto

    have p3: "(qq,t) \<in> set (filter (\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))
       (concat
         (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
           (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))" 
      using l1[OF p1, of "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and> choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))", OF p2] by assumption
    
    have l2: "\<And> f xs x . x \<in> set xs \<Longrightarrow> (f x) \<in> set (map f xs)"
      by auto

    let ?t = "(Inl (fst (qq, t)), t_input (snd (qq, t)), t_output (snd (qq, t)), Inr ?q2)"
    have "?t \<in> set ?d_right"
      using l2[OF p3, of "(\<lambda> qqt . (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr ?q2))"] by assumption
      
    then have "?t \<in> set d_right"
      using d_right_var by meson
    



    then have "?t \<in> set (transitions SSep)"
      using d_containment_var by blast
    then have "(Inl qq, x, t_output t, Inr ?q2) \<in> set (transitions SSep)"
      using \<open>t_input t = x\<close> by auto
    moreover have "Inl qq \<in> nodes SSep"
      using ssep_nodes_from_old[OF \<open>qq \<in> nodes S\<close>] by assumption
    moreover have "x \<in> set (inputs SSep)"
      using \<open>x \<in> set (inputs S)\<close> \<open>set (inputs SSep) = set (inputs S)\<close> by blast
    moreover have "t_output t \<in> set (outputs SSep)"
      using \<open>t_output t \<in> set (outputs M)\<close> \<open>outputs SSep = outputs M\<close>
      by simp 
    ultimately have "(Inl qq, x, t_output t, Inr ?q2) \<in> h SSep"
      by auto
    then show "(\<exists> x y . (Inl qq, x, y, Inr ?q2) \<in> h SSep)" 
      by blast
  qed
    

  
  (* no additional deadlock states (or other Inr-states) exist *) 

  have inl_prop: "\<And> q . q \<in> nodes SSep \<Longrightarrow> q \<noteq> Inr ?q1 \<Longrightarrow> q \<noteq> Inr ?q2 \<Longrightarrow>
                        isl q \<and> \<not> deadlock_state SSep q" 
  proof -
    fix q assume "q \<in> nodes SSep" 
             and "q \<noteq> Inr ?q1"
             and "q \<noteq> Inr ?q2"

   have g1: "isl q" proof (cases "q = initial SSep")
      case True
      then have "q = Inl (initial S)"
        unfolding state_separator_from_product_submachine_def \<open>initial SSep = Inl (initial S)\<close> by (simp only: select_convs)
      then show ?thesis by auto 
    next
      case False 
      then obtain t where "t \<in> h SSep" and "t_target t = q"
        by (meson \<open>q \<in> nodes SSep\<close> nodes_initial_or_target)
        
      show ?thesis using \<open>q \<noteq> Inr ?q1\<close> \<open>q \<noteq> Inr ?q2\<close>
        by (metis UnE \<open>t \<in> set (wf_transitions SSep)\<close> \<open>t_target t = q\<close> d_containment_var d_left_targets d_old_targets d_right_targets d_old_dist_left_targets d_old_dist_right_targets wf_transition_simp) 
    qed

    have "\<And> qq . Inl qq \<in> nodes SSep \<Longrightarrow> \<not> (deadlock_state SSep (Inl qq))"
    proof -
      fix qq assume "Inl qq \<in> nodes SSep"
      
      have "qq \<in> nodes S" proof (cases "Inl qq = initial SSep")
        case True
        then have "Inl qq = Inl (initial S)"
          using \<open>initial SSep = Inl (initial S)\<close>
          by (metis sum.sel(1))
        then show ?thesis by auto
      next
        case False
        then obtain t where "t \<in> h SSep" and "t_target t = Inl qq"
          using nodes_initial_or_target \<open>Inl qq \<in> nodes SSep\<close> by metis
        
        obtain qq' where "t_source t = Inl qq'"
          by (metis \<open>t \<in> set (wf_transitions SSep)\<close> isl_def isl_source ssep_var)

        have "(Inl qq',t_input t, t_output t, Inl qq) \<in> h SSep"
          using \<open>t \<in> h SSep\<close> \<open>t_source t = Inl qq'\<close> \<open>t_target t = Inl qq\<close> using prod.collapse by metis

        then have "(qq',t_input t, t_output t,qq) \<in> h S" 
          using ssep_var d_old_origins by blast 
        then show ?thesis using wf_transition_target
          by fastforce 
      qed
      
      show "\<not> (deadlock_state SSep (Inl qq))"
      proof (cases "deadlock_state S qq")
        case True
        show ?thesis using s_deadlock_transitions_left[OF \<open>qq \<in> nodes S\<close> True]
          unfolding deadlock_state.simps
          by auto  
      next
        case False 
        then obtain t where "t \<in> h S" and "t_source t = qq"
          unfolding deadlock_state.simps by blast
        then have "shift_Inl t \<in> h SSep"
          using ssep_transitions_from_old by blast 
        then show ?thesis 
          unfolding deadlock_state.simps
          using \<open>t_source t = qq\<close> by auto 
      qed
    qed
    then have "\<not> deadlock_state SSep q"
      by (metis \<open>q \<in> nodes SSep\<close> g1 isl_def) 

    then show "isl q \<and> \<not> deadlock_state SSep q"
      using g1 by simp
  qed

  then have has_inl_property: "\<forall>q\<in>nodes ?SSep.
        q \<noteq> Inr ?q1 \<and> q \<noteq> Inr ?q2 \<longrightarrow>
        isl q \<and> \<not> deadlock_state ?SSep q" using ssep_var by blast



  have d_left_sources : "\<And> t . t \<in> set d_left \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> deadlock_state S q \<and> (find
                                                 (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                             \<exists>t2\<in>set (wf_transitions M).
                                                                t_source t1 = fst q \<and>
                                                                t_source t2 = snd q \<and>
                                                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                                                 (inputs M) = Some (t_input t))
                                               \<and> t_input t \<in> set (inputs SSep)
                                               \<and> t_output t \<in> set (outputs SSep))"
  proof -
    fix t assume "t \<in> set d_left"

    have f1: "\<And> t xs f . t \<in> set (map f xs) \<Longrightarrow> (\<exists> x \<in> set xs . t = f x)" by auto
    have f2: "\<And> x xs f . x \<in> set (filter f xs) \<Longrightarrow> f x" by auto
    have f3: "\<And> x xs f . x \<in> set (filter f xs) \<Longrightarrow> x \<in> set xs" by auto

    obtain qqt where *:  "t = (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S)))) qqt" 
                 and **: "qqt \<in> set (filter
                                   (\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                                          (if fst qqt \<in> nodes S \<and> deadlock_state S (fst qqt)
                                           then find
                                                 (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                             \<exists>t2\<in>set (wf_transitions M).
                                                                t_source t1 = fst (fst qqt) \<and>
                                                                t_source t2 = snd (fst qqt) \<and>
                                                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                                                 (inputs M)
                                           else None) =
                                          Some (t_input (snd qqt)))
                                   (concat
                                     (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                       (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))"
      using \<open>t \<in> set d_left\<close> \<open>d_left = ?d_left\<close> unfolding choose_state_separator_deadlock_input_def 
      using f1[of t "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))"] by blast

    have "snd qqt \<in> h M"
      using f3[OF **] concat_pair_set by blast
    then have "t_input (snd qqt) \<in> set (inputs M)" and "t_output (snd qqt) \<in> set (outputs M)"
      by auto
    then have "t_input (snd qqt) \<in> set (inputs SSep)" and "t_output (snd qqt) \<in> set (outputs SSep)"
      by (simp only: \<open>inputs SSep = inputs M\<close> \<open>outputs SSep = outputs M\<close>)+
      

    then have "t_source (snd qqt) = fst (fst qqt) \<and> (fst qqt) \<in> nodes S \<and> deadlock_state S (fst qqt) \<and> find
           (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                       \<exists>t2\<in>set (wf_transitions M).
                          t_source t1 = fst (fst qqt) \<and>
                          t_source t2 = snd (fst qqt) \<and>
                          t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
           (inputs M) = Some (t_input (snd qqt))
          \<and> t_input (snd qqt) \<in> set (inputs SSep)
          \<and> t_output (snd qqt) \<in> set (outputs SSep)"
      using f2[OF **]
      by (meson option.distinct(1)) 
    then have "t_source t = Inl (fst qqt) \<and> (fst qqt) \<in> nodes S \<and> deadlock_state S (fst qqt) \<and> find
           (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                       \<exists>t2\<in>set (wf_transitions M).
                          t_source t1 = fst (fst qqt) \<and>
                          t_source t2 = snd (fst qqt) \<and>
                          t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
           (inputs M) = Some (t_input t)
          \<and> t_input t \<in> set (inputs SSep)
          \<and> t_output t \<in> set (outputs SSep)"
      using * by auto
    then show "(\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> deadlock_state S q \<and> find
                                                 (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                             \<exists>t2\<in>set (wf_transitions M).
                                                                t_source t1 = fst q \<and>
                                                                t_source t2 = snd q \<and>
                                                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                                                 (inputs M) = Some (t_input t)
                                                 \<and> t_input t \<in> set (inputs SSep)
                                                 \<and> t_output t \<in> set (outputs SSep))" by blast
      
  qed

  have d_right_sources : "\<And> t . t \<in> set d_right \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> deadlock_state S q \<and> (find
                                                 (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                             \<exists>t2\<in>set (wf_transitions M).
                                                                t_source t1 = fst q \<and>
                                                                t_source t2 = snd q \<and>
                                                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                                                 (inputs M) = Some (t_input t))
                                               \<and> t_input t \<in> set (inputs SSep)
                                               \<and> t_output t \<in> set (outputs SSep))"
  proof -
    fix t assume "t \<in> set d_right"

    have f1: "\<And> t xs f . t \<in> set (map f xs) \<Longrightarrow> (\<exists> x \<in> set xs . t = f x)" by auto
    have f2: "\<And> x xs f . x \<in> set (filter f xs) \<Longrightarrow> f x" by auto
    have f3: "\<And> x xs f . x \<in> set (filter f xs) \<Longrightarrow> x \<in> set xs" by auto

    obtain qqt where *:  "t = (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S)))) qqt" 
                 and **: "qqt \<in> set (filter
                                   (\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                                          (if fst qqt \<in> nodes S \<and> deadlock_state S (fst qqt)
                                           then find
                                                 (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                             \<exists>t2\<in>set (wf_transitions M).
                                                                t_source t1 = fst (fst qqt) \<and>
                                                                t_source t2 = snd (fst qqt) \<and>
                                                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                                                 (inputs M)
                                           else None) =
                                          Some (t_input (snd qqt)))
                                   (concat
                                     (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                                       (nodes_from_distinct_paths (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S))))))))"
      using \<open>t \<in> set d_right\<close> \<open>d_right = ?d_right\<close> unfolding choose_state_separator_deadlock_input_def 
      using f1[of t "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))"] by blast

    have "snd qqt \<in> h M"
      using f3[OF **] concat_pair_set by blast
    then have "t_input (snd qqt) \<in> set (inputs M)" and "t_output (snd qqt) \<in> set (outputs M)"
      by auto
    then have "t_input (snd qqt) \<in> set (inputs SSep)" and "t_output (snd qqt) \<in> set (outputs SSep)"
      by (simp only: \<open>inputs SSep = inputs M\<close> \<open>outputs SSep = outputs M\<close>)+
      

    then have "t_source (snd qqt) = snd (fst qqt) \<and> (fst qqt) \<in> nodes S \<and> deadlock_state S (fst qqt) \<and> find
           (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                       \<exists>t2\<in>set (wf_transitions M).
                          t_source t1 = fst (fst qqt) \<and>
                          t_source t2 = snd (fst qqt) \<and>
                          t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
           (inputs M) = Some (t_input (snd qqt))
          \<and> t_input (snd qqt) \<in> set (inputs SSep)
          \<and> t_output (snd qqt) \<in> set (outputs SSep)"
      using f2[OF **]
      by (meson option.distinct(1)) 
    then have "t_source t = Inl (fst qqt) \<and> (fst qqt) \<in> nodes S \<and> deadlock_state S (fst qqt) \<and> find
           (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                       \<exists>t2\<in>set (wf_transitions M).
                          t_source t1 = fst (fst qqt) \<and>
                          t_source t2 = snd (fst qqt) \<and>
                          t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
           (inputs M) = Some (t_input t)
          \<and> t_input t \<in> set (inputs SSep)
          \<and> t_output t \<in> set (outputs SSep)"
      using * by auto
    then show "(\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> deadlock_state S q \<and> find
                                                 (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                             \<exists>t2\<in>set (wf_transitions M).
                                                                t_source t1 = fst q \<and>
                                                                t_source t2 = snd q \<and>
                                                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                                                 (inputs M) = Some (t_input t)
                                                 \<and> t_input t \<in> set (inputs SSep)
                                                 \<and> t_output t \<in> set (outputs SSep))" by blast
      
  qed



  



  have d_old_sources : "\<And> t . t \<in> set d_old \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
  proof -
    fix t assume "t \<in> set d_old"
    then have "isl (t_target t)"
      by (simp add: d_old_targets) 
    then obtain qt where "t_target t = Inl qt"
      by (metis sum.collapse(1)) 
    
    have "isl (t_source t)"
      using \<open>t \<in> set d_old\<close> d_old_targets isl_source ssep_transitions_from_old ssep_var by blast
    then obtain qs where "t_source t = Inl qs"
      by (metis sum.collapse(1)) 

    have "(qs,t_input t,t_output t,qt) \<in> h S"
      using d_old_origins
      by (metis \<open>\<And>y x qt qs. (Inl qs, x, y, Inl qt) \<in> set d_old \<Longrightarrow> (qs, x, y, qt) \<in> set (wf_transitions S)\<close> \<open>t \<in> set d_old\<close> \<open>t_source t = Inl qs\<close> \<open>t_target t = Inl qt\<close> prod.collapse)
    then have "\<not> (deadlock_state S qs)"
      unfolding deadlock_state.simps
      by (meson fst_conv) 

    show "(\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
      using \<open>t_source t = Inl qs\<close> \<open>(qs,t_input t,t_output t,qt) \<in> h S\<close> \<open>\<not> (deadlock_state S qs)\<close> by auto
  qed

  have d_old_dist_left_sources : "\<And> t . t \<in> set d_old_dist_left \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
  proof -
    fix t assume "t \<in> set d_old_dist_left"
    then obtain t' where "t' \<in> set d_old" and "t_source t = t_source t'" and "t_input t = t_input t'"
      using d_old_dist_left_var by auto
    then show "(\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
      using d_old_sources by auto
  qed

  have d_old_dist_right_sources : "\<And> t . t \<in> set d_old_dist_right \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
  proof -
    fix t assume "t \<in> set d_old_dist_right"
    then obtain t' where "t' \<in> set d_old" and "t_source t = t_source t'" and "t_input t = t_input t'"
      using d_old_dist_right_var by auto
    then show "(\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
      using d_old_sources by auto
  qed

  have d_non_deadlock_sources : "\<And> t . t \<in> set d_old \<or> t \<in> set d_old_dist_left \<or> t \<in> set d_old_dist_right \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> \<not>deadlock_state S q)"
    using d_old_sources d_old_dist_left_sources d_old_dist_right_sources by blast

  have d_deadlock_sources : "\<And> t . t \<in> set d_left \<or> t \<in> set d_right \<Longrightarrow> (\<exists> q . t_source t = Inl q \<and> q \<in> nodes S \<and> deadlock_state S q)"
    using d_left_sources d_right_sources by blast


  have d_old_dist_left_d_old : "\<And> t . t \<in> set d_old_dist_left \<Longrightarrow> (\<exists> t' \<in> set d_old . t_source t = t_source t' \<and> t_input t = t_input t')"
    using d_old_dist_left_var by auto

  have d_old_dist_right_d_old : "\<And> t . t \<in> set d_old_dist_right \<Longrightarrow> (\<exists> t' \<in> set d_old . t_source t = t_source t' \<and> t_input t = t_input t')"
    using d_old_dist_right_var by auto



     
  have "set d_old \<inter> set d_left = {}"
    using d_old_targets \<open>d_left = ?d_left\<close>
    by (metis (no_types, lifting) Inr_Inl_False d_left_targets disjoint_iff_not_equal prod.collapse prod.inject)
  have "set d_old \<inter> set d_right = {}"
    using d_old_targets \<open>d_right = ?d_right\<close>
    by (metis (no_types, lifting) Inr_Inl_False d_right_targets disjoint_iff_not_equal prod.collapse prod.inject)
  have "set d_left \<inter> set d_right = {}"
    using d_left_targets d_right_targets \<open>fst (initial S) \<noteq> snd (initial S)\<close>
    by fastforce 

  
  have d_source_split : "\<And> t1 t2 . t1 \<in> set d_old \<Longrightarrow> t2 \<in> set d_left \<or> t2 \<in> set d_right \<Longrightarrow> t_source t1 \<noteq> t_source t2"
  proof -
    fix t1 t2 assume "t1 \<in> set d_old" 
                 and "t2 \<in> set d_left \<or> t2 \<in> set d_right"

    then consider "t2 \<in> set d_left" | "t2 \<in> set d_right" by blast
    then show "t_source t1 \<noteq> t_source t2" proof cases
      case 1
      show ?thesis 
        using d_old_sources[OF \<open>t1 \<in> set d_old\<close>] d_left_sources[OF 1]
        by fastforce 
    next
      case 2
      show ?thesis 
        using d_old_sources[OF \<open>t1 \<in> set d_old\<close>] d_right_sources[OF 2]
        by fastforce 
    qed
  qed

  have d_source_split_deadlock : "\<And> t1 t2 . t1 \<in> set d_old \<or> t1 \<in> set d_old_dist_left \<or> t1 \<in> set d_old_dist_right \<Longrightarrow> t2 \<in> set d_left \<or> t2 \<in> set d_right \<Longrightarrow> t_source t1 \<noteq> t_source t2"
  proof -
    fix t1 t2 assume *:  "t1 \<in> set d_old \<or> t1 \<in> set d_old_dist_left \<or> t1 \<in> set d_old_dist_right"
                 and **: "t2 \<in> set d_left \<or> t2 \<in> set d_right"

    obtain q1 where "t_source t1 = Inl q1" and "\<not> (deadlock_state S q1)"
      using d_non_deadlock_sources[OF *] by blast
    obtain q2 where "t_source t2 = Inl q2" and "(deadlock_state S q2)"
      using d_deadlock_sources[OF **] by blast

    have "q1 \<noteq> q2"
      using \<open>\<not> (deadlock_state S q1)\<close> \<open>(deadlock_state S q2)\<close> by blast
    then show "t_source t1 \<noteq> t_source t2" 
      using \<open>t_source t1 = Inl q1\<close> \<open>t_source t2 = Inl q2\<close> by auto
  qed
         



  have d_old_same_sources: "\<And> t1 t2 . t1 \<in> set d_old \<or> t1 \<in> set d_old_dist_left \<or> t1 \<in> set d_old_dist_right \<Longrightarrow> t2 \<in> h SSep \<Longrightarrow> t_source t1 = t_source t2 \<Longrightarrow> t2 \<in> set d_old \<or> t2 \<in> set d_old_dist_left \<or> t2 \<in> set d_old_dist_right"
  proof -
    fix t1 t2 assume "t1 \<in> set d_old \<or> t1 \<in> set d_old_dist_left \<or> t1 \<in> set d_old_dist_right" and "t2 \<in> h SSep" and "t_source t1 = t_source t2"

    have "\<not>(t2 \<in> set d_left \<or> t2 \<in> set d_right)"
      using d_source_split_deadlock[OF \<open>t1 \<in> set d_old \<or> t1 \<in> set d_old_dist_left \<or> t1 \<in> set d_old_dist_right\<close>, of t2] \<open>t_source t1 = t_source t2\<close> by auto
    then show "t2 \<in> set d_old \<or> t2 \<in> set d_old_dist_left \<or> t2 \<in> set d_old_dist_right"
      using d_containment_var \<open>t2 \<in> h SSep\<close> by blast 
  qed


  have d_left_right_same_sources: "\<And> t1 t2 . t1 \<in> set d_left \<or> t1 \<in> set d_right \<Longrightarrow> t2 \<in> h SSep \<Longrightarrow> t_source t1 = t_source t2 \<Longrightarrow> t2 \<in> set d_left \<or> t2 \<in> set d_right"
  proof -
    fix t1 t2 assume "t1 \<in> set d_left \<or> t1 \<in> set d_right" and "t2 \<in> h SSep" and "t_source t1 = t_source t2"

    have "\<not>(t2 \<in> set d_old \<or> t2 \<in> set d_old_dist_left \<or> t2 \<in> set d_old_dist_right)"
      using d_source_split_deadlock[OF _ \<open>t1 \<in> set d_left \<or> t1 \<in> set d_right\<close>, of t2] \<open>t_source t1 = t_source t2\<close> by auto
    then show "t2 \<in> set d_left \<or> t2 \<in> set d_right"
      using d_containment_var \<open>t2 \<in> h SSep\<close> by blast
  qed


  


  
  have d_old_transitions : "\<And> t . t \<in> set d_old \<Longrightarrow> (\<exists> qs qt . t = (Inl qs,t_input t, t_output t, Inl qt) \<and> (qs,t_input t, t_output t, qt) \<in> h S)"
  proof -
    fix t assume "t \<in> set d_old"
    then have "isl (t_target t)"
      by (simp add: d_old_targets) 
    then obtain qt where "t_target t = Inl qt"
      by (metis sum.collapse(1)) 
    have "isl (t_source t)"
      using \<open>t \<in> set d_old\<close> d_old_sources isl_def by blast
    then obtain qs where "t_source t = Inl qs"
      by (metis sum.collapse(1)) 
    have "(qs,t_input t,t_output t,qt) \<in> h S"
      using d_old_origins
      by (metis \<open>\<And>y x qt qs. (Inl qs, x, y, Inl qt) \<in> set d_old \<Longrightarrow> (qs, x, y, qt) \<in> set (wf_transitions S)\<close> \<open>t \<in> set d_old\<close> \<open>t_source t = Inl qs\<close> \<open>t_target t = Inl qt\<close> prod.collapse)
    then show "(\<exists> qs qt . t = (Inl qs,t_input t, t_output t, Inl qt) \<and> (qs,t_input t, t_output t, qt) \<in> h S)"
      using \<open>t_target t = Inl qt\<close> \<open>t_source t = Inl qs\<close>
      by (metis prod.collapse) 
  qed


  (* is single input *)

  have "\<And> t1 t2 . t1 \<in> h SSep \<Longrightarrow> t2 \<in> h SSep \<Longrightarrow> t_source t1 = t_source t2 \<Longrightarrow> t_input t1 = t_input t2"
  proof -
    fix t1 t2 assume "t1 \<in> h SSep"
                 and "t2 \<in> h SSep"
                 and "t_source t1 = t_source t2"

    let ?q = "t_source t1"

    consider "t1 \<in> set d_old \<or> t1 \<in> set d_old_dist_left \<or> t1 \<in> set d_old_dist_right" | "t1 \<in> set d_left \<or> t1 \<in> set d_right"
      using d_containment_var \<open>t1 \<in> h SSep\<close> by auto
    then show "t_input t1 = t_input t2" proof cases
      case 1
      then have "t2 \<in> set d_old \<or> t2 \<in> set d_old_dist_left \<or> t2 \<in> set d_old_dist_right"
        using d_old_same_sources \<open>t2 \<in> h SSep\<close> \<open>t_source t1 = t_source t2\<close> by blast
      then obtain t2' where "t2' \<in> set d_old" and "t_source t2 = t_source t2'" and "t_input t2 = t_input t2'"
        using d_old_dist_left_d_old d_old_dist_right_d_old by metis 
  
      from 1 obtain t1' where "t1' \<in> set d_old" and "t_source t1 = t_source t1'" and "t_input t1 = t_input t1'"
        using d_old_dist_left_d_old d_old_dist_right_d_old by blast

      


      obtain qs1 qt1 where "t1' = (Inl qs1, t_input t1, t_output t1', Inl qt1)" 
                       and "(qs1, t_input t1, t_output t1', qt1) \<in> h S"
        using d_old_transitions[OF \<open>t1' \<in> set d_old\<close>] \<open>t_source t1 = t_source t1'\<close> \<open>t_input t1 = t_input t1'\<close> by metis

      obtain qs2 qt2 where "t2' = (Inl qs2, t_input t2, t_output t2', Inl qt2)" 
                       and "(qs2, t_input t2, t_output t2', qt2) \<in> h S"
        using d_old_transitions[OF \<open>t2' \<in> set d_old\<close>] \<open>t_source t2 = t_source t2'\<close> \<open>t_input t2 = t_input t2'\<close> by metis

      have "qs1 = qs2"
        using \<open>t1' = (Inl qs1, t_input t1, t_output t1', Inl qt1)\<close>
              \<open>t_source t1 = t_source t1'\<close>
              \<open>t_source t1 = t_source t2\<close>
              \<open>t_source t2 = t_source t2'\<close>
              \<open>t2' = (Inl qs2, t_input t2, t_output t2', Inl qt2)\<close>
        by (metis fst_conv old.sum.inject(1))
        
      then have "(qs1, t_input t2, t_output t2', qt2) \<in> h S"
        using \<open>(qs2, t_input t2, t_output t2', qt2) \<in> h S\<close> by auto

      show ?thesis
        using \<open>single_input S\<close> unfolding single_input.simps
        using \<open>(qs1, t_input t1, t_output t1', qt1) \<in> h S\<close> \<open>(qs1, t_input t2, t_output t2', qt2) \<in> h S\<close>
        by (metis fst_conv snd_conv)


    next
      case 2 
      then have "t2 \<in> set d_left \<or> t2 \<in> set d_right"
        using \<open>\<And> t1 t2 . t1 \<in> set d_left \<or> t1 \<in> set d_right \<Longrightarrow> t2 \<in> h SSep \<Longrightarrow> t_source t1 = t_source t2 \<Longrightarrow> t2 \<in> set d_left \<or> t2 \<in> set d_right\<close> \<open>t2 \<in> h SSep\<close> \<open>t_source t1 = t_source t2\<close> by blast

      obtain q1 where "t_source t1 = Inl q1"
                  and "q1 \<in> nodes S"
                  and "deadlock_state S q1"
                  and f1: "find
                         (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                     \<exists>t2\<in>set (wf_transitions M).
                                        t_source t1 = fst q1 \<and>
                                        t_source t2 = snd q1 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                         (inputs M) = Some (t_input t1)"
        using d_left_sources[of t1] d_right_sources[of t1]
        using "2" by blast 

      obtain q2 where "t_source t2 = Inl q2"
                  and "q2 \<in> nodes S"
                  and "deadlock_state S q2"
                  and f2 : "find
                         (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                     \<exists>t2\<in>set (wf_transitions M).
                                        t_source t1 = fst q2 \<and>
                                        t_source t2 = snd q2 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                         (inputs M) = Some (t_input t2)"
        using d_left_sources[of t2] d_right_sources[of t2]
        using \<open>t2 \<in> set d_left \<or> t2 \<in> set d_right\<close> by blast 

      

      show ?thesis
        using f1 f2 \<open>t_source t1 = t_source t2\<close>
        using \<open>t_source t1 = Inl q1\<close> \<open>t_source t2 = Inl q2\<close> by auto 
    qed
  qed
  then have "single_input SSep"
    unfolding single_input.simps by blast
  
  then have is_single_input : "single_input ?SSep" 
    using ssep_var by blast


  (* desired deadlock states are reachable *)

  have "Inr ?q1 \<in> nodes SSep"
  proof -
    obtain qd where "qd \<in> nodes S" and "deadlock_state S qd"
      using acyclic_deadlock_states[OF \<open>acyclic S\<close>] by blast
    show ?thesis
      using s_deadlock_transitions_left[OF \<open>qd \<in> nodes S\<close> \<open>deadlock_state S qd\<close>] 
      using wf_transition_target
      by fastforce
  qed
  then have has_node_left: "Inr ?q1 \<in> nodes ?SSep" 
    using \<open>SSep = ?SSep\<close> by blast

  have "Inr ?q2 \<in> nodes SSep"
  proof -
    obtain qd where "qd \<in> nodes S" and "deadlock_state S qd"
      using acyclic_deadlock_states[OF \<open>acyclic S\<close>] by blast
    show ?thesis
      using s_deadlock_transitions_right[OF \<open>qd \<in> nodes S\<close> \<open>deadlock_state S qd\<close>] 
      using wf_transition_target
      by fastforce
  qed
  then have has_node_right: "Inr ?q2 \<in> nodes ?SSep" 
    using \<open>SSep = ?SSep\<close> by blast



  have "\<And> q . q \<in> nodes SSep \<Longrightarrow> \<not> isl q \<Longrightarrow> deadlock_state SSep q"
  proof -
    fix q assume "q \<in> nodes SSep" and "\<not> isl q"
    have "q = Inr ?q1 \<or> q = Inr ?q2"
      using inl_prop[OF \<open>q \<in> nodes SSep\<close>] \<open>\<not> isl q\<close> by blast
    then show "deadlock_state SSep q" 
      using has_deadlock_left has_deadlock_right \<open>SSep = ?SSep\<close> by blast
  qed

  have isl_target_paths : "\<And> p . path SSep (initial SSep) p \<Longrightarrow> isl (target p (initial SSep)) \<Longrightarrow> (\<exists> p' . path S (initial S) p' \<and> p = map shift_Inl p')"
  proof -
    fix p assume "path SSep (initial SSep) p" and "isl (target p (initial SSep))"
    then show "(\<exists> p' . path S (initial S) p' \<and> p = map shift_Inl p')" 
    proof (induction p rule: rev_induct)
      case Nil
      then show ?case by auto
    next
      case (snoc t p)
      then have "path SSep (initial SSep) p" by auto
      moreover have "\<not> (deadlock_state SSep (target p (initial SSep)))"
        using deadlock_prefix[OF snoc.prems(1)]
        by (metis calculation deadlock_state.simps path_cons_elim path_equivalence_by_h path_suffix snoc.prems(1))  
      ultimately have "isl (target p (initial SSep))"
        using \<open>\<And> q . q \<in> nodes SSep \<Longrightarrow> \<not> isl q \<Longrightarrow> deadlock_state SSep q\<close>
        using nodes_path_initial by blast 

      then obtain p' where "path S (initial S) p'" and "p = map shift_Inl p'"
        using snoc.IH[OF \<open>path SSep (initial SSep) p\<close>] by blast

      have "isl (t_source t)"
        using \<open>isl (target p (initial SSep))\<close> snoc.prems(1)
        by auto 
      moreover have "isl (t_target t)"
        using snoc.prems(2) unfolding target.simps visited_states.simps by auto

      ultimately obtain qs qt where "t = (Inl qs, t_input t, t_output t, Inl qt)"
        by (metis prod.collapse sum.collapse(1))
      then have "(Inl qs, t_input t, t_output t, Inl qt) \<in> h SSep"
        using snoc.prems(1) by auto
      then have "(qs, t_input t, t_output t, qt) \<in> h S"
        using d_old_origins by blast


      have "map t_target p = map Inl (map t_target p')"
        using \<open>p = map shift_Inl p'\<close> by auto
      then have "(target p (initial SSep)) = Inl (target p' (initial S))"
        using \<open>initial SSep = Inl (initial S)\<close> unfolding target.simps visited_states.simps
        by (simp add: last_map) 


      then have "path S (initial S) (p'@[(qs, t_input t, t_output t, qt)])" 
        using \<open>path S (initial S) p'\<close> snoc.prems(1)
        by (metis (no_types, lifting) Inl_inject \<open>(qs, t_input t, t_output t, qt) \<in> set (wf_transitions S)\<close> \<open>t = (Inl qs, t_input t, t_output t, Inl qt)\<close> fst_conv list.inject not_Cons_self2 path.cases path_append_last path_suffix) 

      moreover have "p@[t] = map shift_Inl (p'@[(qs, t_input t, t_output t, qt)])"
        using \<open>p = map shift_Inl p'\<close> \<open>t = (Inl qs, t_input t, t_output t, Inl qt)\<close> by auto
      ultimately show ?case
        by meson 
    qed
  qed

  (* is acylic *)

  have "\<And> p . path SSep (initial SSep) p \<Longrightarrow> distinct (visited_states (initial SSep) p)"
  proof -
    fix p assume "path SSep (initial SSep) p"
    show "distinct (visited_states (initial SSep) p)"
    proof (cases "isl (target p (initial SSep))")
      case True
      then obtain p' where "path S (initial S) p'" and "p = map shift_Inl p'"
        using \<open>\<And> p . path SSep (initial SSep) p \<Longrightarrow> isl (target p (initial SSep)) \<Longrightarrow> (\<exists> p' . path S (initial S) p' \<and> p = map shift_Inl p')\<close>
              \<open>path SSep (initial SSep) p\<close> 
        by blast

      have "map t_target p = map Inl (map t_target p')"
        using \<open>p = map shift_Inl p'\<close> by auto
      then have "visited_states (initial SSep) p = map Inl (visited_states (initial S) p')"
        using \<open>initial SSep = Inl (initial S)\<close> unfolding target.simps visited_states.simps
        by simp 
      moreover have "distinct (visited_states (initial S) p')"
        using \<open>acyclic S\<close> \<open>path S (initial S) p'\<close> unfolding acyclic.simps by blast
      moreover have "\<And> xs :: ('a \<times> 'a) list . distinct xs = distinct (map Inl xs)" 
      proof -
        fix xs :: "('a \<times> 'a) list"
        show "distinct xs = distinct (map Inl xs)" by (induction xs; auto)
      qed
      ultimately show ?thesis
        by force         
    next
      case False 

      have "deadlock_state SSep (target p (initial SSep))"
        using False \<open>\<And> q . q \<in> nodes SSep \<Longrightarrow> \<not> isl q \<Longrightarrow> deadlock_state SSep q\<close>
        using \<open>path SSep (initial SSep) p\<close> nodes_path_initial by blast

      have "target p (initial SSep) \<noteq> initial SSep"
        using False \<open>initial SSep = Inl (initial S)\<close> by auto
      then have "p \<noteq> []"
        by auto
      then obtain t p' where "p = p'@[t]"
        using rev_exhaust by blast
      then have "\<not> (isl (t_target t))"
        using False unfolding target.simps visited_states.simps by auto

      have "path SSep (initial SSep) p'"
        using \<open>p = p'@[t]\<close> \<open>path SSep (initial SSep) p\<close> by auto
      
      show ?thesis proof (cases p' rule: rev_cases)
        case Nil
        then show ?thesis 
          using \<open>\<not> (isl (t_target t))\<close> \<open>p = p'@[t]\<close> unfolding target.simps visited_states.simps
          using \<open>target p (initial SSep) \<noteq> initial SSep\<close> by auto 
      next
        case (snoc p'' t')
        


        then have "isl (target p' (initial SSep))" 
          using \<open>p = p'@[t]\<close> deadlock_prefix[OF \<open>path SSep (initial SSep) p\<close>, of t']
          by (metis \<open>path SSep (initial SSep) p\<close> isl_source not_Cons_self2 path.cases path_suffix ssep_var)
        then obtain pS where "path S (initial S) pS" and "p' = map shift_Inl pS"
          using \<open>\<And> p . path SSep (initial SSep) p \<Longrightarrow> isl (target p (initial SSep)) \<Longrightarrow> (\<exists> p' . path S (initial S) p' \<and> p = map shift_Inl p')\<close>
                [OF \<open>path SSep (initial SSep) p'\<close>] by blast

        have "map t_target p' = map Inl (map t_target pS)"
          using \<open>p' = map shift_Inl pS\<close> by auto
        then have "visited_states (initial SSep) p' = map Inl (visited_states (initial S) pS)"
          using \<open>initial SSep = Inl (initial S)\<close> unfolding target.simps visited_states.simps
          by simp 
        moreover have "distinct (visited_states (initial S) pS)"
          using \<open>acyclic S\<close> \<open>path S (initial S) pS\<close> unfolding acyclic.simps by blast
        moreover have "\<And> xs :: ('a \<times> 'a) list . distinct xs = distinct (map Inl xs)" 
        proof -
          fix xs :: "('a \<times> 'a) list"
          show "distinct xs = distinct (map Inl xs)" by (induction xs; auto)
        qed
        ultimately have "distinct (visited_states (initial SSep) p')"
          by force
        moreover have "t_target t \<notin> set (visited_states (initial SSep) p')"
          using \<open>visited_states (initial SSep) p' = map Inl (visited_states (initial S) pS)\<close> \<open>\<not> (isl (t_target t))\<close>
          by auto 
        ultimately have "distinct ((visited_states (initial SSep) p')@[t_target t])"
          by auto
        then show ?thesis using \<open>p = p'@[t]\<close> unfolding target.simps visited_states.simps
          by simp 
      qed  
    qed
  qed 
  

  then have "acyclic SSep"
    unfolding acyclic.simps by blast
    
  
  then have is_acyclic : "acyclic ?SSep" 
    using \<open>SSep = ?SSep\<close> by blast

  (* all relevant transitions of the canonical separator are retained *)

  have inl_prop_prep: "\<And> t t' . t \<in> h SSep \<Longrightarrow> t' \<in> h CSep \<Longrightarrow> t_source t = t_source t' \<Longrightarrow> t_input t = t_input t' \<Longrightarrow> t' \<in> h SSep"
  proof -
    fix t t' assume "t \<in> h SSep" and "t' \<in> h CSep" and "t_source t = t_source t'" and "t_input t = t_input t'"

    have "t' \<in> h ?CSep"
          using \<open>t' \<in> h CSep\<close> \<open>CSep = ?CSep\<close> by auto

    show "t' \<in> h SSep"
    proof (cases "isl (t_target t')")
      case True

      obtain tP where "tP \<in> h ?PM" and "t' = (Inl (t_source tP), t_input tP, t_output tP, Inl (t_target tP))"
        using canonical_separator_product_h_isl[OF _ True]
        using \<open>t' \<in> h CSep\<close> \<open>CSep = ?CSep\<close>
        by metis

      from \<open>t \<in> h SSep\<close> consider 
        (old)         "t \<in> set d_old \<or> t \<in> set d_old_dist_left \<or> t \<in> set d_old_dist_right"  |
        (left_right)  "t \<in> set d_left \<or> t \<in> set d_right"
        using d_containment_var by blast
      then show "t' \<in> h SSep" proof cases
        case old

        then obtain tO where "tO \<in> set d_old" and "t_source t = t_source tO" and "t_input t = t_input tO"
          using d_old_dist_left_d_old d_old_dist_right_d_old by blast

        obtain tS where "tS \<in> h S" and "tO = (Inl (t_source tS), t_input tS, t_output tS, Inl (t_target tS))"
          using d_old_targets[OF \<open>tO \<in> set d_old\<close>] by auto
        
        have "t_source t = Inl (t_source tS)"
          using \<open>t_source t = t_source tO\<close> 
                \<open>tO = (Inl (t_source tS), t_input tS, t_output tS, Inl (t_target tS))\<close> by (metis fst_conv)

        have "t_source tS = t_source tP"
          using \<open>t_source t = Inl (t_source tS)\<close>
                \<open>t_source t = t_source t'\<close> 
                \<open>t' = (Inl (t_source tP), t_input tP, t_output tP, Inl (t_target tP))\<close>
          by auto

        have "t_input tS = t_input tP"
          using \<open>t_input t = t_input t'\<close>
                \<open>t_input t = t_input tO\<close>
                \<open>tO = (Inl (t_source tS), t_input tS, t_output tS, Inl (t_target tS))\<close>
                \<open>t' = (Inl (t_source tP), t_input tP, t_output tP, Inl (t_target tP))\<close>
          by auto

        have "tP \<in> h S"
          using \<open>retains_outputs_for_states_and_inputs ?PM S\<close>
          unfolding retains_outputs_for_states_and_inputs_def 
          using \<open>tS \<in> h S\<close> \<open>tP \<in> h ?PM\<close> \<open>t_source tS = t_source tP\<close> \<open>t_input tS = t_input tP\<close> by blast
        then have "shift_Inl tP \<in> h SSep"
          using ssep_transitions_from_old by blast   
        then show ?thesis
          using \<open>t' = (Inl (t_source tP), t_input tP, t_output tP, Inl (t_target tP))\<close> by blast  
      next
        case left_right
        then obtain q1 where "t_source t = Inl q1"
                  and "q1 \<in> nodes S"
                  and "deadlock_state S q1"
                  and f1: "find
                         (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                                     \<exists>t2\<in>set (wf_transitions M).
                                        t_source t1 = fst q1 \<and>
                                        t_source t2 = snd q1 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                         (inputs M) = Some (t_input t)"
          using d_left_sources[of t] d_right_sources[of t]
          by blast 
        have "\<not> (\<exists>t1\<in>set (wf_transitions M).
                         \<exists>t2\<in>set (wf_transitions M).
                            t_source t1 = fst q1 \<and>
                            t_source t2 = snd q1 \<and> t_input t1 = t_input t \<and> t_input t2 = t_input t \<and> t_output t1 = t_output t2)"
          using f1
          using find_condition by force 
        then have "\<not> (\<exists>t1\<in>set (wf_transitions (from_FSM M ?q1)).
                         \<exists>t2\<in>set (wf_transitions (from_FSM M ?q2)).
                            t_source t1 = fst q1 \<and>
                            t_source t2 = snd q1 \<and> t_input t1 = t_input t \<and> t_input t2 = t_input t \<and> t_output t1 = t_output t2)" 
          using from_FSM_h[OF assms(2)] from_FSM_h[OF assms(3)] by blast
        then have "\<not> (\<exists> tPM \<in> h ?PM . t_source tPM = q1 \<and> t_input tPM = t_input t)"
          by (metis product_transition_split_ob)

        
        moreover have "\<exists> tPM \<in> h ?PM . t_source tPM = q1 \<and> t_input tPM = t_input t" 
          using canonical_separator_product_h_isl[OF \<open>t' \<in> h ?CSep\<close> True] 
          using \<open>t_source t = t_source t'\<close> \<open>t_source t = Inl q1\<close> \<open>t_input t = t_input t'\<close> 
          by force
        ultimately have "False" by blast
        then show ?thesis by blast
      qed
    next
      case False

      have "t_target t' \<in> nodes CSep"
        using \<open>t' \<in> h CSep\<close> by auto

      
      have "t' \<notin> (set (shifted_transitions M ?q1 ?q2))"
        using False by (meson shifted_transitions_targets) 

      
      
      
      
      have *: "set (transitions ?CSep) = (set (shifted_transitions M ?q1 ?q2)) \<union> (set (distinguishing_transitions_left M ?q1 ?q2)) \<union> (set (distinguishing_transitions_right M ?q1 ?q2))"
        using canonical_separator_simps(4)[of M ?q1 ?q2] by auto
      then have t'_cases : "t' \<in> set (distinguishing_transitions_left M ?q1 ?q2) \<or> t' \<in> set (distinguishing_transitions_right M ?q1 ?q2)"
        using \<open>CSep = ?CSep\<close> \<open>t' \<in> h CSep\<close> 
        using canonical_separator_targets_ineq(1)[OF \<open>t' \<in> h ?CSep\<close> assms(2,3,4)] False
        by (metis UnE shifted_transitions_targets wf_transition_simp)

      from \<open>t \<in> h SSep\<close> consider 
          (old)         "t \<in> set d_old \<or> t \<in> set d_old_dist_left \<or> t \<in> set d_old_dist_right" |
          (left_right)  "t \<in> set d_left \<or> t \<in> set d_right"
        using d_containment_var by blast
      then have "t' \<in> set (transitions SSep)" proof cases
        case old
        
        show ?thesis proof (cases "t' \<in> set d_old \<union> set d_left \<union> set d_right")
          case True
          then show ?thesis using d_containment_var by blast
        next
          case False
          moreover have "(\<exists>t''\<in>set d_old. t_source t' = t_source t'' \<and> t_input t' = t_input t'')"
            using old \<open>t_source t = t_source t'\<close> \<open>t_input t = t_input t'\<close> 
            using d_old_dist_left_d_old 
            using d_old_dist_right_d_old by metis
          ultimately have "t' \<in> set d_old_dist_left \<or> t' \<in> set d_old_dist_right"
            using t'_cases d_old_dist_left_var d_old_dist_right_var by auto
          then show ?thesis using d_containment_var by blast
        qed
      next
        case left_right
        
        then obtain q where "t_source t = Inl q"
                  and "q \<in> nodes S"
                  and "deadlock_state S q"
                  and "find
                   (\<lambda>x. \<not> (\<exists>t1\<in>set (wf_transitions M).
                               \<exists>t2\<in>set (wf_transitions M).
                                  t_source t1 = fst q \<and>
                                  t_source t2 = snd q \<and>
                                  t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))
                   (inputs M) = Some (t_input t)"
                  and "t_input t \<in> set (inputs SSep)"
                  and "t_output t \<in> set (outputs SSep)"
          using d_left_sources d_right_sources by blast

        then have "choose_state_separator_deadlock_input M S q = Some (t_input t)"
          unfolding choose_state_separator_deadlock_input_def by auto

        from t'_cases consider
          (t'_left)  "t' \<in> set (distinguishing_transitions_left M ?q1 ?q2)" | 
          (t'_right) "t' \<in> set (distinguishing_transitions_right M ?q1 ?q2)" by blast
        then show ?thesis proof cases
          case t'_left

          obtain q1' q2' tC where "t_source t' = Inl (q1', q2')"
                             and "q1' \<in> nodes M"
                             and "q2' \<in> nodes M"
                             and "tC \<in> set (wf_transitions M)"
                             and "t_source tC = q1'"
                             and "t_input tC = t_input t'"
                             and "t_output tC = t_output t'"
                             and "\<not> (\<exists>t''\<in>set (wf_transitions M). t_source t'' = q2' \<and> t_input t'' = t_input t' \<and> t_output t'' = t_output t')"
            using distinguishing_transitions_left_sources_targets[OF t'_left assms(2,3)] by blast
  
          have "q = (q1',q2')"
            using \<open>t_source t = Inl q\<close> \<open>t_source t' = Inl (q1',q2')\<close> \<open>t_source t = t_source t'\<close> by auto
          moreover have "q \<in> nodes ?PM"
            using \<open>q \<in> nodes S\<close> submachine_nodes[OF \<open>is_submachine S ?PM\<close>] by blast
          ultimately have "(q1',q2') \<in> nodes ?PM"
            by auto
  
          have "t_target t' = Inr ?q1"
            using t'_left unfolding distinguishing_transitions_left_def by force
  
  
          have p1: "((q1',q2'), tC) \<in> set (concat
                    (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                      (nodes_from_distinct_paths
                        (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))" 
            using concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths ?PM"] 
                  \<open>(q1',q2') \<in> nodes ?PM\<close> nodes_code[of ?PM]   \<open>tC \<in> set (wf_transitions M)\<close> by fastforce
  
          have p2: "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                         choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) ((q1',q2'), tC)"
          proof
            show "t_source (snd ((q1', q2'), tC)) = fst (fst ((q1', q2'), tC))"
              using \<open>t_source tC = q1'\<close> by simp
            show "choose_state_separator_deadlock_input M S (fst ((q1', q2'), tC)) = Some (t_input (snd ((q1', q2'), tC)))"
              using \<open>t_input tC = t_input t'\<close> \<open>choose_state_separator_deadlock_input M S q = Some (t_input t)\<close> \<open>q = (q1',q2')\<close> \<open>t_input t = t_input t'\<close> by force
          qed
  
          have p3: "t' = (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S)))) ((q1',q2'), tC)"
          proof -
            let ?t = "(Inl (fst ((q1', q2'), tC)), t_input (snd ((q1', q2'), tC)), t_output (snd ((q1', q2'), tC)), Inr (fst (initial S)))"
  
            have *: "\<And> t1 t2 . t_source t1 = t_source t2 \<Longrightarrow> t_input t1 = t_input t2 \<Longrightarrow> t_output t1 = t_output t2 \<Longrightarrow> t_target t1 = t_target t2 \<Longrightarrow> t1 = t2"
              by auto
  
            have "t_source t' = t_source ?t" using \<open>t_source t' = Inl (q1', q2')\<close> by auto
            moreover have "t_input t' = t_input ?t" using \<open>t_input tC = t_input t'\<close> by auto
            moreover have "t_output t' = t_output ?t" using \<open>t_output tC = t_output t'\<close> by auto
            moreover have "t_target t' = t_target ?t" using \<open>t_target t' = Inr ?q1\<close>  by auto
            ultimately show "t' = ?t" 
              using *[of t' ?t] by simp
          qed
  
          have f_scheme : "\<And> x x' f g xs . x \<in> set xs \<Longrightarrow> g x \<Longrightarrow> x' = f x \<Longrightarrow> x' \<in> set (map f (filter g xs))" 
            by auto
  
          have "t' \<in> set ?d_left"               
            using f_scheme[of "((q1',q2'), tC)", OF p1, of "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                         choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))" t', OF p2,
                         of "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (fst (initial S))))", OF p3]
            by assumption
          then have "t' \<in> set d_left"
            using d_left_var by blast
          then show ?thesis using d_containment_var by blast
        next
          case t'_right

          obtain q1' q2' tC where "t_source t' = Inl (q1', q2')"
                             and "q1' \<in> nodes M"
                             and "q2' \<in> nodes M"
                             and "tC \<in> set (wf_transitions M)"
                             and "t_source tC = q2'"
                             and "t_input tC = t_input t'"
                             and "t_output tC = t_output t'"
                             and "\<not> (\<exists>t''\<in>set (wf_transitions M). t_source t'' = q1' \<and> t_input t'' = t_input t' \<and> t_output t'' = t_output t')"
            using distinguishing_transitions_right_sources_targets[OF t'_right assms(2,3)] by blast
  
          have "q = (q1',q2')"
            using \<open>t_source t = Inl q\<close> \<open>t_source t' = Inl (q1',q2')\<close> \<open>t_source t = t_source t'\<close> by auto
          moreover have "q \<in> nodes ?PM"
            using \<open>q \<in> nodes S\<close> submachine_nodes[OF \<open>is_submachine S ?PM\<close>] by blast
          ultimately have "(q1',q2') \<in> nodes ?PM"
            by auto
  
          have "t_target t' = Inr ?q2"
            using t'_right unfolding distinguishing_transitions_right_def by force
  
  
          have p1: "((q1',q2'), tC) \<in> set (concat
                    (map (\<lambda>qq'. map (Pair qq') (wf_transitions M))
                      (nodes_from_distinct_paths
                        (product (from_FSM M (fst (initial S))) (from_FSM M (snd (initial S)))))))" 
            using concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths ?PM"] 
                  \<open>(q1',q2') \<in> nodes ?PM\<close> nodes_code[of ?PM]   \<open>tC \<in> set (wf_transitions M)\<close> by fastforce
  
          have p2: "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                         choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt))) ((q1',q2'), tC)"
          proof
            show "t_source (snd ((q1', q2'), tC)) = snd (fst ((q1', q2'), tC))"
              using \<open>t_source tC = q2'\<close> by simp
            show "choose_state_separator_deadlock_input M S (fst ((q1', q2'), tC)) = Some (t_input (snd ((q1', q2'), tC)))"
              using \<open>t_input tC = t_input t'\<close> \<open>choose_state_separator_deadlock_input M S q = Some (t_input t)\<close> \<open>q = (q1',q2')\<close> \<open>t_input t = t_input t'\<close> by force
          qed
  
          have p3: "t' = (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S)))) ((q1',q2'), tC)"
          proof -
            let ?t = "(Inl (fst ((q1', q2'), tC)), t_input (snd ((q1', q2'), tC)), t_output (snd ((q1', q2'), tC)), Inr (snd (initial S)))"
  
            have *: "\<And> t1 t2 . t_source t1 = t_source t2 \<Longrightarrow> t_input t1 = t_input t2 \<Longrightarrow> t_output t1 = t_output t2 \<Longrightarrow> t_target t1 = t_target t2 \<Longrightarrow> t1 = t2"
              by auto
  
            have "t_source t' = t_source ?t" using \<open>t_source t' = Inl (q1', q2')\<close> by auto
            moreover have "t_input t' = t_input ?t" using \<open>t_input tC = t_input t'\<close> by auto
            moreover have "t_output t' = t_output ?t" using \<open>t_output tC = t_output t'\<close> by auto
            moreover have "t_target t' = t_target ?t" using \<open>t_target t' = Inr ?q2\<close>  by auto
            ultimately show "t' = ?t" 
              using *[of t' ?t] by simp
          qed
  
          have f_scheme : "\<And> x x' f g xs . x \<in> set xs \<Longrightarrow> g x \<Longrightarrow> x' = f x \<Longrightarrow> x' \<in> set (map f (filter g xs))" 
            by auto
  
          have "t' \<in> set ?d_right"               
            using f_scheme[of "((q1',q2'), tC)", OF p1, of "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                         choose_state_separator_deadlock_input M S (fst qqt) = Some (t_input (snd qqt)))" t', OF p2,
                         of "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr (snd (initial S))))", OF p3]
            by assumption
          then have "t' \<in> set d_right"
            using d_right_var by blast
          then show ?thesis using d_containment_var by blast
        qed
      qed

      have "t_source t' \<in> nodes SSep"
        using \<open>t_source t = t_source t'\<close> \<open>t \<in> h SSep\<close> by auto

      have "inputs SSep = inputs CSep"
        using \<open>inputs SSep = inputs M\<close>
        using csep_var unfolding canonical_separator_def by simp
      then have "t_input t' \<in> set (inputs SSep)"
        using \<open>t' \<in> h CSep\<close> unfolding wf_transitions.simps by auto 
      
      have "outputs SSep = outputs CSep"
        using \<open>outputs SSep = outputs M\<close>
        using csep_var unfolding canonical_separator_def by simp
      then have "t_output t' \<in> set (outputs SSep)"
        using \<open>t' \<in> h CSep\<close> unfolding wf_transitions.simps by auto

      show ?thesis 
        using \<open>t' \<in> set (transitions SSep)\<close>
        using \<open>t_source t' \<in> nodes SSep\<close> 
        using \<open>t_input t' \<in> set (inputs SSep)\<close>
        using \<open>t_output t' \<in> set (outputs SSep)\<close> by auto
    qed
  qed

  

  have "\<And> q x t t' . q \<in> nodes SSep \<Longrightarrow>
                             x \<in> set (inputs CSep) \<Longrightarrow>
                             t \<in> h SSep \<Longrightarrow> t_source t = q \<Longrightarrow> t_input t = x \<Longrightarrow>
                             t' \<in> h CSep \<Longrightarrow>
                                 t_source t' = q \<Longrightarrow> t_input t' = x \<Longrightarrow> t' \<in> h SSep" 
  proof -
    fix q x t t' assume "q \<in> nodes SSep"
                    and "x \<in> set (inputs CSep)"
                    and "t \<in> h SSep" and "t_source t = q" and "t_input t = x"
                    and "t' \<in> h CSep" 
                    and "t_source t' = q" and "t_input t' = x"
    then have "t \<in> h SSep \<and> t' \<in> h CSep \<and> t_source t = t_source t' \<and> t_input t = t_input t'"
      by auto
    then show "t' \<in> h SSep"
      using inl_prop_prep by blast
  qed
    


  then have has_retains_property: "\<forall>q\<in>nodes ?SSep.
        \<forall>x\<in>set (inputs ?CSep).
           (\<exists>t \<in> h ?SSep . t_source t = q \<and> t_input t = x) \<longrightarrow>
           (\<forall>t' \<in> h ?CSep.
               t_source t' = q \<and> t_input t' = x \<longrightarrow>
               t' \<in> h ?SSep)" 
    using ssep_var csep_var by blast
    
  show ?thesis
    unfolding is_state_separator_from_canonical_separator_def
    using is_sub is_single_input is_acyclic has_deadlock_left has_deadlock_right has_node_left has_node_right has_inl_property has_retains_property
    by presburger
qed



subsection \<open>Calculating a State Separator by Reachability Analysis\<close>




(*
   Function that iteratively calculates state and input pairs (q,x) using states of a given FSM
   such that (q,x) is contained in the result if x is not defined for q or if all transitions for
   x from q reach states calculated in previous iterations and each state occurs at most once in the 
   result.
   The functions is to be applied on the product machine whose initial state is a pair of states to
   find a state-separator for, such that if x is not defined on q, then the left and right state
   component of q share no common reaction to x. 
*)
  
 
fun s_states :: "'a FSM \<Rightarrow> nat \<Rightarrow> ('a \<times> Input) list" where
  "s_states C 0 = []" |
  "s_states C (Suc k) =  
    (if length (s_states C k) < k 
      then (s_states C k)
      else (case find 
                  (\<lambda> qx . (\<forall> qx' \<in> set (s_states C k) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h C . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states C k) . fst qx' = (t_target t)))) 
                  (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs C)) (nodes_from_distinct_paths C)))
            of Some qx \<Rightarrow> (s_states C k)@[qx] | 
               None \<Rightarrow> (s_states C k)))"

fun s_states' :: "('a \<times> Input) list \<Rightarrow> 'a Transition set \<Rightarrow> nat \<Rightarrow> ('a \<times> Input) list" where
  "s_states' QX H 0 = []" |
  "s_states' QX H (Suc k) = (let Q = s_states' QX H k in 
    (if length Q < k 
      then Q
      else (case find (\<lambda> qx . (\<forall> qx' \<in> set Q . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> H . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set Q . fst qx' = (t_target t)))) QX
            of Some qx \<Rightarrow> Q@[qx] | 
               None \<Rightarrow> Q)))"

(* Slightly more efficient formulation of s_states, avoids some repeated calculations *)
fun s_states_opt :: "'a FSM \<Rightarrow> nat \<Rightarrow> ('a \<times> Input) list" where
  "s_states_opt C k = s_states' (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs C)) (nodes_from_distinct_paths C))) (h C) k"



lemma s_states_code : "s_states M k = s_states_opt M k"  
proof (induction k)
  case 0
  then show ?case 
    unfolding s_states.simps s_states_opt.simps s_states'.simps by blast
next
  case (Suc k)
  then show ?case 
    unfolding s_states.simps s_states_opt.simps s_states'.simps Let_def
    by presburger 
qed
  

lemma s_states_length :
  "length (s_states M k) \<le> k"
proof (induction k)
  case 0
  then show ?case by auto 
next
  case (Suc k)
  show ?case
  proof (cases "length (s_states M k) < k")
    case True
    then show ?thesis unfolding s_states.simps
      by simp 
  next
    case False
    then have "s_states M (Suc k) = (case find
                    (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and>
                          (\<forall>t\<in>set (wf_transitions M).
                              t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                              (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t)))
                    (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of
              None \<Rightarrow> (s_states M k) | Some qx \<Rightarrow> (s_states M k) @ [qx])" 
      unfolding s_states.simps by presburger
    then show ?thesis using Suc
      by (metis (mono_tags, lifting) False Suc_lessD eq_iff leI length_append_singleton option.case_eq_if)
  qed
qed

lemma s_states_prefix :
  assumes "i \<le> k"
  shows "take i (s_states M k) = s_states M i"
  using assms proof (induction k)
  case 0
  then show ?case unfolding s_states.simps
    by (metis le_zero_eq  s_states.simps(1) s_states_length take_all) 
next
  case (Suc k)
  then show ?case proof (cases "i < Suc k")
    case True
    then have "take i (s_states M k) = s_states M i"
      using Suc by auto
    then have "length (s_states M i) \<le> length (s_states M k)"
      by (metis dual_order.trans nat_le_linear s_states_length take_all)
    moreover have "take (length (s_states M k)) (s_states M (Suc k)) = s_states M k"
      unfolding s_states.simps
      by (simp add: option.case_eq_if) 
    ultimately have "take i (s_states M (Suc k)) = take i (s_states M k)"
      unfolding s_states.simps (* TODO: refactor auto-generated proof *)
    proof -
      have f1: "\<forall>ps f z. if z = None then (case z of None \<Rightarrow> ps::('a \<times> integer) list | Some (x::'a \<times> integer) \<Rightarrow> f x) = ps else (case z of None \<Rightarrow> ps | Some x \<Rightarrow> f x) = f (the z)"
        by force
      { assume "\<not> i < length (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p])"
        then have "length (s_states M k) \<noteq> k \<or> length (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) \<noteq> Suc (length (s_states M k))"
          using True by linarith
        then have "(if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = s_states M k @ [the (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))))] \<longrightarrow> take i (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = take i (s_states M k)"
          using nat_less_le s_states_length by auto }
      moreover
      { assume "(if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) \<noteq> s_states M k @ [the (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))))]"
        moreover
        { assume "(case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) \<noteq> s_states M k @ [the (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))))]"
          then have "find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) = None"
            using f1 by meson
          then have "take i (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = take i (s_states M k)"
            using f1 by presburger }
        ultimately have "take i (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = take i (s_states M k)"
          by presburger }
      ultimately have "take i (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<and> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = take i (s_states M k)"
        by fastforce
        then show "take i (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa\<in>set (s_states M k). fst p \<noteq> fst pa) \<and> (\<forall>pa\<in>set (wf_transitions M). t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p\<in>set (s_states M k). fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = take i (s_states M k)"
      proof -
        have f1: "\<forall>ps psa psb psc. (take (length (psc::('a \<times> integer) list)) psa = psc \<or> ps @ psb \<noteq> psa) \<or> take (length psc) ps \<noteq> psc"
          by force
        { assume "take i (s_states M (Suc k)) = take i (s_states M k)"
          then have ?thesis
            by simp }
        moreover
        { assume "\<exists>n. take n (s_states M (Suc k)) \<noteq> take n (s_states M k) \<and> n \<le> k"
          then have "\<exists>n. take (min k n) (s_states M (Suc k)) \<noteq> take n (s_states M k) \<and> take (min k n) (s_states M k) = take n (s_states M k)"
            by (metis min.absorb2)
          then have "length (s_states M k) \<noteq> k"
            using f1 by (metis (no_types) \<open>take (length (s_states M k)) (s_states M (Suc k)) = s_states M k\<close> append_eq_conv_conj length_take)
          then have ?thesis
            by (simp add: nat_less_le s_states_length) }
        ultimately show ?thesis
          using True less_Suc_eq_le by blast
      qed
          
        
    qed 
    then show ?thesis 
      using \<open>take i (s_states M k) = s_states M i\<close> by simp
  next
    case False 
    then have "i = Suc k" using Suc.prems by auto
    
    then show ?thesis
      using s_states_length take_all by blast
  qed
qed

lemma s_states_self_length :
  "s_states M k = s_states M (length (s_states M k))" 
  using s_states_prefix 
  by (metis (no_types) nat_le_linear s_states_length s_states_prefix take_all)



lemma s_states_index_properties : 
  assumes "i < length (s_states M k)"
shows "fst (s_states M k ! i) \<in> nodes M" 
      "snd (s_states M k ! i) \<in> set (inputs M)"
      "(\<forall> qx' \<in> set (take i (s_states M k)) . fst (s_states M k ! i) \<noteq> fst qx')" 
      "(\<forall> t \<in> h M . (t_source t = fst (s_states M k ! i) \<and> t_input t = snd (s_states M k ! i)) \<longrightarrow> (\<exists> qx' \<in> set (take i (s_states M k)) . fst qx' = (t_target t)))"
proof -
  have combined_properties: "fst (s_states M k ! i) \<in> nodes M 
       \<and> snd (s_states M k ! i) \<in> set (inputs M)
       \<and> (\<forall> qx' \<in> set (take i (s_states M k)) . fst (s_states M k ! i) \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst (s_states M k ! i) \<and> t_input t = snd (s_states M k ! i)) \<longrightarrow> (\<exists> qx' \<in> set (take i (s_states M k)) . fst qx' = (t_target t)))"
    using assms proof (induction k)
    case 0
    then have "i = 0" by auto 
    then have "s_states M 0 \<noteq> []"
      using 0 by auto
    then obtain qx where qx_def : "s_states M 0 = [qx]"
      unfolding s_states.simps
      by (metis (no_types, lifting) option.case_eq_if) 
    then have *: "find 
            (\<lambda> qx . \<not> (\<exists> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx))) 
            (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs M)) (nodes_from_distinct_paths M))) = Some qx"
      unfolding s_states.simps
      by (metis (mono_tags, lifting) \<open>s_states M 0 = [qx]\<close> \<open>s_states M 0 \<noteq> []\<close>)
    
    have "\<not> (\<exists>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx)"
      using find_condition[OF *] by assumption
    have "qx \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M)))"
      using find_set[OF *] by assumption
    then have "fst qx \<in> nodes M \<and> snd qx \<in> set (inputs M)"
      using nodes_code[of M]
      by (metis (no_types, lifting) concat_map_elem fst_conv list_map_source_elem snd_conv)
    moreover have "(\<forall> qx' \<in> set (take i (s_states M 0)) . fst (s_states M 0 ! i) \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst (s_states M 0 ! i) \<and> t_input t = snd (s_states M 0 ! i)) \<longrightarrow> (\<exists> qx' \<in> set (take i (s_states M 0)) . fst qx' = (t_target t)))"
      using \<open>i = 0\<close>
      using \<open>\<not> (\<exists>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx)\<close> qx_def by auto     
    moreover have "s_states M 0 ! i = qx"
      using \<open>i = 0\<close> qx_def by simp
    ultimately show ?case by blast
  next
    case (Suc k)
    show ?case proof (cases "i < length (s_states M k)")
      case True
      then have "s_states M k ! i = s_states M (Suc k) ! i"
        using s_states_prefix[of i]
      proof -
        have "\<forall>n na. \<not> n < na \<or> Suc n \<le> na"
          by (meson Suc_leI)
        then show ?thesis
          by (metis Suc.prems \<open>i < length (s_states M k)\<close> s_states_prefix s_states_self_length take_last_index)
      qed
      moreover have "take i (s_states M k) = take i (s_states M (Suc k))"
        by (metis Suc.prems Suc_leI less_le_trans nat_less_le not_le s_states_length s_states_prefix)
      ultimately show ?thesis using Suc.IH[OF True] by presburger
    next
      case False
      then have "i = length (s_states M k)"
      proof -
        have "length (s_states M k) = k"
          by (metis (no_types) False Suc.prems nat_less_le s_states.simps(2) s_states_length)
        then show ?thesis
          by (metis (no_types) False Suc.prems Suc_leI leI less_le_trans nat_less_le s_states_length)
      qed
      then have "(s_states M (Suc k)) ! i = last (s_states M (Suc k))"
        by (metis (no_types, lifting) Suc.prems nat_less_le s_states.simps(2) s_states_code s_states_length take_all take_last_index)
      then have "(s_states M (Suc k)) = (s_states M k)@[last (s_states M (Suc k))]"
      proof -
        have "i = k"
          by (metis (no_types) Suc.prems \<open>i = length (s_states M k)\<close> nat_less_le s_states.simps(2) s_states_length)
        then show ?thesis
          by (metis Suc.prems Suc_n_not_le_n \<open>s_states M (Suc k) ! i = last (s_states M (Suc k))\<close> nat_le_linear s_states_prefix take_Suc_conv_app_nth)
      qed 
      then have *: "find 
                  (\<lambda> qx . (\<forall> qx' \<in> set (s_states M k) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states M k) . fst qx' = (t_target t)))) 
                  (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs M)) (nodes_from_distinct_paths M))) = Some (last (s_states M (Suc k)))"
        unfolding s_states.simps(2)
      proof -
        assume "(if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx]) = s_states M k @ [last (if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx])]"
        then have f1: "\<not> length (s_states M k) < k"
          by force
        then have f2: "last (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = last (case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p])"
          by presburger
        have "\<not> length (s_states M k) < k \<and> s_states M k @ [last (s_states M k)] \<noteq> s_states M k"
          using f1 by simp
        then have "find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) \<noteq> None"
        proof -
          have "s_states M k @ [last (if length (s_states M k) < k then s_states M k else case None of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p])] \<noteq> (case None of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p])"
            by force
          then show ?thesis
            by (metis (full_types, lifting) \<open>(if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx]) = s_states M k @ [last (if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx])]\<close> \<open>\<not> length (s_states M k) < k \<and> s_states M k @ [last (s_states M k)] \<noteq> s_states M k\<close>)
        qed
        then have "Some (last (case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p])) = find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M)))"
          using option.collapse by fastforce
        then show "find (\<lambda>p. (\<forall>pa\<in>set (s_states M k). fst p \<noteq> fst pa) \<and> (\<forall>pa\<in>set (wf_transitions M). t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p\<in>set (s_states M k). fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) = Some (last (if length (s_states M k) < k then s_states M k else case find (\<lambda>p. (\<forall>pa\<in>set (s_states M k). fst p \<noteq> fst pa) \<and> (\<forall>pa\<in>set (wf_transitions M). t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p\<in>set (s_states M k). fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]))"
          using f2 by metis
      qed

      
      let ?qx = "last (s_states M (Suc k))"
      
      have "(\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and>
         (\<forall>t\<in>set (wf_transitions M).
             t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
             (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) ?qx"
        using find_condition[OF *] \<open>(s_states M (Suc k)) ! i = last (s_states M (Suc k))\<close> by force


      
      

      have "?qx \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M)))"
        using find_set[OF *] by assumption
      then have "fst ?qx \<in> nodes M \<and> snd ?qx \<in> set (inputs M)"
        using nodes_code[of M] concat_pair_set[of "inputs M" "nodes_from_distinct_paths M"] by blast
      moreover have "(\<forall>qx'\<in>set (take i (s_states M (Suc k))). fst ?qx \<noteq> fst qx')"
        by (metis find_condition[OF *] \<open>i = length (s_states M k)\<close> \<open>s_states M (Suc k) = s_states M k @ [last (s_states M (Suc k))]\<close> append_eq_conv_conj)
      moreover have "(\<forall>t\<in>set (wf_transitions M).
        t_source t = fst (s_states M (Suc k) ! i) \<and> t_input t = snd (s_states M (Suc k) ! i) \<longrightarrow>
        (\<exists>qx'\<in>set (take i (s_states M (Suc k))). fst qx' = t_target t))"
        using find_condition[OF *] \<open>(s_states M (Suc k)) ! i = last (s_states M (Suc k))\<close>
        by (metis \<open>i = length (s_states M k)\<close> le_imp_less_Suc less_or_eq_imp_le s_states_length s_states_prefix s_states_self_length) 
      ultimately show ?thesis by (presburger add: \<open>(s_states M (Suc k)) ! i = last (s_states M (Suc k))\<close>)
    qed
  qed

  show "fst (s_states M k ! i) \<in> nodes M" 
       "snd (s_states M k ! i) \<in> set (inputs M)"
       "(\<forall> qx' \<in> set (take i (s_states M k)) . fst (s_states M k ! i) \<noteq> fst qx')" 
       "(\<forall> t \<in> h M . (t_source t = fst (s_states M k ! i) \<and> t_input t = snd (s_states M k ! i)) \<longrightarrow> (\<exists> qx' \<in> set (take i (s_states M k)) . fst qx' = (t_target t)))"
    using combined_properties by presburger+
qed


  






lemma s_states_distinct_states :
  "distinct (map fst (s_states M k))" 
proof -
  have "(\<And>i. i < length (map fst (s_states M k)) \<Longrightarrow>
          map fst (s_states M k) ! i \<notin> set (take i (map fst (s_states M k))))"
    using s_states_index_properties(3)[of _ M k]
    by (metis (no_types, lifting) length_map list_map_source_elem nth_map take_map) 
  then show ?thesis
    using list_distinct_prefix[of "map fst (s_states M k)"] by blast
qed



lemma s_states_nodes : 
  "set (map fst (s_states M k)) \<subseteq> nodes M"
  using s_states_index_properties(1)[of _ M k]  list_property_from_index_property[of "map fst (s_states M k)" "\<lambda>q . q \<in> nodes M"]
  by fastforce

lemma s_states_size :
  "length (s_states M k) \<le> size M"
proof -
  show ?thesis 
    using s_states_nodes[of M k]
          s_states_distinct_states[of M k]
          nodes_finite[of M]
    by (metis card_mono distinct_card length_map size.simps) 
qed
  
lemma s_states_max_iterations :
  assumes "k \<ge> size M"
  shows "s_states M k = s_states M (size M)"
  using s_states_size[of M k] s_states_prefix[OF assms, of M]
  by simp 



lemma s_states_by_index :
  assumes "i < length (s_states M k)"
  shows "(s_states M k) ! i = last (s_states M (Suc i))"
  by (metis Suc_leI assms s_states_prefix s_states_self_length take_last_index) 














lemma s_states_induces_state_separator_helper_h :
  assumes "t \<in> h \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                      inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                      outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                      transitions = 
                         filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                      (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M \<rparr>"
  shows "(t_source t, t_input t) \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k)" 
  using assms by force

lemma s_states_induces_state_separator_helper_single_input :
  "single_input \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                      inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                      outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                      transitions = 
                         filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                      (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M \<rparr>"
  (is "single_input ?S")
proof -
  have "\<And> t1 t2 . t1 \<in> h ?S \<Longrightarrow> t2 \<in> h ?S \<Longrightarrow> t_source t1 = t_source t2 \<Longrightarrow> t_input t1 = t_input t2"
  proof -
    fix t1 t2 assume "t1 \<in> h ?S"
                 and "t2 \<in> h ?S"
                 and "t_source t1 = t_source t2"

    have "(t_source t1, t_input t1) \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k)"
      using s_states_induces_state_separator_helper_h[OF \<open>t1 \<in> h ?S\<close>] by assumption
    moreover have "(t_source t1, t_input t2) \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k)"
      using s_states_induces_state_separator_helper_h[OF \<open>t2 \<in> h ?S\<close>] \<open>t_source t1 = t_source t2\<close> by auto
    ultimately show "t_input t1 = t_input t2"
      using s_states_distinct_states[of "product (from_FSM M q1) (from_FSM M q2)" k]
      by (meson eq_key_imp_eq_value) 
  qed
  then show ?thesis
    unfolding single_input.simps by blast
qed


lemma s_states_induces_state_separator_helper_retains_outputs :
  "retains_outputs_for_states_and_inputs 
          (product (from_FSM M q1) (from_FSM M q2)) 
              \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                transitions = 
                   filter 
                     (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M \<rparr>"
  (is "retains_outputs_for_states_and_inputs ?PM ?S")
proof -
  have "\<And> tS tM . tS \<in> h ?S \<Longrightarrow> tM \<in> h ?PM \<Longrightarrow> t_source tS = t_source tM \<Longrightarrow> t_input tS = t_input tM \<Longrightarrow> tM \<in> h ?S"
  proof -
    fix tS tM assume "tS \<in> h ?S" 
                 and "tM \<in> h ?PM" 
                 and "t_source tS = t_source tM" 
                 and "t_input tS = t_input tM"

    have "(t_source tS, t_input tS) \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k)"
      using s_states_induces_state_separator_helper_h[OF \<open>tS \<in> h ?S\<close>] by assumption
    then have "\<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source tS = fst qqx \<and> t_input tS = snd qqx"
      by force
    then have "\<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source tM = fst qqx \<and> t_input tM = snd qqx"
      using \<open>t_source tS = t_source tM\<close> \<open>t_input tS = t_input tM\<close> by simp
    then have "tM \<in> set (transitions ?S)"
      using \<open>tM \<in> h ?PM\<close> by force
    moreover have "t_source tM \<in> nodes ?S"
      using \<open>t_source tS = t_source tM\<close> \<open>tS \<in> h ?S\<close>
      by (metis (no_types, lifting) wf_transition_simp) 
    ultimately show "tM \<in> h ?S"
      by simp
  qed
  then show ?thesis
    unfolding retains_outputs_for_states_and_inputs_def by blast
qed



lemma s_states_subset :
  "set (s_states M k) \<subseteq> set (s_states M (Suc k))"
  unfolding s_states.simps
  by (simp add: option.case_eq_if subsetI) 

lemma s_states_last :
  assumes "s_states M (Suc k) \<noteq> s_states M k"
  shows "\<exists> qx . s_states M (Suc k) = (s_states M k)@[qx]
                \<and> (\<forall> qx' \<in> set (s_states M k) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states M k) . fst qx' = (t_target t)))
                \<and> fst qx \<in> nodes M
                \<and> snd qx \<in> set (inputs M)"
proof -
  have *: "\<not> (length (s_states M k) < k) \<and> find
          (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and>
                (\<forall>t\<in>set (wf_transitions M).
                    t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                    (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t)))
          (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) \<noteq> None"
    using assms unfolding s_states.simps
    by (metis (no_types, lifting) option.simps(4))

  then obtain qx where qx_find: "find
          (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and>
                (\<forall>t\<in>set (wf_transitions M).
                    t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                    (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t)))
          (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) = Some qx"
    by blast

  then have "s_states M (Suc k) = (s_states M k)@[qx]"
    using * by auto
  moreover have "(\<forall> qx' \<in> set (s_states M k) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states M k) . fst qx' = (t_target t)))"
    using find_condition[OF qx_find] by assumption
  moreover have "fst qx \<in> nodes M
                \<and> snd qx \<in> set (inputs M)"
    using find_set[OF qx_find]
  proof -
    have "fst qx \<in> set (nodes_from_distinct_paths M) \<and> snd qx \<in> set (inputs M)"
      using \<open>qx \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M)))\<close> concat_pair_set by blast
    then show ?thesis
      by (metis (no_types) nodes_code)
  qed 
  ultimately show ?thesis by blast
qed
  

lemma s_states_transition_target :
  assumes "(t_source t, t_input t) \<in> set (s_states M k)"
  and     "t \<in> h M"
shows "t_target t \<in> set (map fst (s_states M (k-1)))"
  and "t_target t \<noteq> t_source t"
proof -
  have "t_target t \<in> set (map fst (s_states M (k-1))) \<and> t_target t \<noteq> t_source t"
    using assms(1) proof (induction k)
    case 0 
    then show ?case by auto
  next
    case (Suc k)
    show ?case proof (cases "(t_source t, t_input t) \<in> set (s_states M k)")
      case True
      then have "t_target t \<in> set (map fst (s_states M (k - 1))) \<and> t_target t \<noteq> t_source t"
        using Suc.IH by auto
      moreover have "set (s_states M (k - 1)) \<subseteq> set (s_states M (Suc k - 1))"
        using s_states_subset
        by (metis Suc_pred' diff_Suc_1 diff_is_0_eq' nat_less_le order_refl zero_le) 
      ultimately show ?thesis by auto
    next
      case False
      then have "set (s_states M k) \<noteq> set (s_states M (Suc k))"
        using Suc.prems by blast
      then have "s_states M (Suc k) \<noteq> s_states M k"
        by auto
      
      obtain qx where    "s_states M (Suc k) = s_states M k @ [qx]"
                  and    "(\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx')"
                  and *: "(\<forall>t\<in>set (wf_transitions M).
                                 t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))"
                  and    "fst qx \<in> nodes M \<and> snd qx \<in> set (inputs M)"
        using s_states_last[OF \<open>s_states M (Suc k) \<noteq> s_states M k\<close>] by blast
      
      have "qx = (t_source t, t_input t)"
        using Suc.prems False \<open>s_states M (Suc k) = s_states M k @ [qx]\<close>
        by auto
      then have "(\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t)"
        using assms(2) by (simp add: "*")
      then have "t_target t \<in> set (map fst (s_states M (Suc k-1)))"
        by (metis diff_Suc_1 in_set_zipE prod.collapse zip_map_fst_snd) 
      moreover have \<open>t_target t \<noteq> t_source t\<close>
        using \<open>\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t\<close> \<open>\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx'\<close> \<open>qx = (t_source t, t_input t)\<close> by fastforce
      ultimately show ?thesis by blast
    qed
  qed
  then show "t_target t \<in> set (map fst (s_states M (k-1)))"
        and "t_target t \<noteq> t_source t" by simp+
qed














lemma s_states_last_ex :
  assumes "qx1 \<in> set (s_states M k)"
  shows "\<exists> k' . k' \<le> k \<and> k' > 0 \<and> qx1 \<in> set (s_states M k') \<and> qx1 = last (s_states M k') \<and> (\<forall> k'' < k' . k'' > 0 \<longrightarrow> qx1 \<noteq> last (s_states M k''))"
proof -

  obtain k' where k'_find: "find_index (\<lambda> qqt . qqt = qx1) (s_states M k) = Some k'"
    using find_index_exhaustive[of "s_states M k" "(\<lambda> qqt . qqt = qx1)"] assms
    by blast 

  have "Suc k' \<le> k"
    using find_index_index(1)[OF k'_find] s_states_length[of M k] by presburger
  moreover have "Suc k' \<ge> 0" 
    by auto
  moreover have "qx1 \<in> set (s_states M (Suc k'))"
    using find_index_index(2)[OF k'_find]
    by (metis Suc_neq_Zero \<open>Suc k' \<le> k\<close> assms find_index_index(1) k'_find last_in_set s_states_by_index s_states_prefix take_eq_Nil) 
  moreover have "qx1 = last (s_states M (Suc k'))"
    using find_index_index(1,2)[OF k'_find]  k'_find s_states_by_index by blast 
  moreover have "(\<forall> k'' < Suc k' . k'' > 0 \<longrightarrow> qx1 \<noteq> last (s_states M k''))"
    using find_index_index(3)[OF k'_find] s_states_prefix[of _ k' M]
  proof -
    assume a1: "\<And>j. j < k' \<Longrightarrow> s_states M k ! j \<noteq> qx1"
    { fix nn :: nat
      have ff1: "\<And>n. Some k' \<noteq> Some n \<or> n < length (s_states M k)"
        using find_index_index(1) k'_find by blast
      obtain nna :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
        ff2: "\<And>n na. (\<not> n < Suc na \<or> n = 0 \<or> Suc (nna n na) = n) \<and> (\<not> n < Suc na \<or> nna n na < na \<or> n = 0)"
        by (metis less_Suc_eq_0_disj)
      moreover
      { assume "nn \<le> k \<and> s_states M k ! nna nn k' \<noteq> qx1"
        then have "Suc (nna nn k') = nn \<longrightarrow> nn = 0 \<or> (\<exists>n\<ge>Suc k'. \<not> nn < n) \<or> (\<exists>n. Suc n = nn \<and> n \<noteq> nna nn k') \<or> \<not> 0 < nn \<or> \<not> nn < Suc k' \<or> last (s_states M nn) \<noteq> qx1"
          using ff1 by (metis (no_types) Suc_less_eq nat_less_le s_states_prefix take_last_index) }
      ultimately have "Suc (nna nn k') = nn \<longrightarrow> nn = 0 \<or> \<not> 0 < nn \<or> \<not> nn < Suc k' \<or> last (s_states M nn) \<noteq> qx1"
        using a1 by (metis Suc_leI Suc_n_not_le_n \<open>Suc k' \<le> k\<close> less_le_trans nat.inject nat_le_linear)
      then have "\<not> 0 < nn \<or> \<not> nn < Suc k' \<or> last (s_states M nn) \<noteq> qx1"
        using ff2 by blast }
    then show ?thesis
      by blast
  qed
  ultimately show ?thesis by blast
qed


lemma s_states_last_least : 
  assumes "qx1 \<in> set (s_states M k')"
  and "qx1 = last (s_states M k')"
  and "(\<forall> k'' < k' . k'' > 0 \<longrightarrow> qx1 \<noteq> last (s_states M k''))"
shows "(k' = (LEAST k' . qx1 \<in> set (s_states M k')))" 
proof (rule ccontr)
  assume "k' \<noteq> (LEAST k'. qx1 \<in> set (s_states M k'))"
  then obtain k'' where "k'' < k'" and "qx1 \<in> set (s_states M k'')"
    by (metis (no_types, lifting) LeastI assms(1) nat_neq_iff not_less_Least)

  obtain k''' where "k''' \<le> k''" and "k'''>0" and "qx1 = last (s_states M k''')" and "(\<forall>k''<k'''. 0 < k'' \<longrightarrow> qx1 \<noteq> last (s_states M k''))"
    using s_states_last_ex[OF \<open>qx1 \<in> set (s_states M k'')\<close>] by blast

  have "k''' < k'"
    using \<open>k''' \<le> k''\<close> \<open>k'' < k'\<close> by simp

  show "False"
    using assms(3) \<open>k'''>0\<close> \<open>k''' < k'\<close> \<open>qx1 = last (s_states M k''')\<close>  by blast
qed




lemma s_states_distinct_least :
  assumes "t \<in> set (filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states M k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                        (wf_transitions M))"
  shows "(LEAST k' . t_target t \<in> set (map fst (s_states M k'))) < (LEAST k' . t_source t \<in> set (map fst (s_states M k')))"
    and "t_source t \<in> set (map fst (s_states M k))"
    and "t_target t \<in> set (map fst (s_states M k))"
proof -
  have "(LEAST k' . t_target t \<in> set (map fst (s_states M k'))) < (LEAST k' . t_source t \<in> set (map fst (s_states M k')))
         \<and> t_source t \<in> set (map fst (s_states M k))
         \<and> t_target t \<in> set (map fst (s_states M k))"
  using assms proof (induction k)
    case 0
    then show ?case by auto
  next
    case (Suc k)
    show ?case proof (cases "s_states M (Suc k) = s_states M k")
      case True
      then show ?thesis using Suc by auto
    next
      case False
  
      obtain qx where "s_states M (Suc k) = s_states M k @ [qx]"
                      "(\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx')"
                      "(\<forall>t\<in>set (wf_transitions M).
                         t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                         (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))"
                      "fst qx \<in> nodes M \<and> snd qx \<in> set (inputs M)"
        using s_states_last[OF False] by blast
  
      
  
      then show ?thesis proof (cases "t_source t = fst qx")
        case True
  
        
        
        have "fst qx \<notin> set (map fst (s_states M k))"
          using \<open>\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx'\<close> by auto
        then have "\<And> k' . k' < Suc k \<Longrightarrow> fst qx \<notin> set (map fst (s_states M k'))"
          using s_states_prefix[of _ k M]
          by (metis \<open>\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx'\<close> in_set_takeD less_Suc_eq_le list_map_source_elem) 
        moreover have "fst qx \<in> set (map fst (s_states M (Suc k)))"
          using \<open>s_states M (Suc k) = s_states M k @ [qx]\<close> by auto
          
        ultimately have "(LEAST k' . fst qx \<in> set (map fst (s_states M k'))) = Suc k"
        proof -
          have "\<not> (LEAST n. fst qx \<in> set (map fst (s_states M n))) < Suc k"
            by (meson LeastI_ex \<open>\<And>k'. k' < Suc k \<Longrightarrow> fst qx \<notin> set (map fst (s_states M k'))\<close> \<open>fst qx \<in> set (map fst (s_states M (Suc k)))\<close>)
          then show ?thesis
            by (meson \<open>fst qx \<in> set (map fst (s_states M (Suc k)))\<close> not_less_Least not_less_iff_gr_or_eq)
        qed 
  
  
        have "(t_source t, t_input t) \<in> set (s_states M (Suc k)) \<and> t \<in> set (wf_transitions M)"
          using Suc.prems by auto 
        then have "t_target t \<in> set (map fst (s_states M k))"
          using s_states_transition_target(1)[of t M "Suc k"] by auto
        then have "(LEAST k' . t_target t \<in> set (map fst (s_states M k'))) \<le> k"
          by (simp add: Least_le)
        then have "(LEAST k'. t_target t \<in> set (map fst (s_states M k'))) < (LEAST k'. t_source t \<in> set (map fst (s_states M k')))" 
          using \<open>(LEAST k' . fst qx \<in> set (map fst (s_states M k'))) = Suc k\<close> True by force
        then show ?thesis
          using \<open>fst qx \<in> set (map fst (s_states M (Suc k)))\<close> True 
                \<open>t_target t \<in> set (map fst (s_states M k))\<close>
                \<open>s_states M (Suc k) = s_states M k @ [qx]\<close> by auto
      next
        case False
        then show ?thesis
          using Suc.IH Suc.prems \<open>s_states M (Suc k) = s_states M k @ [qx]\<close> by fastforce 
      qed
    qed
  qed

  then show "(LEAST k' . t_target t \<in> set (map fst (s_states M k'))) < (LEAST k' . t_source t \<in> set (map fst (s_states M k')))"
        and "t_source t \<in> set (map fst (s_states M k))"
        and "t_target t \<in> set (map fst (s_states M k))" by simp+
qed









lemma s_states_induces_state_separator_helper_distinct_pathlikes :
  assumes "\<And> i . (Suc i) < length (t#p) \<Longrightarrow> t_source ((t#p) ! (Suc i)) = t_target ((t#p) ! i)"
  assumes "set (t#p) \<subseteq> set (filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states M k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                        (wf_transitions M))"
  
  shows "distinct ((t_source t) # map t_target (t#p))" 
proof - 

  let ?f = "\<lambda> q . LEAST k' . q \<in> set (map fst (s_states M k'))"
  let ?p = "(t_source t) # map t_target (t#p)"

  have "\<And> i . (Suc i) < length ?p \<Longrightarrow> ?f (?p ! i) > ?f (?p ! (Suc i))"
  proof -
    fix i assume "Suc i < length ?p"
    
    
    let ?t1 = "(t#t#p) ! i"
    let ?t2 = "(t#t#p) ! (Suc i)"

    have "length (t#t#p) = length ?p" by auto
    



    show "?f (?p ! i) > ?f (?p ! (Suc i))" proof (cases i)
      case 0
      then have "?t1 = ?t2"
        by auto

      have "?t1 \<in> h M"
        using assms(2) 
        by (metis (no_types, lifting) Suc_lessD \<open>Suc i < length (t_source t # map t_target (t # p))\<close> \<open>length (t # t # p) = length (t_source t # map t_target (t # p))\<close> filter_is_subset list.set_intros(1) nth_mem set_ConsD subsetD)  
      have "?t1 \<in> set (t#t#p)"
        using \<open>length (t#t#p) = length ?p\<close>
              \<open>Suc i < length ?p\<close>
        by (metis Suc_lessD nth_mem)
      have "?t1 \<in> set (filter (\<lambda>t. \<exists>qqx\<in>set (s_states M k). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions M))"
        using \<open>?t1 \<in> set (t#t#p)\<close> assms(2)
        by (metis (no_types, lifting) list.set_intros(1) set_ConsD subsetD) 
      then have **: "(LEAST k'. t_target ?t1 \<in> set (map fst (s_states M k')))
            < (LEAST k'. t_source ?t1 \<in> set (map fst (s_states M k')))"
        using s_states_distinct_least(1)[of ?t1 M k] by presburger
      then show ?thesis using \<open>?t1 = ?t2\<close>
        by (simp add: "0") 
    next
      case (Suc m)

      have "?t2 \<in> set (t#t#p)"
        using \<open>Suc i < length ?p\<close> \<open>length (t#t#p) = length ?p\<close>
        by (metis nth_mem) 
      
      have "?t2 \<in> h M"
        using assms(2) using \<open>(t#t#p) ! (Suc i) \<in> set (t#t#p)\<close> by auto 
  
      have "?t2 \<in> set (filter (\<lambda>t. \<exists>qqx\<in>set (s_states M k). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions M))"
        using \<open>?t2 \<in> set (t#t#p)\<close> assms(2)
        by (metis (no_types, lifting) list.set_intros(1) set_ConsD subsetD) 
      then have **: "(LEAST k'. t_target ?t2 \<in> set (map fst (s_states M k')))
            < (LEAST k'. t_source ?t2 \<in> set (map fst (s_states M k')))"
        using s_states_distinct_least(1)[of ?t2 M k] by presburger

      have "t_source ?t2 = t_target ?t1"
        using assms(1) \<open>Suc i < length ?p\<close> \<open>length (t#t#p) = length ?p\<close>
        by (simp add: Suc) 

      then have " t_target ((t # t # p) ! Suc i) = (t_source t # map t_target (t # p)) ! Suc i"
        by (metis Suc_less_eq \<open>Suc i < length (t_source t # map t_target (t # p))\<close> length_Cons length_map nth_Cons_Suc nth_map)
      moreover have "t_source ((t # t # p) ! Suc i) = (t_source t # map t_target (t # p)) ! i"
        by (metis Suc Suc_lessD Suc_less_eq \<open>Suc i < length (t_source t # map t_target (t # p))\<close> \<open>t_source ((t # t # p) ! Suc i) = t_target ((t # t # p) ! i)\<close> length_Cons length_map nth_Cons_Suc nth_map)  
        
      ultimately show "?f (?p ! i) > ?f (?p ! (Suc i))" using ** by simp
    qed
  qed
  then have f1: "\<And> i . (Suc i) < length (map ?f ?p) \<Longrightarrow> ?f (?p ! (Suc i)) < ?f (?p ! i)"
    by auto

  moreover have f2: "\<And> i . i < length (map ?f ?p) \<Longrightarrow> map ?f ?p ! i = (LEAST k'. (t_source t # map t_target (t # p)) ! i \<in> set (map fst (s_states M k')))"
  proof -
    fix i assume "i < length (map ?f ?p)"
    have map_index : "\<And> xs f i . i < length (map f xs) \<Longrightarrow> (map f xs) ! i = f (xs ! i)"
      by simp
    show "map ?f ?p ! i = (LEAST k'. (t_source t # map t_target (t # p)) ! i \<in> set (map fst (s_states M k')))"
      using map_index[OF \<open>i < length (map ?f ?p)\<close>] by assumption
  qed

  ultimately have "(\<And>i. Suc i < length (map ?f ?p) \<Longrightarrow> map ?f ?p ! Suc i < map ?f ?p ! i)"
    using Suc_lessD by presburger 

  then have "distinct (map ?f ?p)"
    using ordered_list_distinct_rev[of "map ?f ?p"] by blast

  then show "distinct ?p"
    by (metis distinct_map) 
qed


lemma s_states_induces_state_separator_helper_distinct_paths :
  assumes "path \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                      inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                      outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                      transitions = 
                         filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                      (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M \<rparr>
                 q
                 p"
    (is "path ?S q p")
  shows "distinct (visited_states q p)" 
proof (cases p)
  case Nil
  then show ?thesis by auto
next
  case (Cons t p')

  then have *: "\<And> i . (Suc i) < length (t#p') \<Longrightarrow> t_source ((t#p') ! (Suc i)) = t_target ((t#p') ! i)"
    using assms(1) by (simp add: path_source_target_index) 
  
  have "set (t#p') \<subseteq> set (transitions ?S)"
    using Cons path_h[OF assms(1)] unfolding wf_transitions.simps 
    by (meson filter_is_subset subset_code(1)) 
  then have **: "set (t#p') \<subseteq> set (filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                      (wf_transitions (product (from_FSM M q1) (from_FSM M q2))))"
    by simp

  have "distinct (t_source t # map t_target (t # p'))"
    using s_states_induces_state_separator_helper_distinct_pathlikes[OF * **]
    by auto
  moreover have "visited_states q p = (t_source t # map t_target (t # p'))"
    using Cons assms(1) unfolding visited_states.simps target.simps
    by blast 
  ultimately show "distinct (visited_states q p)"
    by auto
qed
  

lemma s_states_induces_state_separator_helper_acyclic :
  shows "acyclic \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                      inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                      outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                      transitions = 
                         filter 
                           (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                      (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M \<rparr>"
    (is "acyclic ?S")

proof -
  have "\<And> p . path ?S (initial ?S) p \<Longrightarrow> distinct (visited_states (initial ?S) p)"
  proof -
    fix p assume "path ?S (initial ?S) p"
    show "distinct (visited_states (initial ?S) p)"
      using s_states_induces_state_separator_helper_distinct_paths[OF \<open>path ?S (initial ?S) p\<close>] by assumption
  qed
  then show ?thesis unfolding acyclic.simps by blast
qed
  
  











lemma s_states_last_ex_k :
  assumes "qqx \<in> set (s_states M k)"  
  shows "\<exists> k' . s_states M (Suc k') = (s_states M k') @ [qqx]"
proof -
  obtain k' where "k'\<le>k" and "0 < k'" and "qqx = last (s_states M k')" 
                  "(\<forall>k''<k'. 0 < k'' \<longrightarrow> qqx \<noteq> last (s_states M k''))"
    using s_states_last_ex[OF assms] by blast

  have "k' = (LEAST k' . qqx \<in> set (s_states M k'))"
    by (metis \<open>0 < k'\<close> \<open>\<forall>k''<k'. 0 < k'' \<longrightarrow> qqx \<noteq> last (s_states M k'')\<close> \<open>qqx = last (s_states M k')\<close> assms nat_neq_iff s_states_last_ex s_states_last_least)

  from \<open>0 < k'\<close> obtain k'' where Suc: "k' = Suc k''"
    using gr0_conv_Suc by blast 

  then have "qqx = last (s_states M (Suc k''))"
    using \<open>qqx = last (s_states M k')\<close> by auto
  have "Suc k'' = (LEAST k' . qqx \<in> set (s_states M k'))"
    using \<open>k' = (LEAST k' . qqx \<in> set (s_states M k'))\<close> Suc by auto
  then have "qqx \<notin> set (s_states M k'')"
    by (metis lessI not_less_Least)
  then have "(s_states M (Suc k'')) \<noteq> (s_states M k'')"
    using \<open>Suc k'' = (LEAST k' . qqx \<in> set (s_states M k'))\<close>
    by (metis Suc Suc_neq_Zero \<open>k' \<le> k\<close> \<open>qqx = last (s_states M (Suc k''))\<close> assms last_in_set s_states_prefix take_eq_Nil)

  have "s_states M (Suc k'') = s_states M k'' @ [qqx]"
    by (metis \<open>qqx = last (s_states M (Suc k''))\<close> \<open>s_states M (Suc k'') \<noteq> s_states M k''\<close> last_snoc s_states_last)
  then show ?thesis by blast
qed




(* TODO: remove repetitions and results in x = 0 that can be replaced by _helper lemmata *)
lemma s_states_induces_state_separator :
  assumes "(s_states (product (from_FSM M q1) (from_FSM M q2)) k) \<noteq> []" 
  and "q1 \<in> nodes M"
  and "q2 \<in> nodes M"
  and "q1 \<noteq> q2"
shows "induces_state_separator_for_prod M q1 q2 \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                                                  inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                                                  outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                                                  transitions = 
                                                     filter 
                                                       (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                                                  (wf_transitions (product (from_FSM M q1) (from_FSM M q2))),
                                                  \<dots> = more M\<rparr>"
using assms(1) proof (induction k rule: less_induct)
  case (less x)
  then show ?case proof (cases x)
    case 0
    then have "s_states (product (from_FSM M q1) (from_FSM M q2)) x = s_states (product (from_FSM M q1) (from_FSM M q2)) 0"
              "s_states (product (from_FSM M q1) (from_FSM M q2)) 0 \<noteq> []"
      using less.prems by auto

    let ?PM = "(product (from_FSM M q1) (from_FSM M q2))"
    let ?S = " \<lparr> initial = fst (last (s_states ?PM 0)),
                                     inputs = inputs ?PM,
                                     outputs = outputs ?PM,
                                     transitions = 
                                        filter 
                                          (\<lambda>t . \<exists> qqx \<in> set (s_states ?PM 0) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                                          (wf_transitions ?PM), \<dots> = more M \<rparr>"
  
    (* avoid handling the entire term of ?S *)
    obtain S where "S = ?S" by blast
    
    obtain qx where qx_def: "s_states ?PM 0 = [qx]"
      using \<open>s_states ?PM 0 \<noteq> []\<close> unfolding s_states.simps
      by (metis (mono_tags, lifting) option.case_eq_if) 
    then have "(s_states ?PM 0) ! 0 = qx" and "last (s_states ?PM 0) = qx"
      by auto
    then have "initial ?S = fst qx"
      by auto
      
    have "0 < length (s_states ?PM 0)"
      using less 0 by blast
    have "fst qx \<in> nodes ?PM"
      using s_states_index_properties(1)[OF \<open>0 < length (s_states ?PM 0)\<close>] \<open>(s_states ?PM 0) ! 0 = qx\<close> by auto
    have "snd qx \<in> set (inputs ?PM)"
      using s_states_index_properties(2)[OF \<open>0 < length (s_states ?PM 0)\<close>] \<open>(s_states ?PM 0) ! 0 = qx\<close> by auto 
    then have "snd qx \<in> set (inputs M)"
      by (simp add: product_simps(2) from_FSM_simps(2))
    have "\<not>(\<exists> t \<in> h ?PM. t_source t = fst qx \<and> t_input t = snd qx)"
      using s_states_index_properties(4)[OF \<open>0 < length (s_states ?PM 0)\<close>] \<open>(s_states ?PM 0) ! 0 = qx\<close>
      by (metis length_pos_if_in_set less_numeral_extra(3) list.size(3) take_eq_Nil) 
  
    have "(last (s_states (product (from_FSM M q1) (from_FSM M q2)) 0)) = qx"
      using qx_def 
      by (metis last.simps)  
  
    (* is_submachine *)
    let ?PS = "product (from_FSM M (fst (fst qx))) (from_FSM M (snd (fst qx)))" 
    have "initial ?S = initial ?PS"
      using \<open>(last (s_states (product (from_FSM M q1) (from_FSM M q2)) 0)) = qx\<close>
      by (simp add: from_FSM_simps(1) product_simps(1)) 
    moreover have "inputs ?S = inputs ?PS"
      by (simp add: from_FSM_simps(2) product_simps(2)) 
    moreover have "outputs ?S = outputs ?PS"
      by (simp add: from_FSM_simps(3) product_simps(3)) 
    moreover have "h ?S \<subseteq> h ?PS"
    proof -
      have "initial ?S \<in> nodes ?PS"
        using calculation(1) nodes.initial
        by (metis (no_types, lifting)) 
      have *: "set (transitions ?S) \<subseteq> set (transitions (from_FSM ?PM (fst qx)))"
        by (metis (no_types, lifting) filter_filter filter_is_subset from_FSM_transitions select_convs(4) wf_transitions.simps)
      have **: "h ?PS = h (from_FSM ?PM (fst qx))"
        using \<open>fst qx \<in> nodes ?PM\<close> from_product_from_h by (metis prod.collapse)
      show ?thesis
        by (metis (no_types, lifting) "*" "**" \<open>last (s_states (product (from_FSM M q1) (from_FSM M q2)) 0) = qx\<close> from_FSM_simps(1) from_FSM_simps(2) from_FSM_simps(3) nodes.simps select_convs(1) select_convs(2) select_convs(3) transition_subset_h) 
    qed
    ultimately have is_sub : "is_submachine ?S ?PS"
      unfolding is_submachine.simps by blast
  
  
    (* single_input *)
  
    have is_single_input : "single_input ?S" 
      using qx_def unfolding single_input.simps by auto
  
  
  
    (* acyclic *)
  
    from qx_def have qx_find : "find
                (\<lambda>qx. \<not> (\<exists>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                          t_source t = fst qx \<and> t_input t = snd qx))
                 (concat
                   (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                     (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) = Some qx "
      unfolding s_states.simps 
      by (metis (mono_tags, lifting) \<open>s_states ?PM 0 = [qx]\<close> \<open>s_states ?PM 0 \<noteq> []\<close>)
  
  
    have "transitions ?S = filter
                           (\<lambda>t. t_source t = fst qx \<and> t_input t = snd qx)
                           (wf_transitions ?PM)"
      using qx_def
      by auto 
    then have "\<And> t . t \<in> set (transitions ?S) \<Longrightarrow> t \<in> h ?PM \<and> t_source t = fst qx \<and> t_input t = snd qx"
      by (metis (mono_tags, lifting) filter_set member_filter)
    then have "\<And> t . t \<in> h ?S \<Longrightarrow> t \<in> h ?PM \<and> t_source t = fst qx \<and> t_input t = snd qx"
      unfolding wf_transitions.simps
      by (metis (no_types, lifting) filter_set member_filter) 
    then have "\<And> t . t \<in> h ?S \<Longrightarrow> False"
      using find_condition[OF qx_find] by blast
    then have "h ?S = {}"
      using last_in_set by blast
    then have "\<And> p . path ?S (initial ?S) p \<Longrightarrow> set p = {}"
      using path_h[of ?S "initial ?S"]
      by (metis (no_types, lifting) subset_empty) 
    then have "L ?S = {[]}"
      unfolding LS.simps by blast
    moreover have "finite {[]}"
      by auto
    ultimately have is_acyclic: "acyclic ?S"
      using acyclic_alt_def[of ?S] by metis
  
    
    (* deadlock_states r(0)-distinguish *)
  
    
  
    from \<open>S = ?S\<close> have "\<And> p . path S (initial S) p \<Longrightarrow> p = []"
      using \<open>\<And> p . path ?S (initial ?S) p \<Longrightarrow> set p = {}\<close> by blast
    then have "{ target p (initial S) | p . path S (initial S) p } = {initial S}"
      unfolding target.simps visited_states.simps by auto
    then have "nodes S = {initial S}"
      using nodes_set_alt_def[of S] by blast
    then have "nodes S = {fst qx}"
      using \<open>initial ?S = fst qx\<close> \<open>S = ?S\<close> by metis
    then have "(\<forall>qq\<in>nodes S.
            deadlock_state S qq \<longrightarrow>
              (\<exists>x\<in>set (inputs M).
                  \<not> (\<exists>t1\<in>set (wf_transitions M).
                         \<exists>t2\<in>set (wf_transitions M).
                            t_source t1 = fst qq \<and>
                            t_source t2 = snd qq \<and>
                            t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)))"
      using product_deadlock[OF find_condition[OF qx_find] \<open>fst qx \<in> nodes ?PM\<close> \<open>snd qx \<in> set (inputs M)\<close>] 
            \<open>snd qx \<in> set (inputs M)\<close>
      by auto 
    then have has_deadlock_property: "(\<forall>qq\<in>nodes ?S.
            deadlock_state ?S qq \<longrightarrow>
              (\<exists>x\<in>set (inputs M).
                  \<not> (\<exists>t1\<in>set (wf_transitions M).
                         \<exists>t2\<in>set (wf_transitions M).
                            t_source t1 = fst qq \<and>
                            t_source t2 = snd qq \<and>
                            t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)))"
      using \<open>S = ?S\<close> by blast
  
  
    (* retains outputs *)
  
    have retains_outputs : "retains_outputs_for_states_and_inputs ?PM ?S"
      unfolding retains_outputs_for_states_and_inputs_def
      using \<open>\<And>t. t \<in> set (wf_transitions \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) 0)), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) 0). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>) \<Longrightarrow> False\<close> by blast 
    
  
    (* collect properties *)
  
    show ?thesis 
      unfolding induces_state_separator_for_prod_def
      using is_sub
            is_single_input
            is_acyclic
            has_deadlock_property
            retains_outputs
      using \<open>initial ?S = fst qx\<close> \<open>s_states ?PM x = s_states ?PM 0\<close> by presburger 

  next
    case (Suc k)

    then show ?thesis proof (cases "length (s_states (product (from_FSM M q1) (from_FSM M q2)) x) < x")
      case True
      then have "s_states (product (from_FSM M q1) (from_FSM M q2)) x = s_states (product (from_FSM M q1) (from_FSM M q2)) k"
        using Suc
        by (metis le_SucI less_Suc_eq_le nat_le_linear s_states_prefix take_all) 
      
      show ?thesis
        using Suc \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) x = s_states (product (from_FSM M q1) (from_FSM M q2)) k\<close> less.IH less.prems lessI by presburger
    next
      case False

      then have "s_states (product (from_FSM M q1) (from_FSM M q2)) x = s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)"
                "s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k) \<noteq> []"
        using Suc less.prems by auto

      then have "s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k) \<noteq> s_states (product (from_FSM M q1) (from_FSM M q2)) k"
        by (metis False Suc le_imp_less_Suc s_states_length)

      let ?PM = "product (from_FSM M q1) (from_FSM M q2)"
      let ?S = "\<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))),
                  inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                  outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                  transitions = 
                     filter 
                       (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                  (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M \<rparr>"


      obtain qx where "s_states ?PM (Suc k) = s_states ?PM k @ [qx]"
                  and "(\<forall>qx'\<in>set (s_states ?PM k). fst qx \<noteq> fst qx')"
                  and "(\<forall>t\<in> h ?PM.
                           t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                          (\<exists>qx'\<in>set (s_states ?PM k). fst qx' = t_target t))"
                   and "fst qx \<in> nodes ?PM"
                   and "snd qx \<in> set (inputs ?PM)"
        using s_states_last[OF \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k) \<noteq> s_states (product (from_FSM M q1) (from_FSM M q2)) k\<close>]
        by blast
      then have "qx = (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)))"
        by auto

      

      (* avoid handling the entire term of ?S *)
      obtain S where "S = ?S" by blast
    
      
    
      (* single input *)
      have is_single_input : "single_input ?S"
        using s_states_induces_state_separator_helper_single_input by metis
      (* retains outputs *)
      have retains_outputs : "retains_outputs_for_states_and_inputs ?PM ?S"
        using s_states_induces_state_separator_helper_retains_outputs by metis
      (* acyclic *)
      have is_acyclic : "acyclic ?S"
        using s_states_induces_state_separator_helper_acyclic by metis

      (* is_submachine *)
      let ?PS = "product (from_FSM M (fst (fst qx))) (from_FSM M (snd (fst qx)))" 
      have "initial ?S = initial ?PS"
        using \<open>qx = (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)))\<close>
        by (simp add: from_FSM_simps(1) product_simps(1)) 
      moreover have "inputs ?S = inputs ?PS"
        by (simp add: from_FSM_simps(2) product_simps(2)) 
      moreover have "outputs ?S = outputs ?PS"
        by (simp add: from_FSM_simps(3) product_simps(3)) 
      moreover have "h ?S \<subseteq> h ?PS"
      proof -
        have "initial ?S \<in> nodes ?PS"
          using calculation(1) nodes.initial
          by (metis (no_types, lifting)) 
        have *: "set (transitions ?S) \<subseteq> set (transitions (from_FSM ?PM (fst qx)))"
          by (metis (no_types, lifting) filter_filter filter_is_subset from_FSM_transitions select_convs(4) wf_transitions.simps)
        have **: "h ?PS = h (from_FSM ?PM (fst qx))"
          using \<open>fst qx \<in> nodes ?PM\<close> from_product_from_h by (metis prod.collapse)
        show ?thesis
          by (metis (no_types, lifting) "*" "**" \<open>qx = last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))\<close> from_FSM_simps(1) from_FSM_simps(2) from_FSM_simps(3) nodes.simps select_convs(1) select_convs(2) select_convs(3) transition_subset_h) 
      qed
      ultimately have is_sub : "is_submachine ?S ?PS"
        unfolding is_submachine.simps by blast
    

      (* has deadlock property *)
      have "\<And> qq . qq \<in> nodes ?S \<Longrightarrow> deadlock_state ?S qq \<Longrightarrow> (\<exists>x\<in>set (inputs M).
                                                                \<not> (\<exists>t1\<in>set (wf_transitions M).
                                                                       \<exists>t2\<in>set (wf_transitions M).
                                                                          t_source t1 = fst qq \<and>
                                                                          t_source t2 = snd qq \<and>
                                                                          t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))"
      proof -
        fix qq assume "qq \<in> nodes ?S"
                  and "deadlock_state ?S qq"

        have "qq = fst qx \<or> (\<exists> t \<in> h ?S . t_target t = qq)" 
          using \<open>qq \<in> nodes ?S\<close>
                nodes_from_transition_targets[of ?S]
          by (metis (no_types, lifting) \<open>qx = last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))\<close> nodes_initial_or_target select_convs(1)) 
        
        have "qq \<in> set (map fst (s_states ?PM (Suc k)))"
        proof (cases "qq = fst qx")
          case True
          then show ?thesis using \<open>qx = last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))\<close>
            using \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k) \<noteq> []\<close> by auto 
        next
          case False
          then obtain t where "t \<in> h ?S" and "t_target t = qq"
            using \<open>qq = fst qx \<or> (\<exists> t \<in> h ?S . t_target t = qq)\<close> by blast

          have "(t_source t, t_input t) \<in> set (s_states ?PM (Suc k))"
            using s_states_induces_state_separator_helper_h[OF \<open>t \<in> h ?S\<close>] by assumption
          have "t \<in> h ?PM"
            using \<open>t \<in> h ?S\<close>
          proof -
            have f1: "t \<in> set (wf_transitions \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>p. \<exists>pa. pa \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)) \<and> t_source p = fst pa \<and> t_input p = snd pa) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>)"
              by (metis \<open>t \<in> set (wf_transitions \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>)\<close>)
            have "set (wf_transitions \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>p. \<exists>pa. pa \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)) \<and> t_source p = fst pa \<and> t_input p = snd pa) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>) \<subseteq> set (wf_transitions (product (from_FSM M (fst (fst qx))) (from_FSM M (snd (fst qx)))))"
              by (metis (full_types) \<open>set (wf_transitions \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>) \<subseteq> set (wf_transitions (product (from_FSM M (fst (fst qx))) (from_FSM M (snd (fst qx)))))\<close>)
            then have f2: "t \<in> set (wf_transitions (product (from_FSM M (fst (fst qx))) (from_FSM M (snd (fst qx)))))"
              using f1 by blast
            have "(fst (fst qx), snd (fst qx)) = fst qx"
              by simp
            then show ?thesis
              using f2 by (metis (no_types) \<open>fst qx \<in> nodes (product (from_FSM M q1) (from_FSM M q2))\<close> product_from_transition_shared_node)
          qed 

          have "set (map fst (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k - 1))) \<subseteq> set (map fst (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)))"
            using \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k) = s_states (product (from_FSM M q1) (from_FSM M q2)) k @ [qx]\<close> by auto
          then show ?thesis 
            using s_states_transition_target(1)[OF \<open>(t_source t, t_input t) \<in> set (s_states ?PM (Suc k))\<close> \<open>t \<in> h ?PM\<close>]
                  \<open>t_target t = qq\<close>
            by blast  
        qed


        moreover have "\<And> xs x . x \<in> set (map fst xs) \<Longrightarrow> (\<exists> y . (x,y) \<in> set xs)"
          by auto

        

        ultimately obtain x where "(qq,x) \<in> set (s_states ?PM (Suc k))"
          by auto 

        then obtain i where "i < length (s_states ?PM (Suc k))" and "(s_states ?PM (Suc k)) ! i = (qq,x)"
          by (meson in_set_conv_nth)

        have "qq \<in> nodes ?PM"
          using s_states_index_properties(1)[OF \<open>i < length (s_states ?PM (Suc k))\<close>] \<open>(s_states ?PM (Suc k)) ! i = (qq,x)\<close> by auto
        have "x \<in> set (inputs ?PM)"
          using s_states_index_properties(2)[OF \<open>i < length (s_states ?PM (Suc k))\<close>] \<open>(s_states ?PM (Suc k)) ! i = (qq,x)\<close> by auto
        then have "x \<in> set (inputs M)"
          by (simp add: from_FSM_product_inputs)
        have "\<forall>qx'\<in> set (take i (s_states ?PM (Suc k))). qq \<noteq> fst qx'"
          using s_states_index_properties(3)[OF \<open>i < length (s_states ?PM (Suc k))\<close>] \<open>(s_states ?PM (Suc k)) ! i = (qq,x)\<close> by auto
        have "\<forall> t \<in> h ?PM.
                 t_source t = qq \<and>
                 t_input t = x \<longrightarrow>
                 (\<exists> qx' \<in> set (take i (s_states ?PM (Suc k))). fst qx' = t_target t)"
          using s_states_index_properties(4)[OF \<open>i < length (s_states ?PM (Suc k))\<close>] \<open>(s_states ?PM (Suc k)) ! i = (qq,x)\<close> by auto
        then have "\<forall> t \<in> h ?PM.
                 t_source t = qq \<and>
                 t_input t = x \<longrightarrow>
                 (\<exists> qx' \<in> set (s_states ?PM (Suc k)). fst qx' = t_target t)"
          by (meson in_set_takeD) 
          

        have "\<not> (\<exists> t \<in> h ?PM. t_source t = qq \<and> t_input t = x)"
        proof 
          assume "(\<exists> t \<in> h ?PM. t_source t = qq \<and> t_input t = x)"
          then obtain t where "t \<in> h ?PM" and "t_source t = qq" and "t_input t = x" by blast
          then have "\<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)).
                             t_source t = fst qqx \<and> t_input t = snd qqx"
            using \<open>(qq,x) \<in> set (s_states ?PM (Suc k))\<close> prod.collapse[of "(qq,x)"]
            by force 
          then have "t \<in> set (transitions ?S)"
            using \<open>t \<in> h ?PM\<close>
            by simp 
          then have "t \<in> h ?S"
            using \<open>t \<in> h ?PM\<close>
            by (metis (no_types, lifting) \<open>qq \<in> nodes \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k)). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>\<close> \<open>t_source t = qq\<close> select_convs(2) select_convs(3) wf_transition_simp) 
          then have "\<not> (deadlock_state ?S qq)"
            unfolding deadlock_state.simps using \<open>t_source t = qq\<close>
            by blast 
          then show "False"
            using \<open>deadlock_state ?S qq\<close> by blast
        qed

        then have "\<not> (\<exists> t1 \<in> h M . \<exists> t2 \<in> h M.
                                t_source t1 = fst qq \<and>
                                t_source t2 = snd qq \<and>
                                t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)"
          using product_deadlock[OF _ \<open>qq \<in> nodes ?PM\<close> \<open>x \<in> set (inputs M)\<close>] by blast
        then show "(\<exists>x\<in>set (inputs M).
                    \<not> (\<exists>t1\<in>set (wf_transitions M).
                           \<exists>t2\<in>set (wf_transitions M).
                              t_source t1 = fst qq \<and>
                              t_source t2 = snd qq \<and>
                              t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2))"
          using \<open>x \<in> set (inputs M)\<close> by blast
      qed


      then have has_deadlock_property: "(\<forall>qq\<in>nodes ?S.
          deadlock_state ?S qq \<longrightarrow>
            (\<exists>x\<in>set (inputs M).
                \<not> (\<exists>t1\<in>set (wf_transitions M).
                       \<exists>t2\<in>set (wf_transitions M).
                          t_source t1 = fst qq \<and>
                          t_source t2 = snd qq \<and>
                          t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)))"
      by blast
      
    
    
      (* collect properties *)
      have "initial ?S = fst qx"
        by (metis \<open>qx = last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc k))\<close> select_convs(1))
        

      show ?thesis 
        unfolding induces_state_separator_for_prod_def
        using is_sub
              is_single_input
              is_acyclic
              has_deadlock_property
              retains_outputs
        using \<open>initial ?S = fst qx\<close>  \<open>s_states ?PM x = s_states ?PM (Suc k)\<close>
        by presburger 
    qed
  qed
qed




















lemma induces_from_prod: "induces_state_separator M S = induces_state_separator_for_prod M (fst (initial S)) (snd (initial S)) S"
  unfolding induces_state_separator_def induces_state_separator_for_prod_def by blast



  
                                                           
(*
  is_state_separator_from_canonical_separator
            (canonical_separator M (fst (initial S)) (snd (initial S)))
            (fst (initial S))
            (snd (initial S))
            (state_separator_from_product_submachine M S)



  induces_state_separator_for_prod M q1 q2 \<lparr> initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) k)),
                                                  inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
                                                  outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
                                                  transitions = 
                                                     filter 
                                                       (\<lambda>t . \<exists> qqx \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) k) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                                                  (wf_transitions (product (from_FSM M q1) (from_FSM M q2)))
*)


(* TODO: move *)
lemma filter_ex_by_find :
  "filter (\<lambda>x . \<exists> y \<in> set ys . P x y) xs = filter (\<lambda>x . find (\<lambda> y . P x y) ys \<noteq> None) xs"
  using find_None_iff by metis


(* old version filtering by (\<lambda>t . \<exists> qqx \<in> set (take (Suc i) SS) . t_source t = fst qqx \<and> t_input t = snd qqx) *)
(*
definition calculate_state_separator_from_s_states :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) FSM option" where
  "calculate_state_separator_from_s_states M q1 q2 = 
    (let PR = product (from_FSM M q1) (from_FSM M q2); SS = (s_states_opt PR (size PR))  in
      (case find_index (\<lambda>qqt . fst qqt = (q1,q2)) SS of
        Some i \<Rightarrow> Some (state_separator_from_product_submachine M \<lparr> initial = (q1,q2),
                                                    inputs = inputs PR,
                                                    outputs = outputs PR,
                                                    transitions = 
                                                       filter 
                                                         (\<lambda>t . \<exists> qqx \<in> set (take (Suc i) SS) . t_source t = fst qqx \<and> t_input t = snd qqx) 
                                                       (wf_transitions PR),
                                                    \<dots> = more M\<rparr>) |
        None \<Rightarrow> None))"
*)

definition calculate_state_separator_from_s_states :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> (('a \<times> 'a) + 'a) FSM option" where
  "calculate_state_separator_from_s_states M q1 q2 = 
    (let PR = product (from_FSM M q1) (from_FSM M q2); SS = (s_states_opt PR (size PR))  in
      (case find_index (\<lambda>qqt . fst qqt = (q1,q2)) SS of
        Some i \<Rightarrow> Some (state_separator_from_product_submachine M \<lparr> initial = (q1,q2),
                                                    inputs = inputs PR,
                                                    outputs = outputs PR,
                                                    transitions = 
                                                       filter 
                                                         (\<lambda>t . find (\<lambda> qqx . t_source t = fst qqx \<and> t_input t = snd qqx) (take (Suc i) SS) \<noteq> None) 
                                                       (wf_transitions PR),
                                                    \<dots> = more M\<rparr>) |
        None \<Rightarrow> None))"


value "calculate_state_separator_from_s_states M_ex_9 0 1"
value "calculate_state_separator_from_s_states M_ex_9 0 2"
value "calculate_state_separator_from_s_states M_ex_9 0 3"
value "calculate_state_separator_from_s_states M_ex_9 3 1"
value "calculate_state_separator_from_canonical_separator_naive M_ex_9 0 3"



lemma calculate_state_separator_from_s_states_soundness :
  assumes "calculate_state_separator_from_s_states M q1 q2 = Some S"
  and "q1 \<in> nodes M"
  and "q2 \<in> nodes M"
  and "q1 \<noteq> q2"
  and "completely_specified M"
  shows "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
proof -
  let ?PR = " product (from_FSM M q1) (from_FSM M q2)"
  let ?SS = "(s_states_opt ?PR (size ?PR))"

  obtain i where i_def: "find_index (\<lambda>qqt . fst qqt = (q1,q2)) ?SS = Some i"
    using assms unfolding calculate_state_separator_from_s_states_def Let_def
    by fastforce 
  then have s1: "S = 
        (state_separator_from_product_submachine M
          \<lparr>initial = (q1, q2), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)),
             outputs = outputs (product (from_FSM M q1) (from_FSM M q2)),
             transitions =
               filter
                (\<lambda>t. \<exists>qqx\<in>set (take (Suc i)
                                 (s_states_opt (product (from_FSM M q1) (from_FSM M q2))
                                   (FSM.size (product (from_FSM M q1) (from_FSM M q2))))).
                        t_source t = fst qqx \<and> t_input t = snd qqx)
                (wf_transitions (product (from_FSM M q1) (from_FSM M q2))),
             \<dots> = more M\<rparr>)"
    using assms(1) unfolding calculate_state_separator_from_s_states_def Let_def filter_ex_by_find
    by (metis (mono_tags, lifting) option.inject option.simps(5)) 
  
  
  have "(s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))))
                 = s_states ?PR (size ?PR)"
    using s_states_code by metis
  then have "take i (s_states ?PR (size ?PR)) = take i (s_states ?PR (size ?PR))"
    by force
  
  have "i < length (s_states_opt ?PR (size ?PR))"
    using find_index_index(1)[OF i_def] by metis
  then have "i < length (s_states ?PR (size ?PR))"
    using s_states_code by metis
  moreover have "length (s_states ?PR (size ?PR)) \<le> size ?PR"
    using s_states_size by blast
  ultimately have "i < size ?PR" by force


  have "fst (last (take (Suc i) (s_states_opt ?PR (size ?PR)))) = (q1,q2)"
    using find_index_index(2)[OF i_def]
    using take_last_index[OF \<open>i < length (s_states_opt ?PR (size ?PR))\<close>]
    by force

  have "Suc i \<le> size ?PR"
    using \<open>i < size ?PR\<close> by simp
  have "(take (Suc i) (s_states_opt ?PR (size ?PR))) = s_states ?PR (Suc i)"
    using s_states_prefix[OF \<open>Suc i \<le> size ?PR\<close>] s_states_code by metis

  let ?S = "\<lparr>initial = fst (last (s_states ?PR (Suc i))), inputs = inputs ?PR,
             outputs = outputs ?PR,
             transitions =
               filter
                (\<lambda>t. \<exists>qqx\<in>set (s_states ?PR (Suc i)).
                        t_source t = fst qqx \<and> t_input t = snd qqx)
                (wf_transitions ?PR),
             \<dots> = more M\<rparr>"

  have s2 : "S = (state_separator_from_product_submachine M ?S)"
    using s1 
  proof -
    have "fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i))) = (q1, q2)"
      by (metis \<open>fst (last (take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))))) = (q1, q2)\<close> \<open>take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i)\<close>)
    then show ?thesis
      using \<open>S = state_separator_from_product_submachine M \<lparr>initial = (q1, q2), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))))). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>\<close> \<open>take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i)\<close> by presburger
  qed 

  have "s_states ?PR (Suc i) \<noteq> []"
    using \<open>i < length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))))\<close> \<open>s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))\<close> \<open>take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i)\<close> by auto

  have "induces_state_separator_for_prod M q1 q2 ?S"
    using  s_states_induces_state_separator[OF \<open>s_states ?PR (Suc i) \<noteq> []\<close> assms(2,3,4)] by assumption

  then have "induces_state_separator M ?S" 
    using \<open>fst (last (take (Suc i) (s_states_opt ?PR (size ?PR)))) = (q1,q2)\<close> \<open>(take (Suc i) (s_states_opt ?PR (size ?PR))) = s_states ?PR (Suc i)\<close> 
    using induces_from_prod
    by (metis (no_types, lifting) fst_conv select_convs(1) snd_conv) 




  have "fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i) )) = (q1,q2)"
    using \<open>fst (last (take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))))) = (q1, q2)\<close> \<open>take (Suc i) (s_states_opt (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i)\<close> by auto 
  
  have "fst (initial ?S) = q1"
    using \<open>fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i))) = (q1,q2)\<close> by force
  then have "fst (initial ?S) \<in> nodes M"
    using assms(2) by auto

  have "snd (initial ?S) = q2"
    using \<open>fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i))) = (q1,q2)\<close> by force
  then have "snd (initial ?S) \<in> nodes M"
    using assms(3) by auto

  have "fst (initial ?S) \<noteq> snd (initial ?S)"
    using \<open>fst (initial ?S) = q1\<close> \<open>snd (initial ?S) = q2\<close> assms(4) by auto

  have "is_state_separator_from_canonical_separator
   (canonical_separator M (fst (initial ?S)) (snd (initial ?S))) (fst (initial ?S)) (snd (initial ?S))
   (state_separator_from_product_submachine M ?S)"
    using state_separator_from_induces_state_separator
          [OF \<open>induces_state_separator M ?S\<close>
              \<open>fst (initial ?S) \<in> nodes M\<close>
              \<open>snd (initial ?S) \<in> nodes M\<close>
              \<open>fst (initial ?S) \<noteq> snd (initial ?S)\<close>
              \<open>completely_specified M\<close>] by assumption

  then show ?thesis using s2
    by (metis \<open>fst (initial \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i)). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>) = q1\<close> \<open>snd (initial \<lparr>initial = fst (last (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i))), inputs = inputs (product (from_FSM M q1) (from_FSM M q2)), outputs = outputs (product (from_FSM M q1) (from_FSM M q2)), transitions = filter (\<lambda>t. \<exists>qqx\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc i)). t_source t = fst qqx \<and> t_input t = snd qqx) (wf_transitions (product (from_FSM M q1) (from_FSM M q2))), \<dots> = more M\<rparr>) = q2\<close>) 
qed




lemma s_states_find_props :
  assumes "s_states M (Suc k) = s_states M k @ [qqx]"
  shows "(\<forall>qx'\<in>set (s_states M k). fst qqx \<noteq> fst qx')" 
  and "(\<forall>t\<in>set (wf_transitions M). t_source t = fst qqx \<and> t_input t = snd qqx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))"
  and "fst qqx \<in> nodes M"
  and "snd qqx \<in> set (inputs M)"
proof -
  have *: "find
              (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and>
                    (\<forall>t\<in>set (wf_transitions M).
                        t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                        (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t)))
              (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) = Some qqx"
    using assms unfolding s_states.simps
  proof -
    assume "(if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx]) = s_states M k @ [qqx]"
    then have f1: "\<not> length (s_states M k) < k \<or> s_states M (Suc k) = s_states M k"
      using assms by presburger
    have f2: "find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) \<noteq> None \<or> length (s_states M k) < k \<or> s_states M (Suc k) = s_states M k"
      by (metis (lifting) \<open>(if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx]) = s_states M k @ [qqx]\<close> assms option.simps(4))
      
    have f3: "s_states M (Suc k) \<noteq> s_states M k"
      using assms by force
    then have f4: "\<not> length (s_states M k) < k"
      using f1 by meson
    have f5: "find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) \<noteq> None"
      using f3 f2 f1 by meson
    have f6: "(case find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some p \<Rightarrow> s_states M k @ [p]) = s_states M (Suc k)"
      by (metis (lifting) \<open>(if length (s_states M k) < k then s_states M k else case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states M k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions M). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M))) of None \<Rightarrow> s_states M k | Some qx \<Rightarrow> s_states M k @ [qx]) = s_states M k @ [qqx]\<close> assms f4)
      
    obtain pp :: "('a \<times> integer) option \<Rightarrow> 'a \<times> integer" where
      f7: "\<And>z. z = None \<or> Some (pp z) = z"
      by (metis (no_types) not_None_eq)
    then have "\<And>z ps f. z = None \<or> (case z of None \<Rightarrow> ps::('a \<times> integer) list | Some x \<Rightarrow> f x) = f (pp z)"
      by (metis (no_types) option.case_eq_if option.sel)
    then have "find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) = None \<or> s_states M k @ [pp (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))))] = s_states M (Suc k)"
      using f6 by fastforce
    then have "s_states M k @ [pp (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))))] = s_states M (Suc k)"
      using f5 by meson
    then have "pp (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M)))) = last (s_states M (Suc k))"
      by (metis (no_types, lifting) last_snoc)
      
    then have "find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) = None \<or> find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states M k) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions M) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states M k) \<and> fst p = t_target pa))) (concat (map (\<lambda>a. map (Pair a) (inputs M)) (nodes_from_distinct_paths M))) = Some qqx"
      using f7 assms by fastforce
    then show ?thesis
      using f5 by meson
  qed 

  show "(\<forall>qx'\<in>set (s_states M k). fst qqx \<noteq> fst qx')" 
  and  "(\<forall>t\<in>set (wf_transitions M). t_source t = fst qqx \<and> t_input t = snd qqx \<longrightarrow> (\<exists>qx'\<in>set (s_states M k). fst qx' = t_target t))"
    using find_condition[OF *] by blast+

  
  have "qqx \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M)))"
    using find_set[OF *] by assumption

  then show "fst qqx \<in> nodes M"
        and "snd qqx \<in> set (inputs M)"
    using concat_pair_set[of "inputs M" "nodes_from_distinct_paths M"] nodes_code[of M] by blast+
qed
  
lemma s_states_step :
  assumes "qqx \<in> set (s_states (from_FSM M q) k)"
  and "q \<in> nodes M"
shows "\<exists> qqx' \<in> set (s_states M (size M)) . fst qqx = fst qqx'" 
using assms(1) proof (induction k arbitrary: qqx)
  case 0
  then show ?case by auto
next
  case (Suc k)
  
  show ?case proof (cases "qqx \<in> set (s_states (from_FSM M q) k)")
    case True
    then show ?thesis using Suc.IH by blast
  next
    case False

    let ?l = "length (s_states M (size M))"
    have "s_states M (size M) = s_states M ?l"
      using s_states_self_length by blast
    then have "s_states M ?l = s_states M (Suc ?l)"
      by (metis Suc_n_not_le_n nat_le_linear s_states_max_iterations s_states_prefix take_all)
      

    have "\<exists>qqx'\<in>set (s_states M ?l). fst qqx = fst qqx'"  proof (rule ccontr)
      assume c_assm: "\<not> (\<exists>qqx'\<in>set (s_states M ?l). fst qqx = fst qqx')"
      

      from False have *: "(s_states (from_FSM M q) (Suc k)) \<noteq> (s_states (from_FSM M q) k)"
        using Suc.prems by auto
      have qqx_last: "(s_states (from_FSM M q) (Suc k)) = (s_states (from_FSM M q) k) @ [qqx]"
        using Suc.prems False s_states_last[OF *]
        by force
      
      have "(\<forall>qx'\<in>set (s_states (from_FSM M q) k). fst qqx \<noteq> fst qx')" 
      and **: "(\<forall>t\<in>set (wf_transitions (from_FSM M q)).
                  t_source t = fst qqx \<and> t_input t = snd qqx \<longrightarrow>
                  (\<exists>qx'\<in>set (s_states (from_FSM M q) k). fst qx' = t_target t))"
      and  "fst qqx \<in> nodes (from_FSM M q)"
      and  "snd qqx \<in> set (inputs (from_FSM M q))"
        using s_states_find_props[OF qqx_last] by blast+
  

      have "(\<forall>qx'\<in>set (s_states M ?l). fst qqx \<noteq> fst qx')"
        using c_assm by blast
      moreover have "\<And> t . t \<in> h M \<Longrightarrow>
                t_source t = fst qqx \<Longrightarrow> 
                t_input t = snd qqx \<Longrightarrow>
                (\<exists>qx'\<in>set (s_states M ?l). fst qx' = t_target t)"
        using Suc.IH ** \<open>s_states M (size M) = s_states M ?l\<close>
        by (metis \<open>fst qqx \<in> nodes (from_FSM M q)\<close> from_FSM_nodes_transitions) 
      ultimately have "(\<lambda> qx . (\<forall> qx' \<in> set (s_states M ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states M ?l) . fst qx' = (t_target t)))) qqx"
        by auto
      moreover have "qqx \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M)))"
      proof -
        have "fst qqx \<in> set (nodes_from_distinct_paths M)" 
          using from_FSM_nodes[OF assms(2)] \<open>fst qqx \<in> nodes (from_FSM M q)\<close> nodes_code
          by (metis subsetCE) 
        moreover have "snd qqx \<in> set (inputs M)"
          using from_FSM_simps(2) \<open>snd qqx \<in> set (inputs (from_FSM M q))\<close> by metis
        ultimately show ?thesis using concat_pair_set[of "inputs M" "nodes_from_distinct_paths M"]
          by blast 
      qed
      ultimately have "find 
                  (\<lambda> qx . (\<forall> qx' \<in> set (s_states M ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states M?l) . fst qx' = (t_target t)))) 
                  (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs M)) (nodes_from_distinct_paths M))) \<noteq> None"
        using find_from[of "(concat (map (\<lambda>q. map (Pair q) (inputs M)) (nodes_from_distinct_paths M)))" "(\<lambda> qx . (\<forall> qx' \<in> set (s_states M ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h M . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states M ?l) . fst qx' = (t_target t))))"] by blast

      then have "s_states M (Suc ?l) \<noteq> s_states M ?l"
        unfolding s_states.simps
        using \<open>s_states M (FSM.size M) = s_states M (length (s_states M (FSM.size M)))\<close> by auto
      then show "False"
        using \<open>s_states M ?l = s_states M (Suc ?l)\<close>
        by simp
    qed

    then show ?thesis
      using \<open>s_states M (size M) = s_states M ?l\<close> by auto
  qed
qed


lemma s_states_step_prod :
  assumes "qqx \<in> set (s_states (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t)))) k)"
  and "t \<in> h (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))"
shows "\<exists> qqx' \<in> set (s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (size (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))))) . fst qqx = fst qqx'"
  using assms(1) proof (induction k arbitrary: qqx)
  case 0
  then show ?case by auto
next
  case (Suc k)

  let ?PMT = "(product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t))))"
  let ?PMS = "(product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))"
  
  show ?case proof (cases "qqx \<in> set (s_states ?PMT k)")
    case True
    then show ?thesis using Suc.IH by blast
  next
    case False

    let ?l = "length (s_states ?PMS (size ?PMS))"
    have "s_states ?PMS (size ?PMS) = s_states ?PMS ?l"
      using s_states_self_length by blast
    then have "s_states ?PMS ?l = s_states ?PMS (Suc ?l)"
    proof -
      have f1: "\<forall>n. n \<le> Suc n"
        using Suc_leD by blast
      then have f2: "\<forall>f. s_states (f::('a \<times> 'a) FSM) (Suc (Suc (FSM.size f))) = s_states f (FSM.size f)"
        by (meson Suc_leD s_states_max_iterations)
      have "\<forall>f. length (s_states (f::('a \<times> 'a) FSM) (FSM.size f)) \<le> Suc (FSM.size f)"
        using f1 by (metis (no_types) s_states_length s_states_max_iterations)
      then show ?thesis
        using f2 f1 by (metis (no_types) Suc_le_mono \<open>s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (FSM.size (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))) = s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (length (s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (FSM.size (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))))))\<close> s_states_prefix take_all)
    qed
      
      

    have "\<exists>qqx'\<in>set (s_states ?PMS ?l). fst qqx = fst qqx'"  proof (rule ccontr)
      assume c_assm: "\<not> (\<exists>qqx'\<in>set (s_states ?PMS ?l). fst qqx = fst qqx')"
      

      from False have *: "(s_states ?PMT (Suc k)) \<noteq> (s_states ?PMT k)"
        using Suc.prems by auto
      have qqx_last: "(s_states ?PMT (Suc k)) = (s_states ?PMT k) @ [qqx]"
        using Suc.prems False s_states_last[OF *]
        by force
      
      have "(\<forall>qx'\<in>set (s_states ?PMT k). fst qqx \<noteq> fst qx')" 
      and **: "(\<forall>t\<in>set (wf_transitions ?PMT).
                  t_source t = fst qqx \<and> t_input t = snd qqx \<longrightarrow>
                  (\<exists>qx'\<in>set (s_states ?PMT k). fst qx' = t_target t))"
      and  "fst qqx \<in> nodes ?PMT"
      and  "snd qqx \<in> set (inputs ?PMT)"
        using s_states_find_props[OF qqx_last] by blast+

      have "(fst (t_target t), snd (t_target t)) \<in> nodes ?PMS"
        using assms(2) by auto
      have "fst qqx \<in> nodes ?PMS"
      proof -
        obtain p where "path ?PMT (initial ?PMT) p" and "target p (initial ?PMT) = fst qqx"
          using \<open>fst qqx \<in> nodes ?PMT\<close>
          using path_to_node by force 
        then have "path ?PMT (fst (t_target t), snd (t_target t)) p" 
        and       "target p (fst (t_target t), snd (t_target t)) = fst qqx"
          by (simp add: from_FSM_product_initial)+

        then have "path (from_FSM ?PMS (fst (t_target t), snd (t_target t))) (fst (t_target t), snd (t_target t)) p"
          using product_from_next'_path[OF assms(2)] by auto
        then have "path ?PMS (fst (t_target t), snd (t_target t)) p"
          using from_FSM_path[OF \<open>(fst (t_target t), snd (t_target t)) \<in> nodes ?PMS\<close>] by metis
        then have "target p (fst (t_target t), snd (t_target t)) \<in> nodes ?PMS" 
          using path_target_is_node by metis
        then show ?thesis 
          using \<open>target p (fst (t_target t), snd (t_target t)) = fst qqx\<close> by simp
      qed

      have "snd qqx \<in> set (inputs ?PMS)"
        using \<open>snd qqx \<in> set (inputs ?PMT)\<close>
        by (simp add: from_FSM_simps(2) product_simps(2)) 

      

     


      have "(\<forall>qx'\<in>set (s_states ?PMS ?l). fst qqx \<noteq> fst qx')"
        using c_assm by blast
      moreover have "\<And> t . t \<in> h ?PMS \<Longrightarrow>
                t_source t = fst qqx \<Longrightarrow> 
                t_input t = snd qqx \<Longrightarrow>
                (\<exists>qx'\<in>set (s_states ?PMS ?l). fst qx' = t_target t)"
        using Suc.IH ** \<open>s_states ?PMS (size ?PMS) = s_states ?PMS ?l\<close> 
        using \<open>fst qqx \<in> nodes ?PMS\<close> \<open>snd qqx \<in> set (inputs ?PMS)\<close>
      proof -
        fix ta :: "('a \<times> 'a) \<times> integer \<times> integer \<times> 'a \<times> 'a"
        assume a1: "t_source ta = fst qqx"
        assume a2: "t_input ta = snd qqx"
        assume a3: "ta \<in> set (wf_transitions (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))))"
        have "\<forall>p. p = (fst p::'a, snd p::'a)"
          by simp
        then show "\<exists>p\<in>set (s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (length (s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (FSM.size (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))))))). fst p = t_target ta"
          using a3 a2 a1 by (metis (no_types) "**" Suc.IH \<open>fst qqx \<in> nodes (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))\<close> \<open>fst qqx \<in> nodes (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t))))\<close> \<open>s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (FSM.size (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))) = s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (length (s_states (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (FSM.size (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))))))\<close> from_FSM_transition_initial from_product_from_h product_from_transition_shared_node)
      qed
      ultimately have "(\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PMS ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PMS . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PMS ?l) . fst qx' = (t_target t)))) qqx"
        by auto
      moreover have "qqx \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs ?PMS)) (nodes_from_distinct_paths ?PMS)))"
      proof -
        
        have "fst qqx \<in> set (nodes_from_distinct_paths ?PMS)" 
          using \<open>fst qqx \<in> nodes ?PMS\<close> nodes_code[of ?PMS] 
          by blast
        then show ?thesis using concat_pair_set[of "inputs ?PMS" "nodes_from_distinct_paths ?PMS"]
          using \<open>snd qqx \<in> set (inputs ?PMS)\<close> by blast 
      qed
      ultimately have "find 
                  (\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PMS ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PMS . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PMS ?l) . fst qx' = (t_target t)))) 
                  (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs ?PMS)) (nodes_from_distinct_paths ?PMS))) \<noteq> None"
        using find_from[of "(concat (map (\<lambda>q. map (Pair q) (inputs ?PMS)) (nodes_from_distinct_paths ?PMS)))" "(\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PMS ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PMS . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PMS ?l) . fst qx' = (t_target t))))"] by blast

      then have "s_states ?PMS (Suc ?l) \<noteq> s_states ?PMS ?l"
        unfolding s_states.simps
        using \<open>s_states ?PMS (size ?PMS) = s_states ?PMS ?l\<close> by auto
      then show "False"
        using \<open>s_states ?PMS ?l = s_states ?PMS (Suc ?l)\<close>
        by simp
    qed

    then show ?thesis
      using \<open>s_states ?PMS (size ?PMS) = s_states ?PMS ?l\<close> by auto
  qed
qed





lemma s_states_exhaustiveness :
  assumes "r_distinguishable_k M q1 q2 k"
  and "q1 \<in> nodes M"
  and "q2 \<in> nodes M"
shows "\<exists> qqt \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) (size (product (from_FSM M q1) (from_FSM M q2)))) . fst qqt = (q1,q2)" 
using assms proof (induction k arbitrary: q1 q2)
  case 0

  let ?PM = "product (from_FSM M q1) (from_FSM M q2)"

  from 0 obtain x where "x \<in> set (inputs M)"
                  and "\<not> (\<exists>t1\<in>set (wf_transitions M).
                            \<exists>t2\<in>set (wf_transitions M).
                               t_source t1 = q1 \<and>
                               t_source t2 = q2 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)"
    unfolding r_distinguishable_k.simps by blast
  then have *: "\<not> (\<exists>t1 \<in> h (from_FSM M q1).
                            \<exists>t2 \<in> h (from_FSM M q2).
                               t_source t1 = q1 \<and>
                               t_source t2 = q2 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)"
    using from_FSM_h[OF "0.prems"(2)] from_FSM_h[OF "0.prems"(3)] by blast

  then have "\<And> t . t \<in> h ?PM \<Longrightarrow> \<not>(t_source t = (q1,q2) \<and> t_input t = x)"
  proof -
    fix t assume "t \<in> h ?PM"
    show "\<not>(t_source t = (q1,q2) \<and> t_input t = x)"
    proof 
      assume "t_source t = (q1, q2) \<and> t_input t = x"
      then have "(q1, x, t_output t, fst (t_target t)) \<in> set (wf_transitions (from_FSM M q1))"
            and "(q2, x, t_output t, snd (t_target t)) \<in> set (wf_transitions (from_FSM M q2))"
        using product_transition_split[OF \<open>t \<in> h ?PM\<close>] by auto
      then show "False"
        using * by force
    qed
  qed

  have "(q1,q2) \<in> set (nodes_from_distinct_paths ?PM)"
    using nodes_code nodes.initial product_simps(1) from_FSM_simps(1) by metis
  
  have p_find_1: "\<And> k' . (\<forall> t \<in> h ?PM . (t_source t = fst ((q1,q2),x) \<and> t_input t = snd ((q1,q2),x) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PM k') . fst qx' = (t_target t))))"
    by (simp add: \<open>\<And>t. t \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))) \<Longrightarrow> \<not> (t_source t = (q1, q2) \<and> t_input t = x)\<close>)

  have p_find_2: "((q1,q2),x) \<in> set (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs ?PM)) (nodes_from_distinct_paths ?PM)))"
    using concat_pair_set \<open>x \<in> set (inputs M)\<close> \<open>(q1,q2) \<in> set (nodes_from_distinct_paths ?PM)\<close>
  proof -
    have f1: "\<forall>a ps aa f. set (concat (map (\<lambda>p. map (Pair (p::'a \<times> 'a)) (inputs (product (from_FSM (f::'a FSM) a) (from_FSM f aa)))) ps)) = set (concat (map (\<lambda>p. map (Pair p) (inputs f)) ps))"
      by (simp add: from_FSM_product_inputs)
    have "\<forall>is p ps. p \<in> set (concat (map (\<lambda>p. map (Pair (p::'a \<times> 'a)) is) ps)) \<or> \<not> (fst p \<in> set ps \<and> (snd p::integer) \<in> set is)"
      using concat_pair_set by blast
    then show ?thesis
      using f1 by (metis \<open>(q1, q2) \<in> set (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))\<close> \<open>x \<in> set (inputs M)\<close> fst_conv snd_conv)
  qed 


  have p_find: "\<And> k . (\<forall> qx' \<in> set (s_states ?PM k) . (q1,q2) \<noteq> fst qx') \<Longrightarrow>
               ((\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PM k) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PM . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PM k) . fst qx' = (t_target t)))) ((q1,q2),x))
                \<and> ((q1,q2),x) \<in> set (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs ?PM)) (nodes_from_distinct_paths ?PM)))"
    using p_find_1 p_find_2
    by (metis fst_conv) 

  have p_find_alt : "\<And> k . (\<forall> qx' \<in> set (s_states ?PM k) . (q1,q2) \<noteq> fst qx') \<Longrightarrow>
                            find
                              (\<lambda>qx. (\<forall>qx'\<in>set (s_states ?PM k).
                                        fst qx \<noteq> fst qx') \<and>
                                    (\<forall>t\<in>set (wf_transitions ?PM).
                                        t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                                        (\<exists>qx'\<in>set (s_states ?PM k).
                                            fst qx' = t_target t)))
                              (concat
                                (map (\<lambda>q. map (Pair q) (inputs ?PM))
                                  (nodes_from_distinct_paths ?PM))) \<noteq> None" 
    
  proof -
    fix k assume assm: "(\<forall> qx' \<in> set (s_states ?PM k) . (q1,q2) \<noteq> fst qx')"
    show "find
            (\<lambda>qx. (\<forall>qx'\<in>set (s_states ?PM k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions ?PM). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states ?PM k). fst qx' = t_target t)))
            (concat (map (\<lambda>q. map (Pair q) (inputs ?PM)) (nodes_from_distinct_paths ?PM))) \<noteq> None"
      using find_None_iff[of "(\<lambda>qx. (\<forall>qx'\<in>set (s_states ?PM k). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions ?PM). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states ?PM k). fst qx' = t_target t)))"
                             "(concat (map (\<lambda>q. map (Pair q) (inputs ?PM)) (nodes_from_distinct_paths ?PM)))" ]
            p_find[OF assm] by blast
  qed
          






  have "\<exists> x . ((q1,q2),x) \<in> set (s_states ?PM (size ?PM))"
  proof (rule ccontr)
    assume "\<not> (\<exists> x . ((q1,q2),x) \<in> set (s_states ?PM (size ?PM)))"
    
    let ?l = "length (s_states ?PM (size ?PM))"
    have "s_states ?PM (size ?PM) = s_states ?PM ?l"
      by (metis (no_types, hide_lams) s_states_self_length)

    then have l_assm: "\<not> (\<exists> x . ((q1,q2),x) \<in> set (s_states ?PM ?l))"
      using \<open>\<not> (\<exists> x . ((q1,q2),x) \<in> set (s_states ?PM (size ?PM)))\<close> by auto
    
    then have "(q1,q2) \<notin> set (map fst (s_states ?PM ?l))" by auto

    have "?l \<le> size ?PM"
      using s_states_length by blast
      

    then consider  
      (a) "?l = 0" |
      (b) "0 < ?l \<and> ?l < size ?PM" |
      (c) "?l = size ?PM"
      using nat_less_le by blast
    then show "False" proof cases
      case a 
      
      then have "(s_states ?PM (Suc 0)) = []"
        by (metis s_states_prefix s_states_self_length s_states_size take_eq_Nil)
      then have *: "find
              (\<lambda>qx. (\<forall>qx'\<in>set []. fst qx \<noteq> fst qx') \<and>
                    (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                        t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                        (\<exists>qx'\<in>set []. fst qx' = t_target t)))
              (concat
                (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) = None"
        unfolding s_states.simps
        using find_None_iff by fastforce 
      then have "\<not>(\<exists> qqt \<in> set (concat
                (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) . (\<lambda>qx. (\<forall>qx'\<in>set []. fst qx \<noteq> fst qx') \<and>
                    (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                        t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                        (\<exists>qx'\<in>set []. fst qx' = t_target t))) qqt)"
        unfolding s_states.simps
        using find_None_iff[of "(\<lambda>qx. (\<forall>qx'\<in>set []. fst qx \<noteq> fst qx') \<and>
                    (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                        t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                        (\<exists>qx'\<in>set []. fst qx' = t_target t)))" "(concat
                (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))" ] by blast
      then have "\<not>(\<exists> qqt \<in> set (concat
                (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                  (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) . (\<lambda>qx. (\<forall>qx'\<in>set (s_states ?PM 0). fst qx \<noteq> fst qx') \<and>
                    (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                        t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                        (\<exists>qx'\<in>set (s_states ?PM 0). fst qx' = t_target t))) qqt)"
        unfolding s_states.simps by assumption

      then show "False"
        using p_find[of 0]
        by (metis \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))))\<close> a length_0_conv length_greater_0_conv length_pos_if_in_set)  

    next 
      case b
      
      then obtain l' where Suc: "?l = Suc l'" using gr0_conv_Suc by blast
      moreover obtain l where "l = ?l" by auto
      ultimately have "l = Suc l'" by auto

      have "s_states ?PM ?l = s_states ?PM (Suc ?l)"
        using s_states_prefix[of ?l "Suc ?l"] s_states_max_iterations
      proof -
        have "\<forall>n. n \<le> Suc n"
          by simp
        then show ?thesis
          by (metis Suc_le_mono \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))))\<close> s_states_length s_states_max_iterations s_states_prefix take_all)
      qed 

      have "length (s_states ?PM l') < length (s_states ?PM ?l)" using Suc
        using \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))))\<close> less_Suc_eq_le s_states_length by auto

      have "length (s_states (product (from_FSM M q1) (from_FSM M q2)) l) = l"
        using \<open>l = length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))))\<close> \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))))\<close> by auto
      then have "\<not>(length (s_states (product (from_FSM M q1) (from_FSM M q2)) l) < l)"
        by force

      have "\<forall>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l). (q1, q2) \<noteq> fst qx'"
        using l_assm \<open>l = ?l\<close>
        by auto 

      have "s_states ?PM l = s_states ?PM (Suc l)"
      proof -
        show ?thesis
          using \<open>length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2)))) = Suc l'\<close> \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) (length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))))) = s_states (product (from_FSM M q1) (from_FSM M q2)) (Suc (length (s_states (product (from_FSM M q1) (from_FSM M q2)) (FSM.size (product (from_FSM M q1) (from_FSM M q2))))))\<close> 
          using \<open>l = Suc l'\<close>
          by presburger
      qed
      then have "s_states ?PM l = (case find
                (\<lambda>qx. (\<forall>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l).
                          fst qx \<noteq> fst qx') \<and>
                      (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                          t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                          (\<exists>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l).
                              fst qx' = t_target t)))
                (concat
                  (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) of
          None \<Rightarrow> s_states (product (from_FSM M q1) (from_FSM M q2)) l
          | Some qx \<Rightarrow> s_states (product (from_FSM M q1) (from_FSM M q2)) l @ [qx])"
        unfolding s_states.simps
        using \<open>\<not>(length (s_states (product (from_FSM M q1) (from_FSM M q2)) l) < l)\<close> by force

      then have "find
                (\<lambda>qx. (\<forall>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l).
                          fst qx \<noteq> fst qx') \<and>
                      (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))).
                          t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow>
                          (\<exists>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l).
                              fst qx' = t_target t)))
                (concat
                  (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2))))
                    (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) = None"
      proof -
        have "s_states (product (from_FSM M q1) (from_FSM M q2)) l @ [the (find (\<lambda>p. (\<forall>pa. pa \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) l) \<longrightarrow> fst p \<noteq> fst pa) \<and> (\<forall>pa. pa \<in> set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))) \<longrightarrow> t_source pa = fst p \<and> t_input pa = snd p \<longrightarrow> (\<exists>p. p \<in> set (s_states (product (from_FSM M q1) (from_FSM M q2)) l) \<and> fst p = t_target pa))) (concat (map (\<lambda>p. map (Pair p) (inputs (product (from_FSM M q1) (from_FSM M q2)))) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))] \<noteq> s_states (product (from_FSM M q1) (from_FSM M q2)) l"
          by force
        then show ?thesis
          using \<open>s_states (product (from_FSM M q1) (from_FSM M q2)) l = (case find (\<lambda>qx. (\<forall>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l). fst qx \<noteq> fst qx') \<and> (\<forall>t\<in>set (wf_transitions (product (from_FSM M q1) (from_FSM M q2))). t_source t = fst qx \<and> t_input t = snd qx \<longrightarrow> (\<exists>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l). fst qx' = t_target t))) (concat (map (\<lambda>q. map (Pair q) (inputs (product (from_FSM M q1) (from_FSM M q2)))) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))) of None \<Rightarrow> s_states (product (from_FSM M q1) (from_FSM M q2)) l | Some qx \<Rightarrow> s_states (product (from_FSM M q1) (from_FSM M q2)) l @ [qx])\<close> by force
      qed 

      then show "False" using p_find_alt[OF \<open>\<forall>qx'\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2)) l). (q1, q2) \<noteq> fst qx'\<close>] by blast
    next
      case c
      have "distinct (map fst (s_states ?PM ?l))"
        using s_states_distinct_states by blast
      then have "card (set (map fst (s_states ?PM ?l))) = size ?PM"
        using c distinct_card by fastforce 
      moreover have "set (map fst (s_states ?PM ?l)) \<subseteq> nodes ?PM"
        using s_states_nodes by metis
      ultimately have "set (map fst (s_states ?PM ?l)) = nodes ?PM"
        using nodes_finite[of ?PM]
        by (simp add: card_subset_eq) 

      then  have "(q1,q2) \<notin> nodes ?PM"
        using \<open>(q1,q2) \<notin> set (map fst (s_states ?PM ?l))\<close>
        by blast 
      moreover have "(q1,q2) \<in> nodes ?PM"
        using nodes.initial[of ?PM] product_simps(1) from_FSM_simps(1) by metis
      ultimately show "False" 
        by blast
    qed 
  qed

  then show ?case
    by (meson fst_conv)
next
  case (Suc k)

  (* sketch: 
    \<longrightarrow> cases Suc k = LEAST,
      \<longrightarrow> FALSE: then also k \<longrightarrow> by IH
      \<longrightarrow> TRUE
        \<longrightarrow> \<noteq> 0
        \<longrightarrow> exists input x such that for every ((q1,q2),x,y,(s1,s2)) \<in> h ?PM , s1 and s2 are r(k)-d
          \<longrightarrow> (s1,s2) is contained in s_states for product for s1 s2
          \<longrightarrow> also: (s1,s2) (initial state of the above) is a node of product for q1 q2
          \<longrightarrow> then (s1,s2) is in s_states for product for q1 q2
          \<longrightarrow> by construction there must then exist some x' s.t. ((q1,q2),x') \<in> s_states 
  *)
  
  let ?PM = "(product (from_FSM M q1) (from_FSM M q2))"

  show ?case proof (cases "r_distinguishable_k M q1 q2 k")
    case True
    show ?thesis using Suc.IH[OF True Suc.prems(2,3)] by assumption
  next
    case False
    then obtain x where "x \<in> set (inputs M)"
                    and "\<forall>t1\<in>set (wf_transitions M).
                           \<forall>t2\<in>set (wf_transitions M).
                              t_source t1 = q1 \<and>
                              t_source t2 = q2 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2 \<longrightarrow>
                              r_distinguishable_k M (t_target t1) (t_target t2) k"
      using Suc.prems(1) unfolding r_distinguishable_k.simps by blast
    then have x_transitions: "\<forall>t1\<in>set (wf_transitions (from_FSM M q1)).
                               \<forall>t2\<in>set (wf_transitions (from_FSM M q2)).
                                  t_source t1 = q1 \<and>
                                  t_source t2 = q2 \<and> t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2 \<longrightarrow>
                                  r_distinguishable_k M (t_target t1) (t_target t2) k"
      using from_FSM_h[OF Suc.prems(2)] from_FSM_h[OF Suc.prems(3)] by blast
    


    have x_prop: "\<And> t . t \<in> h ?PM \<Longrightarrow> t_source t = (q1,q2) \<Longrightarrow> t_input t = x \<Longrightarrow> 
                (\<exists>qqt\<in>set (s_states ?PM (size ?PM)) .
                   fst qqt = t_target t)"
    proof -
      fix t assume "t \<in> h ?PM" and "t_source t = (q1,q2)" and "t_input t = x"

      have *: "(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> set (wf_transitions (from_FSM M q1))"
      and **: "(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> set (wf_transitions (from_FSM M q2))"
        using product_transition_t[of t "from_FSM M q1" "from_FSM M q2"] \<open>t \<in> h ?PM\<close>  by simp+

      then have "(q1,x,t_output t,fst (t_target t)) \<in> h (from_FSM M q1)"
           and  "(q2,x,t_output t,snd (t_target t)) \<in> h (from_FSM M q2)"
        using \<open>t_source t = (q1,q2)\<close> \<open>t_input t = x\<close> by simp+

      then have "r_distinguishable_k M (fst (t_target t)) (snd (t_target t)) k"
        using x_transitions by auto
      moreover have "fst (t_target t) \<in> nodes M"
        using from_FSM_nodes[OF Suc.prems(2)] wf_transition_target[OF *] by auto
      moreover have "snd (t_target t) \<in> nodes M"
        using from_FSM_nodes[OF Suc.prems(3)] wf_transition_target[OF **] by auto

      ultimately have "\<exists>qqt\<in>set (s_states (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t))))
                                  (FSM.size (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t)))))).
                         fst qqt = (fst (t_target t), snd (t_target t))"
        using Suc.IH[of "(fst (t_target t))" "(snd (t_target t))"] by blast

      then obtain qqt where qqt_def: "qqt\<in>set (s_states (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t))))
                                  (FSM.size (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t))))))"
                      and   "fst qqt = (fst (t_target t), snd (t_target t))" 
        by blast


      let ?PM' = "product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))"
      have "?PM = ?PM'"
        using \<open>t_source t = (q1,q2)\<close> by auto
      then have "t \<in> h ?PM'"
        using \<open>t \<in> h ?PM\<close> by simp

      show "\<exists>qqt\<in>set (s_states (product (from_FSM M q1) (from_FSM M q2))
                     (FSM.size (product (from_FSM M q1) (from_FSM M q2)))).
            fst qqt = t_target t"
        using s_states_step_prod[OF qqt_def \<open>t \<in> h ?PM'\<close>] \<open>?PM = ?PM'\<close> 
              \<open>fst qqt = (fst (t_target t), snd (t_target t))\<close>
        by (metis prod.collapse)
    qed


    let ?l = "length (s_states ?PM (size ?PM))"
    have "s_states ?PM (size ?PM) = s_states ?PM ?l"
      using s_states_self_length by blast
    then have "s_states ?PM ?l = s_states ?PM (Suc ?l)"
      by (metis Suc_n_not_le_n nat_le_linear s_states_max_iterations s_states_prefix take_all)

    have "\<exists>qqx'\<in>set (s_states ?PM ?l). (q1,q2) = fst qqx'"  proof (rule ccontr)
      assume c_assm: "\<not> (\<exists>qqx'\<in>set (s_states ?PM ?l). (q1,q2) = fst qqx')"
      

      have "(\<forall>qx'\<in>set (s_states ?PM ?l). (q1,q2) \<noteq> fst qx')"
        using c_assm by blast
      moreover have "\<And> t . t \<in> h ?PM \<Longrightarrow>
                t_source t = fst ((q1,q2),x) \<Longrightarrow> 
                t_input t = snd ((q1,q2),x) \<Longrightarrow>
                (\<exists>qx'\<in>set (s_states ?PM ?l). fst qx' = t_target t)"
        using x_prop snd_conv[of "(q1,q2)" x] fst_conv[of "(q1,q2)" x] \<open>s_states ?PM (size ?PM) = s_states ?PM ?l\<close> by auto 
      ultimately have "(\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PM ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PM . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PM ?l) . fst qx' = (t_target t)))) ((q1,q2),x)"
        by auto
      moreover have "((q1,q2),x) \<in> set (concat (map (\<lambda>q. map (Pair q) (inputs ?PM)) (nodes_from_distinct_paths ?PM)))"
      proof -
        have "fst ((q1,q2),x) \<in> set (nodes_from_distinct_paths ?PM)" 
          using nodes.initial nodes_code 
                fst_conv product_simps(1) from_FSM_simps(1)
          by metis 
        moreover have "snd ((q1,q2),x) \<in> set (inputs ?PM)"
          using \<open>x \<in> set (inputs M)\<close>
          by (simp add: from_FSM_simps(2) product_simps(2)) 
        ultimately show ?thesis using concat_pair_set[of "inputs ?PM" "nodes_from_distinct_paths ?PM"]
          by blast 
      qed
      ultimately have "find 
                  (\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PM ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PM . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PM ?l) . fst qx' = (t_target t)))) 
                  (concat (map (\<lambda> q . map (\<lambda> x . (q,x)) (inputs ?PM)) (nodes_from_distinct_paths ?PM))) \<noteq> None"
        using find_from[of "(concat (map (\<lambda>q. map (Pair q) (inputs ?PM)) (nodes_from_distinct_paths ?PM)))" "(\<lambda> qx . (\<forall> qx' \<in> set (s_states ?PM ?l) . fst qx \<noteq> fst qx') \<and> (\<forall> t \<in> h ?PM . (t_source t = fst qx \<and> t_input t = snd qx) \<longrightarrow> (\<exists> qx' \<in> set (s_states ?PM ?l) . fst qx' = (t_target t))))"] by blast

      then have "s_states ?PM (Suc ?l) \<noteq> s_states ?PM ?l"
        unfolding s_states.simps
        using \<open>s_states ?PM (FSM.size ?PM) = s_states ?PM ?l\<close> by auto
      then show "False"
        using \<open>s_states ?PM ?l = s_states ?PM (Suc ?l)\<close>
        by simp
    qed

    then show ?thesis
      using \<open>s_states ?PM (size ?PM) = s_states ?PM ?l\<close>
      by force 
  qed
qed



lemma calculate_state_separator_from_s_states_exhaustiveness :
  assumes "r_distinguishable_k M q1 q2 k"
  and "q1 \<in> nodes M"
  and "q2 \<in> nodes M"   
shows "calculate_state_separator_from_s_states M q1 q2 \<noteq> None" 
proof -

  let ?PM = "product (from_FSM M q1) (from_FSM M q2)"
  let ?SS = "s_states_opt ?PM (FSM.size ?PM)"

  have "\<exists> qqt \<in> set (s_states ?PM (size ?PM)) . fst qqt = (q1, q2)"
    using s_states_exhaustiveness[OF \<open>r_distinguishable_k M q1 q2 k\<close> assms(2,3)] by blast

  have "find_index (\<lambda>qqt. fst qqt = (q1, q2)) ?SS \<noteq> None"
    using find_index_exhaustive[OF \<open>\<exists> qqt \<in> set (s_states ?PM (size ?PM)) . fst qqt = (q1, q2)\<close>]
    by (simp add: s_states_code) 


  then obtain S where "calculate_state_separator_from_s_states M q1 q2 = Some S"
    unfolding calculate_state_separator_from_s_states_def Let_def
    by (meson option.case_eq_if)

  then show ?thesis by auto
qed















subsection \<open>State Separators and R-Distinguishability\<close>

(* TODO: check *)
declare from_FSM.simps[simp ]
declare product.simps[simp ]
declare from_FSM_simps[simp ]
declare product_simps[simp ]

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

(* TODO: check *)
declare from_FSM.simps[simp del]
declare product.simps[simp del]
declare from_FSM_simps[simp del]
declare product_simps[simp del]




lemma r_distinguishability_implies_state_separator :
  assumes "r_distinguishable M q1 q2"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "q1 \<noteq> q2"
  and     "completely_specified M"
shows "\<exists> S . is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S"
proof -

  let ?PM = "product (from_FSM M q1) (from_FSM M q2)"
  let ?SS = "s_states_opt ?PM (FSM.size ?PM)"

  obtain k where "r_distinguishable_k M q1 q2 k"
    by (meson assms r_distinguishable_alt_def) 

  then obtain S where "calculate_state_separator_from_s_states M q1 q2 = Some S"
    using calculate_state_separator_from_s_states_exhaustiveness[OF _ assms(2,3)] by blast

  show ?thesis
    using calculate_state_separator_from_s_states_soundness
            [OF \<open>calculate_state_separator_from_s_states M q1 q2 = Some S\<close> assms(2,3,4,5)] by blast
qed



lemma r_distinguishable_iff_state_separator_exists :
  assumes "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "q1 \<noteq> q2"
  and     "completely_specified M"
shows "r_distinguishable M q1 q2 \<longleftrightarrow> (\<exists> S . is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 S)"
  using r_distinguishability_implies_state_separator[OF _ assms] state_separator_r_distinguishes_k r_distinguishable_alt_def[OF assms(1,2)]  
  by metis



subsection \<open>Generalizing the Separator Definition\<close>

definition is_separator :: "'a FSM \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> 'c FSM \<Rightarrow> 'c \<Rightarrow> 'c \<Rightarrow> bool" where
  "is_separator M q1 q2 A t1 t2 = 
    (single_input A
     \<and> acyclic A
     \<and> observable A
     \<and> deadlock_state A t1 
     \<and> deadlock_state A t2
     \<and> t1 \<in> nodes A
     \<and> t2 \<in> nodes A
     \<and> (\<forall> t \<in> nodes A . (t \<noteq> t1 \<and> t \<noteq> t2) \<longrightarrow> \<not> deadlock_state A t)
     \<and> (\<forall> io \<in> L A . (\<forall> x yq yt . (io@[(x,yq)] \<in> LS M q1 \<and> io@[(x,yt)] \<in> L A) \<longrightarrow> (io@[(x,yq)] \<in> L A))
                   \<and> (\<forall> x yq2 yt . (io@[(x,yq2)] \<in> LS M q2 \<and> io@[(x,yt)] \<in> L A) \<longrightarrow> (io@[(x,yq2)] \<in> L A)))
     \<and> (\<forall> p . (path A (initial A) p \<and> target p (initial A) = t1) \<longrightarrow> p_io p \<in> LS M q1 - LS M q2)
     \<and> (\<forall> p . (path A (initial A) p \<and> target p (initial A) = t2) \<longrightarrow> p_io p \<in> LS M q2 - LS M q1)
     \<and> (\<forall> p . (path A (initial A) p \<and> target p (initial A) \<noteq> t1 \<and> target p (initial A) \<noteq> t2) \<longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2)
     \<and> q1 \<noteq> q2
     \<and> t1 \<noteq> t2
     \<and> set (inputs A) \<subseteq> set (inputs M))"


lemma is_separator_simps :
  assumes "is_separator M q1 q2 A t1 t2"
shows "single_input A"
  and "acyclic A"
  and "observable A"
  and "deadlock_state A t1"
  and "deadlock_state A t2"
  and "t1 \<in> nodes A"
  and "t2 \<in> nodes A"
  and "\<And> t . t \<in> nodes A \<Longrightarrow> t \<noteq> t1 \<Longrightarrow> t \<noteq> t2 \<Longrightarrow> \<not> deadlock_state A t"
  and "\<And> io x yq yt . io@[(x,yq)] \<in> LS M q1 \<Longrightarrow> io@[(x,yt)] \<in> L A \<Longrightarrow> (io@[(x,yq)] \<in> L A)"
  and "\<And> io x yq yt . io@[(x,yq)] \<in> LS M q2 \<Longrightarrow> io@[(x,yt)] \<in> L A \<Longrightarrow> (io@[(x,yq)] \<in> L A)"
  and "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2"
  and "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1"
  and "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) \<noteq> t1 \<Longrightarrow> target p (initial A) \<noteq> t2 \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2"
  and "q1 \<noteq> q2"
  and "t1 \<noteq> t2"
  and "set (inputs A) \<subseteq> set (inputs M)"
proof -
  have p01: "single_input A"
  and  p02: "acyclic A"
  and  p03: "observable A"
  and  p04: "deadlock_state A t1" 
  and  p05: "deadlock_state A t2"
  and  p06: "t1 \<in> nodes A"
  and  p07: "t2 \<in> nodes A"
  and  p08: "(\<forall> t \<in> nodes A . (t \<noteq> t1 \<and> t \<noteq> t2) \<longrightarrow> \<not> deadlock_state A t)"
  and  p09: "(\<forall> io \<in> L A . (\<forall> x yq yt . (io@[(x,yq)] \<in> LS M q1 \<and> io@[(x,yt)] \<in> L A) \<longrightarrow> (io@[(x,yq)] \<in> L A))
                         \<and> (\<forall> x yq2 yt . (io@[(x,yq2)] \<in> LS M q2 \<and> io@[(x,yt)] \<in> L A) \<longrightarrow> (io@[(x,yq2)] \<in> L A)))"
  and  p10: "(\<forall> p . (path A (initial A) p \<and> target p (initial A) = t1) \<longrightarrow> p_io p \<in> LS M q1 - LS M q2)"
  and  p11: "(\<forall> p . (path A (initial A) p \<and> target p (initial A) = t2) \<longrightarrow> p_io p \<in> LS M q2 - LS M q1)"
  and  p12: "(\<forall> p . (path A (initial A) p \<and> target p (initial A) \<noteq> t1 \<and> target p (initial A) \<noteq> t2) \<longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2)"
  and  p13: "q1 \<noteq> q2"
  and  p14: "t1 \<noteq> t2"
  and  p15: "set (inputs A) \<subseteq> set (inputs M)"
    using assms unfolding is_separator_def by presburger+

  show "single_input A" using p01 by assumption
  show "acyclic A" using p02 by assumption
  show "observable A" using p03 by assumption
  show "deadlock_state A t1" using p04 by assumption
  show "deadlock_state A t2" using p05 by assumption
  show "t1 \<in> nodes A" using p06 by assumption
  show "t2 \<in> nodes A" using p07 by assumption
  show "\<And> io x yq yt . io@[(x,yq)] \<in> LS M q1 \<Longrightarrow> io@[(x,yt)] \<in> L A \<Longrightarrow> (io@[(x,yq)] \<in> L A)" using p09 language_prefix[of _ _ A "initial A"] by blast
  show "\<And> io x yq yt . io@[(x,yq)] \<in> LS M q2 \<Longrightarrow> io@[(x,yt)] \<in> L A \<Longrightarrow> (io@[(x,yq)] \<in> L A)" using p09 language_prefix[of _ _ A "initial A"] by blast
  show "\<And> t . t \<in> nodes A \<Longrightarrow> t \<noteq> t1 \<Longrightarrow> t \<noteq> t2 \<Longrightarrow> \<not> deadlock_state A t" using p08 by blast
  show "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2" using p10 by blast
  show "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1" using p11 by blast
  show "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) \<noteq> t1 \<Longrightarrow> target p (initial A) \<noteq> t2 \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2" using p12 by blast
  show "q1 \<noteq> q2" using p13 by assumption
  show "t1 \<noteq> t2" using p14 by assumption
  show "set (inputs A) \<subseteq> set (inputs M)" using p15 by assumption
qed


lemma separator_path_targets :
  assumes "is_separator M q1 q2 A t1 t2"
  and     "path A (initial A) p"
shows "p_io p \<in> LS M q1 - LS M q2 \<Longrightarrow> target p (initial A) = t1"
and   "p_io p \<in> LS M q2 - LS M q1 \<Longrightarrow> target p (initial A) = t2"
and   "p_io p \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> (target p (initial A) \<noteq> t1 \<and> target p (initial A) \<noteq> t2)"
and   "p_io p \<in> LS M q1 \<union> LS M q2"
proof -
  have pt1: "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2" 
  and  pt2: "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1" 
  and  pt3: "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) \<noteq> t1 \<Longrightarrow> target p (initial A) \<noteq> t2 \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2" 
  and  "t1 \<noteq> t2"
  and  "observable A"
    using is_separator_simps[OF assms(1)] by blast+

  show "p_io p \<in> LS M q1 - LS M q2 \<Longrightarrow> target p (initial A) = t1"
    using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close> by blast
  show "p_io p \<in> LS M q2 - LS M q1 \<Longrightarrow> target p (initial A) = t2"
    using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close> by blast
  show "p_io p \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> (target p (initial A) \<noteq> t1 \<and> target p (initial A) \<noteq> t2)"
    using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close> by blast
  show "p_io p \<in> LS M q1 \<union> LS M q2"
    using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close> by blast
qed


lemma separator_language :
  assumes "is_separator M q1 q2 A t1 t2"
  and     "io \<in> L A"
shows "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets A io (initial A) = {t1}"
and   "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets A io (initial A) = {t2}"
and   "io \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> io_targets A io (initial A) \<inter> {t1,t2} = {}"
and   "io \<in> LS M q1 \<union> LS M q2"
proof -

  obtain p where "path A (initial A) p" and "p_io p = io"
    using \<open>io \<in> L A\<close>  by auto

  have pt1: "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2" 
  and  pt2: "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = t2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1" 
  and  pt3: "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) \<noteq> t1 \<Longrightarrow> target p (initial A) \<noteq> t2 \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2" 
  and  "t1 \<noteq> t2"
  and  "observable A"
    using is_separator_simps[OF assms(1)] by blast+



  show "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets A io (initial A) = {t1}"
  proof -
    assume "io \<in> LS M q1 - LS M q2"
    
    then have "p_io p \<in> LS M q1 - LS M q2"
      using \<open>p_io p = io\<close> by auto
    then have "target p (initial A) = t1"
      using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close>
      by blast 
    then have "t1 \<in> io_targets A io (initial A)"
      using \<open>path A (initial A) p\<close> \<open>p_io p = io\<close> unfolding io_targets.simps by force
    then show "io_targets A io (initial A) = {t1}"
      using observable_io_targets[OF \<open>observable A\<close>]
      by (metis \<open>io \<in> L A\<close> singletonD) 
  qed

  show "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets A io (initial A) = {t2}"
  proof -
    assume "io \<in> LS M q2 - LS M q1"
    
    then have "p_io p \<in> LS M q2 - LS M q1"
      using \<open>p_io p = io\<close> by auto
    then have "target p (initial A) = t2"
      using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close>
      by blast 
    then have "t2 \<in> io_targets A io (initial A)"
      using \<open>path A (initial A) p\<close> \<open>p_io p = io\<close> unfolding io_targets.simps by force
    then show "io_targets A io (initial A) = {t2}"
      using observable_io_targets[OF \<open>observable A\<close>]
      by (metis \<open>io \<in> L A\<close> singletonD) 
  qed

  show "io \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> io_targets A io (initial A) \<inter> {t1,t2} = {}"
  proof -
    assume "io \<in> LS M q1 \<inter> LS M q2"
    
    then have "p_io p \<in> LS M q1 \<inter> LS M q2"
      using \<open>p_io p = io\<close> by auto
    then have "target p (initial A) \<noteq> t1" and "target p (initial A) \<noteq> t2"
      using pt1[OF \<open>path A (initial A) p\<close>] pt2[OF \<open>path A (initial A) p\<close>] pt3[OF \<open>path A (initial A) p\<close>] \<open>t1 \<noteq> t2\<close>
      by blast+ 
    moreover have "target p (initial A) \<in> io_targets A io (initial A)"
      using \<open>path A (initial A) p\<close> \<open>p_io p = io\<close> unfolding io_targets.simps by force
    ultimately show "io_targets A io (initial A) \<inter> {t1,t2} = {}"
      using observable_io_targets[OF \<open>observable A\<close> \<open>io \<in> L A\<close>]
      by (metis (no_types, hide_lams) inf_bot_left insert_disjoint(2) insert_iff singletonD) 
  qed

  show "io \<in> LS M q1 \<union> LS M q2"
    using separator_path_targets(4)[OF assms(1) \<open>path A (initial A) p\<close>] \<open>p_io p = io\<close> by auto
qed


lemma is_separator_sym :
  "is_separator M q1 q2 A t1 t2 \<Longrightarrow> is_separator M q2 q1 A t2 t1"
  unfolding is_separator_def by blast



(* TODO: move *)
lemma canonical_separator_path_targets_language :
  assumes "path (canonical_separator M q1 q2) (initial (canonical_separator M q1 q2)) p"
  and     "observable M" 
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "isl (target p (initial (canonical_separator M q1 q2))) \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2"
and   "(target p (initial (canonical_separator M q1 q2))) = Inr q1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2 \<and> p_io (butlast p) \<in> LS M q1 \<inter> LS M q2"
and   "(target p (initial (canonical_separator M q1 q2))) = Inr q2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1 \<and> p_io (butlast p) \<in> LS M q1 \<inter> LS M q2"
and   "p_io p \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> isl (target p (initial (canonical_separator M q1 q2)))"
and   "p_io p \<in> LS M q1 - LS M q2 \<Longrightarrow> target p (initial (canonical_separator M q1 q2)) = Inr q1"
and   "p_io p \<in> LS M q2 - LS M q1 \<Longrightarrow> target p (initial (canonical_separator M q1 q2)) = Inr q2"
proof -
  let ?C = "canonical_separator M q1 q2"
  let ?tgt = "target p (initial ?C)"

  show "isl ?tgt \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2"
  proof -
    assume "isl ?tgt"
    then obtain s1 s2 where "?tgt = Inl (s1,s2)"
      by (metis isl_def old.prod.exhaust)
    then obtain p1 p2 where "path M q1 p1" and "path M q2 p2" and "p_io p1 = p_io p" and "p_io p2 = p_io p" 
      using canonical_separator_path_initial(1)[OF assms(1) \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> \<open>?tgt = Inl (s1,s2)\<close>] by force
    then show "p_io p \<in> LS M q1 \<inter> LS M q2"
      unfolding LS.simps by force
  qed
  moreover show "?tgt = Inr q1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2 \<and> p_io (butlast p) \<in> LS M q1 \<inter> LS M q2"
  proof -
    assume "?tgt = Inr q1"
    obtain p1 p2 t where "path M q1 (p1 @ [t])" and "path M q2 p2" and "p_io (p1 @ [t]) = p_io p" and "p_io p2 = butlast (p_io p)" and "(\<nexists>p2. path M q2 p2 \<and> p_io p2 = p_io p)" 
      using canonical_separator_path_initial(2)[OF assms(1) \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> \<open>?tgt = Inr q1\<close>] by meson

    have "path M q1 p1"
      using \<open>path M q1 (p1@[t])\<close> by auto
    have "p_io p1 = butlast (p_io p)"
      using \<open>p_io (p1 @ [t]) = p_io p\<close> 
      by (metis (no_types, lifting) butlast_snoc map_butlast)

    have "p_io p \<in> LS M q1" 
      using \<open>path M q1 (p1@[t])\<close> \<open>p_io (p1 @ [t]) = p_io p\<close> unfolding LS.simps by force
    moreover have "p_io p \<notin> LS M q2"
      using \<open>(\<nexists>p2. path M q2 p2 \<and> p_io p2 = p_io p)\<close> unfolding LS.simps by force
    moreover have "butlast (p_io p) \<in> LS M q1"
      using \<open>path M q1 p1\<close> \<open>p_io p1 = butlast (p_io p)\<close> unfolding LS.simps by force
    moreover have "butlast (p_io p) \<in> LS M q2"
      using \<open>path M q2 p2\<close> \<open>p_io p2 = butlast (p_io p)\<close> unfolding LS.simps by force
    ultimately show "p_io p \<in> LS M q1 - LS M q2 \<and> p_io (butlast p) \<in> LS M q1 \<inter> LS M q2"
      by (simp add: map_butlast)
  qed 
  moreover show "?tgt = Inr q2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1 \<and> p_io (butlast p) \<in> LS M q1 \<inter> LS M q2"
  proof -
    assume "?tgt = Inr q2"
    obtain p1 p2 t where "path M q2 (p2 @ [t])" and "path M q1 p1" and "p_io (p2 @ [t]) = p_io p" and "p_io p1 = butlast (p_io p)" and "(\<nexists>p2. path M q1 p2 \<and> p_io p2 = p_io p)" 
      using canonical_separator_path_initial(3)[OF assms(1) \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> \<open>?tgt = Inr q2\<close>] by meson

    have "path M q2 p2"
      using \<open>path M q2 (p2@[t])\<close> by auto
    have "p_io p2 = butlast (p_io p)"
      using \<open>p_io (p2 @ [t]) = p_io p\<close> 
      by (metis (no_types, lifting) butlast_snoc map_butlast)

    have "p_io p \<in> LS M q2" 
      using \<open>path M q2 (p2@[t])\<close> \<open>p_io (p2 @ [t]) = p_io p\<close> unfolding LS.simps by force
    moreover have "p_io p \<notin> LS M q1"
      using \<open>(\<nexists>p2. path M q1 p2 \<and> p_io p2 = p_io p)\<close> unfolding LS.simps by force
    moreover have "butlast (p_io p) \<in> LS M q1"
      using \<open>path M q1 p1\<close> \<open>p_io p1 = butlast (p_io p)\<close> unfolding LS.simps by force
    moreover have "butlast (p_io p) \<in> LS M q2"
      using \<open>path M q2 p2\<close> \<open>p_io p2 = butlast (p_io p)\<close> unfolding LS.simps by force
    ultimately show "p_io p \<in> LS M q2 - LS M q1 \<and> p_io (butlast p) \<in> LS M q1 \<inter> LS M q2"
      by (simp add: map_butlast)
  qed 
  moreover have "isl ?tgt \<or> ?tgt = Inr q1 \<or> ?tgt = Inr q2"
    using canonical_separator_path_initial(4)[OF assms(1) \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> ] by force
  ultimately show "p_io p \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> isl (target p (initial (canonical_separator M q1 q2)))"
             and  "p_io p \<in> LS M q1 - LS M q2 \<Longrightarrow> target p (initial (canonical_separator M q1 q2)) = Inr q1"
             and  "p_io p \<in> LS M q2 - LS M q1 \<Longrightarrow> target p (initial (canonical_separator M q1 q2)) = Inr q2"
    by blast+
qed
  

  



lemma canonical_separator_language_target :
  assumes "io \<in> L (canonical_separator M q1 q2)"
  and     "observable M" 
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets (canonical_separator M q1 q2) io (initial (canonical_separator M q1 q2)) = {Inr q1}"
and   "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets (canonical_separator M q1 q2) io (initial (canonical_separator M q1 q2)) = {Inr q2}"
proof -
  let ?C = "canonical_separator M q1 q2"
  obtain p where "path ?C (initial ?C) p" and "p_io p = io"
    using assms(1) by force

  show "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets (canonical_separator M q1 q2) io (initial (canonical_separator M q1 q2)) = {Inr q1}"
  proof -
    assume "io \<in> LS M q1 - LS M q2"
    then have "p_io p \<in> LS M q1 - LS M q2"
      using \<open>p_io p = io\<close> by auto
    have "Inr q1 \<in> io_targets ?C io (initial ?C)"
      using canonical_separator_path_targets_language(5)[OF \<open>path ?C (initial ?C) p\<close> assms(2,3,4) \<open>p_io p \<in> LS M q1 - LS M q2\<close>]
      using \<open>path ?C (initial ?C) p\<close> unfolding io_targets.simps 
      by (metis (mono_tags, lifting) \<open>p_io p = io\<close> mem_Collect_eq)
    then show ?thesis
      by (metis (mono_tags, lifting) assms(1) assms(2) assms(3) assms(4) canonical_separator_observable observable_io_targets singletonD)
  qed

  show "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets (canonical_separator M q1 q2) io (initial (canonical_separator M q1 q2)) = {Inr q2}"
  proof -
    assume "io \<in> LS M q2 - LS M q1"
    then have "p_io p \<in> LS M q2 - LS M q1"
      using \<open>p_io p = io\<close> by auto
    have "Inr q2 \<in> io_targets ?C io (initial ?C)"
      using canonical_separator_path_targets_language(6)[OF \<open>path ?C (initial ?C) p\<close> assms(2,3,4) \<open>p_io p \<in> LS M q2 - LS M q1\<close>]
      using \<open>path ?C (initial ?C) p\<close> unfolding io_targets.simps 
      by (metis (mono_tags, lifting) \<open>p_io p = io\<close> mem_Collect_eq)
    then show ?thesis
      by (metis (mono_tags, lifting) assms(1) assms(2) assms(3) assms(4) canonical_separator_observable observable_io_targets singletonD)
  qed
qed





(* TODO: move *)
lemma canonical_separator_language_intersection :
  assumes "io \<in> LS M q1"
  and     "io \<in> LS M q2"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "io \<in> L (canonical_separator M q1 q2)" (is "io \<in> L ?C")
proof -
  let ?P = "product (from_FSM M q1) (from_FSM M q2)"

  have "io \<in> L ?P"
    using \<open>io \<in> LS M q1\<close> \<open>io \<in> LS M q2\<close> product_language[of "from_FSM M q1" "from_FSM M q2"] 
    unfolding from_FSM_language[OF \<open>q1 \<in> nodes M\<close>] from_FSM_language[OF \<open>q2 \<in> nodes M\<close>]
    by blast
  then obtain p where "path ?P (initial ?P) p" and "p_io p = io"
    by auto
  then have *: "path ?C (initial ?C) (map shift_Inl p)"
    using canonical_separator_path_shift[of M q1 q2] by auto
  have **: "p_io (map shift_Inl p) = io"
    using \<open>p_io p = io\<close> by (induction p; auto)
  show "io \<in> L ?C" 
    using language_state_containment[OF * **] by assumption
qed






lemma state_separator_from_canonical_separator_language_target :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "io \<in> L A"
  and     "observable M" 
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
shows "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets A io (initial A) = {Inr q1}"
and   "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets A io (initial A) = {Inr q2}"
and   "io \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> io_targets A io (initial A) \<inter> {Inr q1, Inr q2} = {}"
proof -
  have "observable A"
    using state_separator_from_canonical_separator_observable[OF assms(1,3,4,5)] by assumption

  let ?C = "canonical_separator M q1 q2"

  obtain p where "path A (initial A) p" and "p_io p = io"
    using assms(2) by force
  then have "path ?C (initial ?C) p"
    using submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)]] by auto
  then have "io \<in> L ?C"
    using \<open>p_io p = io\<close> by auto

  show "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets A io (initial A) = {Inr q1}"
  proof -
    assume "io \<in> LS M q1 - LS M q2"

    have "target p (initial A) = Inr q1"
    using submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)] \<open>path A (initial A) p\<close>] 
          canonical_separator_language_target(1)[OF \<open>io \<in> L ?C\<close> assms(3,4,5) \<open>io \<in> LS M q1 - LS M q2\<close>] 
          \<open>p_io p = io\<close>
      unfolding io_targets.simps state_separator_from_canonical_separator_initial[OF assms(1)] canonical_separator_simps product_simps from_FSM_simps by blast
    then have "Inr q1 \<in> io_targets A io (initial A)"
      using \<open>path A (initial A) p\<close> \<open>p_io p = io\<close> unfolding io_targets.simps
      by (metis (mono_tags, lifting) mem_Collect_eq)  
    then show "io_targets A io (initial A) = {Inr q1}"
      using observable_io_targets[OF \<open>observable A\<close> \<open>io \<in> L A\<close>]
      by (metis singletonD)   
  qed

  show "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets A io (initial A) = {Inr q2}"
  proof -
    assume "io \<in> LS M q2 - LS M q1"

    have "target p (initial A) = Inr q2"
    using submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)] \<open>path A (initial A) p\<close>] 
          canonical_separator_language_target(2)[OF \<open>io \<in> L ?C\<close> assms(3,4,5) \<open>io \<in> LS M q2 - LS M q1\<close>] 
          \<open>p_io p = io\<close>
      unfolding io_targets.simps state_separator_from_canonical_separator_initial[OF assms(1)] canonical_separator_simps product_simps from_FSM_simps by blast
    then have "Inr q2 \<in> io_targets A io (initial A)"
      using \<open>path A (initial A) p\<close> \<open>p_io p = io\<close> unfolding io_targets.simps
      by (metis (mono_tags, lifting) mem_Collect_eq)  
    then show "io_targets A io (initial A) = {Inr q2}"
      using observable_io_targets[OF \<open>observable A\<close> \<open>io \<in> L A\<close>]
      by (metis singletonD)   
  qed

  show "io \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> io_targets A io (initial A) \<inter> {Inr q1, Inr q2} = {}"
  proof -
    let ?P = "product (from_FSM M q1) (from_FSM M q2)"
    

    assume "io \<in> LS M q1 \<inter> LS M q2"

    have"\<And> q . q \<in> io_targets A io (initial A) \<Longrightarrow> q \<notin> {Inr q1, Inr q2}"
    proof -
      fix q assume "q \<in> io_targets A io (initial A)"
      then obtain p where "q = target p (initial A)" and "path A (initial A) p" and "p_io p = io"
        by auto
      then have "path ?C (initial ?C) p"
        using submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)]] by auto
      then have "isl (target p (initial ?C))"
        using canonical_separator_path_targets_language(4)[OF _ \<open>observable M\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> ]
        using \<open>p_io p = io\<close> \<open>io \<in> LS M q1 \<inter> LS M q2\<close> by auto
      then show "q \<notin> {Inr q1, Inr q2}"
        using \<open>q = target p (initial A)\<close> 
        unfolding state_separator_from_canonical_separator_initial[OF assms(1)]
        unfolding canonical_separator_simps product_simps from_FSM_simps by auto
    qed

    then show "io_targets A io (initial A) \<inter> {Inr q1, Inr q2} = {}"
      by blast
  qed
qed


(* TODO: move *)
lemma language_initial_path_append_transition :
  assumes "ios @ [io] \<in> L M"
  obtains p t where "path M (initial M) (p@[t])" and "p_io (p@[t]) = ios @ [io]"
proof -
  obtain pt where "path M (initial M) pt" and "p_io pt = ios @ [io]"
    using assms unfolding LS.simps by auto
  then have "pt \<noteq> []"
    by auto
  then obtain p t where "pt = p @ [t]"
    using rev_exhaust by blast  
  then have "path M (initial M) (p@[t])" and "p_io (p@[t]) = ios @ [io]"
    using \<open>path M (initial M) pt\<close> \<open>p_io pt = ios @ [io]\<close> by auto
  then show ?thesis using that by simp
qed

lemma language_path_append_transition :
  assumes "ios @ [io] \<in> LS M q"
  obtains p t where "path M q (p@[t])" and "p_io (p@[t]) = ios @ [io]"
proof -
  obtain pt where "path M q pt" and "p_io pt = ios @ [io]"
    using assms unfolding LS.simps by auto
  then have "pt \<noteq> []"
    by auto
  then obtain p t where "pt = p @ [t]"
    using rev_exhaust by blast  
  then have "path M q (p@[t])" and "p_io (p@[t]) = ios @ [io]"
    using \<open>path M q pt\<close> \<open>p_io pt = ios @ [io]\<close> by auto
  then show ?thesis using that by simp
qed







lemma path_map_target : "target (map (\<lambda> t . (f1 (t_source t), f2 (t_input t), f3 (t_output t), f4 (t_target t))) p) (f4 q) = f4 (target p q)" 
  by (induction p; auto)




lemma state_separator_from_canonical_separator_is_separator :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "observable M" 
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "q1 \<noteq> q2"
shows "is_separator M q1 q2 A (Inr q1) (Inr q2)"
proof -
  let ?C = "canonical_separator M q1 q2"
  have "observable ?C"
    using canonical_separator_observable[OF assms(2,3,4)] by assumption

  have "is_submachine A ?C" 
  and   p1: "single_input A"
  and   p2: "acyclic A"
  and   p4: "deadlock_state A (Inr q1)"
  and   p5: "deadlock_state A (Inr q2)"
  and   p6: "((Inr q1) \<in> nodes A)"
  and   p7: "((Inr q2) \<in> nodes A)"
  and   "\<And> q . q \<in> nodes A \<Longrightarrow> q \<noteq> Inr q1 \<Longrightarrow> q \<noteq> Inr q2 \<Longrightarrow> (isl q \<and> \<not> deadlock_state A q)"
  and   compl: "\<And> q x t . q \<in> nodes A \<Longrightarrow> x \<in> set (inputs M) \<Longrightarrow> (\<exists> t \<in> h A . t_source t = q \<and> t_input t = x) \<Longrightarrow> t \<in> h ?C \<Longrightarrow> t_source t = q \<Longrightarrow> t_input t = x \<Longrightarrow> t \<in> h A"
    using is_state_separator_from_canonical_separator_simps[OF assms(1)]
    unfolding canonical_separator_simps
    by blast+

  have p3: "observable A" 
    using state_separator_from_canonical_separator_observable[OF assms(1-4)] by assumption

  have p8: "(\<forall>t\<in>nodes A. t \<noteq> Inr q1 \<and> t \<noteq> Inr q2 \<longrightarrow> \<not> deadlock_state A t)"
    using \<open>\<And> q . q \<in> nodes A \<Longrightarrow> q \<noteq> Inr q1 \<Longrightarrow> q \<noteq> Inr q2 \<Longrightarrow> (isl q \<and> \<not> deadlock_state A q)\<close> by simp

  have "\<And> io . io \<in> L A \<Longrightarrow> 
        (io \<in> LS M q1 - LS M q2 \<longrightarrow> io_targets A io (initial A) = {Inr q1}) \<and>
        (io \<in> LS M q2 - LS M q1 \<longrightarrow> io_targets A io (initial A) = {Inr q2}) \<and>
        (io \<in> LS M q1 \<inter> LS M q2 \<longrightarrow> io_targets A io (initial A) \<inter> {Inr q1, Inr q2} = {}) \<and>
        (\<forall>x yq yt. io @ [(x, yq)] \<in> LS M q1 \<and> io @ [(x, yt)] \<in> LS A (initial A) \<longrightarrow> io @ [(x, yq)] \<in> LS A (initial A)) \<and>
        (\<forall>x yq2 yt. io @ [(x, yq2)] \<in> LS M q2 \<and> io @ [(x, yt)] \<in> LS A (initial A) \<longrightarrow> io @ [(x, yq2)] \<in> LS A (initial A))"
  proof -
    fix io assume "io \<in> L A"

    have "io \<in> LS M q1 - LS M q2 \<Longrightarrow> io_targets A io (initial A) = {Inr q1}"
      using state_separator_from_canonical_separator_language_target(1)[OF assms(1) \<open>io \<in> L A\<close> assms(2,3,4)] by assumption
    moreover have "io \<in> LS M q2 - LS M q1 \<Longrightarrow> io_targets A io (initial A) = {Inr q2}"
      using state_separator_from_canonical_separator_language_target(2)[OF assms(1) \<open>io \<in> L A\<close> assms(2,3,4)] by assumption
    moreover have "io \<in> LS M q1 \<inter> LS M q2 \<Longrightarrow> io_targets A io (initial A) \<inter> {Inr q1, Inr q2} = {}"
      using state_separator_from_canonical_separator_language_target(3)[OF assms(1) \<open>io \<in> L A\<close> assms(2,3,4)] by assumption
    moreover have "\<And> x yq yt. io @ [(x, yq)] \<in> LS M q1 \<Longrightarrow> io @ [(x, yt)] \<in> L A \<Longrightarrow> io @ [(x, yq)] \<in> L A"
    proof -
      fix x yq yt assume "io @ [(x, yq)] \<in> LS M q1" and "io @ [(x, yt)] \<in> L A"

      obtain pA tA where "path A (initial A) (pA@[tA])" and "p_io (pA@[tA]) = io @ [(x, yt)]"
        using language_initial_path_append_transition[OF \<open>io @ [(x, yt)] \<in> L A\<close>] by blast
      then have "path A (initial A) pA" and "p_io pA = io"
        by auto
      then have "path ?C (initial ?C) pA"
        using submachine_path_initial[OF \<open>is_submachine A ?C\<close>] by auto

      obtain p1 t1 where "path M q1 (p1@[t1])" and "p_io (p1@[t1]) = io @ [(x, yq)]"
        using language_path_append_transition[OF \<open>io @ [(x, yq)] \<in> LS M q1\<close>] by blast
      then have "path M q1 p1" and "p_io p1 = io" and "t1 \<in> h M" and "t_input t1 = x" and "t_output t1 = yq" and "t_source t1 = target p1 q1"
        by auto

      let ?q = "target pA (initial A)"
      have "?q \<in> nodes A"
        using path_target_is_node \<open>path A (initial A) (pA@[tA])\<close> by auto

      have "tA \<in> h A" and "t_input tA = x" and "t_output tA = yt" and "t_source tA = target pA (initial A)"
        using \<open>path A (initial A) (pA@[tA])\<close> \<open>p_io (pA@[tA]) = io @ [(x, yt)]\<close> by auto
      then have "x \<in> set (inputs M)"
        using \<open>is_submachine A ?C\<close> 
        unfolding is_submachine.simps canonical_separator_simps by auto
      
      have "\<exists>t\<in>set (wf_transitions A). t_source t = target pA (initial A) \<and> t_input t = x"
        using \<open>tA \<in> h A\<close> \<open>t_input tA = x\<close> \<open>t_source tA = target pA (initial A)\<close> by blast

      have "io \<in> LS M q2"
        using submachine_language[OF \<open>is_submachine A ?C\<close>] \<open>io @ [(x, yt)] \<in> L A\<close> 
        using canonical_separator_language_prefix[OF _ assms(3,4,2), of io "(x,yt)"] by blast
      then obtain p2 where "path M q2 p2" and "p_io p2 = io"
        by auto
      


      show "io @ [(x, yq)] \<in> L A" 
      proof (cases "\<exists> t2 \<in> h M . t_source t2 = target p2 q2 \<and> t_input t2 = x \<and> t_output t2 = yq")
        case True
        then obtain t2 where "t2 \<in> h M" and "t_source t2 = target p2 q2" and "t_input t2 = x" and "t_output t2 = yq"
          by blast
        then have "path M q2 (p2@[t2])" and "p_io (p2@[t2]) = io@[(x,yq)]"
          using path_append_last[OF \<open>path M q2 p2\<close>] \<open>p_io p2 = io\<close> by auto
        then have "io @ [(x, yq)] \<in> LS M q2"
          unfolding LS.simps by (metis (mono_tags, lifting) mem_Collect_eq) 
        then have "io@[(x,yq)] \<in> L ?C"
          using  canonical_separator_language_intersection[OF \<open>io @ [(x, yq)] \<in> LS M q1\<close> _ assms(3,4)] by blast
        
        obtain pA' tA' where "path ?C (initial ?C) (pA'@[tA'])" and "p_io (pA'@[tA']) = io@[(x,yq)]"
          using language_initial_path_append_transition[OF \<open>io @ [(x, yq)] \<in> L ?C\<close>] by blast
        then have "path ?C (initial ?C) pA'" and "p_io pA' = io" and "tA' \<in> h ?C" and "t_source tA' = target pA' (initial ?C)" and "t_input tA' = x" and "t_output tA' = yq"
          by auto

        have "pA = pA'"
          using observable_path_unique[OF \<open>observable ?C\<close> \<open>path ?C (initial ?C) pA'\<close> \<open>path ?C (initial ?C) pA\<close>]
          using \<open>p_io pA' = io\<close> \<open>p_io pA = io\<close> by auto
        then have "t_source tA' = target pA (initial A)"
          using \<open>t_source tA' = target pA' (initial ?C)\<close>
          using state_separator_from_canonical_separator_initial[OF assms(1)]
          unfolding target.simps visited_states.simps canonical_separator_simps product_simps from_FSM_simps by auto


        have "tA' \<in> h A"
          using compl[OF \<open>?q \<in> nodes A\<close> \<open>x \<in> set (inputs M)\<close> \<open>\<exists>t\<in>set (wf_transitions A). t_source t = target pA (initial A) \<and> t_input t = x\<close> \<open>tA' \<in> h ?C\<close> \<open>t_source tA' = target pA (initial A)\<close> \<open>t_input tA' = x\<close>] by assumption
        then have "path A (initial A) (pA@[tA'])" 
          using \<open>path A (initial A) pA\<close> \<open>t_source tA' = target pA (initial A)\<close> using path_append_last by metis
        moreover have "p_io (pA@[tA']) = io@[(x,yq)]"
          using \<open>t_input tA' = x\<close> \<open>t_output tA' = yq\<close> \<open>p_io pA = io\<close> by auto
        
        ultimately show ?thesis 
          using language_state_containment
          by (metis (mono_tags, lifting)) 
          
      next
        case False

        let ?P = "product (from_FSM M q1) (from_FSM M q2)"
        let ?qq = "(target p1 q1, target p2 q2)"
        let ?tA = "(Inl (target p1 q1, target p2 q2), x, yq, Inr q1)"

        have "path (from_FSM M q1) (initial (from_FSM M q1)) p1" 
          using from_FSM_path_initial[OF \<open>q1 \<in> nodes M\<close>] \<open>path M q1 p1\<close> by auto
        moreover have "path (from_FSM M q2) (initial (from_FSM M q2)) p2" 
          using from_FSM_path_initial[OF \<open>q2 \<in> nodes M\<close>] \<open>path M q2 p2\<close> by auto
        moreover have "p_io p1 = p_io p2"
          using \<open>p_io p1 = io\<close> \<open>p_io p2 = io\<close> by auto
        ultimately have "?qq \<in> nodes ?P"
          using product_node_from_path[of "target p1 q1" "target p2 q2" "from_FSM M q1" "from_FSM M q2"]
          unfolding from_FSM_simps by blast
        then have "(?qq,t1) \<in> set (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"  
          using \<open>t1 \<in> h M\<close> unfolding nodes_code concat_pair_set by auto
        moreover have "(\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                      \<not> (\<exists>t'\<in>set (transitions M).
                             t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (?qq,t1)"
          unfolding fst_conv snd_conv \<open>t_input t1 = x\<close> \<open>t_output t1 = yq\<close>
          using \<open>t_source t1 = target p1 q1\<close> False 
          using path_target_is_node[OF \<open>path M q2 p2\<close>] 
          using \<open>t1 \<in> h M\<close> \<open>t_output t1 = yq\<close> \<open>x \<in> set (inputs M)\<close> by auto

        ultimately have *: "(?qq,t1) \<in> set (filter
               (\<lambda>qqt. t_source (snd qqt) = fst (fst qqt) \<and>
                      \<not> (\<exists>t'\<in>set (transitions M).
                             t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
               (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
          by auto

        have scheme: "\<And> f xs x . x \<in> set xs \<Longrightarrow> f x \<in> set (map f xs)"
          by auto

        have "?tA \<in> set (distinguishing_transitions_left M q1 q2)"
          unfolding distinguishing_transitions_left_def 
          using scheme[of _ _ "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))", OF *]
          unfolding fst_conv snd_conv \<open>t_input t1 = x\<close> \<open>t_output t1 = yq\<close> by assumption
        then have "(Inl (target p1 q1, target p2 q2), x, yq, Inr q1) \<in> h ?C"
          using canonical_separator_distinguishing_transitions_left_h by metis

        let ?pP = "zip_path p1 p2"
        let ?pC = "map shift_Inl ?pP"
        have "path ?P (initial ?P) ?pP" 
        and  "target ?pP (initial ?P) = (target p1 q1, target p2 q2)"
          using  product_path_from_paths[OF \<open>path (from_FSM M q1) (initial (from_FSM M q1)) p1\<close>
                                            \<open>path (from_FSM M q2) (initial (from_FSM M q2)) p2\<close>
                                            \<open>p_io p1 = p_io p2\<close>]
          unfolding from_FSM_simps by auto

        have "length p1 = length p2"
          using \<open>p_io p1 = p_io p2\<close> map_eq_imp_length_eq by blast 
        then have "p_io ?pP = io"
          using \<open>p_io p1 = io\<close>  by (induction p1 p2 arbitrary: io rule: list_induct2; auto)
        

        have "path ?C (initial ?C) ?pC"
          using canonical_separator_path_shift[of M q1 q2 ?pP] \<open>path ?P (initial ?P) ?pP\<close> by simp

        have "target ?pC (initial ?C) = Inl (target p1 q1, target p2 q2)"
          using path_map_target[of Inl id id Inl ?pP "initial ?P"]
          using \<open>target ?pP (initial ?P) = (target p1 q1, target p2 q2)\<close>
          unfolding canonical_separator_simps by force
        
        have "p_io ?pC = io"
          using \<open>p_io ?pP = io\<close> by auto
        have "p_io pA = p_io ?pC"
          unfolding \<open>p_io ?pC = io\<close>
          using \<open>p_io pA = io\<close> by assumption
  
        then have "?pC = pA"
          using observable_path_unique[OF \<open>observable ?C\<close> \<open>path ?C (initial ?C) pA\<close> \<open>path ?C (initial ?C) ?pC\<close>] by auto
        then have "t_source ?tA = target pA (initial A)"
          using \<open>target ?pC (initial ?C) = Inl (target p1 q1, target p2 q2)\<close>
          unfolding state_separator_from_canonical_separator_initial[OF assms(1)]
                    canonical_separator_simps product_simps from_FSM_simps fst_conv by force

        have "?tA \<in> h A"
          using compl[OF \<open>?q \<in> nodes A\<close> \<open>x \<in> set (inputs M)\<close> \<open>\<exists>t\<in>set (wf_transitions A). t_source t = target pA (initial A) \<and> t_input t = x\<close> \<open>?tA \<in> h ?C\<close> \<open>t_source ?tA = target pA (initial A)\<close> ]
          unfolding snd_conv fst_conv by simp

        have *: "path A (initial A) (pA@[?tA])"
          using path_append_last[OF \<open>path A (initial A) pA\<close> \<open>?tA \<in> h A\<close>  \<open>t_source ?tA = target pA (initial A)\<close>] by assumption

        have **: "p_io (pA@[?tA]) = io@[(x,yq)]"
          using \<open>p_io pA = io\<close> by auto

        show ?thesis 
          using language_state_containment[OF * **] by assumption
      qed
    qed

    
    moreover have "\<And> x yq yt. io @ [(x, yq)] \<in> LS M q2 \<Longrightarrow> io @ [(x, yt)] \<in> L A \<Longrightarrow> io @ [(x, yq)] \<in> L A"
    proof -
      fix x yq yt assume "io @ [(x, yq)] \<in> LS M q2" and "io @ [(x, yt)] \<in> L A"

      obtain pA tA where "path A (initial A) (pA@[tA])" and "p_io (pA@[tA]) = io @ [(x, yt)]"
        using language_initial_path_append_transition[OF \<open>io @ [(x, yt)] \<in> L A\<close>] by blast
      then have "path A (initial A) pA" and "p_io pA = io"
        by auto
      then have "path ?C (initial ?C) pA"
        using submachine_path_initial[OF \<open>is_submachine A ?C\<close>] by auto

      obtain p2 t2 where "path M q2 (p2@[t2])" and "p_io (p2@[t2]) = io @ [(x, yq)]"
        using language_path_append_transition[OF \<open>io @ [(x, yq)] \<in> LS M q2\<close>] by blast
      then have "path M q2 p2" and "p_io p2 = io" and "t2 \<in> h M" and "t_input t2 = x" and "t_output t2 = yq" and "t_source t2 = target p2 q2"
        by auto

      let ?q = "target pA (initial A)"
      have "?q \<in> nodes A"
        using path_target_is_node \<open>path A (initial A) (pA@[tA])\<close> by auto

      have "tA \<in> h A" and "t_input tA = x" and "t_output tA = yt" and "t_source tA = target pA (initial A)"
        using \<open>path A (initial A) (pA@[tA])\<close> \<open>p_io (pA@[tA]) = io @ [(x, yt)]\<close> by auto
      then have "x \<in> set (inputs M)"
        using \<open>is_submachine A ?C\<close> 
        unfolding is_submachine.simps canonical_separator_simps by auto
      
      have "\<exists>t\<in>set (wf_transitions A). t_source t = target pA (initial A) \<and> t_input t = x"
        using \<open>tA \<in> h A\<close> \<open>t_input tA = x\<close> \<open>t_source tA = target pA (initial A)\<close> by blast

      have "io \<in> LS M q1"
        using submachine_language[OF \<open>is_submachine A ?C\<close>] \<open>io @ [(x, yt)] \<in> L A\<close> 
        using canonical_separator_language_prefix[OF _ assms(3,4,2), of io "(x,yt)"] by blast
      then obtain p1 where "path M q1 p1" and "p_io p1 = io"
        by auto
      


      show "io @ [(x, yq)] \<in> L A" 
      proof (cases "\<exists> t1 \<in> h M . t_source t1 = target p1 q1 \<and> t_input t1 = x \<and> t_output t1 = yq")
        case True
        then obtain t1 where "t1 \<in> h M" and "t_source t1 = target p1 q1" and "t_input t1 = x" and "t_output t1 = yq"
          by blast
        then have "path M q1 (p1@[t1])" and "p_io (p1@[t1]) = io@[(x,yq)]"
          using path_append_last[OF \<open>path M q1 p1\<close>] \<open>p_io p1 = io\<close> by auto
        then have "io @ [(x, yq)] \<in> LS M q1"
          unfolding LS.simps by (metis (mono_tags, lifting) mem_Collect_eq) 
        then have "io@[(x,yq)] \<in> L ?C"
          using  canonical_separator_language_intersection[OF _ \<open>io @ [(x, yq)] \<in> LS M q2\<close> assms(3,4)] by blast
        
        obtain pA' tA' where "path ?C (initial ?C) (pA'@[tA'])" and "p_io (pA'@[tA']) = io@[(x,yq)]"
          using language_initial_path_append_transition[OF \<open>io @ [(x, yq)] \<in> L ?C\<close>] by blast
        then have "path ?C (initial ?C) pA'" and "p_io pA' = io" and "tA' \<in> h ?C" and "t_source tA' = target pA' (initial ?C)" and "t_input tA' = x" and "t_output tA' = yq"
          by auto

        have "pA = pA'"
          using observable_path_unique[OF \<open>observable ?C\<close> \<open>path ?C (initial ?C) pA'\<close> \<open>path ?C (initial ?C) pA\<close>]
          using \<open>p_io pA' = io\<close> \<open>p_io pA = io\<close> by auto
        then have "t_source tA' = target pA (initial A)"
          using \<open>t_source tA' = target pA' (initial ?C)\<close>
          using state_separator_from_canonical_separator_initial[OF assms(1)]
          unfolding target.simps visited_states.simps canonical_separator_simps product_simps from_FSM_simps by auto


        have "tA' \<in> h A"
          using compl[OF \<open>?q \<in> nodes A\<close> \<open>x \<in> set (inputs M)\<close> \<open>\<exists>t\<in>set (wf_transitions A). t_source t = target pA (initial A) \<and> t_input t = x\<close> \<open>tA' \<in> h ?C\<close> \<open>t_source tA' = target pA (initial A)\<close> \<open>t_input tA' = x\<close>] by assumption
        then have "path A (initial A) (pA@[tA'])" 
          using \<open>path A (initial A) pA\<close> \<open>t_source tA' = target pA (initial A)\<close> using path_append_last by metis
        moreover have "p_io (pA@[tA']) = io@[(x,yq)]"
          using \<open>t_input tA' = x\<close> \<open>t_output tA' = yq\<close> \<open>p_io pA = io\<close> by auto
        
        ultimately show ?thesis 
          using language_state_containment
          by (metis (mono_tags, lifting)) 
          
      next
        case False

        let ?P = "product (from_FSM M q1) (from_FSM M q2)"
        let ?qq = "(target p1 q1, target p2 q2)"
        let ?tA = "(Inl (target p1 q1, target p2 q2), x, yq, Inr q2)"

        have "path (from_FSM M q1) (initial (from_FSM M q1)) p1" 
          using from_FSM_path_initial[OF \<open>q1 \<in> nodes M\<close>] \<open>path M q1 p1\<close> by auto
        moreover have "path (from_FSM M q2) (initial (from_FSM M q2)) p2" 
          using from_FSM_path_initial[OF \<open>q2 \<in> nodes M\<close>] \<open>path M q2 p2\<close> by auto
        moreover have "p_io p1 = p_io p2"
          using \<open>p_io p1 = io\<close> \<open>p_io p2 = io\<close> by auto
        ultimately have "?qq \<in> nodes ?P"
          using product_node_from_path[of "target p1 q1" "target p2 q2" "from_FSM M q1" "from_FSM M q2"]
          unfolding from_FSM_simps by blast
        then have "(?qq,t2) \<in> set (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"  
          using \<open>t2 \<in> h M\<close> unfolding nodes_code concat_pair_set by auto
        moreover have "(\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                      \<not> (\<exists>t'\<in>set (transitions M).
                             t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) (?qq,t2)"
          unfolding fst_conv snd_conv \<open>t_input t2 = x\<close> \<open>t_output t2 = yq\<close>
          using \<open>t_source t2 = target p2 q2\<close> False 
          using path_target_is_node[OF \<open>path M q2 p2\<close>] 
          using \<open>t2 \<in> h M\<close> \<open>t_output t2 = yq\<close> \<open>x \<in> set (inputs M)\<close>
          using \<open>path M q1 p1\<close> path_target_is_node by fastforce

        ultimately have *: "(?qq,t2) \<in> set (filter
               (\<lambda>qqt. t_source (snd qqt) = snd (fst qqt) \<and>
                      \<not> (\<exists>t'\<in>set (transitions M).
                             t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
               (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
          by auto

        have scheme: "\<And> f xs x . x \<in> set xs \<Longrightarrow> f x \<in> set (map f xs)"
          by auto

        have "?tA \<in> set (distinguishing_transitions_right M q1 q2)"
          unfolding distinguishing_transitions_right_def 
          using scheme[of _ _ "(\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2))", OF *]
          unfolding fst_conv snd_conv \<open>t_input t2 = x\<close> \<open>t_output t2 = yq\<close> by assumption
        then have "?tA \<in> h ?C"
          using canonical_separator_distinguishing_transitions_right_h by metis

        let ?pP = "zip_path p1 p2"
        let ?pC = "map shift_Inl ?pP"
        have "path ?P (initial ?P) ?pP" 
        and  "target ?pP (initial ?P) = (target p1 q1, target p2 q2)"
          using  product_path_from_paths[OF \<open>path (from_FSM M q1) (initial (from_FSM M q1)) p1\<close>
                                            \<open>path (from_FSM M q2) (initial (from_FSM M q2)) p2\<close>
                                            \<open>p_io p1 = p_io p2\<close>]
          unfolding from_FSM_simps by auto

        have "length p1 = length p2"
          using \<open>p_io p1 = p_io p2\<close> map_eq_imp_length_eq by blast 
        then have "p_io ?pP = io"
          using \<open>p_io p1 = io\<close>  by (induction p1 p2 arbitrary: io rule: list_induct2; auto)
        

        have "path ?C (initial ?C) ?pC"
          using canonical_separator_path_shift[of M q1 q2 ?pP] \<open>path ?P (initial ?P) ?pP\<close> by simp

        have "target ?pC (initial ?C) = Inl (target p1 q1, target p2 q2)"
          using path_map_target[of Inl id id Inl ?pP "initial ?P"]
          using \<open>target ?pP (initial ?P) = (target p1 q1, target p2 q2)\<close>
          unfolding canonical_separator_simps by force
        
        have "p_io ?pC = io"
          using \<open>p_io ?pP = io\<close> by auto
        have "p_io pA = p_io ?pC"
          unfolding \<open>p_io ?pC = io\<close>
          using \<open>p_io pA = io\<close> by assumption
  
        then have "?pC = pA"
          using observable_path_unique[OF \<open>observable ?C\<close> \<open>path ?C (initial ?C) pA\<close> \<open>path ?C (initial ?C) ?pC\<close>] by auto
        then have "t_source ?tA = target pA (initial A)"
          using \<open>target ?pC (initial ?C) = Inl (target p1 q1, target p2 q2)\<close>
          unfolding state_separator_from_canonical_separator_initial[OF assms(1)]
                    canonical_separator_simps product_simps from_FSM_simps fst_conv by force

        have "?tA \<in> h A"
          using compl[OF \<open>?q \<in> nodes A\<close> \<open>x \<in> set (inputs M)\<close> \<open>\<exists>t\<in>set (wf_transitions A). t_source t = target pA (initial A) \<and> t_input t = x\<close> \<open>?tA \<in> h ?C\<close> \<open>t_source ?tA = target pA (initial A)\<close> ]
          unfolding snd_conv fst_conv by simp

        have *: "path A (initial A) (pA@[?tA])"
          using path_append_last[OF \<open>path A (initial A) pA\<close> \<open>?tA \<in> h A\<close>  \<open>t_source ?tA = target pA (initial A)\<close>] by assumption

        have **: "p_io (pA@[?tA]) = io@[(x,yq)]"
          using \<open>p_io pA = io\<close> by auto

        show ?thesis 
          using language_state_containment[OF * **] by assumption
      qed
    qed

    

    ultimately show "(io \<in> LS M q1 - LS M q2 \<longrightarrow> io_targets A io (initial A) = {Inr q1}) \<and>
        (io \<in> LS M q2 - LS M q1 \<longrightarrow> io_targets A io (initial A) = {Inr q2}) \<and>
        (io \<in> LS M q1 \<inter> LS M q2 \<longrightarrow> io_targets A io (initial A) \<inter> {Inr q1, Inr q2} = {}) \<and>
        (\<forall>x yq yt. io @ [(x, yq)] \<in> LS M q1 \<and> io @ [(x, yt)] \<in> LS A (initial A) \<longrightarrow> io @ [(x, yq)] \<in> LS A (initial A)) \<and>
        (\<forall>x yq2 yt. io @ [(x, yq2)] \<in> LS M q2 \<and> io @ [(x, yt)] \<in> LS A (initial A) \<longrightarrow> io @ [(x, yq2)] \<in> LS A (initial A))" 
      by blast 
  qed

  moreover have "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = Inr q1 \<Longrightarrow> p_io p \<in> LS M q1 - LS M q2"
    using canonical_separator_maximal_path_distinguishes_left[OF assms(1) _ _ \<open>observable M\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>q1 \<noteq> q2\<close>] by blast
  moreover have "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) = Inr q2 \<Longrightarrow> p_io p \<in> LS M q2 - LS M q1"
    using canonical_separator_maximal_path_distinguishes_right[OF assms(1) _ _ \<open>observable M\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>q1 \<noteq> q2\<close>] by blast
  moreover have "\<And> p . path A (initial A) p \<Longrightarrow> target p (initial A) \<noteq> Inr q1 \<Longrightarrow> target p (initial A) \<noteq> Inr q2 \<Longrightarrow> p_io p \<in> LS M q1 \<inter> LS M q2"
  proof -
    fix p assume "path A (initial A) p" and "target p (initial A) \<noteq> Inr q1" and "target p (initial A) \<noteq> Inr q2"

    have "path ?C (initial ?C) p"
      using submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)] \<open>path A (initial A) p\<close>] by assumption

    have "target p (initial ?C) \<noteq> Inr q1" and "target p (initial ?C) \<noteq> Inr q2"
      using \<open>target p (initial A) \<noteq> Inr q1\<close> \<open>target p (initial A) \<noteq> Inr q2\<close>
      unfolding is_state_separator_from_canonical_separator_initial[OF assms(1)] canonical_separator_initial by blast+

    then have "isl (target p (initial ?C))"
      using canonical_separator_path_initial(4)[OF \<open>path ?C (initial ?C) p\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close>]
      by auto 

    then show "p_io p \<in> LS M q1 \<inter> LS M q2"
      using \<open>path ?C (initial ?C) p\<close> canonical_separator_path_targets_language(1)[OF _ \<open>observable M\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close>] by auto
  qed

 moreover have "set (inputs A) \<subseteq> set (inputs M)"
    using \<open>is_submachine A ?C\<close>
    unfolding is_submachine.simps canonical_separator_simps by auto

  ultimately show ?thesis
    unfolding is_separator_def
    using p1 p2 p3 p4 p5 p6 p7 p8 \<open>q1 \<noteq> q2\<close>
    by (meson sum.simps(2))
qed






end