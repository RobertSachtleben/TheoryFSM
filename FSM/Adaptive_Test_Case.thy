theory Adaptive_Test_Case
imports State_Separator 
begin

section \<open>Adaptive Test Cases\<close>

subsection \<open>Basic Definition\<close>

(* An ATC is a single input, acyclic, observable FSM, which is equivalent to a tree whose inner 
   nodes are labeled with inputs and whose edges are labeled with outputs *)
definition is_ATC :: "('a,'b) FSM_scheme \<Rightarrow> bool" where
  "is_ATC M = (single_input M \<and> acyclic M \<and> observable M)"

lemma is_ATC_from :
  assumes "t \<in> h A"
  and     "is_ATC A"
shows "is_ATC (from_FSM A (t_target t))"
  using from_FSM_acyclic[OF wf_transition_target[OF assms(1)]] 
        from_FSM_single_input[OF wf_transition_target[OF assms(1)]]
        from_FSM_observable[OF _ wf_transition_target[OF assms(1)]]
        assms(2)
  unfolding is_ATC_def
  by blast


subsection \<open>Applying Adaptive Test Cases\<close>


(* FSM A passes ATC A if and only if the parallel execution of M and A does not visit a fail_state in A and M produces no output not allowed in A *)
fun pass_ATC' :: "('a,'b) FSM_scheme \<Rightarrow> ('c,'d) FSM_scheme \<Rightarrow> 'c set \<Rightarrow> nat \<Rightarrow> bool" where
  "pass_ATC' M A fail_states 0 = (\<not> (initial A \<in> fail_states))" |
  "pass_ATC' M A fail_states (Suc k) = ((\<not> (initial A \<in> fail_states)) \<and> (case find (\<lambda> x . \<exists> t \<in> h A . t_input t = x \<and> t_source t = initial A) (inputs A) of
    None \<Rightarrow> True |
    Some x \<Rightarrow> \<forall> t \<in> h M . (t_input t = x \<and> t_source t = initial M) \<longrightarrow> (\<exists> t' \<in> h A . t_input t' = x \<and> t_source t' = initial A \<and> t_output t' = t_output t \<and> pass_ATC' (from_FSM M (t_target t)) (from_FSM A (t_target t')) fail_states k)))"

(* Applies pass_ATC' for a depth of at most (size A) (i.e., an upper bound on the length of paths in A) *)
fun pass_ATC :: "('a,'b) FSM_scheme \<Rightarrow> ('c,'d) FSM_scheme \<Rightarrow> 'c set \<Rightarrow> bool" where
  "pass_ATC M A fail_states = pass_ATC' M A fail_states (size A)"



lemma pass_ATC'_initial :
  assumes "pass_ATC' M A FS k"
  shows "initial A \<notin> FS"
using assms by (cases k; auto) 


lemma pass_ATC'_io :
  assumes "pass_ATC' M A FS k"
  and     "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
  and     "io@[ioA] \<in> L A"
  and     "io@[ioM] \<in> L M"
  and     "fst ioA = fst ioM"
  and     "length (io@[ioA]) \<le> k" 
shows "io@[ioM] \<in> L A"
and   "io_targets A (io@[ioM]) (initial A) \<inter> FS = {}"
proof -
  have "io@[ioM] \<in> L A \<and> io_targets A (io@[ioM]) (initial A) \<inter> FS = {}"
    using assms proof (induction k arbitrary: io A M)
    case 0
    then show ?case by auto
  next
    case (Suc k)
    then show ?case proof (cases io)
      case Nil
      
      obtain tA where "tA \<in> h A"
                  and "t_source tA = initial A"
                  and "t_input tA = fst ioA"
                  and "t_output tA = snd ioA"
        using Nil \<open>io@[ioA] \<in> L A\<close> by auto
      then have "fst ioA \<in> set (inputs A)"
        by auto

      have *: "\<And> x . x \<in> set (inputs A) \<Longrightarrow> \<exists> t' \<in> h A . t_input t' = x \<and> t_source t' = initial A \<Longrightarrow> x = fst ioA"
        using \<open>is_ATC A\<close> \<open>tA \<in> h A\<close> unfolding is_ATC_def single_input.simps
        using \<open>t_source tA = initial A\<close> \<open>t_input tA = fst ioA\<close>
        by metis 

      have find_scheme : "\<And> P xs x. x \<in> set xs \<Longrightarrow> P x \<Longrightarrow> (\<And> x' . x' \<in> set xs \<Longrightarrow> P x' \<Longrightarrow> x' = x) \<Longrightarrow> find P xs = Some x"
        by (metis find_None_iff find_condition find_set option.exhaust)

      have "find (\<lambda> x . \<exists> t \<in> h A . t_input t = x \<and> t_source t = initial A) (inputs A) = Some (fst ioA)"
        using find_scheme[OF \<open>fst ioA \<in> set (inputs A)\<close>, of "\<lambda>x . \<exists> t' \<in> h A . t_input t' = x \<and> t_source t' = initial A"]
        using * \<open>tA \<in> h A\<close> \<open>t_source tA = initial A\<close> by blast

      
      then have ***: "\<And> tM . tM \<in> h M \<Longrightarrow> t_input tM = fst ioA \<Longrightarrow> t_source tM = initial M \<Longrightarrow>
        (\<exists> tA \<in> h A .
            t_input tA = fst ioA \<and>
            t_source tA = initial A \<and> t_output tA = t_output tM \<and> pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA)) FS k)"
        using Suc.prems(1) unfolding pass_ATC'.simps by auto

      obtain tM where "tM \<in> h M"
                  and "t_source tM = initial M"
                  and "t_input tM = fst ioA"
                  and "t_output tM = snd ioM"
        using Nil \<open>io@[ioM] \<in> L M\<close> \<open>fst ioA = fst ioM\<close> by auto

      then obtain tA' where "tA' \<in> h A"
                       and "t_input tA' = fst ioM"
                       and "t_source tA' = initial A" 
                       and "t_output tA' = snd ioM" 
                       and "pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA')) FS k"
        using ***[of tM] \<open>fst ioA = fst ioM\<close> by auto

      then have "path A (initial A) [tA']"
        using single_transition_path[OF \<open>tA' \<in> h A\<close>] by auto
      moreover have "p_io [tA'] = [ioM]"
        using \<open>t_input tA' = fst ioM\<close> \<open>t_output tA' = snd ioM\<close> by auto
      ultimately have "[ioM] \<in> LS A (initial A)"
        unfolding LS.simps
        by (metis (mono_tags, lifting) mem_Collect_eq) 
      then have "io @ [ioM] \<in> LS A (initial A)"
        using Nil by auto

      have "target [tA'] (initial A) = t_target tA'"
        by auto
      then have "t_target tA' \<in> io_targets A [ioM] (initial A)"
        unfolding io_targets.simps 
        using \<open>path A (initial A) [tA']\<close> \<open>p_io [tA'] = [ioM]\<close>
        by (metis (mono_tags, lifting) mem_Collect_eq)
      then have "io_targets A (io @ [ioM]) (initial A) = {t_target tA'}"
        using observable_io_targets[OF _ \<open>io @ [ioM] \<in> LS A (initial A)\<close>] \<open>is_ATC A\<close> Nil
        unfolding is_ATC_def
        by (metis append_self_conv2 singletonD) 
      moreover have "t_target tA' \<notin> FS"
        using \<open>pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA')) FS k\<close>
        by (metis from_FSM_simps(1) pass_ATC'_initial) 
      ultimately have "io_targets A (io @ [ioM]) (initial A) \<inter> FS = {}"
        by auto
      
      then show ?thesis
        using \<open>io @ [ioM] \<in> LS A (initial A)\<close> by auto
    next
      case (Cons io' io'')

      have "[io'] \<in> L A"
        using Cons \<open>io@[ioA] \<in> L A\<close>
        by (metis append.left_neutral append_Cons language_prefix)


      then obtain tA where "tA \<in> h A"
                  and "t_source tA = initial A"
                  and "t_input tA = fst io'"
                  and "t_output tA = snd io'"
        by auto
      then have "fst io' \<in> set (inputs A)"
        by auto

      have *: "\<And> x . x \<in> set (inputs A) \<Longrightarrow> \<exists> t' \<in> h A . t_input t' = x \<and> t_source t' = initial A \<Longrightarrow> x = fst io'"
        using \<open>is_ATC A\<close> \<open>tA \<in> h A\<close> unfolding is_ATC_def single_input.simps
        using \<open>t_source tA = initial A\<close> \<open>t_input tA = fst io'\<close>
        by metis 

      have find_scheme : "\<And> P xs x. x \<in> set xs \<Longrightarrow> P x \<Longrightarrow> (\<And> x' . x' \<in> set xs \<Longrightarrow> P x' \<Longrightarrow> x' = x) \<Longrightarrow> find P xs = Some x"
        by (metis find_None_iff find_condition find_set option.exhaust)

      have "find (\<lambda> x . \<exists> t \<in> h A . t_input t = x \<and> t_source t = initial A) (inputs A) = Some (fst io')"
        using find_scheme[OF \<open>fst io' \<in> set (inputs A)\<close>, of "\<lambda>x . \<exists> t' \<in> h A . t_input t' = x \<and> t_source t' = initial A"]
        using * \<open>tA \<in> h A\<close> \<open>t_source tA = initial A\<close> by blast

      
      then have ***: "\<And> tM . tM \<in> h M \<Longrightarrow> t_input tM = fst io' \<Longrightarrow> t_source tM = initial M \<Longrightarrow>
        (\<exists> tA \<in> h A .
            t_input tA = fst io' \<and>
            t_source tA = initial A \<and> t_output tA = t_output tM \<and> pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA)) FS k)"
        using Suc.prems(1) unfolding pass_ATC'.simps by auto

      have "[io'] \<in> L M"
        using Cons \<open>io@[ioM] \<in> L M\<close>
        by (metis append.left_neutral append_Cons language_prefix)
      then obtain tM where "tM \<in> h M"
                  and "t_source tM = initial M"
                  and "t_input tM = fst io'"
                  and "t_output tM = snd io'"
        by auto

      
      then obtain tA' where "tA' \<in> h A"
                       and "t_input tA' = fst io'"
                       and "t_source tA' = initial A" 
                       and "t_output tA' = snd io'" 
                       and "pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA')) FS k"
        using ***[of tM] by auto
      
      then have "tA = tA'"
        using \<open>is_ATC A\<close>
        unfolding is_ATC_def observable.simps
        by (metis \<open>tA \<in> set (wf_transitions A)\<close> \<open>t_input tA = fst io'\<close> \<open>t_output tA = snd io'\<close> \<open>t_source tA = initial A\<close> prod.collapse) 
      
      then have "pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA)) FS k"
        using \<open>pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA')) FS k\<close> by auto
      
      have "set (inputs (from_FSM A (t_target tA))) \<subseteq> set (inputs (from_FSM M (t_target tM)))"
        by (simp add: Suc.prems(4) from_FSM_simps(2))

      have "length (io'' @ [ioA]) \<le> k"
        using Cons \<open>length (io @ [ioA]) \<le> Suc k\<close> by auto

      have "(io' # (io''@[ioA])) \<in> LS A (t_source tA)"
        using \<open>t_source tA = initial A\<close> \<open>io@[ioA] \<in> L A\<close> Cons by auto
      have "io'' @ [ioA] \<in> LS (from_FSM A (t_target tA)) (initial (from_FSM A (t_target tA)))"
        using observable_language_next[OF \<open>(io' # (io''@[ioA])) \<in> LS A (t_source tA)\<close>]
              \<open>is_ATC A\<close> \<open>tA \<in> h A\<close> \<open>t_input tA = fst io'\<close> \<open>t_output tA = snd io'\<close>
        using is_ATC_def by blast 

      have "(io' # (io''@[ioM])) \<in> LS M (t_source tM)"
        using \<open>t_source tM = initial M\<close> \<open>io@[ioM] \<in> L M\<close> Cons by auto
      have "io'' @ [ioM] \<in> LS (from_FSM M (t_target tM)) (initial (from_FSM M (t_target tM)))"
        using observable_language_next[OF \<open>(io' # (io''@[ioM])) \<in> LS M (t_source tM)\<close>]
              \<open>observable M\<close> \<open>tM \<in> h M\<close> \<open>t_input tM = fst io'\<close> \<open>t_output tM = snd io'\<close>
        by blast
        
      have "observable (from_FSM M (t_target tM))"
        using \<open>observable M\<close> \<open>tM \<in> h M\<close>
        by (meson from_FSM_observable wf_transition_target) 
      
      have "io'' @ [ioM] \<in> LS (from_FSM A (t_target tA)) (initial (from_FSM A (t_target tA)))"
       and "io_targets (from_FSM A (t_target tA)) (io'' @ [ioM]) (initial (from_FSM A (t_target tA))) \<inter> FS = {}" 
        using Suc.IH[OF \<open>pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target tA)) FS k\<close>
                        is_ATC_from[OF \<open>tA \<in> h A\<close> \<open>is_ATC A\<close>]
                        \<open>observable (from_FSM M (t_target tM))\<close>
                        \<open>set (inputs (from_FSM A (t_target tA))) \<subseteq> set (inputs (from_FSM M (t_target tM)))\<close>
                        \<open>io'' @ [ioA] \<in> LS (from_FSM A (t_target tA)) (initial (from_FSM A (t_target tA)))\<close>
                        \<open>io'' @ [ioM] \<in> LS (from_FSM M (t_target tM)) (initial (from_FSM M (t_target tM)))\<close>
                        \<open>fst ioA = fst ioM\<close>
                        \<open>length (io'' @ [ioA]) \<le> k\<close>]
        by blast+

      then obtain pA where "path (from_FSM A (t_target tA)) (initial (from_FSM A (t_target tA))) pA" and "p_io pA = io'' @ [ioM]"
        by auto

      have "path A (initial A) (tA#pA)"
        using \<open>path (from_FSM A (t_target tA)) (initial (from_FSM A (t_target tA))) pA\<close> \<open>tA \<in> h A\<close> 
        by (metis \<open>t_source tA = initial A\<close> cons from_FSM_path_initial wf_transition_target)
      moreover have "p_io (tA#pA) = io' # io'' @ [ioM]"
        using \<open>t_input tA = fst io'\<close> \<open>t_output tA = snd io'\<close> \<open>p_io pA = io'' @ [ioM]\<close> by auto
      ultimately have "io' # io'' @ [ioM] \<in> L A"
        unfolding LS.simps
        by (metis (mono_tags, lifting) mem_Collect_eq) 
      then have "io @ [ioM] \<in> L A"
        using Cons by auto

      have "observable A"
        using Suc.prems(2) is_ATC_def by blast

      (* TODO: maybe move *)
      have ex_scheme: "\<And> xs P x . (\<exists>! x' . x' \<in> set xs \<and> P x') \<Longrightarrow> x \<in> set xs \<Longrightarrow> P x \<Longrightarrow> set (filter P xs) = {x}"
        by force
        
      have "set (filter (\<lambda>t. t_source t = initial A \<and> t_input t = fst io' \<and> t_output t = snd io') (wf_transitions A)) = {tA}"
        using ex_scheme[of "wf_transitions A" "(\<lambda> t' . t_source t' = initial A \<and> t_input t' = fst io' \<and> t_output t' = snd io')", OF
                          observable_transition_unique[OF \<open>observable A\<close> \<open>tA \<in> h A\<close> \<open>t_source tA = initial A\<close> \<open>t_input tA = fst io'\<close> \<open>t_output tA = snd io'\<close>]]
        using \<open>tA \<in> h A\<close> \<open>t_source tA = initial A\<close> \<open>t_input tA = fst io'\<close> \<open>t_output tA = snd io'\<close>
        by blast


      have concat_scheme: "\<And> f g h xs x. set (filter h xs) = {x} \<Longrightarrow> set (concat (map f (map g (filter h xs)))) = set (f (g x))"
      proof -
        {
          fix x :: 'a 
          and xs h 
          and g :: "'a \<Rightarrow> 'b"
          and f :: "'b \<Rightarrow> 'c list"
          assume "set (filter h xs) = {x}"
          then have "\<And> y . y \<in> set (map f (map g (filter h xs))) \<Longrightarrow> y = f (g x)"
            by auto
          then have "\<And> y . y \<in> set (concat (map f (map g (filter h xs)))) \<Longrightarrow> y \<in> set (f (g x))"
            by fastforce
          moreover have "\<And> y . y \<in> set (f (g x)) \<Longrightarrow> y \<in> set (concat (map f (map g (filter h xs))))"
          proof -
            fix y :: 'c
            assume a1: "y \<in> set (f (g x))"
            have "set (filter h xs) \<noteq> {}"
              using \<open>set (filter h xs) = {x}\<close> by fastforce
            then have "filter h xs \<noteq> []"
              by blast
            then show "y \<in> set (concat (map f (map g (filter h xs))))"
              using a1 by (metis (no_types) UN_I \<open>\<And>y. y \<in> set (map f (map g (filter h xs))) \<Longrightarrow> y = f (g x)\<close> ex_in_conv list.map_disc_iff set_concat set_empty)
          qed
          ultimately have "set (concat (map f (map g (filter h xs)))) = set (f (g x))" by blast
        }
        thus "\<And> f g h xs x. set (filter h xs) = {x} \<Longrightarrow> set (concat (map f (map g (filter h xs)))) = set (f (g x))"
          by simp 
      qed
        

      have "set (io_targets_list A (io' # (io'' @ [ioM])) (initial A)) = set (io_targets_list A (io'' @ [ioM]) (t_target tA))"
        unfolding io_targets_list.simps 
        using concat_scheme[OF \<open>set (filter (\<lambda>t. t_source t = initial A \<and> t_input t = fst io' \<and> t_output t = snd io') (wf_transitions A)) = {tA}\<close>]
        by metis

      then have "io_targets A (io' # (io'' @ [ioM])) (initial A) = io_targets A (io'' @ [ioM]) (t_target tA)"
        using nodes.initial[of A] wf_transition_target[OF \<open>tA \<in> h A\<close>]
        by (metis io_targets_from_list) 

      then have "io_targets A (io' # (io'' @ [ioM])) (initial A) = io_targets (from_FSM A (t_target tA)) (io'' @ [ioM]) (initial (from_FSM A (t_target tA)))"
        unfolding io_targets.simps using from_FSM_path_initial[OF wf_transition_target[OF \<open>tA \<in> h A\<close>]]
        by auto

      then have "io_targets A (io @ [ioM]) (initial A) \<inter> FS = {}"
        using \<open>io_targets (from_FSM A (t_target tA)) (io'' @ [ioM]) (initial (from_FSM A (t_target tA))) \<inter> FS = {}\<close> Cons by auto
        
      show ?thesis
        using \<open>io @ [ioM] \<in> L A\<close> \<open>io_targets A (io @ [ioM]) (initial A) \<inter> FS = {}\<close> by simp
    qed
  qed

  thus "io@[ioM] \<in> L A"
  and  "io_targets A (io@[ioM]) (initial A) \<inter> FS = {}"
    by auto
qed



lemma pass_ATC_io :
  assumes "pass_ATC M A FS"
  and     "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
  and     "io@[ioA] \<in> L A"
  and     "io@[ioM] \<in> L M"
  and     "fst ioA = fst ioM" 
shows "io@[ioM] \<in> L A"
and   "io_targets A (io@[ioM]) (initial A) \<inter> FS = {}"
proof -

  have "acyclic A"
    using \<open>is_ATC A\<close> is_ATC_def by blast 

  have "length (io @ [ioA]) \<le> (size A)"
    using \<open>io@[ioA] \<in> L A\<close> unfolding LS.simps using acyclic_path_length[OF \<open>acyclic A\<close>]
    by force 
  
  show "io@[ioM] \<in> L A"
  and  "io_targets A (io@[ioM]) (initial A) \<inter> FS = {}"
    using pass_ATC'_io[OF _ assms(2-7) \<open>length (io @ [ioA]) \<le> (size A)\<close>]
    using assms(1) by simp+
qed


lemma pass_ATC_io_explicit_io_tuple :
  assumes "pass_ATC M A FS"
  and     "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
  and     "io@[(x,y)] \<in> L A"
  and     "io@[(x,y')] \<in> L M" 
shows "io@[(x,y')] \<in> L A"
and   "io_targets A (io@[(x,y')]) (initial A) \<inter> FS = {}"
  apply (metis pass_ATC_io(1) assms fst_conv)
  by (metis pass_ATC_io(2) assms fst_conv)



lemma pass_ATC_io_fail_fixed_io :
  assumes "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
  and     "io@[ioA] \<in> L A"
  and     "io@[ioM] \<in> L M"
  and     "fst ioA = fst ioM" 
  and     "io@[ioM] \<notin> L A \<or> io_targets A (io@[ioM]) (initial A) \<inter> FS \<noteq> {}"
shows "\<not>pass_ATC M A FS" 
proof -
  consider (a) "io@[ioM] \<notin> L A" |
           (b) "io_targets A (io@[ioM]) (initial A) \<inter> FS \<noteq> {}"
    using assms(7) by blast 
  then show ?thesis proof (cases)
    case a
    then show ?thesis using pass_ATC_io(1)[OF _ assms(1-6)] by blast
  next
    case b
    then show ?thesis using pass_ATC_io(2)[OF _ assms(1-6)] by blast
  qed
qed




lemma pass_ATC'_io_fail :
  assumes "\<not>pass_ATC' M A FS k "
  and     "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
shows "initial A \<in> FS \<or> (\<exists> io ioA ioM . io@[ioA] \<in> L A
                          \<and> io@[ioM] \<in> L M
                          \<and> fst ioA = fst ioM
                          \<and> (io@[ioM] \<notin> L A \<or> io_targets A (io@[ioM]) (initial A) \<inter> FS \<noteq> {}))"
using assms proof (induction k arbitrary: M A)
  case 0
  then show ?case by auto
next
  case (Suc k)
  then show ?case proof (cases "initial A \<in> FS")
    case True
    then show ?thesis by auto
  next
    case False
    then obtain x where "find (\<lambda> x . \<exists> t \<in> h A . t_input t = x \<and> t_source t = initial A) (inputs A) = Some x"
      using Suc.prems(1) unfolding pass_ATC'.simps
      by fastforce 
    then have "pass_ATC' M A FS (Suc k) = (\<forall>t\<in>set (wf_transitions M).
                                            t_input t = x \<and> t_source t = initial M \<longrightarrow>
                                            (\<exists>t'\<in>set (wf_transitions A).
                                                t_input t' = x \<and>
                                                t_source t' = initial A \<and>
                                                t_output t' = t_output t \<and>
                                                pass_ATC' (from_FSM M (t_target t)) (from_FSM A (t_target t')) FS k))"
      using False unfolding pass_ATC'.simps by fastforce
    then obtain tM where "tM \<in> h M" 
                   and   "t_input tM = x" 
                   and   "t_source tM = initial M"
                   and *:"\<not>(\<exists>t'\<in>set (wf_transitions A).
                            t_input t' = x \<and>
                            t_source t' = initial A \<and>
                            t_output t' = t_output tM \<and>
                            pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target t')) FS k)" 
      using Suc.prems(1) by blast

    obtain tA where "tA \<in> h A" and "t_input tA = x" and "t_source tA = initial A"
      using find_condition[OF \<open>find (\<lambda> x . \<exists> t \<in> h A . t_input t = x \<and> t_source t = initial A) (inputs A) = Some x\<close>] by blast

    let ?ioA = "(x, t_output tA)"
    let ?ioM = "(x, t_output tM)"

    have "[?ioA] \<in> L A"
      using \<open>tA \<in> h A\<close> \<open>t_input tA = x\<close> \<open>t_source tA = initial A\<close> unfolding LS.simps
    proof -
      have "[(x, t_output tA)] = p_io [tA]"
        by (simp add: \<open>t_input tA = x\<close>)
      then have "\<exists>ps. [(x, t_output tA)] = p_io ps \<and> path A (initial A) ps"
        by (metis (no_types) \<open>tA \<in> set (wf_transitions A)\<close> \<open>t_source tA = initial A\<close> single_transition_path)
      then show "[(x, t_output tA)] \<in> {p_io ps |ps. path A (initial A) ps}"
        by blast
    qed

    (* TODO: extract *)
    have "[?ioM] \<in> L M"
      using \<open>tM \<in> h M\<close> \<open>t_input tM = x\<close> \<open>t_source tM = initial M\<close> unfolding LS.simps
    proof -
      have "[(x, t_output tM)] = p_io [tM]"
        by (simp add: \<open>t_input tM = x\<close>)
      then have "\<exists>ps. [(x, t_output tM)] = p_io ps \<and> path M (initial M) ps"
        by (metis (no_types) \<open>tM \<in> set (wf_transitions M)\<close> \<open>t_source tM = initial M\<close> single_transition_path)
      then show "[(x, t_output tM)] \<in> {p_io ps |ps. path M (initial M) ps}"
        by blast
    qed

    have "fst ?ioA = fst ?ioM"
      by auto

    consider (a) "\<not>(\<exists>t'\<in>set (wf_transitions A).
                            t_input t' = x \<and>
                            t_source t' = initial A \<and>
                            t_output t' = t_output tM)" |
             (b) "\<exists>t'\<in>set (wf_transitions A).
                            t_input t' = x \<and>
                            t_source t' = initial A \<and>
                            t_output t' = t_output tM \<and>
                            \<not>(pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target t')) FS k)"
      using * by blast
       
    then show ?thesis proof cases
      case a

      have "[?ioM] \<notin> L A"
      proof 
        assume "[?ioM] \<in> L A"
        then obtain p where "path A (initial A) p" and "p_io p = [?ioM]" (* TODO: extract *)
          unfolding LS.simps
        proof -
          assume a1: "[(x, t_output tM)] \<in> {p_io p |p. path A (initial A) p}"
          assume a2: "\<And>p. \<lbrakk>path A (initial A) p; p_io p = [(x, t_output tM)]\<rbrakk> \<Longrightarrow> thesis"
          have "\<exists>ps. [(x, t_output tM)] = p_io ps \<and> path A (initial A) ps"
            using a1 by force
          then show ?thesis
            using a2 by (metis (lifting))
        qed 
        then obtain t where "p = [t]" and "t \<in> h A" and "t_source t = initial A" and "t_input t = x" and "t_output t = t_output tM"
          by auto
        then show "False" 
          using a by blast
      qed

      then have "\<exists> io ioA ioM . io@[ioA] \<in> L A
                          \<and> io@[ioM] \<in> L M
                          \<and> fst ioA = fst ioM
                          \<and> io@[ioM] \<notin> L A"
        using \<open>[?ioA] \<in> L A\<close> \<open>[?ioM] \<in> L M\<close> \<open>fst ?ioA = fst ?ioM\<close>
        by (metis append_Nil)
      thus ?thesis by blast
        
    next
      case b
      then obtain t' where "t' \<in> h A"
                       and "t_input t' = x"
                       and "t_source t' = initial A"
                       and "t_output t' = t_output tM"
                       and "\<not>(pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target t')) FS k)"
        by blast

      have "set (inputs (from_FSM A (t_target t'))) \<subseteq> set (inputs (from_FSM M (t_target tM)))"
        using \<open>set (inputs A) \<subseteq> set (inputs M)\<close> 
        by (simp add: from_FSM_simps(2)) 

      have "observable A"
        using \<open>is_ATC A\<close> unfolding is_ATC_def by auto

      consider (b1) "initial (from_FSM A (t_target t')) \<in> FS" |
               (b2) "(\<exists>io ioA ioM.
                        io @ [ioA] \<in> LS (from_FSM A (t_target t')) (initial (from_FSM A (t_target t'))) \<and>
                        io @ [ioM] \<in> LS (from_FSM M (t_target tM)) (initial (from_FSM M (t_target tM))) \<and>
                        fst ioA = fst ioM \<and>
                        (io @ [ioM] \<notin> LS (from_FSM A (t_target t')) (initial (from_FSM A (t_target t'))) \<or>
                        io_targets (from_FSM A (t_target t')) (io @ [ioM]) (initial (from_FSM A (t_target t'))) \<inter> FS \<noteq> {}))"
        using Suc.IH[OF \<open>\<not>(pass_ATC' (from_FSM M (t_target tM)) (from_FSM A (t_target t')) FS k)\<close>
                        is_ATC_from[OF \<open>t' \<in> h A\<close> \<open>is_ATC A\<close>]
                        from_FSM_observable[OF \<open>observable M\<close> wf_transition_target[OF \<open>tM \<in> h M\<close>]]
                        \<open>set (inputs (from_FSM A (t_target t'))) \<subseteq> set (inputs (from_FSM M (t_target tM)))\<close> ] 
        by blast              
      then show ?thesis proof cases
        case b1 (* analogous to case a *)

        have "p_io [t'] = [(x, t_output tM)]"
          using \<open>t_input t' = x\<close> \<open>t_output t' = t_output tM\<close>
          by auto
        moreover have "target [t'] (initial A) = t_target t'"
          using \<open>t_source t' = initial A\<close> by auto
        ultimately have "t_target t' \<in> io_targets A [?ioM] (initial A)"
          unfolding io_targets.simps
          using single_transition_path[OF \<open>t' \<in> h A\<close>]
          by (metis (mono_tags, lifting) \<open>t_source t' = initial A\<close> mem_Collect_eq)
        then have "initial (from_FSM A (t_target t')) \<in> io_targets A [?ioM] (initial A)"
          by (simp add: from_FSM_simps(1))
        then have "io_targets A ([] @ [?ioM]) (initial A) \<inter> FS \<noteq> {}"
          using b1 by (metis IntI append_Nil empty_iff) 

        then have "\<exists> io ioA ioM . io@[ioA] \<in> L A
                          \<and> io@[ioM] \<in> L M
                          \<and> fst ioA = fst ioM
                          \<and> io_targets A (io @ [ioM]) (initial A) \<inter> FS \<noteq> {}"
          using \<open>[?ioA] \<in> L A\<close> \<open>[?ioM] \<in> L M\<close> \<open>fst ?ioA = fst ?ioM\<close> 
          using append_Nil by metis
        
        then show ?thesis by blast

      next
        case b2 (* obtain io ioA ioM and prepend (x,t_output tM) *)

        then obtain io ioA ioM where
              "io @ [ioA] \<in> LS (from_FSM A (t_target t')) (initial (from_FSM A (t_target t')))"
          and "io @ [ioM] \<in> LS (from_FSM M (t_target tM)) (initial (from_FSM M (t_target tM)))"
          and "fst ioA = fst ioM"
          and "(io @ [ioM] \<notin> LS (from_FSM A (t_target t')) (initial (from_FSM A (t_target t'))) \<or> io_targets (from_FSM A (t_target t')) (io @ [ioM]) (initial (from_FSM A (t_target t'))) \<inter> FS \<noteq> {})"
          by blast

        have "(?ioM # io) @ [ioA] \<in> L A"
          using language_state_prepend_transition[OF \<open>io @ [ioA] \<in> LS (from_FSM A (t_target t')) (initial (from_FSM A (t_target t')))\<close> \<open>t' \<in> h A\<close>]
          using \<open>t_input t' = x\<close> \<open>t_source t' = initial A\<close> \<open>t_output t' = t_output tM\<close>
          by simp

        moreover have "(?ioM # io) @ [ioM] \<in> L M"
          using language_state_prepend_transition[OF \<open>io @ [ioM] \<in> L (from_FSM M (t_target tM))\<close> \<open>tM \<in> h M\<close>]
          using \<open>t_input tM = x\<close> \<open>t_source tM = initial M\<close>
          by simp

        moreover have "((?ioM # io) @ [ioM] \<notin> L A \<or> io_targets A ((?ioM # io) @ [ioM]) (initial A) \<inter> FS \<noteq> {})"
        proof -
          consider (f1) "io @ [ioM] \<notin> L (from_FSM A (t_target t'))" |
                   (f2) "io_targets (from_FSM A (t_target t')) (io @ [ioM]) (initial (from_FSM A (t_target t'))) \<inter> FS \<noteq> {}"
            using \<open>(io @ [ioM] \<notin> LS (from_FSM A (t_target t')) (initial (from_FSM A (t_target t'))) \<or> io_targets (from_FSM A (t_target t')) (io @ [ioM]) (initial (from_FSM A (t_target t'))) \<inter> FS \<noteq> {})\<close>
            by blast
          then show ?thesis proof cases
            case f1

            have "p_io [t'] = [(x, t_output tM)]"
              using \<open>t_input t' = x\<close> \<open>t_output t' = t_output tM\<close>
              by auto
            moreover have "target [t'] (initial A) = t_target t'"
              using \<open>t_source t' = initial A\<close> by auto
            ultimately have "t_target t' \<in> io_targets A [?ioM] (initial A)"
              unfolding io_targets.simps
              using single_transition_path[OF \<open>t' \<in> h A\<close>]
              by (metis (mono_tags, lifting) \<open>t_source t' = initial A\<close> mem_Collect_eq)
              
            
            show ?thesis 
              using observable_io_targets_language[of "[(x, t_output tM)]" "io@[ioM]" A "initial A" "t_target t'", OF _ \<open>observable A\<close> \<open>t_target t' \<in> io_targets A [?ioM] (initial A)\<close>]
              using f1
              by (metis \<open>observable A\<close> \<open>t' \<in> set (wf_transitions A)\<close> \<open>t_input t' = x\<close> \<open>t_output t' = t_output tM\<close> \<open>t_source t' = initial A\<close> append_Cons fst_conv observable_language_next snd_conv) 
              
          next
            case f2

            
            have "io_targets A (p_io [t'] @ io @ [ioM]) (t_source t') = io_targets A ([?ioM] @ io @ [ioM]) (t_source t')"
              using \<open>t_input t' = x\<close> \<open>t_output t' = t_output tM\<close> by auto 
            moreover have "io_targets A (io @ [ioM]) (t_target t') = io_targets (from_FSM A (t_target t')) (io @ [ioM]) (initial (from_FSM A (t_target t')))"
              unfolding io_targets.simps
              using from_FSM_path_initial[OF wf_transition_target[OF \<open>t' \<in> h A\<close>]] by auto
            ultimately have "io_targets A ([?ioM] @ io @ [ioM]) (t_source t') = io_targets (from_FSM A (t_target t')) (io @ [ioM]) (initial (from_FSM A (t_target t')))"
              using observable_io_targets_next[OF \<open>observable A\<close> \<open>t' \<in> h A\<close>, of "io @ [ioM]"] by auto

            then show ?thesis
              using f2 \<open>t_source t' = initial A\<close> by auto
          qed
        qed
          
        
          

        ultimately show ?thesis using \<open>fst ioA = fst ioM\<close> by blast
      qed
    qed
  qed
qed







lemma pass_ATC_io_fail :
  assumes "\<not>pass_ATC M A FS"
  and     "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
shows "initial A \<in> FS \<or> (\<exists> io ioA ioM . io@[ioA] \<in> L A
                          \<and> io@[ioM] \<in> L M
                          \<and> fst ioA = fst ioM
                          \<and> (io@[ioM] \<notin> L A \<or> io_targets A (io@[ioM]) (initial A) \<inter> FS \<noteq> {}))"
  using pass_ATC'_io_fail[OF _ assms(2-4)] using assms(1) by auto



lemma pass_ATC_fail :
  assumes "is_ATC A"
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
  and     "io@[(x,y)] \<in> L A"
  and     "io@[(x,y')] \<in> L M" 
  and     "io@[(x,y')] \<notin> L A"
(*and   "io_targets A (io@[(x,y')]) (initial A) \<inter> FS = {}"*)
shows "\<not> pass_ATC M A FS"
  using assms(1) assms(2) assms(3) assms(4) assms(5) assms(6) pass_ATC_io_explicit_io_tuple(1) by blast



lemma pass_ATC_reduction :
  assumes "L M2 \<subseteq> L M1"
  and     "is_ATC A"
  and     "observable M1"
  and     "observable M2"
  and     "set (inputs A) \<subseteq> set (inputs M1)"
  and     "set (inputs M2) = set (inputs M1)"
  and     "pass_ATC M1 A FS"
shows "pass_ATC M2 A FS"
proof (rule ccontr)
  assume "\<not> pass_ATC M2 A FS"
  have "set (inputs A) \<subseteq> set (inputs M2)"
    using assms(5,6) by blast
  
  have "initial A \<notin> FS"
    using \<open>pass_ATC M1 A FS\<close> by (cases "size A"; auto)  
  then show "False"
    using pass_ATC_io_fail[OF \<open>\<not> pass_ATC M2 A FS\<close> assms(2,4) \<open>set (inputs A) \<subseteq> set (inputs M2)\<close>] using assms(1)
  proof -
    obtain pps :: "(integer \<times> integer) list" and pp :: "integer \<times> integer" and ppa :: "integer \<times> integer" where
      f1: "pps @ [pp] \<in> LS A (initial A) \<and> pps @ [ppa] \<in> LS M2 (initial M2) \<and> fst pp = fst ppa \<and> (pps @ [ppa] \<notin> LS A (initial A) \<or> io_targets A (pps @ [ppa]) (initial A) \<inter> FS \<noteq> {})"
      using \<open>initial A \<in> FS \<or> (\<exists>io ioA ioM. io @ [ioA] \<in> LS A (initial A) \<and> io @ [ioM] \<in> LS M2 (initial M2) \<and> fst ioA = fst ioM \<and> (io @ [ioM] \<notin> LS A (initial A) \<or> io_targets A (io @ [ioM]) (initial A) \<inter> FS \<noteq> {}))\<close> \<open>initial A \<notin> FS\<close> by blast
    then have "pps @ [ppa] \<in> LS M1 (initial M1)"
      using \<open>LS M2 (initial M2) \<subseteq> LS M1 (initial M1)\<close> by blast
    then show ?thesis
      using f1 by (metis (no_types) assms(2) assms(3) assms(5) assms(7) pass_ATC_fail pass_ATC_io_explicit_io_tuple(2) prod.collapse)
  qed 
qed


lemma pass_ATC_fail_no_reduction :
  assumes "is_ATC A"
  and     "observable T" 
  and     "observable M"
  and     "set (inputs A) \<subseteq> set (inputs M)"
  and     "set (inputs T) = set (inputs M)"
  and     "pass_ATC M A FS"
  and     "\<not>pass_ATC T A FS"
shows   "\<not> (L T \<subseteq> L M)" 
  using pass_ATC_reduction[OF _ assms(1,3,2,4,5,6)] assms(7) by blast









subsection \<open>State Separators as Adaptive Test Cases\<close>

fun pass_separator_ATC :: "('a,'b) FSM_scheme \<Rightarrow> ('c,'d) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'c \<Rightarrow> bool" where
  "pass_separator_ATC M S q1 t2 = pass_ATC (from_FSM M q1) S {t2}"

(*
fun pass_separator_ATC :: "('a,'b) FSM_scheme \<Rightarrow> (('a \<times> 'a) + 'a,'b) FSM_scheme \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> bool" where
  "pass_separator_ATC M S q1 q2 = pass_ATC (from_FSM M q1) S {Inr q2}"
*)


lemma state_separator_is_ATC :
  assumes "is_separator M q1 q2 A t1 t2"
  and     "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  shows "is_ATC A"
unfolding is_ATC_def 
  using is_separator_simps(1,2,3)[OF assms(1)] by blast



(*
lemma state_separator_from_canonical_separator_is_ATC :
  assumes "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  shows "is_ATC A"
unfolding is_ATC_def 
  using is_state_separator_from_canonical_separator_simps(2,3)[OF assms(1)]
  using submachine_observable[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(1)] canonical_separator_observable[OF assms(2,3,4)]]
  by blast
*)

(* todo: move *)
lemma nodes_initial_deadlock :
  assumes "deadlock_state M (initial M)"
  shows "nodes M = {initial M}"
proof -
  have "initial M \<in> nodes M"
    by auto
  moreover have "\<And> q . q \<in> nodes M \<Longrightarrow> q \<noteq> initial M \<Longrightarrow> False"
  proof -
    fix q assume "q \<in> nodes M" and "q \<noteq> initial M"
    
    obtain p where "path M (initial M) p" and "q = target p (initial M)"
      using path_to_node[OF \<open>q \<in> nodes M\<close>] by auto
    
    have "p \<noteq> []" 
    proof
      assume "p = []"
      then have "q = initial M" using \<open>q = target p (initial M)\<close> by auto
      then show "False" using \<open>q \<noteq> initial M\<close> by simp
    qed
    then obtain t p' where "p = t # p'" 
      using list.exhaust by blast
    then have "t \<in> h M" and "t_source t = initial M"
      using \<open>path M (initial M) p\<close> by auto
    then show "False"
      using \<open>deadlock_state M (initial M)\<close> unfolding deadlock_state.simps by blast
  qed
  ultimately show ?thesis by blast
qed
    
(* TODO: move *)
lemma separator_initial :
  assumes "is_separator M q1 q2 A t1 t2"
shows "initial A \<noteq> t1"
and   "initial A \<noteq> t2"
proof -
  show "initial A \<noteq> t1"
  proof 
    assume "initial A = t1"
    then have "deadlock_state A (initial A)"
      using is_separator_simps(4)[OF assms] by auto
    then have "nodes A = {initial A}" 
      using nodes_initial_deadlock by blast
    then show "False"
      using is_separator_simps(7,15)[OF assms] \<open>initial A = t1\<close> by auto
  qed

  show "initial A \<noteq> t2"
  proof 
    assume "initial A = t2"
    then have "deadlock_state A (initial A)"
      using is_separator_simps(5)[OF assms] by auto
    then have "nodes A = {initial A}" 
      using nodes_initial_deadlock by blast
    then show "False"
      using is_separator_simps(6,15)[OF assms] \<open>initial A = t2\<close> by auto
  qed
qed



lemma pass_separator_ATC_from_separator :
  assumes "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_separator M q1 q2 A t1 t2" 
shows "pass_separator_ATC M A q1 t2" (* note t2 instead of previously used q2*)
proof (rule ccontr)
  assume "\<not> pass_separator_ATC M A q1 t2"

  then have "\<not> pass_ATC (from_FSM M q1) A {t2}"
    by auto

  have "is_ATC A"
    using state_separator_is_ATC[OF assms(4,1,2,3)] by assumption

  have "initial A \<notin> {t2}"
    using separator_initial(2)[OF assms(4)] by blast
  then obtain io ioA ioM where
    "io @ [ioA] \<in> L A"
    "io @ [ioM] \<in> LS M q1"
    "fst ioA = fst ioM"
    "io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {t2} \<noteq> {}"

    using pass_ATC_io_fail[OF \<open>\<not> pass_ATC (from_FSM M q1) A {t2}\<close> \<open>is_ATC A\<close> from_FSM_observable[OF \<open>observable M\<close> \<open>q1 \<in> nodes M\<close>] ] 
    using is_separator_simps(16)[OF assms(4)]
    using from_FSM_language[OF \<open>q1 \<in> nodes M\<close>]
    unfolding from_FSM_simps by blast
  then obtain x ya ym where
    "io @ [(x,ya)] \<in> L A"
    "io @ [(x,ym)] \<in> LS M q1"
    "io @ [(x,ym)] \<notin> L A \<or> io_targets A (io @ [(x,ym)]) (initial A) \<inter> {t2} \<noteq> {}"
    by (metis fst_eqD old.prod.exhaust)

  have "io @ [(x,ym)] \<in> L A"
    using is_separator_simps(12)[OF assms(4) \<open>io @ [(x,ym)] \<in> LS M q1\<close> \<open>io @ [(x,ya)] \<in> L A\<close>] by assumption

  have "t1 \<noteq> t2" using is_separator_simps(15)[OF assms(4)] by assumption
  
  consider (a) "io @ [(x, ym)] \<in> LS M q1 - LS M q2" |
           (b) "io @ [(x, ym)] \<in> LS M q1 \<inter> LS M q2"
    using \<open>io @ [(x,ym)] \<in> LS M q1\<close> by blast 
  then have "io_targets A (io @ [(x,ym)]) (initial A) \<inter> {t2} = {}"
    using is_separator_simps(9,11)[OF assms(4) \<open>io @ [(x,ym)] \<in> L A\<close>] 
  proof (cases)
    case a
    show ?thesis using is_separator_simps(9)[OF assms(4) \<open>io @ [(x,ym)] \<in> L A\<close> a] \<open>t1 \<noteq> t2\<close> by auto
  next
    case b
    show ?thesis using is_separator_simps(11)[OF assms(4) \<open>io @ [(x,ym)] \<in> L A\<close> b] \<open>t1 \<noteq> t2\<close> by auto
  qed
  
  then show "False"
    using \<open>io @ [(x,ym)] \<in> L A\<close>
    using \<open>io @ [(x,ym)] \<notin> L A \<or> io_targets A (io @ [(x,ym)]) (initial A) \<inter> {t2} \<noteq> {}\<close> by blast
qed

(* TODO: continue refactoring *)

end (*




lemma pass_separator_ATC_from_state_separator_left :
  assumes "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A" 
shows "pass_separator_ATC M A q1 q2"
proof (rule ccontr)
  assume "\<not> pass_separator_ATC M A q1 q2"

  have "set (inputs A) \<subseteq> set (inputs M)"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
    unfolding is_submachine.simps canonical_separator_simps product_simps from_FSM_simps by auto

  have "is_ATC A"
    using state_separator_from_canonical_separator_is_ATC[OF assms(4,1,2,3)] by assumption

  

  have "initial A = Inl (q1,q2)"
    using state_separator_from_canonical_separator_initial[OF assms(4)] by assumption
  then have "initial A \<notin> {Inr q2}" by auto
  
  have *: "observable (from_FSM M q1)"
    using assms(1,2) from_FSM_observable by metis
  have **: "set (inputs A) \<subseteq> set (inputs (from_FSM M q1))"
    using from_FSM_simps(2) \<open>set (inputs A) \<subseteq> set (inputs M)\<close> by metis
  have "q1 \<in> nodes (from_FSM M q1)"
    using from_FSM_simps(1) nodes.initial by metis



  (* get error sequence of minimal length *)
  (* TODO: check if minimality is still required *)
  let ?errorSeqs = "{io . \<exists> ioA ioM . io @ [ioA] \<in> L A \<and>
                                       io @ [ioM] \<in> L (from_FSM M q1) \<and>
                                       fst ioA = fst ioM \<and>
                                       (io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q2} \<noteq> {})}"
  have "?errorSeqs \<noteq> {}"
    using \<open>\<not> pass_separator_ATC M A q1 q2\<close>
    unfolding pass_separator_ATC.simps
    using pass_ATC_io_fail[OF _ \<open>is_ATC A\<close> * **, of "{Inr q2}"] 
    using \<open>initial A \<notin> {Inr q2}\<close> 
    by blast

  have "?errorSeqs \<subseteq> L A"
  proof -
    have "\<And>ps. (\<forall>p pa. ps @ [p] \<notin> LS A (initial A) \<or> ps @ [pa] \<notin> LS (from_FSM M q1) (initial (from_FSM M q1)) \<or> fst p \<noteq> fst pa \<or> ps @ [pa] \<in> LS A (initial A) \<and> io_targets A (ps @ [pa]) (initial A) \<inter> {Inr q2} = {}) \<or> ps \<in> LS A (initial A)"
      by (meson language_prefix)
    then show ?thesis
      by blast
  qed
  then have "finite ?errorSeqs"
    using acyclic_alt_def[of A] 
    using \<open>is_ATC A\<close> unfolding is_ATC_def
    by (meson rev_finite_subset) 
  
  obtain io where "io \<in> ?errorSeqs" and "\<And> io' . io' \<in> ?errorSeqs \<Longrightarrow> length io \<le> length io'"
    using arg_min_if_finite[OF \<open>finite ?errorSeqs\<close> \<open>?errorSeqs \<noteq> {}\<close>, of length]
    by (metis (no_types, lifting) nat_le_linear nat_less_le) 

  then obtain ioA ioM where "io @ [ioA] \<in> L A" 
                      and   "io @ [ioM] \<in> L (from_FSM M q1)" 
                      and   "fst ioA = fst ioM" 
                      and   "(io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q2} \<noteq> {})"
    by blast


  

  (* show that io is both in LS M q1 and LS M q2 *)
  let ?C = "canonical_separator M q1 q2"
  let ?P = "product (from_FSM M q1) (from_FSM M q2)"

  have "io @ [ioA] \<in> L ?C"
    using submachine_language[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]] \<open>io @ [ioA] \<in> L A\<close> by blast

  then have "io \<in> LS M q2"
    using canonical_separator_language_prefix(2)[OF _ assms(2,3,1)] by blast

  obtain pA where "path A (initial A) pA" and "p_io pA = io@[ioA]"
    using \<open>io@[ioA] \<in> L A\<close> by auto
  then have "pA \<noteq> []" by auto
  then obtain pA' tA where "pA = pA'@[tA]"
    using rev_exhaust by blast
  then have "path A (initial A) (pA'@[tA])" and "p_io (pA'@[tA]) = io@[ioA]"
    using \<open>path A (initial A) pA\<close> \<open>p_io pA = io@[ioA]\<close> by auto
  then have "path ?C (initial ?C) (pA'@[tA])"
    using submachine_path[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]]
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
    unfolding is_submachine.simps by auto
  then have "path ?C (initial ?C) pA'"
    by auto

  obtain s1 s2 where "target pA' (initial ?C) = Inl (s1,s2)"
    using canonical_separator_path_split_target_isl[OF \<open>path ?C (initial ?C) (pA'@[tA])\<close>] 
    by (metis isl_def old.prod.exhaust)
  then have "target pA' (initial A) = Inl (s1,s2)"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
    unfolding is_submachine.simps by auto
  then have "Inl (s1,s2) \<in> nodes A"
    using \<open>path A (initial A) (pA'@[tA])\<close> path_target_is_node by auto

  then have "Inl (s1,s2) \<in> nodes ?C"
    using submachine_nodes[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]] by blast
  then have "(s1,s2) \<in> nodes ?P"
    using canonical_separator_nodes by force 

  have "t_source tA = Inl (s1,s2)" and "tA \<in> h A"
    using \<open>target pA' (initial A) = Inl (s1,s2)\<close> \<open>path A (initial A) (pA'@[tA])\<close> by auto
  have "t_input tA = fst ioA"
    using \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto
  

  obtain pL pR where "path M q1 pL" and "path M q2 pR" and "p_io pL = p_io pA'" and "p_io pL = p_io pR" and "target pL q1 = s1" and "target pR q2 = s2"
    using canonical_separator_path_initial(1)[OF \<open>path ?C (initial ?C) pA'\<close> assms(2,3,1) \<open>target pA' (initial ?C) = Inl (s1,s2)\<close>] by blast+
  then have "p_io pR = p_io pA'"
    by simp

  then have "p_io pR = io"
    using \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto

  have "fst (ioA) \<in> set (inputs A)"
      using \<open>path A (initial A) (pA'@[tA])\<close> \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto 
    then have "fst (ioA) \<in> set (inputs ?C)"
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)] unfolding is_submachine.simps by auto
    then have "fst ioA \<in> set (inputs M)" 
      unfolding canonical_separator_simps by assumption

    
   
    have "\<exists> t \<in> h A . t_source t = Inl (s1,s2) \<and> t_input t = fst ioA"
      using \<open>tA \<in> h A\<close> \<open>t_source tA = Inl (s1,s2)\<close> \<open>t_input tA = fst ioA\<close> by blast

    have "io@[ioM] \<in> LS M q1"
      using \<open>io@[ioM] \<in> L (from_FSM M q1)\<close> unfolding from_FSM_simps LS.simps using from_FSM_path[OF \<open>q1 \<in> nodes M\<close>, of q1] by blast

    then obtain pM where "path M q1 pM" and "p_io pM = io@[ioM]"
      by auto
    then have "pM \<noteq> []" by auto
    then obtain pM' tM where "pM = pM' @ [tM]"
      using rev_exhaust by blast
    then have "path M q1 pM'" and "p_io pM' = io"
      using \<open>path M q1 pM\<close> \<open>p_io pM = io@[ioM]\<close> by auto 
    then have "p_io pM' = p_io pL"
      using \<open>p_io pM' = io\<close> \<open>p_io pL = p_io pA'\<close> \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto
    then have "pM' = pL"
      using observable_path_unique[OF assms(1) \<open>path M q1 pM'\<close> \<open>path M q1 pL\<close> ] by blast
    then have "tM \<in> h M" 
          and "t_source tM = s1" 
          and "t_input tM = fst ioA" 
          and "t_output tM = snd ioM"
      using \<open>pM = pM' @ [tM]\<close> \<open>path M q1 pM\<close> \<open>p_io pM = io@[ioM]\<close> \<open>target pL q1 = s1\<close> \<open>fst ioA = fst ioM\<close> by auto
    then have "p_io (pL@[tM]) = io@[ioM]"
      using \<open>pM' = pL\<close> \<open>p_io pM' = io\<close> \<open>fst ioA = fst ioM\<close> by auto


  (* case analysis on (io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q2} \<noteq> {}) *)

  (*  if (io @ [ioM] \<notin> L A), then A is not complete for (fst ioA) after applying io *)

  have "path (from_FSM M q1) (initial (from_FSM M q1)) (pL @ [tM])"
    using \<open>pM' = pL\<close>  from_FSM_path_rev_initial[OF \<open>path M q1 pL\<close>] unfolding from_FSM_simps using \<open>tM \<in> h M\<close> \<open>t_source tM = s1\<close> \<open>target pL q1 = s1\<close> from_FSM_h[OF \<open>q1 \<in> nodes M\<close>]
    by (metis from_FSM_nodes_transitions path_append_last path_target_is_node) 

  then have "\<exists> t . t \<in> set (wf_transitions (canonical_separator M q1 q2)) \<and> t_source t = Inl (s1, s2) \<and> t_input t = fst ioA \<and> t_output t = snd ioM"
  proof (cases "\<exists> tR \<in> set (transitions M) . t_source tR = s2 \<and> t_input tR = t_input tM \<and> t_output tR = t_output tM")
    case True
    then obtain tR where "tR \<in> set (transitions M)" and "t_source tR = s2" and "t_input tR = t_input tM" and "t_output tR = t_output tM"
      by blast

    have "t_source tR \<in> nodes M"
      unfolding \<open>t_source tR = s2\<close> \<open>target pR q2 = s2\<close> 
      using \<open>(s1,s2) \<in> nodes ?P\<close> product_nodes from_FSM_nodes[OF \<open>q2 \<in> nodes M\<close>] by blast

    then have "tR \<in> h M"
      using \<open>tR \<in> set (transitions M)\<close> \<open>t_input tR = t_input tM\<close> \<open>t_output tR = t_output tM\<close> \<open>tM \<in> h M\<close> by auto

    then have "path M q2 (pR@[tR])" 
      using \<open>path M q2 pR\<close> \<open>t_source tR = s2\<close> \<open>target pR q2 = s2\<close> path_append_last by metis
    then have pRf': "path (from_FSM M q2) (initial (from_FSM M q2)) (pR@[tR])"
      using from_FSM_path_initial[OF \<open>q2 \<in> nodes M\<close>] by auto

    

    
    
    let ?PP = "(zip_path (pL@[tM]) (pR@[tR]))"
    let ?PC = "map shift_Inl ?PP"
    let ?tMR = "((t_source tM,t_source tR),t_input tM, t_output tM, (t_target tM,t_target tR))"
    let ?tCMR = "(Inl (t_source tM,t_source tR),t_input tM, t_output tM, Inl (t_target tM,t_target tR))"

    have "length pL = length pR"
      using \<open>p_io pL = p_io pR\<close> map_eq_imp_length_eq by blast 
    then have "?PP = (zip_path pL pR) @ [?tMR]"
      by auto
    then have "?PC = (map shift_Inl (zip_path pL pR)) @ [?tCMR]"
      by auto


    have "length pL = length pR"
      using \<open>p_io pL = p_io pR\<close> map_eq_imp_length_eq by blast
    moreover have "p_io (pL@[tM]) = p_io (pR@[tR])"
      using \<open>p_io pR = io\<close> \<open>t_input tM = fst ioA\<close> \<open>t_output tM = snd ioM\<close> \<open>t_input tR = t_input tM\<close> \<open>t_output tR = t_output tM\<close> \<open>p_io (pL@[tM]) = io@[ioM]\<close> 
      by auto
    ultimately have "p_io ?PP = p_io (pL@[tM])"
      by (induction pL pR rule: list_induct2; auto)

    have "p_io ?PC = p_io ?PP"
      by auto
       
    
      
    have "path ?P (initial ?P) ?PP"
      using product_path_from_paths(1)[OF \<open>path (from_FSM M q1) (initial (from_FSM M q1)) (pL @ [tM])\<close> pRf' \<open>p_io (pL@[tM]) = p_io (pR@[tR])\<close>] 
      by assumption
      


    then have "path ?C (initial ?C) ?PC"
      using canonical_separator_path_shift[of M q1 q2 ?PP] by simp

    have scheme: "\<And> xs xs' x . xs = xs' @ [x] \<Longrightarrow> x \<in> set xs" by auto
    have "?tCMR \<in> set ?PC"
      using scheme[OF \<open>?PC = (map shift_Inl (zip_path pL pR)) @ [?tCMR]\<close>] by assumption
      
    then have "?tCMR \<in> h ?C"
      using path_h[OF \<open>path ?C (initial ?C) ?PC\<close>] by blast

    then show ?thesis unfolding \<open>t_source tM = s1\<close> \<open>t_source tR = s2\<close> \<open>t_input tM = fst ioA\<close> \<open>t_output tM = snd ioM\<close> by force
  next
    case False

    have f1: "((s1,s2),tM) \<in> set (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
      using \<open>(s1,s2) \<in> nodes ?P\<close> \<open>tM \<in> h M\<close> concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] unfolding nodes_code 
      by (metis (no_types, lifting) fst_conv mem_Collect_eq snd_conv)
    have f2: "(\<lambda> qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) ((s1,s2),tM)"
    proof 
      show "t_source (snd ((s1, s2), tM)) = fst (fst ((s1, s2), tM))"
        using \<open>t_source tM = s1\<close> by auto 
      show "\<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst ((s1, s2), tM)) \<and> t_input t' = t_input (snd ((s1, s2), tM)) \<and> t_output t' = t_output (snd ((s1, s2), tM)))"
        using False unfolding fst_conv snd_conv \<open>target pR q2 = s2\<close> by assumption
    qed
    
    have m1: "((s1,s2),tM) \<in> set (filter (\<lambda> qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                                                (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
      using filter_list_set[OF f1, of "(\<lambda> qqt. t_source (snd qqt) = fst (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = snd (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))", OF f2]
      by assumption
 

    let ?t = "(Inl (s1,s2), t_input tM, t_output tM, Inr q1)"
    have "?t \<in> set (distinguishing_transitions_left M q1 q2)"
      using map_set[OF m1, of " (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q1))"] 
      unfolding distinguishing_transitions_left_def fst_conv snd_conv by assumption
    then have "?t \<in> h ?C" 
      using canonical_separator_distinguishing_transitions_left_h by metis
    then show ?thesis 
      unfolding \<open>t_source tM = s1\<close> \<open>t_input tM = fst ioA\<close> \<open>t_output tM = snd ioM\<close> by force
  qed

  then obtain tF where "tF \<in> h ?C" and "t_source tF = Inl (s1, s2)" and "t_input tF = fst ioA" and "t_output tF = snd ioM"
    by blast
  then have "tF \<in> h A"
    using is_state_separator_from_canonical_separator_simps(9)[OF assms(4) \<open>Inl (s1,s2) \<in> nodes A\<close> \<open>fst (ioA) \<in> set (inputs ?C)\<close> \<open>\<exists> t \<in> h A . t_source t = Inl (s1,s2) \<and> t_input t = fst ioA\<close>] by blast

  moreover have "path A (initial A) pA'"
    using \<open>path A (initial A) (pA'@[tA])\<close> by auto
  ultimately have "path A (initial A) (pA'@[tF])"
    using \<open>t_source tF = Inl (s1, s2)\<close> \<open>target pA' (initial ?C) = Inl (s1,s2)\<close> 
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)] 
    unfolding is_submachine.simps  
    by (metis path_append_last)
  moreover have "p_io (pA'@[tF]) = io@[ioM]"
    using \<open>p_io (pA'@[tA]) = io@[ioA]\<close> \<open>t_input tF = fst ioA\<close> \<open>t_output tF = snd ioM\<close> \<open>fst ioA = fst ioM\<close> by auto
  ultimately have "io@[ioM] \<in> L A"
    unfolding LS.simps
    by (metis (mono_tags, lifting) mem_Collect_eq)


  (*  if (io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q2} \<noteq> {}), then (io@[ioM] is also in LS M q2 and hence its target is Inl, not Inr q2 *)

  then have "io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q2} \<noteq> {}"
    using \<open>(io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q2} \<noteq> {})\<close> by blast
  
  then obtain p2 where "path A (initial A) p2" and "target p2 (initial A) = Inr q2" and "p_io p2 = io@[ioM]"
    by auto

  show "False"
  proof (cases "q1 = q2")
    case True
    
    have "set (transitions ?C) \<subseteq> set (shifted_transitions M q2 q2)"
      unfolding True canonical_separator_simps
                distinguishing_transitions_left_empty[OF assms(1,3)]
                distinguishing_transitions_right_empty[OF assms(1,3)]
      by auto
    then have "h A \<subseteq> set (shifted_transitions M q2 q2)"
      using submachine_h[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]] by auto
    then have "\<And> t . t \<in> set p2 \<Longrightarrow> isl (t_target t)"
      unfolding shifted_transitions_def using path_h[OF \<open>path A (initial A) p2\<close>] by force
    then have "isl (target p2 (initial A))"
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
      unfolding target.simps visited_states.simps is_submachine.simps canonical_separator_simps
      by (cases p2 rule: rev_cases; auto)
    then show "False"
      using \<open>target p2 (initial A) = Inr q2\<close> by simp      
  next
    case False
    then have "io@[ioM] \<notin> LS M q1"
      using canonical_separator_maximal_path_distinguishes_right[OF assms(4) \<open>path A (initial A) p2\<close> \<open>target p2 (initial A) = Inr q2\<close> assms(1,2,3)]      
      using \<open>p_io p2 = io@[ioM]\<close> by auto
    then show "False"
      using \<open>io@[ioM] \<in> LS M q1\<close> by blast
  qed
qed



lemma pass_separator_ATC_from_state_separator_right :
  assumes "observable M"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A" 
shows "pass_separator_ATC M A q2 q1"
proof (rule ccontr)
  assume "\<not> pass_separator_ATC M A q2 q1"

  have "set (inputs A) \<subseteq> set (inputs M)"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
    unfolding is_submachine.simps canonical_separator_simps product_simps from_FSM_simps by auto

  have "is_ATC A"
    using state_separator_from_canonical_separator_is_ATC[OF assms(4,1,2,3)] by assumption

  

  have "initial A = Inl (q1,q2)"
    using state_separator_from_canonical_separator_initial[OF assms(4)] by assumption
  then have "initial A \<notin> {Inr q1}" by auto
  
  have *: "observable (from_FSM M q2)"
    using assms(1,3) from_FSM_observable by metis
  have **: "set (inputs A) \<subseteq> set (inputs (from_FSM M q2))"
    using from_FSM_simps(2) \<open>set (inputs A) \<subseteq> set (inputs M)\<close> by metis
  have "q1 \<in> nodes (from_FSM M q1)"
    using from_FSM_simps(1) nodes.initial by metis



  let ?errorSeqs = "{io . \<exists> ioA ioM . io @ [ioA] \<in> L A \<and>
                                       io @ [ioM] \<in> L (from_FSM M q2) \<and>
                                       fst ioA = fst ioM \<and>
                                       (io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q1} \<noteq> {})}"
  have "?errorSeqs \<noteq> {}"
    using \<open>\<not> pass_separator_ATC M A q2 q1\<close>
    unfolding pass_separator_ATC.simps
    using pass_ATC_io_fail[OF _ \<open>is_ATC A\<close> * **, of "{Inr q1}"] 
    using \<open>initial A \<notin> {Inr q1}\<close> 
    by blast

  have "?errorSeqs \<subseteq> L A"
  proof -
    have "\<And>ps. (\<forall>p pa. ps @ [p] \<notin> LS A (initial A) \<or> ps @ [pa] \<notin> LS (from_FSM M q2) (initial (from_FSM M q2)) \<or> fst p \<noteq> fst pa \<or> ps @ [pa] \<in> LS A (initial A) \<and> io_targets A (ps @ [pa]) (initial A) \<inter> {Inr q1} = {}) \<or> ps \<in> LS A (initial A)"
      by (meson language_prefix)
    then show ?thesis
      by blast
  qed
  then have "finite ?errorSeqs"
    using acyclic_alt_def[of A] 
    using \<open>is_ATC A\<close> unfolding is_ATC_def
    by (meson rev_finite_subset) 
  
  obtain io where "io \<in> ?errorSeqs" and "\<And> io' . io' \<in> ?errorSeqs \<Longrightarrow> length io \<le> length io'"
    using arg_min_if_finite[OF \<open>finite ?errorSeqs\<close> \<open>?errorSeqs \<noteq> {}\<close>, of length]
    by (metis (no_types, lifting) nat_le_linear nat_less_le) 

  then obtain ioA ioM where "io @ [ioA] \<in> L A" 
                      and   "io @ [ioM] \<in> L (from_FSM M q2)" 
                      and   "fst ioA = fst ioM" 
                      and   "(io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q1} \<noteq> {})"
    by blast


  

  (* show that io is both in LS M q1 and LS M q2 *)
  let ?C = "canonical_separator M q1 q2"
  let ?P = "product (from_FSM M q1) (from_FSM M q2)"

  have "io @ [ioA] \<in> L ?C"
    using submachine_language[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]] \<open>io @ [ioA] \<in> L A\<close> by blast

  then have "io \<in> LS M q2"
    using canonical_separator_language_prefix(2)[OF _ assms(2,3,1)] by blast

  obtain pA where "path A (initial A) pA" and "p_io pA = io@[ioA]"
    using \<open>io@[ioA] \<in> L A\<close> by auto
  then have "pA \<noteq> []" by auto
  then obtain pA' tA where "pA = pA'@[tA]"
    using rev_exhaust by blast
  then have "path A (initial A) (pA'@[tA])" and "p_io (pA'@[tA]) = io@[ioA]"
    using \<open>path A (initial A) pA\<close> \<open>p_io pA = io@[ioA]\<close> by auto
  then have "path ?C (initial ?C) (pA'@[tA])"
    using submachine_path[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]]
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
    unfolding is_submachine.simps by auto
  then have "path ?C (initial ?C) pA'"
    by auto

  obtain s1 s2 where "target pA' (initial ?C) = Inl (s1,s2)"
    using canonical_separator_path_split_target_isl[OF \<open>path ?C (initial ?C) (pA'@[tA])\<close>] 
    by (metis isl_def old.prod.exhaust)
  then have "target pA' (initial A) = Inl (s1,s2)"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
    unfolding is_submachine.simps by auto
  then have "Inl (s1,s2) \<in> nodes A"
    using \<open>path A (initial A) (pA'@[tA])\<close> path_target_is_node by auto

  then have "Inl (s1,s2) \<in> nodes ?C"
    using submachine_nodes[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]] by blast
  then have "(s1,s2) \<in> nodes ?P"
    using canonical_separator_nodes by force 

  have "t_source tA = Inl (s1,s2)" and "tA \<in> h A"
    using \<open>target pA' (initial A) = Inl (s1,s2)\<close> \<open>path A (initial A) (pA'@[tA])\<close> by auto
  have "t_input tA = fst ioA"
    using \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto
  

  obtain pL pR where "path M q1 pL" and "path M q2 pR" and "p_io pL = p_io pA'" and "p_io pL = p_io pR" and "target pL q1 = s1" and "target pR q2 = s2"
    using canonical_separator_path_initial(1)[OF \<open>path ?C (initial ?C) pA'\<close> assms(2,3,1) \<open>target pA' (initial ?C) = Inl (s1,s2)\<close>] by blast+
  then have "p_io pR = p_io pA'"
    by simp

  then have "p_io pR = io"
    using \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto

  have "fst (ioA) \<in> set (inputs A)"
      using \<open>path A (initial A) (pA'@[tA])\<close> \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto 
    then have "fst (ioA) \<in> set (inputs ?C)"
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)] unfolding is_submachine.simps by auto
    then have "fst ioA \<in> set (inputs M)" 
      unfolding canonical_separator_simps by assumption

    
   
    have "\<exists> t \<in> h A . t_source t = Inl (s1,s2) \<and> t_input t = fst ioA"
      using \<open>tA \<in> h A\<close> \<open>t_source tA = Inl (s1,s2)\<close> \<open>t_input tA = fst ioA\<close> by blast

    have "io@[ioM] \<in> LS M q2"
      using \<open>io@[ioM] \<in> L (from_FSM M q2)\<close> unfolding from_FSM_simps LS.simps using from_FSM_path[OF \<open>q2 \<in> nodes M\<close>, of q2] by blast

    then obtain pM where "path M q2 pM" and "p_io pM = io@[ioM]"
      by auto
    then have "pM \<noteq> []" by auto
    then obtain pM' tM where "pM = pM' @ [tM]"
      using rev_exhaust by blast
    then have "path M q2 pM'" and "p_io pM' = io"
      using \<open>path M q2 pM\<close> \<open>p_io pM = io@[ioM]\<close> by auto 
    then have "p_io pM' = p_io pR"
      using \<open>p_io pM' = io\<close> \<open>p_io pR = p_io pA'\<close> \<open>p_io (pA'@[tA]) = io@[ioA]\<close> by auto
    then have "pM' = pR"
      using observable_path_unique[OF assms(1) \<open>path M q2 pM'\<close> \<open>path M q2 pR\<close> ] by blast
    then have "tM \<in> h M" 
          and "t_source tM = s2" 
          and "t_input tM = fst ioA" 
          and "t_output tM = snd ioM"
      using \<open>pM = pM' @ [tM]\<close> \<open>path M q2 pM\<close> \<open>p_io pM = io@[ioM]\<close> \<open>target pR q2 = s2\<close> \<open>fst ioA = fst ioM\<close> by auto
    then have "p_io (pR@[tM]) = io@[ioM]"
      using \<open>pM' = pR\<close> \<open>p_io pM' = io\<close> \<open>fst ioA = fst ioM\<close> by auto


  (* case analysis on (io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q1} \<noteq> {}) *)

  (*  if (io @ [ioM] \<notin> L A), then A is not complete for (fst ioA) after applying io *)

  have "path (from_FSM M q2) (initial (from_FSM M q2)) (pR @ [tM])"
    using \<open>pM' = pR\<close>  from_FSM_path_rev_initial[OF \<open>path M q2 pR\<close>] unfolding from_FSM_simps using \<open>tM \<in> h M\<close> \<open>t_source tM = s2\<close> \<open>target pR q2 = s2\<close> 
    by (metis from_FSM_nodes_transitions path_append_last path_target_is_node) 

  then have "\<exists> t . t \<in> set (wf_transitions (canonical_separator M q1 q2)) \<and> t_source t = Inl (s1, s2) \<and> t_input t = fst ioA \<and> t_output t = snd ioM"
  proof (cases "\<exists> tL \<in> set (transitions M) . t_source tL = s1 \<and> t_input tL = t_input tM \<and> t_output tL = t_output tM")
    case True
    then obtain tL where "tL \<in> set (transitions M)" and "t_source tL = s1" and "t_input tL = t_input tM" and "t_output tL = t_output tM"
      by blast

    have "t_source tL \<in> nodes M"
      unfolding \<open>t_source tL = s1\<close> \<open>target pL q1 = s1\<close> 
      using \<open>(s1,s2) \<in> nodes ?P\<close> product_nodes from_FSM_nodes[OF \<open>q1 \<in> nodes M\<close>] by blast

    then have "tL \<in> h M"
      using \<open>tL \<in> set (transitions M)\<close> \<open>t_input tL = t_input tM\<close> \<open>t_output tL = t_output tM\<close> \<open>tM \<in> h M\<close> by auto

    then have "path M q1 (pL@[tL])" 
      using \<open>path M q1 pL\<close> \<open>t_source tL = s1\<close> \<open>target pL q1 = s1\<close> path_append_last by metis
    then have pLf': "path (from_FSM M q1) (initial (from_FSM M q1)) (pL@[tL])"
      using from_FSM_path_initial[OF \<open>q1 \<in> nodes M\<close>] by auto

    

    
    
    let ?PP = "(zip_path (pL@[tL]) (pR@[tM]))"
    let ?PC = "map shift_Inl ?PP"
    let ?tMR = "((t_source tL,t_source tM),t_input tM, t_output tM, (t_target tL,t_target tM))"
    let ?tCMR = "(Inl (t_source tL,t_source tM),t_input tM, t_output tM, Inl (t_target tL,t_target tM))"

    have "length pL = length pR"
      using \<open>p_io pL = p_io pR\<close> map_eq_imp_length_eq by blast 
    then have "?PP = (zip_path pL pR) @ [?tMR]"
      using \<open>t_input tL = t_input tM\<close> \<open>t_output tL = t_output tM\<close> by auto
    then have "?PC = (map shift_Inl (zip_path pL pR)) @ [?tCMR]"
      by auto


    have "length pL = length pR"
      using \<open>p_io pL = p_io pR\<close> map_eq_imp_length_eq by blast
    moreover have "p_io (pL@[tL]) = p_io (pR@[tM])"
      using \<open>t_input tL = t_input tM\<close> \<open>t_output tL = t_output tM\<close> \<open>p_io (pR@[tM]) = io@[ioM]\<close>
      by (simp add: \<open>p_io pL = p_io pR\<close>)
    ultimately have "p_io ?PP = p_io (pL@[tM])"
      by (induction pL pR rule: list_induct2; auto)

    have "p_io ?PC = p_io ?PP"
      by auto
       
    
      
    have "path ?P (initial ?P) ?PP"
      using product_path_from_paths(1)[OF pLf' \<open>path (from_FSM M q2) (initial (from_FSM M q2)) (pR @ [tM])\<close>  \<open>p_io (pL@[tL]) = p_io (pR@[tM])\<close>] 
      by assumption
      


    then have "path ?C (initial ?C) ?PC"
      using canonical_separator_path_shift[of M q1 q2 ?PP] by simp

    have scheme: "\<And> xs xs' x . xs = xs' @ [x] \<Longrightarrow> x \<in> set xs" by auto
    have "?tCMR \<in> set ?PC"
      using scheme[OF \<open>?PC = (map shift_Inl (zip_path pL pR)) @ [?tCMR]\<close>] by assumption
      
    then have "?tCMR \<in> h ?C"
      using path_h[OF \<open>path ?C (initial ?C) ?PC\<close>] by blast

    then show ?thesis unfolding \<open>t_source tM = s2\<close> \<open>t_source tL = s1\<close> \<open>t_input tM = fst ioA\<close> \<open>t_output tM = snd ioM\<close> by force
  next
    case False

    have f1: "((s1,s2),tM) \<in> set (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2)))))"
      using \<open>(s1,s2) \<in> nodes ?P\<close> \<open>tM \<in> h M\<close> concat_pair_set[of "wf_transitions M" "nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))"] unfolding nodes_code 
      by (metis (no_types, lifting) fst_conv mem_Collect_eq snd_conv)
    have f2: "(\<lambda> qqt. t_source (snd qqt) = snd (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt))) ((s1,s2),tM)"
      by (simp add: False \<open>t_source tM = s2\<close>)
    
    have m1: "((s1,s2),tM) \<in> set (filter (\<lambda> qqt. t_source (snd qqt) = snd (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))
                                                (concat (map (\<lambda>qq'. map (Pair qq') (wf_transitions M)) (nodes_from_distinct_paths (product (from_FSM M q1) (from_FSM M q2))))))"
      using filter_list_set[OF f1, of "(\<lambda> qqt. t_source (snd qqt) = snd (fst qqt) \<and> \<not> (\<exists>t'\<in>set (transitions M). t_source t' = fst (fst qqt) \<and> t_input t' = t_input (snd qqt) \<and> t_output t' = t_output (snd qqt)))", OF f2]
      by assumption
 

    let ?t = "(Inl (s1,s2), t_input tM, t_output tM, Inr q2)"
    have "?t \<in> set (distinguishing_transitions_right M q1 q2)"
      using map_set[OF m1, of " (\<lambda>qqt. (Inl (fst qqt), t_input (snd qqt), t_output (snd qqt), Inr q2))"] 
      unfolding distinguishing_transitions_right_def fst_conv snd_conv by assumption
    then have "?t \<in> h ?C" 
      using canonical_separator_distinguishing_transitions_right_h by metis
    then show ?thesis 
      unfolding \<open>t_source tM = s2\<close> \<open>t_input tM = fst ioA\<close> \<open>t_output tM = snd ioM\<close> by force
  qed

  then obtain tF where "tF \<in> h ?C" and "t_source tF = Inl (s1, s2)" and "t_input tF = fst ioA" and "t_output tF = snd ioM"
    by blast
  then have "tF \<in> h A"
    using is_state_separator_from_canonical_separator_simps(9)[OF assms(4) \<open>Inl (s1,s2) \<in> nodes A\<close> \<open>fst (ioA) \<in> set (inputs ?C)\<close> \<open>\<exists> t \<in> h A . t_source t = Inl (s1,s2) \<and> t_input t = fst ioA\<close>] by blast

  moreover have "path A (initial A) pA'"
    using \<open>path A (initial A) (pA'@[tA])\<close> by auto
  ultimately have "path A (initial A) (pA'@[tF])"
    using \<open>t_source tF = Inl (s1, s2)\<close> \<open>target pA' (initial ?C) = Inl (s1,s2)\<close> 
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)] 
    unfolding is_submachine.simps  
    by (metis path_append_last)
  moreover have "p_io (pA'@[tF]) = io@[ioM]"
    using \<open>p_io (pA'@[tA]) = io@[ioA]\<close> \<open>t_input tF = fst ioA\<close> \<open>t_output tF = snd ioM\<close> \<open>fst ioA = fst ioM\<close> by auto
  ultimately have "io@[ioM] \<in> L A"
    unfolding LS.simps
    by (metis (mono_tags, lifting) mem_Collect_eq)


  (*  if (io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q1} \<noteq> {}), then (io@[ioM] is also in LS M q1 and hence its target is Inl, not Inr q1 *)

  then have "io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q1} \<noteq> {}"
    using \<open>(io @ [ioM] \<notin> L A \<or> io_targets A (io @ [ioM]) (initial A) \<inter> {Inr q1} \<noteq> {})\<close> by blast
  
  then obtain p1 where "path A (initial A) p1" and "target p1 (initial A) = Inr q1" and "p_io p1 = io@[ioM]"
    by auto

  show "False"
  proof (cases "q1 = q2")
    case True
    
    have "set (transitions ?C) \<subseteq> set (shifted_transitions M q2 q2)"
      unfolding True canonical_separator_simps
                distinguishing_transitions_left_empty[OF assms(1,3)]
                distinguishing_transitions_right_empty[OF assms(1,3)]
      by auto
    then have "h A \<subseteq> set (shifted_transitions M q2 q2)"
      using submachine_h[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]] by auto
    then have "\<And> t . t \<in> set p1 \<Longrightarrow> isl (t_target t)"
      unfolding shifted_transitions_def using path_h[OF \<open>path A (initial A) p1\<close>] by force
    then have "isl (target p1 (initial A))"
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(4)]
      unfolding target.simps visited_states.simps is_submachine.simps canonical_separator_simps
      by (cases p1 rule: rev_cases; auto)
    then show "False"
      using \<open>target p1 (initial A) = Inr q1\<close> by simp      
  next
    case False
    then have "io@[ioM] \<notin> LS M q2"
      using canonical_separator_maximal_path_distinguishes_left[OF assms(4) \<open>path A (initial A) p1\<close> \<open>target p1 (initial A) = Inr q1\<close> assms(1,2,3)]      
      using \<open>p_io p1 = io@[ioM]\<close> by auto
    then show "False"
      using \<open>io@[ioM] \<in> LS M q2\<close> by blast
  qed
qed

  



lemma pass_separator_ATC_path_left :
  assumes "pass_separator_ATC T A t1 q2"
  and     "observable T" 
  and     "observable M"
  and     "t1 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "q1 \<noteq> q2"
  and     "path A (initial A) pA"
  and     "path T t1 pT"
  and     "p_io pA = p_io pT"
shows "target pA (initial A) \<noteq> Inr q2"
and   "\<exists> pM . path M q1 pM \<and> p_io pM = p_io pA"
proof -
   have "set (inputs A) \<subseteq> set (inputs M)"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)]  
    unfolding is_submachine.simps canonical_separator_simps by auto
  then have "pass_separator_ATC M A q1 q2"
    using pass_separator_ATC_from_state_separator_left[OF assms(3,5,6,7)] by blast
  

  then have "pass_ATC (from_FSM M q1) A {Inr q2}"
    by auto

  have "length pA = length pT"
    using \<open>p_io pA = p_io pT\<close>
    using map_eq_imp_length_eq by blast
  then have "target pA (initial A) \<noteq> Inr q2 \<and> (\<exists> pM . path M q1 pM \<and> p_io pM = p_io pA)"
    using assms(10,11,12) 
  proof (induction pA pT rule: rev_induct2)
    case Nil
    then have "target [] (initial A) \<noteq> Inr q2"    
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)]
      unfolding is_submachine.simps canonical_separator_simps by auto
    moreover have "(\<exists> pM . path M q1 pM \<and> p_io pM = p_io [])"
      using \<open>q1 \<in> nodes M\<close>  by auto
    ultimately show ?case by blast
  next
    case (snoc tA pA tT pT)
    have "target pA (initial A) \<noteq> Inr q2" and "(\<exists>pM. path M q1 pM \<and> p_io pM = p_io pA)" 
      using snoc.IH[OF path_prefix[OF snoc.prems(1)] path_prefix[OF snoc.prems(2)]] snoc.prems(3) by auto
    then obtain pM where "path M q1 pM" and "p_io pM = p_io pA"
      by blast


    have "path A (initial A) pA" and "tA \<in> h A" and "t_source tA = target pA (initial A)"
      using snoc.prems(1) by auto
    then have "\<not> deadlock_state A (target pA (initial A))"
      unfolding deadlock_state.simps by blast
    then have "target pA (initial A) \<noteq> Inr q1" and "target pA (initial A) \<noteq> Inr q2"
      using is_state_separator_from_canonical_separator_simps(4,5)[OF assms(7)] by metis+
    then have "isl (target pA (initial A))"
      using is_state_separator_from_canonical_separator_simps(8)[OF assms(7) path_target_is_node[OF \<open>path A (initial A) pA\<close>]] by blast


    have "is_ATC A"
      using state_separator_from_canonical_separator_is_ATC[OF assms(7,3,5,6)] by assumption
    have "set (inputs A) \<subseteq> set (inputs T)"
      using \<open>set (inputs A) \<subseteq> set (inputs M)\<close> assms(8) by auto
    then have "set (inputs A) \<subseteq> set (inputs (from_FSM T t1))"
      unfolding from_FSM_simps by assumption

    obtain io ioA where "p_io (pA@[tA]) = io @ [ioA]" by auto
    then have "io @ [ioA] \<in> L A" 
      using snoc.prems(1) unfolding LS.simps
      by (metis (mono_tags, lifting) mem_Collect_eq) 
    have "p_io (pT@[tT]) = io @ [ioA]"
      using snoc.prems(3) \<open>p_io (pA@[tA]) = io @ [ioA]\<close> by auto
    then have "io @ [ioA] \<in> LS (from_FSM T t1) (initial (from_FSM T t1))"
      using snoc.prems(2) from_FSM_language[OF assms(4)] unfolding LS.simps
      by (metis (mono_tags, lifting) mem_Collect_eq) 

    let ?C = "canonical_separator M q1 q2"
    have "path ?C (initial ?C) (pA @ [tA])"
      using \<open>path A (initial A) (pA @ [tA])\<close> submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(7)]] by auto

    consider (a) "(\<exists>s1' s2'. target (pA @ [tA]) (initial (canonical_separator M q1 q2)) = Inl (s1', s2'))" |
             (b) "target (pA @ [tA]) (initial (canonical_separator M q1 q2)) = Inr q1" |
             (c) "target (pA @ [tA]) (initial (canonical_separator M q1 q2)) = Inr q2"
      using canonical_separator_path_initial(4)[OF \<open>path ?C (initial ?C) (pA @ [tA])\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close>]
      by blast
    then show ?case proof cases
      case a
      then have "target (pA @ [tA]) (initial A) \<noteq> Inr q2" 
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)] by auto
      then show ?thesis 
        using canonical_separator_path_initial(1)[OF \<open>path ?C (initial ?C) (pA @ [tA])\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> ] a 
        by meson 
    next
      case b
      then have "target (pA @ [tA]) (initial A) = Inr q1"
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)] by auto
      then have "target (pA @ [tA]) (initial A) \<noteq> Inr q2"
        using \<open>q1 \<noteq> q2\<close> by auto
      then show ?thesis
        using canonical_separator_path_initial(2)[OF \<open>path ?C (initial ?C) (pA @ [tA])\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> b] 
        by meson 
    next
      case c
      then have "target (pA @ [tA]) (initial A) = Inr q2"
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)] by auto
      then have "io_targets A (io @ [ioA]) (initial A) \<inter> {Inr q2} \<noteq> {}" 
        using \<open>p_io (pA@[tA]) = io @ [ioA]\<close>  snoc.prems(1) unfolding io_targets.simps by force
      then have "\<not> pass_ATC (from_FSM T t1) A {Inr q2}" (* A cannot be passed by t1 in T if Inr q2 is reached *)
        using pass_ATC_io_fail_fixed_io[OF \<open>is_ATC A\<close> from_FSM_observable[OF assms(2,4)] \<open>set (inputs A) \<subseteq> set (inputs (from_FSM T t1))\<close> \<open>io @ [ioA] \<in> L A\<close> \<open>io @ [ioA] \<in> LS (from_FSM T t1) (initial (from_FSM T t1))\<close>, of "{Inr q2}"] by blast
      then show ?thesis 
        using assms(1) unfolding pass_separator_ATC.simps by blast (* contradiction *)
    qed
  qed

  then show "target pA (initial A) \<noteq> Inr q2"
       and  "\<exists> pM . path M q1 pM \<and> p_io pM = p_io pA" by blast+
qed


lemma pass_separator_ATC_path_right :
  assumes "pass_separator_ATC T A t2 q1"
  and     "observable T" 
  and     "observable M"
  and     "t2 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "q1 \<noteq> q2"
  and     "path A (initial A) pA"
  and     "path T t2 pT"
  and     "p_io pA = p_io pT"
shows "target pA (initial A) \<noteq> Inr q1"
and   "\<exists> pM . path M q2 pM \<and> p_io pM = p_io pA" 
proof -
   have "set (inputs A) \<subseteq> set (inputs M)"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)]  
    unfolding is_submachine.simps canonical_separator_simps by auto
  then have "pass_separator_ATC M A q1 q2"
    using pass_separator_ATC_from_state_separator_left[OF assms(3,5,6,7)] by blast
  

  then have "pass_ATC (from_FSM M q1) A {Inr q2}"
    by auto

  have "length pA = length pT"
    using \<open>p_io pA = p_io pT\<close>
    using map_eq_imp_length_eq by blast
  then have "target pA (initial A) \<noteq> Inr q1 \<and> (\<exists> pM . path M q2 pM \<and> p_io pM = p_io pA)"
    using assms(10,11,12) 
  proof (induction pA pT rule: rev_induct2)
    case Nil
    then have "target [] (initial A) \<noteq> Inr q1"    
      using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)]
      unfolding is_submachine.simps canonical_separator_simps by auto
    moreover have "(\<exists> pM . path M q2 pM \<and> p_io pM = p_io [])"
      using \<open>q2 \<in> nodes M\<close>  by auto
    ultimately show ?case by blast
  next
    case (snoc tA pA tT pT)
    have "target pA (initial A) \<noteq> Inr q1" and "(\<exists>pM. path M q2 pM \<and> p_io pM = p_io pA)" 
      using snoc.IH[OF path_prefix[OF snoc.prems(1)] path_prefix[OF snoc.prems(2)]] snoc.prems(3) by auto
    then obtain pM where "path M q2 pM" and "p_io pM = p_io pA"
      by blast


    have "path A (initial A) pA" and "tA \<in> h A" and "t_source tA = target pA (initial A)"
      using snoc.prems(1) by auto
    then have "\<not> deadlock_state A (target pA (initial A))"
      unfolding deadlock_state.simps by blast
    then have "target pA (initial A) \<noteq> Inr q1" and "target pA (initial A) \<noteq> Inr q2"
      using is_state_separator_from_canonical_separator_simps(4,5)[OF assms(7)] by metis+
    then have "isl (target pA (initial A))"
      using is_state_separator_from_canonical_separator_simps(8)[OF assms(7) path_target_is_node[OF \<open>path A (initial A) pA\<close>]] by blast


    have "is_ATC A"
      using state_separator_from_canonical_separator_is_ATC[OF assms(7,3,5,6)] by assumption
    have "set (inputs A) \<subseteq> set (inputs T)"
      using \<open>set (inputs A) \<subseteq> set (inputs M)\<close> assms(8) by auto
    then have "set (inputs A) \<subseteq> set (inputs (from_FSM T t2))"
      unfolding from_FSM_simps by assumption

    obtain io ioA where "p_io (pA@[tA]) = io @ [ioA]" by auto
    then have "io @ [ioA] \<in> L A" 
      using snoc.prems(1) unfolding LS.simps
      by (metis (mono_tags, lifting) mem_Collect_eq) 
    have "p_io (pT@[tT]) = io @ [ioA]"
      using snoc.prems(3) \<open>p_io (pA@[tA]) = io @ [ioA]\<close> by auto
    then have "io @ [ioA] \<in> LS (from_FSM T t2) (initial (from_FSM T t2))"
      using snoc.prems(2) from_FSM_language[OF assms(4)] unfolding LS.simps
      by (metis (mono_tags, lifting) mem_Collect_eq) 

    let ?C = "canonical_separator M q1 q2"
    have "path ?C (initial ?C) (pA @ [tA])"
      using \<open>path A (initial A) (pA @ [tA])\<close> submachine_path_initial[OF is_state_separator_from_canonical_separator_simps(1)[OF assms(7)]] by auto

    consider (a) "(\<exists>s1' s2'. target (pA @ [tA]) (initial (canonical_separator M q1 q2)) = Inl (s1', s2'))" |
             (b) "target (pA @ [tA]) (initial (canonical_separator M q1 q2)) = Inr q1" |
             (c) "target (pA @ [tA]) (initial (canonical_separator M q1 q2)) = Inr q2"
      using canonical_separator_path_initial(4)[OF \<open>path ?C (initial ?C) (pA @ [tA])\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close>]
      by blast
    then show ?case proof cases
      case a
      then have "target (pA @ [tA]) (initial A) \<noteq> Inr q1" 
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)] by auto
      then show ?thesis 
        using canonical_separator_path_initial(1)[OF \<open>path ?C (initial ?C) (pA @ [tA])\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> ] a 
        by force 
    next
      case b
      then have "io_targets A (io @ [ioA]) (initial A) \<inter> {Inr q1} \<noteq> {}" 
        using \<open>p_io (pA@[tA]) = io @ [ioA]\<close>  snoc.prems(1) unfolding io_targets.simps by force
      then have "\<not> pass_ATC (from_FSM T t2) A {Inr q1}" (* A cannot be passed by t1 in T if Inr q2 is reached *)
        using pass_ATC_io_fail_fixed_io[OF \<open>is_ATC A\<close> from_FSM_observable[OF assms(2,4)] \<open>set (inputs A) \<subseteq> set (inputs (from_FSM T t2))\<close> \<open>io @ [ioA] \<in> L A\<close> \<open>io @ [ioA] \<in> LS (from_FSM T t2) (initial (from_FSM T t2))\<close>, of "{Inr q1}"] 
        by blast
      then show ?thesis 
        using assms(1) unfolding pass_separator_ATC.simps by blast (* contradiction *)
    next
      case c
      then have "target (pA @ [tA]) (initial A) = Inr q2"
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(7)] by auto
      then have "target (pA @ [tA]) (initial A) \<noteq> Inr q1"
        using \<open>q1 \<noteq> q2\<close> by auto
      then show ?thesis
        using canonical_separator_path_initial(3)[OF \<open>path ?C (initial ?C) (pA @ [tA])\<close> \<open>q1 \<in> nodes M\<close> \<open>q2 \<in> nodes M\<close> \<open>observable M\<close> c] 
        by meson 
    qed
  qed

  then show "target pA (initial A) \<noteq> Inr q1"
       and  "\<exists> pM . path M q2 pM \<and> p_io pM = p_io pA" by blast+
qed



    




lemma pass_separator_ATC_fail_no_reduction :
  assumes "observable T" 
  and     "observable M"
  and     "t1 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "\<not>pass_separator_ATC T A t1 q2"
shows   "\<not> (LS T t1 \<subseteq> LS M q1)" 
proof 
  assume "LS T t1 \<subseteq> LS M q1"

  have "is_ATC A"
    using state_separator_from_canonical_separator_is_ATC[OF assms(6,2,4,5)] by assumption

  have *: "set (inputs A) \<subseteq> set (inputs (from_FSM M q1))"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)]
    unfolding is_submachine.simps canonical_separator_simps from_FSM_simps by auto

  have "pass_ATC (from_FSM M q1) A {Inr q2}"
    using pass_separator_ATC_from_state_separator_left[OF assms(2,4,5,6)] by auto

  have "\<not> pass_ATC (from_FSM T t1) A {Inr q2}"
    using \<open>\<not>pass_separator_ATC T A t1 q2\<close> by auto

  moreover have "pass_ATC (from_FSM T t1) A {Inr q2}"
    using pass_ATC_reduction[OF _ \<open>is_ATC A\<close> from_FSM_observable[OF \<open>observable M\<close> \<open>q1 \<in> nodes M\<close>] from_FSM_observable[OF \<open>observable T\<close> \<open>t1 \<in> nodes T\<close>] *]
    using \<open>LS T t1 \<subseteq> LS M q1\<close> \<open>pass_ATC (from_FSM M q1) A {Inr q2}\<close>  
    unfolding from_FSM_language[OF assms(3)] from_FSM_language[OF assms(4)]
    unfolding from_FSM_simps \<open>set (inputs T) = set (inputs M)\<close> by blast
  ultimately show "False" by simp
qed





lemma pass_separator_ATC_pass_left :
  assumes "observable T" 
  and     "observable M"
  and     "t1 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "path A (initial A) p"
  and     "p_io p \<in> LS T t1"
  and     "q1 \<noteq> q2"
  and     "pass_separator_ATC T A t1 q2"
shows "target p (initial A) \<noteq> Inr q2"
and   "target p (initial A) = Inr q1 \<or> isl (target p (initial A))"
proof -

  from \<open>p_io p \<in> LS T t1\<close> obtain pT where "path T t1 pT" and "p_io p = p_io pT"
    by auto

  then show "target p (initial A) \<noteq> Inr q2" 
    using pass_separator_ATC_path_left[OF assms(11,1-7,10,8)] by simp

  obtain pM where "path M q1 pM" and "p_io pM = p_io p"
    using pass_separator_ATC_path_left[OF assms(11,1-7,10,8) \<open>path T t1 pT\<close> \<open>p_io p = p_io pT\<close>]  by blast
  then have "p_io p \<in> LS M q1"
    unfolding LS.simps by force

  then show "target p (initial A) = Inr q1 \<or> isl (target p (initial A))"
    using state_separator_from_canonical_separator_targets_left_inclusion[OF assms(1-8)] by blast
qed


lemma pass_separator_ATC_pass_right :
  assumes "observable T" 
  and     "observable M"
  and     "t2 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "path A (initial A) p"
  and     "p_io p \<in> LS T t2"
  and     "q1 \<noteq> q2"
  and     "pass_separator_ATC T A t2 q1"
shows "target p (initial A) \<noteq> Inr q1"
and   "target p (initial A) = Inr q2 \<or> isl (target p (initial A))"
proof -

  from \<open>p_io p \<in> LS T t2\<close> obtain pT where "path T t2 pT" and "p_io p = p_io pT"
    by auto

  then show "target p (initial A) \<noteq> Inr q1" 
    using pass_separator_ATC_path_right[OF assms(11,1-7,10,8)] by simp

  obtain pM where "path M q2 pM" and "p_io pM = p_io p"
    using pass_separator_ATC_path_right[OF assms(11,1-7,10,8) \<open>path T t2 pT\<close> \<open>p_io p = p_io pT\<close>] by blast
  then have "p_io p \<in> LS M q2"
    unfolding LS.simps by force

  then show "target p (initial A) = Inr q2 \<or> isl (target p (initial A))"
    using state_separator_from_canonical_separator_targets_right_inclusion[OF assms(1-8)] by blast
qed



lemma pass_separator_ATC_completely_specified_left :
  assumes "observable T" 
  and     "observable M"
  and     "t1 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "q1 \<noteq> q2"
  and     "pass_separator_ATC T A t1 q2"
  and     "completely_specified T"
shows "\<exists> p . path A (initial A) p \<and> p_io p \<in> LS T t1 \<and> target p (initial A) = Inr q1"
and   "\<not> (\<exists> p . path A (initial A) p \<and> p_io p \<in> LS T t1 \<and> target p (initial A) = Inr q2)"
proof -
  have p1: "pass_ATC (from_FSM T t1) A {Inr q2}"
    using assms(9) by auto

  have p2: "is_ATC A"
    using state_separator_from_canonical_separator_is_ATC[OF assms(6,2,4,5)] by assumption

  have p3: "observable (from_FSM T t1)"
    using from_FSM_observable[OF assms(1,3)] by assumption

  have p4: "set (inputs A) \<subseteq> set (inputs (from_FSM T t1))"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] 
    unfolding from_FSM_simps is_submachine.simps canonical_separator_simps assms(7) by auto



  
  let ?C = "canonical_separator M q1 q2"
  have c_path: "\<And> p . path A (initial A) p \<Longrightarrow> path ?C (initial ?C) p"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] submachine_path_initial by metis

  

  have path_ext: "\<And> p . path A (initial A) p \<Longrightarrow> p_io p \<in> LS T t1 \<Longrightarrow> (target p (initial A) \<noteq> Inr q2) \<and> (target p (initial A) = Inr q1 \<or> (\<exists> t \<in> h A . path A (initial A) (p@[t]) \<and> p_io (p@[t]) \<in> LS T t1))"
  proof -
    fix p assume "path A (initial A) p" and "p_io p \<in> LS T t1"

    then have "target p (initial A) \<noteq> Inr q2"
         and  "target p (initial A) = Inr q1 \<or> isl (target p (initial A))"
      using pass_separator_ATC_pass_left[OF assms(1-7) _ _ assms(8,9)] by auto
    then consider (a) "target p (initial A) = Inr q1" |
                  (b) "isl (target p (initial A))"
      by blast
    then show "(target p (initial A) \<noteq> Inr q2) \<and> (target p (initial A) = Inr q1 \<or> (\<exists> t \<in> h A . path A (initial A) (p@[t]) \<and> p_io (p@[t]) \<in> LS T t1))"
    proof cases
      case a
      then show ?thesis using \<open>target p (initial A) \<noteq> Inr q2\<close> by auto
    next
      case b
      then obtain s1 s2 where "target p (initial A) = Inl (s1,s2)"
        by (metis isl_def surj_pair)
      then have "Inl (s1,s2) \<in> nodes A"
        using \<open>path A (initial A) p\<close> path_target_is_node by metis
      moreover have "Inl (s1,s2) \<noteq> Inr q1" and "Inl (s1,s2) \<noteq> Inr q2"
        by auto
      ultimately have "\<not> deadlock_state A (Inl (s1,s2))"
        using is_state_separator_from_canonical_separator_simps(8)[OF assms(6)] by blast

      then obtain tA where "tA \<in> h A" and "t_source tA = Inl (s1,s2)"
        by auto
      then have "path A (initial A) (p@[tA])"
        using \<open>path A (initial A) p\<close> \<open>target p (initial A) = Inl (s1,s2)\<close> path_append_last by metis
      then have "p_io (p@[tA]) \<in> L A"
        unfolding LS.simps
        by (metis (mono_tags, lifting) mem_Collect_eq) 
      then have "p_io p @ [(t_input tA, t_output tA)] \<in> L A"
        by simp

      have "t_input tA \<in> set (inputs A)"
        using \<open>tA \<in> h A\<close> by auto
      then have "t_input tA \<in> set (inputs ?C)"
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] by auto
      then have "t_input tA \<in> set (inputs T)"
        using assms(7) unfolding canonical_separator_simps by blast

      
      from \<open>p_io p \<in> LS T t1\<close> obtain pT where "path T t1 pT" and "p_io pT = p_io p"
        by auto
      obtain tT where "tT \<in> h T" and "t_source tT = target pT t1" and "t_input tT = t_input tA"
        using \<open>completely_specified T\<close> path_target_is_node[OF \<open>path T t1 pT\<close>] \<open>t_input tA \<in> set (inputs T)\<close>
        unfolding completely_specified.simps by metis
      then have "path T t1 (pT@[tT])"
        using \<open>path T t1 pT\<close> path_append_last by metis
      then have "p_io (pT@[tT]) \<in> LS T t1"
        unfolding LS.simps
        by (metis (mono_tags, lifting) mem_Collect_eq) 
      then have "p_io p @ [(t_input tA, t_output tT)] \<in> L (from_FSM T t1)"
        using \<open>p_io pT = p_io p\<close> \<open>t_input tT = t_input tA\<close> unfolding from_FSM_language[OF \<open>t1 \<in> nodes T\<close>] by auto

      have "p_io p @ [(t_input tA, t_output tT)] \<in> LS A (initial A)"
      and  "io_targets A (p_io p @ [(t_input tA, t_output tT)]) (initial A) \<inter> {Inr q2} = {}"
        using pass_ATC_io[OF p1 p2 p3 p4 \<open>p_io p @ [(t_input tA, t_output tA)] \<in> L A\<close> \<open>p_io p @ [(t_input tA, t_output tT)] \<in> L (from_FSM T t1)\<close>] 
        unfolding fst_conv by blast+

      obtain p' where p'_def: "path A (initial A) p' \<and> p_io p' = p_io p @ [(t_input tA, t_output tT)]"
        using \<open>p_io p @ [(t_input tA, t_output tT)] \<in> L A\<close> by auto
      then obtain p'' t' where "p' = p'' @ [t']" by (cases p' rule: rev_cases; auto) 
      then have "path A (initial A) (p'' @ [t'])" and "p_io (p'' @ [t']) = p_io p @ [(t_input tA, t_output tT)]"
        using p'_def by auto
      then have "path A (initial A) p''" and "p_io p'' = p_io p" and "p_io [t'] = [(t_input tA, t_output tT)]"
        by auto
      have "observable A"
        using state_separator_from_canonical_separator_observable[OF assms(6,2,4,5)] by assumption
      have "p'' = p"
        using observable_path_unique[OF \<open>observable A\<close> \<open>path A (initial A) p''\<close> \<open>path A (initial A) p\<close> \<open>p_io p'' = p_io p\<close>] by assumption
      then have "path A (initial A) (p @ [t'])" and "t' \<in> h A" and "p_io (p @ [t']) = p_io p @ [(t_input tA, t_output tT)]"
        using \<open>path A (initial A) (p'' @ [t'])\<close> \<open>p_io (p'' @ [t']) = p_io p @ [(t_input tA, t_output tT)]\<close> by auto
        

      then have "\<exists>t\<in>set (wf_transitions A). path A (initial A) (p @ [t]) \<and> p_io (p @ [t]) \<in> LS T t1"
        using \<open>p_io p @ [(t_input tA, t_output tT)] \<in> L (from_FSM T t1)\<close> 
        unfolding from_FSM_language[OF \<open>t1 \<in> nodes T\<close>]
      proof -
        assume "p_io p @ [(t_input tA, t_output tT)] \<in> LS T t1"
        then show ?thesis
          by (metis (lifting) \<open>p_io (p @ [t']) = p_io p @ [(t_input tA, t_output tT)]\<close> \<open>path A (initial A) (p @ [t'])\<close> \<open>t' \<in> set (wf_transitions A)\<close>)
      qed 
      then show ?thesis using \<open>target p (initial A) \<noteq> Inr q2\<close> by blast
    qed
  qed


  (* largest path that satisfies (path A (initial A) p) and (p_io p \<in> LS T t1) cannot be extended further and must thus target (Inr q1)  *)

  have "acyclic A"
    using \<open>is_ATC A\<close> is_ATC_def by auto
  then have "finite {p . path A (initial A) p}"
    by (meson acyclic_finite_paths) 
  then have "finite {p . path A (initial A) p \<and> p_io p \<in> LS T t1}"
    by auto

  have "[] \<in> {p . path A (initial A) p \<and> p_io p \<in> LS T t1}"
    using \<open>t1 \<in> nodes T\<close> by auto
  then have "{p . path A (initial A) p \<and> p_io p \<in> LS T t1} \<noteq> {}"
    by blast

  have scheme: "\<And> S . finite S \<Longrightarrow> S \<noteq> {} \<Longrightarrow> \<exists> x \<in> S . \<forall> y \<in> S . length y \<le> length x"
    by (meson leI max_length_elem)
    
    
  obtain p where "p \<in> {p . path A (initial A) p \<and> p_io p \<in> LS T t1}" and "\<And> p' . p' \<in> {p . path A (initial A) p \<and> p_io p \<in> LS T t1} \<Longrightarrow> length p' \<le> length p"
    using scheme[OF \<open>finite {p . path A (initial A) p \<and> p_io p \<in> LS T t1}\<close> \<open>{p . path A (initial A) p \<and> p_io p \<in> LS T t1} \<noteq> {}\<close>] 
    by blast
  then have "path A (initial A) p" and "p_io p \<in> LS T t1" and "\<And> p' . path A (initial A) p' \<Longrightarrow> p_io p' \<in> LS T t1 \<Longrightarrow> length p' \<le> length p"
    by blast+

  have "target p (initial A) = Inr q1"
    using path_ext[OF \<open>path A (initial A) p\<close> \<open>p_io p \<in> LS T t1\<close>] \<open>\<And> p' . path A (initial A) p' \<Longrightarrow> p_io p' \<in> LS T t1 \<Longrightarrow> length p' \<le> length p\<close>
    by (metis (no_types, lifting) Suc_n_not_le_n length_append_singleton) 

  then show "\<exists>p. path A (initial A) p \<and> p_io p \<in> LS T t1 \<and> target p (initial A) = Inr q1"
    using \<open>path A (initial A) p\<close> \<open>p_io p \<in> LS T t1\<close> by blast

  show "\<nexists>p. path A (initial A) p \<and> p_io p \<in> LS T t1 \<and> target p (initial A) = Inr q2"
    using path_ext by blast
qed



lemma pass_separator_ATC_completely_specified_right :
  assumes "observable T" 
  and     "observable M"
  and     "t2 \<in> nodes T"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"
  and     "set (inputs T) = set (inputs M)"
  and     "q1 \<noteq> q2"
  and     "pass_separator_ATC T A t2 q1"
  and     "completely_specified T"
shows "\<exists> p . path A (initial A) p \<and> p_io p \<in> LS T t2 \<and> target p (initial A) = Inr q2"
and   "\<not> (\<exists> p . path A (initial A) p \<and> p_io p \<in> LS T t2 \<and> target p (initial A) = Inr q1)"
proof -
  have p1: "pass_ATC (from_FSM T t2) A {Inr q1}"
    using assms(9) by auto

  have p2: "is_ATC A"
    using state_separator_from_canonical_separator_is_ATC[OF assms(6,2,4,5)] by assumption

  have p3: "observable (from_FSM T t2)"
    using from_FSM_observable[OF assms(1,3)] by assumption

  have p4: "set (inputs A) \<subseteq> set (inputs (from_FSM T t2))"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] 
    unfolding from_FSM_simps is_submachine.simps canonical_separator_simps assms(7) by auto



  
  let ?C = "canonical_separator M q1 q2"
  have c_path: "\<And> p . path A (initial A) p \<Longrightarrow> path ?C (initial ?C) p"
    using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] submachine_path_initial by metis

  

  have path_ext: "\<And> p . path A (initial A) p \<Longrightarrow> p_io p \<in> LS T t2 \<Longrightarrow> (target p (initial A) \<noteq> Inr q1) \<and> (target p (initial A) = Inr q2 \<or> (\<exists> t \<in> h A . path A (initial A) (p@[t]) \<and> p_io (p@[t]) \<in> LS T t2))"
  proof -
    fix p assume "path A (initial A) p" and "p_io p \<in> LS T t2"

    then have "target p (initial A) \<noteq> Inr q1"
         and  "target p (initial A) = Inr q2 \<or> isl (target p (initial A))"
      using pass_separator_ATC_pass_right[OF assms(1-7) _ _ assms(8,9)] by auto
    then consider (a) "target p (initial A) = Inr q2" |
                  (b) "isl (target p (initial A))"
      by blast
    then show "(target p (initial A) \<noteq> Inr q1) \<and> (target p (initial A) = Inr q2 \<or> (\<exists> t \<in> h A . path A (initial A) (p@[t]) \<and> p_io (p@[t]) \<in> LS T t2))"
    proof cases
      case a
      then show ?thesis using \<open>target p (initial A) \<noteq> Inr q1\<close> by auto
    next
      case b
      then obtain s1 s2 where "target p (initial A) = Inl (s1,s2)"
        by (metis isl_def surj_pair)
      then have "Inl (s1,s2) \<in> nodes A"
        using \<open>path A (initial A) p\<close> path_target_is_node by metis
      moreover have "Inl (s1,s2) \<noteq> Inr q1" and "Inl (s1,s2) \<noteq> Inr q2"
        by auto
      ultimately have "\<not> deadlock_state A (Inl (s1,s2))"
        using is_state_separator_from_canonical_separator_simps(8)[OF assms(6)] by blast

      then obtain tA where "tA \<in> h A" and "t_source tA = Inl (s1,s2)"
        by auto
      then have "path A (initial A) (p@[tA])"
        using \<open>path A (initial A) p\<close> \<open>target p (initial A) = Inl (s1,s2)\<close> path_append_last by metis
      then have "p_io (p@[tA]) \<in> L A"
        unfolding LS.simps
        by (metis (mono_tags, lifting) mem_Collect_eq) 
      then have "p_io p @ [(t_input tA, t_output tA)] \<in> L A"
        by simp

      have "t_input tA \<in> set (inputs A)"
        using \<open>tA \<in> h A\<close> by auto
      then have "t_input tA \<in> set (inputs ?C)"
        using is_state_separator_from_canonical_separator_simps(1)[OF assms(6)] by auto
      then have "t_input tA \<in> set (inputs T)"
        using assms(7) unfolding canonical_separator_simps by blast

      
      from \<open>p_io p \<in> LS T t2\<close> obtain pT where "path T t2 pT" and "p_io pT = p_io p"
        by auto
      obtain tT where "tT \<in> h T" and "t_source tT = target pT t2" and "t_input tT = t_input tA"
        using \<open>completely_specified T\<close> path_target_is_node[OF \<open>path T t2 pT\<close>] \<open>t_input tA \<in> set (inputs T)\<close>
        unfolding completely_specified.simps by metis
      then have "path T t2 (pT@[tT])"
        using \<open>path T t2 pT\<close> path_append_last by metis
      then have "p_io (pT@[tT]) \<in> LS T t2"
        unfolding LS.simps
        by (metis (mono_tags, lifting) mem_Collect_eq) 
      then have "p_io p @ [(t_input tA, t_output tT)] \<in> L (from_FSM T t2)"
        using \<open>p_io pT = p_io p\<close> \<open>t_input tT = t_input tA\<close> unfolding from_FSM_language[OF \<open>t2 \<in> nodes T\<close>] by auto

      have "p_io p @ [(t_input tA, t_output tT)] \<in> LS A (initial A)"
      and  "io_targets A (p_io p @ [(t_input tA, t_output tT)]) (initial A) \<inter> {Inr q1} = {}"
        using pass_ATC_io[OF p1 p2 p3 p4 \<open>p_io p @ [(t_input tA, t_output tA)] \<in> L A\<close> \<open>p_io p @ [(t_input tA, t_output tT)] \<in> L (from_FSM T t2)\<close>] 
        unfolding fst_conv by blast+

      obtain p' where p'_def: "path A (initial A) p' \<and> p_io p' = p_io p @ [(t_input tA, t_output tT)]"
        using \<open>p_io p @ [(t_input tA, t_output tT)] \<in> L A\<close> by auto
      then obtain p'' t' where "p' = p'' @ [t']" by (cases p' rule: rev_cases; auto) 
      then have "path A (initial A) (p'' @ [t'])" and "p_io (p'' @ [t']) = p_io p @ [(t_input tA, t_output tT)]"
        using p'_def by auto
      then have "path A (initial A) p''" and "p_io p'' = p_io p" and "p_io [t'] = [(t_input tA, t_output tT)]"
        by auto
      have "observable A"
        using state_separator_from_canonical_separator_observable[OF assms(6,2,4,5)] by assumption
      have "p'' = p"
        using observable_path_unique[OF \<open>observable A\<close> \<open>path A (initial A) p''\<close> \<open>path A (initial A) p\<close> \<open>p_io p'' = p_io p\<close>] by assumption
      then have "path A (initial A) (p @ [t'])" and "t' \<in> h A" and "p_io (p @ [t']) = p_io p @ [(t_input tA, t_output tT)]"
        using \<open>path A (initial A) (p'' @ [t'])\<close> \<open>p_io (p'' @ [t']) = p_io p @ [(t_input tA, t_output tT)]\<close> by auto
        

      then have "\<exists>t\<in>set (wf_transitions A). path A (initial A) (p @ [t]) \<and> p_io (p @ [t]) \<in> LS T t2"
        using \<open>p_io p @ [(t_input tA, t_output tT)] \<in> L (from_FSM T t2)\<close> 
        unfolding from_FSM_language[OF \<open>t2 \<in> nodes T\<close>]
      proof -
        assume "p_io p @ [(t_input tA, t_output tT)] \<in> LS T t2"
        then show ?thesis
          by (metis (lifting) \<open>p_io (p @ [t']) = p_io p @ [(t_input tA, t_output tT)]\<close> \<open>path A (initial A) (p @ [t'])\<close> \<open>t' \<in> set (wf_transitions A)\<close>)
      qed 
      then show ?thesis using \<open>target p (initial A) \<noteq> Inr q1\<close> by blast
    qed
  qed


  (* largest path that satisfies (path A (initial A) p) and (p_io p \<in> LS T t1) cannot be extended further and must thus target (Inr q1)  *)

  have "acyclic A"
    using \<open>is_ATC A\<close> is_ATC_def by auto
  then have "finite {p . path A (initial A) p}"
    by (meson acyclic_finite_paths) 
  then have "finite {p . path A (initial A) p \<and> p_io p \<in> LS T t2}"
    by auto

  have "[] \<in> {p . path A (initial A) p \<and> p_io p \<in> LS T t2}"
    using \<open>t2 \<in> nodes T\<close> by auto
  then have "{p . path A (initial A) p \<and> p_io p \<in> LS T t2} \<noteq> {}"
    by blast

  have scheme: "\<And> S . finite S \<Longrightarrow> S \<noteq> {} \<Longrightarrow> \<exists> x \<in> S . \<forall> y \<in> S . length y \<le> length x"
    by (meson leI max_length_elem)
    
    
  obtain p where "p \<in> {p . path A (initial A) p \<and> p_io p \<in> LS T t2}" and "\<And> p' . p' \<in> {p . path A (initial A) p \<and> p_io p \<in> LS T t2} \<Longrightarrow> length p' \<le> length p"
    using scheme[OF \<open>finite {p . path A (initial A) p \<and> p_io p \<in> LS T t2}\<close> \<open>{p . path A (initial A) p \<and> p_io p \<in> LS T t2} \<noteq> {}\<close>] 
    by blast
  then have "path A (initial A) p" and "p_io p \<in> LS T t2" and "\<And> p' . path A (initial A) p' \<Longrightarrow> p_io p' \<in> LS T t2 \<Longrightarrow> length p' \<le> length p"
    by blast+

  have "target p (initial A) = Inr q2"
    using path_ext[OF \<open>path A (initial A) p\<close> \<open>p_io p \<in> LS T t2\<close>] \<open>\<And> p' . path A (initial A) p' \<Longrightarrow> p_io p' \<in> LS T t2 \<Longrightarrow> length p' \<le> length p\<close>
    by (metis (no_types, lifting) Suc_n_not_le_n length_append_singleton) 

  then show "\<exists>p. path A (initial A) p \<and> p_io p \<in> LS T t2 \<and> target p (initial A) = Inr q2"
    using \<open>path A (initial A) p\<close> \<open>p_io p \<in> LS T t2\<close> by blast

  show "\<nexists>p. path A (initial A) p \<and> p_io p \<in> LS T t2 \<and> target p (initial A) = Inr q1"
    using path_ext by blast
qed




  





lemma pass_separator_ATC_reduction_distinction : 
  assumes "observable M"
  and     "observable T"
  and     "set (inputs T) = set (inputs M)"
  and     "pass_separator_ATC T A t1 q2"
  and     "pass_separator_ATC T A t2 q1"
  and     "q1 \<in> nodes M"
  and     "q2 \<in> nodes M"
  and     "q1 \<noteq> q2"
  and     "t1 \<in> nodes T"
  and     "t2 \<in> nodes T"
  and     "is_state_separator_from_canonical_separator (canonical_separator M q1 q2) q1 q2 A"  
  and     "completely_specified T"
shows "t1 \<noteq> t2"
proof -

  (* As t1 passes A against q2, (Inr q1) must be reached during application, while
     at the same time (Inr q2) is never reached *)

  have "\<exists>p. path A (initial A) p \<and> p_io p \<in> LS T t1 \<and> target p (initial A) = Inr q1"
  and  "\<not> (\<exists>p. path A (initial A) p \<and> p_io p \<in> LS T t1 \<and> target p (initial A) = Inr q2)"
    using pass_separator_ATC_completely_specified_left[OF assms(2,1,9,6,7,11,3,8,4,12)] by blast+

  (* As t2 passes A against q1, (Inr q2) must be reached during application, while
     at the same time (Inr q1) is never reached *)
  
  moreover have "\<exists>p. path A (initial A) p \<and> p_io p \<in> LS T t2 \<and> target p (initial A) = Inr q2"
           and  "\<not> (\<exists>p. path A (initial A) p \<and> p_io p \<in> LS T t2 \<and> target p (initial A) = Inr q1)"
    using pass_separator_ATC_completely_specified_right[OF assms(2,1,10,6,7,11,3,8,5,12)] by blast+

  (* Thus it is not possible for (t1 = t2) to hold *)

  ultimately show "t1 \<noteq> t2"
    by blast
qed




end