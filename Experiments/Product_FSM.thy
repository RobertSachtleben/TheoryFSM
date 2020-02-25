theory Product_FSM
imports FSM

begin


subsection \<open>Product Machine\<close>

lift_definition product :: "('a,'b,'c) fsm \<Rightarrow> ('d,'b,'c) fsm \<Rightarrow> ('a \<times> 'd,'b,'c) fsm" is FSM_Impl.product 
proof -
  fix A :: "('a,'b,'c) fsm_impl"
  fix B :: "('d,'b,'c) fsm_impl"
  assume "well_formed_fsm A" and "well_formed_fsm B"

  then have p1a: "fsm_impl.initial A \<in> fsm_impl.nodes A"
        and p2a: "finite (fsm_impl.nodes A)"
        and p3a: "finite (fsm_impl.inputs A)"
        and p4a: "finite (fsm_impl.outputs A)"
        and p5a: "finite (fsm_impl.transitions A)"
        and p6a: "(\<forall>t\<in>fsm_impl.transitions A.
            t_source t \<in> fsm_impl.nodes A \<and>
            t_input t \<in> fsm_impl.inputs A \<and> t_target t \<in> fsm_impl.nodes A \<and>
                                             t_output t \<in> fsm_impl.outputs A)"
        and p1b: "fsm_impl.initial B \<in> fsm_impl.nodes B"
        and p2b: "finite (fsm_impl.nodes B)"
        and p3b: "finite (fsm_impl.inputs B)"
        and p4b: "finite (fsm_impl.outputs B)"
        and p5b: "finite (fsm_impl.transitions B)"
        and p6b: "(\<forall>t\<in>fsm_impl.transitions B.
            t_source t \<in> fsm_impl.nodes B \<and>
            t_input t \<in> fsm_impl.inputs B \<and> t_target t \<in> fsm_impl.nodes B \<and>
                                             t_output t \<in> fsm_impl.outputs B)"
    by simp+

  let ?P = "FSM_Impl.product A B"

  
  have "fsm_impl.initial ?P \<in> fsm_impl.nodes ?P" 
    using p1a p1b by auto
  moreover have "finite (fsm_impl.nodes ?P)"
    using p2a p2b by auto
  moreover have "finite (fsm_impl.inputs ?P)"
    using p3a p3b by auto
  moreover have "finite (fsm_impl.outputs ?P)"
    using p4a p4b by auto
  moreover have "finite (fsm_impl.transitions ?P)"
    using p5a p5b unfolding product_code_naive by auto
  moreover have "(\<forall>t\<in>fsm_impl.transitions ?P.
            t_source t \<in> fsm_impl.nodes ?P \<and>
            t_input t \<in> fsm_impl.inputs ?P \<and> t_target t \<in> fsm_impl.nodes ?P \<and>
                                             t_output t \<in> fsm_impl.outputs ?P)"
    using p6a p6b by auto

  ultimately show "well_formed_fsm (FSM_Impl.product A B)"
    by blast
qed





value "product m_ex_H m_ex_9"
value "reachable_nodes (product m_ex_H m_ex_9)"

abbreviation "left_path p \<equiv> map (\<lambda>t. (fst (t_source t), t_input t, t_output t, fst (t_target t))) p"
abbreviation "right_path p \<equiv> map (\<lambda>t. (snd (t_source t), t_input t, t_output t, snd (t_target t))) p"
abbreviation "zip_path p1 p2 \<equiv> (map (\<lambda> t . ((t_source (fst t), t_source (snd t)), t_input (fst t), t_output (fst t), (t_target (fst t), t_target (snd t)))) (zip p1 p2))"


lemma product_simps[simp]:
  "initial (product A B) = (initial A, initial B)"  
  "nodes (product A B) = (nodes A) \<times> (nodes B)"
  "inputs (product A B) = inputs A \<union> inputs B"
  "outputs (product A B) = outputs A \<union> outputs B"  
  by (transfer; simp)+

lemma product_transitions_def :
  "transitions (product A B) = {((qA,qB),x,y,(qA',qB')) | qA qB x y qA' qB' . (qA,x,y,qA') \<in> transitions A \<and> (qB,x,y,qB') \<in> transitions B}"
  by (transfer; simp)+

lemma product_transitions_alt_def :
  "transitions (product A B) = {((t_source tA, t_source tB),t_input tA, t_output tA, (t_target tA, t_target tB)) | tA tB . tA \<in> transitions A \<and> tB \<in> transitions B \<and> t_input tA = t_input tB \<and> t_output tA = t_output tB}"
  (is "?T1 = ?T2")
proof -
  have "\<And> t . t \<in> ?T1 \<Longrightarrow> t \<in> ?T2"
  proof -
    fix tt assume "tt \<in> ?T1"
    then obtain qA qB x y qA' qB' where "tt = ((qA,qB),x,y,(qA',qB'))" and "(qA,x,y,qA') \<in> transitions A" and "(qB,x,y,qB') \<in> transitions B"
      unfolding product_transitions_def by blast
    then have "((t_source (qA,x,y,qA'), t_source (qB,x,y,qB')),t_input (qA,x,y,qA'), t_output (qA,x,y,qA'), (t_target (qA,x,y,qA'), t_target (qB,x,y,qB'))) \<in> ?T2" 
      by auto
    then show "tt \<in> ?T2"
      unfolding \<open>tt = ((qA,qB),x,y,(qA',qB'))\<close> fst_conv snd_conv by assumption
  qed
  moreover have "\<And> t . t \<in> ?T2 \<Longrightarrow> t \<in> ?T1" 
  proof -
    fix tt assume "tt \<in> ?T2"
    then obtain tA tB where "tt = ((t_source tA, t_source tB),t_input tA, t_output tA, (t_target tA, t_target tB))" 
                        and "tA \<in> transitions A" and "tB \<in> transitions B" and "t_input tA = t_input tB" and "t_output tA = t_output tB"
      by blast
    then have "(t_source tA, t_input tA, t_output tA, t_target tA) \<in> transitions A" 
         and  "(t_source tB, t_input tA, t_output tA, t_target tB) \<in> transitions B"
      by (metis prod.collapse)+
    then show "tt \<in> ?T1"
      unfolding product_transitions_def \<open>tt = ((t_source tA, t_source tB),t_input tA, t_output tA, (t_target tA, t_target tB))\<close> by blast
  qed
  ultimately show ?thesis by blast
qed
      











lemma zip_path_last : "length xs = length ys \<Longrightarrow> (zip_path (xs @ [x]) (ys @ [y])) = (zip_path xs ys)@(zip_path [x] [y])"
  by (induction xs ys rule: list_induct2; simp)

lemma product_path_from_paths :
  assumes "path A (initial A) p1"
      and "path B (initial B) p2"
      and "p_io p1 = p_io p2"
    shows "path (product A B) (initial (product A B)) (zip_path p1 p2)"
      and "target (initial (product A B)) (zip_path p1 p2) = (target (initial A) p1, target (initial B) p2)"
proof -
  have "initial (product A B) = (initial A, initial B)" by auto
  then have "(initial A, initial B) \<in> nodes (product A B)"
    by (metis fsm_initial) 

  have "length p1 = length p2" using assms(3)
    using map_eq_imp_length_eq by blast 
  then have c: "path (product A B) (initial (product A B)) (zip_path p1 p2) \<and> target (initial (product A B)) (zip_path p1 p2) = (target (initial A) p1, target (initial B) p2)"
    using assms proof (induction p1 p2 rule: rev_induct2)
    case Nil
    
    then have "path (product A B) (initial (product A B)) (zip_path [] [])" 
      using \<open>initial (product A B) = (initial A, initial B)\<close> \<open>(initial A, initial B) \<in> nodes (product A B)\<close>
      by (metis Nil_is_map_conv path.nil zip_Nil)
    moreover have "target (initial (product A B)) (zip_path [] []) = (target (initial A) [], target (initial B) [])"
      using \<open>initial (product A B) = (initial A, initial B)\<close> by auto
    ultimately show ?case by fast
  next
    case (snoc x xs y ys)
    
    have "path A (initial A) xs" using snoc.prems(1) by auto
    moreover have "path B (initial B) ys" using snoc.prems(2) by auto
    moreover have "p_io xs = p_io ys" using snoc.prems(3) by auto
    ultimately have *:"path (product A B) (initial (product A B)) (zip_path xs ys)" 
                and **:"target (initial (product A B)) (zip_path xs ys) = (target (initial A) xs, target (initial B) ys)" 
      using snoc.IH by blast+
    then have "(target (initial A) xs, target (initial B) ys) \<in> nodes (product A B)"
      by (metis (no_types, lifting) path_target_is_node)
    then have "(t_source x, t_source y) \<in> nodes (product A B)"
      using snoc.prems(1-2)  by (metis path_cons_elim path_suffix) 

    have "x \<in> transitions A" using snoc.prems(1) by auto
    moreover have "y \<in> transitions B" using snoc.prems(2) by auto
    moreover have "t_input x = t_input y" using snoc.prems(3) by auto
    moreover have "t_output x = t_output y" using snoc.prems(3) by auto
    ultimately have "((t_source x, t_source y), t_input x, t_output x, (t_target x, t_target y)) \<in> transitions (product A B)"
      unfolding product_transitions_alt_def by blast

    
    moreover have "t_source x = target (initial A) xs" using snoc.prems(1) by auto
    moreover have "t_source y = target (initial B) ys" using snoc.prems(2) by auto
    ultimately have "((target (initial A) xs, target (initial B) ys), t_input x, t_output x, (t_target x, t_target y)) \<in> transitions (product A B)"
      using \<open>(t_source x, t_source y) \<in> nodes (product A B)\<close>
      by simp
    then have ***: "path (product A B) (initial (product A B)) ((zip_path xs ys)@[((target (initial A) xs, target (initial B) ys), t_input x, t_output x, (t_target x, t_target y))])"
      using * **
      by (metis (no_types, lifting) fst_conv path_append_transition)    

    have "t_target x = target (initial A) (xs@[x])" by auto
    moreover have "t_target y = target (initial B) (ys@[y])" by auto
    ultimately have ****: "target (initial (product A B)) ((zip_path xs ys)@[((target (initial A) xs, target (initial B) ys), t_input x, t_output x, (t_target x, t_target y))]) = (target (initial A) (xs@[x]), target (initial B) (ys@[y]))"
      by fastforce


    have "(zip_path [x] [y]) = [((target (initial A) xs, target (initial B) ys), t_input x, t_output x, (t_target x, t_target y))]"
      using \<open>t_source x = target (initial A) xs\<close> \<open>t_source y = target (initial B) ys\<close> by auto
    moreover have "(zip_path (xs @ [x]) (ys @ [y])) = (zip_path xs ys)@(zip_path [x] [y])"
      using zip_path_last[of xs ys x y, OF snoc.hyps]  by assumption
    ultimately have *****:"(zip_path (xs@[x]) (ys@[y])) = (zip_path xs ys)@[((target (initial A) xs, target (initial B) ys), t_input x, t_output x, (t_target x, t_target y))]"
      by auto
    then have "path (product A B) (initial (product A B)) (zip_path (xs@[x]) (ys@[y]))"
      using *** by presburger 
    moreover have "target (initial (product A B)) (zip_path (xs@[x]) (ys@[y])) = (target (initial A) (xs@[x]), target (initial B) (ys@[y]))"
      using **** ***** by auto
    ultimately show ?case by linarith
  qed

  from c show "path (product A B) (initial (product A B)) (zip_path p1 p2)" by auto
  from c show "target (initial (product A B)) (zip_path p1 p2) = (target (initial A) p1, target (initial B) p2)" by auto
qed


lemma paths_from_product_path :
  assumes "path (product A B) (initial (product A B)) p"
  shows   "path A (initial A) (left_path p)"
      and "path B (initial B) (right_path p)"
      and "target (initial A) (left_path p) = fst (target (initial (product A B)) p)"
      and "target (initial B) (right_path p) = snd (target (initial (product A B)) p)"
proof -
  have "path A (initial A) (left_path p)
            \<and> path B (initial B) (right_path p)
            \<and> target (initial A) (left_path p) = fst (target (initial (product A B)) p)
            \<and> target (initial B) (right_path p) = snd (target (initial (product A B)) p)"
  using assms proof (induction p rule: rev_induct)
    case Nil
    then show ?case by auto
  next
    case (snoc t p)
    then have "path (product A B) (initial (product A B)) p" by fast
    then have "path A (initial A) (left_path p)"
      and "path B (initial B) (right_path p)"
      and "target (initial A) (left_path p) = fst (target (initial (product A B)) p)"
      and "target (initial B) (right_path p) = snd (target (initial (product A B)) p)" 
      using snoc.IH  by fastforce+

    then have "t_source t = (target (initial A) (left_path p), target (initial B) (right_path p))"
      using snoc.prems by (metis (no_types, lifting) path_cons_elim path_suffix prod.collapse) 


    have ***: "target (initial A) (left_path (p@[t]))= fst (target (initial (product A B)) (p@[t]))"
      by fastforce
    have ****: "target (initial B) (right_path (p@[t]))= snd (target (initial (product A B)) (p@[t]))"
      by fastforce

    have "t \<in> transitions (product A B)" using snoc.prems by auto
    
    then have "(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> transitions A" 
      unfolding product_transitions_alt_def by force
    moreover have "target (initial A) (left_path p) = fst (t_source t)"
      using \<open>t_source t = (target (initial A) (left_path p), target (initial B) (right_path p))\<close> by auto
    ultimately have "path A (initial A) ((left_path p)@[(fst (t_source t), t_input t, t_output t, fst (t_target t))])"
      by (simp add: \<open>path A (initial A) (map (\<lambda>t. (fst (t_source t), t_input t, t_output t, fst (t_target t))) p)\<close> path_append_transition)
    then have *: "path A (initial A) (left_path (p@[t]))" by auto

    have "(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> transitions B"
      using \<open>t \<in> transitions (product A B)\<close> unfolding product_transitions_alt_def by auto
    moreover have "target (initial B) (right_path p) = snd (t_source t)"
      using \<open>t_source t = (target (initial A) (left_path p), target (initial B) (right_path p))\<close> by auto
    ultimately have "path B (initial B) ((right_path p)@[(snd (t_source t), t_input t, t_output t, snd (t_target t))])"
      by (simp add: \<open>path B (initial B) (map (\<lambda>t. (snd (t_source t), t_input t, t_output t, snd (t_target t))) p)\<close> path_append_transition)
    then have **: "path B (initial B) (right_path (p@[t]))" by auto


    show ?case using * ** *** **** by blast
  qed

  then show "path A (initial A) (left_path p)"
      and "path B (initial B) (right_path p)"
      and "target (initial A) (left_path p) = fst (target (initial (product A B)) p)"
      and "target (initial B) (right_path p) = snd (target (initial (product A B)) p)" by linarith+
qed



lemma zip_path_left_right[simp] :
  "(zip_path (left_path p) (right_path p)) = p" by (induction p; auto)

lemma product_reachable_node_paths :
  assumes "(q1,q2) \<in> reachable_nodes (product A B)" 
obtains p1 p2 
  where "path A (initial A) p1" 
  and   "path B (initial B) p2" 
  and   "target (initial A) p1 = q1" 
  and   "target (initial B) p2 = q2" 
  and   "p_io p1 = p_io p2"
  and   "path (product A B) (initial (product A B)) (zip_path p1 p2)"
  and   "target (initial (product A B)) (zip_path p1 p2) = (q1,q2)"
proof -
  let ?P = "product A B"
  from assms obtain p where "path ?P (initial ?P) p" and "target (initial ?P) p = (q1,q2)"
    unfolding reachable_nodes_def by auto
  
  have "path A (initial A) (left_path p)"
   and "path B (initial B) (right_path p)"
   and "target (initial A) (left_path p) = q1"
   and "target (initial B) (right_path p) = q2"
    using paths_from_product_path[OF \<open>path ?P (initial ?P) p\<close>] \<open>target (initial ?P) p = (q1,q2)\<close> by auto

  moreover have "p_io (left_path p) = p_io (right_path p)" by auto
  moreover have "path (product A B) (initial (product A B)) (zip_path (left_path p) (right_path p))"
    using \<open>path ?P (initial ?P) p\<close> by auto
  moreover have "target (initial (product A B)) (zip_path (left_path p) (right_path p)) = (q1,q2)"
    using \<open>target (initial ?P) p = (q1,q2)\<close> by auto
  ultimately show ?thesis using that by blast
qed




lemma product_reachable_nodes[iff] :
  "(q1,q2) \<in> reachable_nodes (product A B) \<longleftrightarrow> (\<exists> p1 p2 . path A (initial A) p1 \<and> path B (initial B) p2 \<and> target (initial A) p1 = q1 \<and> target (initial B) p2 = q2 \<and> p_io p1 = p_io p2)"
proof 
  show "(q1,q2) \<in> reachable_nodes (product A B) \<Longrightarrow> (\<exists> p1 p2 . path A (initial A) p1 \<and> path B (initial B) p2 \<and> target (initial A) p1 = q1 \<and> target (initial B) p2 = q2 \<and> p_io p1 = p_io p2)"
    using product_reachable_node_paths[of q1 q2 A B] by blast
  show "(\<exists> p1 p2 . path A (initial A) p1 \<and> path B (initial B) p2 \<and> target (initial A) p1 = q1 \<and> target (initial B) p2 = q2 \<and> p_io p1 = p_io p2) \<Longrightarrow> (q1,q2) \<in> reachable_nodes (product A B)"
  proof -
    assume "(\<exists> p1 p2 . path A (initial A) p1 \<and> path B (initial B) p2 \<and> target (initial A) p1 = q1 \<and> target (initial B) p2 = q2 \<and> p_io p1 = p_io p2)"
    then obtain p1 p2 where "path A (initial A) p1 \<and> path B (initial B) p2 \<and> target (initial A) p1 = q1 \<and> target (initial B) p2 = q2 \<and> p_io p1 = p_io p2"
      by blast
    then show ?thesis 
      using product_path_from_paths[of A p1 B p2] unfolding reachable_nodes_def
      by (metis (mono_tags, lifting) mem_Collect_eq) 
  qed
qed







lemma left_path_zip : "length p1 = length p2 \<Longrightarrow> left_path (zip_path p1 p2) = p1" 
  by (induction p1 p2 rule: list_induct2; simp)

lemma right_path_zip : "length p1 = length p2 \<Longrightarrow> p_io p1 = p_io p2 \<Longrightarrow> right_path (zip_path p1 p2) = p2" 
  by (induction p1 p2 rule: list_induct2; simp)

lemma zip_path_append_left_right : "length p1 = length p2 \<Longrightarrow> zip_path (p1@(left_path p)) (p2@(right_path p)) = (zip_path p1 p2)@p"
proof (induction p1 p2 rule: list_induct2)
  case Nil
  then show ?case by (induction p; simp)
next
  case (Cons x xs y ys)
  then show ?case by simp
qed
  
    
      

lemma product_path:
  "path (product A B) (q1,q2) p \<longleftrightarrow> (path A q1 (left_path p) \<and> path B q2 (right_path p))"
proof (induction p arbitrary: q1 q2)
  case Nil
  then show ?case by auto
next
  case (Cons t p)
  
  
  have "path (Product_FSM.product A B) (q1, q2) (t # p) \<Longrightarrow> (path A q1 (left_path (t # p)) \<and> path B q2 (right_path (t # p)))"
  proof -
    assume "path (Product_FSM.product A B) (q1, q2) (t # p)"
    then obtain x y qA' qB' where "t = ((q1,q2),x,y,(qA',qB'))" using prod.collapse
      by (metis path_cons_elim) 
    then have "((q1,q2),x,y,(qA',qB')) \<in> transitions (product A B)"
      using \<open>path (Product_FSM.product A B) (q1, q2) (t # p)\<close> by auto
    then have "(q1, x, y, qA') \<in> FSM.transitions A" and "(q2, x, y, qB') \<in> FSM.transitions B"
      unfolding product_transitions_def by blast+
    moreover have "(path A qA' (left_path p) \<and> path B qB' (right_path p))"
      using Cons.IH[of qA' qB'] \<open>path (Product_FSM.product A B) (q1, q2) (t # p)\<close> unfolding \<open>t = ((q1,q2),x,y,(qA',qB'))\<close> by auto
    ultimately show ?thesis 
      unfolding \<open>t = ((q1,q2),x,y,(qA',qB'))\<close>
      by (simp add: path_prepend_t) 
  qed

  moreover have "path A q1 (left_path (t # p)) \<Longrightarrow> path B q2 (right_path (t # p)) \<Longrightarrow> path (Product_FSM.product A B) (q1, q2) (t # p)"
  proof -
    assume "path A q1 (left_path (t # p))" and "path B q2 (right_path (t # p))"
    then obtain x y qA' qB' where "t = ((q1,q2),x,y,(qA',qB'))" using prod.collapse
      by (metis (no_types, lifting) fst_conv list.simps(9) path_cons_elim)
    then have "(q1, x, y, qA') \<in> FSM.transitions A" and "(q2, x, y, qB') \<in> FSM.transitions B"
      using \<open>path A q1 (left_path (t # p))\<close> \<open>path B q2 (right_path (t # p))\<close> by auto
    then have "((q1,q2),x,y,(qA',qB')) \<in> transitions (product A B)"
      unfolding product_transitions_def by blast
    moreover have "path (Product_FSM.product A B) (qA', qB') p"
      using Cons.IH[of qA' qB'] \<open>path A q1 (left_path (t # p))\<close> \<open>path B q2 (right_path (t # p))\<close> unfolding \<open>t = ((q1,q2),x,y,(qA',qB'))\<close> by auto
    ultimately show "path (Product_FSM.product A B) (q1, q2) (t # p)"
      unfolding \<open>t = ((q1,q2),x,y,(qA',qB'))\<close>
      by (simp add: path_prepend_t) 
  qed
      
  ultimately show ?case by force
qed


    
      












lemma product_path_rev:
  assumes "p_io p1 = p_io p2"
  shows "path (product A B) (q1,q2) (zip_path p1 p2) \<longleftrightarrow> (path A q1 p1 \<and> path B q2 p2)"
proof -
  have "length p1 = length p2" using assms
    using map_eq_imp_length_eq by blast 
  then have "(map (\<lambda> t . (fst (t_source t), t_input t, t_output t, fst (t_target t))) (map (\<lambda> t . ((t_source (fst t), t_source (snd t)), t_input (fst t), t_output (fst t), (t_target (fst t), t_target (snd t)))) (zip p1 p2))) = p1"
    by (induction p1 p2 arbitrary: q1 q2 rule: list_induct2; auto)

  moreover have "(map (\<lambda> t . (snd (t_source t), t_input t, t_output t, snd (t_target t))) (map (\<lambda> t . ((t_source (fst t), t_source (snd t)), t_input (fst t), t_output (fst t), (t_target (fst t), t_target (snd t)))) (zip p1 p2))) = p2"
    using \<open>length p1 = length p2\<close> assms by (induction p1 p2 arbitrary: q1 q2 rule: list_induct2; auto)

  ultimately show ?thesis using product_path[of A B q1 q2 "(map (\<lambda> t . ((t_source (fst t), t_source (snd t)), t_input (fst t), t_output (fst t), (t_target (fst t), t_target (snd t)))) (zip p1 p2))"]
    by auto
qed
    
    






lemma product_language_state : 
  shows "LS (product A B) (q1,q2) = LS A q1 \<inter> LS B q2"
proof 
  show "LS (product A B) (q1, q2) \<subseteq> LS A q1 \<inter> LS B q2"
  proof 
    fix io assume "io \<in> LS (product A B) (q1, q2)"
    then obtain p where "io = p_io p" 
                    and "path (product A B) (q1,q2) p"
      by auto
    then obtain p1 p2 where "path A q1 p1" 
                        and "path B q2 p2"
                        and "io = p_io p1" 
                        and "io = p_io p2"
      using product_path[of A B q1 q2 p] by fastforce
    then show "io \<in> LS A q1 \<inter> LS B q2" 
      unfolding LS.simps by blast
  qed

  show "LS A q1 \<inter> LS B q2 \<subseteq> LS (product A B) (q1, q2)"
  proof
    fix io assume "io \<in> LS A q1 \<inter> LS B q2"
    then obtain p1 p2 where "path A q1 p1" 
                        and "path B q2 p2"
                        and "io = p_io p1" 
                        and "io = p_io p2"
                        and "p_io p1 = p_io p2"
      by auto

    let ?p = "zip_path p1 p2"
    
    
    have "length p1 = length p2"
      using \<open>p_io p1 = p_io p2\<close> map_eq_imp_length_eq by blast 
    moreover have "p_io ?p = p_io (map fst (zip p1 p2))" by auto
    ultimately have "p_io ?p = p_io p1" by auto

    then have "p_io ?p = io" 
      using \<open>io = p_io p1\<close> by auto
    moreover have "path (product A B) (q1, q2) ?p"
      using product_path_rev[OF \<open>p_io p1 = p_io p2\<close>, of A B q1 q2] \<open>path A q1 p1\<close> \<open>path B q2 p2\<close> by auto
    ultimately show "io \<in> LS (product A B) (q1, q2)" 
      unfolding LS.simps by blast
  qed
qed


lemma product_language : "L (product A B) = L A \<inter> L B"
  unfolding product_simps product_language_state by blast


(* TODO: omit? *)
lemma product_transition_split_ob :
  assumes "t \<in> transitions (product A B)"
  obtains t1 t2 
  where "t1 \<in> transitions A \<and> t_source t1 = fst (t_source t) \<and> t_input t1 = t_input t \<and> t_output t1 = t_output t \<and> t_target t1 = fst (t_target t)"
    and "t2 \<in> transitions B \<and> t_source t2 = snd (t_source t) \<and> t_input t2 = t_input t \<and> t_output t2 = t_output t \<and> t_target t2 = snd (t_target t)"      
  using assms unfolding product_transitions_alt_def
  by auto 


(* TODO: omit? *)
lemma product_transition_split :
  assumes "t \<in> transitions (product A B)"
  shows "(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> transitions A"
    and "(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> transitions B"      
  using product_transition_split_ob[OF assms] prod.collapse by fastforce+



subsection \<open>Other Lemmata\<close>

lemma  product_target_split:
  assumes "target (q1,q2) p = (q1',q2')"
  shows "target q1 (left_path p) = q1'"
    and "target q2 (right_path p) = q2'"
using assms by (induction p arbitrary: q1 q2; force)+


lemma product_from_reachable_next : 
  assumes "((q1,q2),x,y,(q1',q2')) \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
  and     "q1 \<in> reachable_nodes M"
  and     "q2 \<in> reachable_nodes M"
  shows   "(product (from_FSM M q1') (from_FSM M q2')) = (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2'))" 
          (is "?P1 = ?P2")
proof -
  have "q1 \<in> nodes (from_FSM M q1)" and "q2 \<in> nodes (from_FSM M q2)" and "q1' \<in> nodes (from_FSM M q1)" and "q2' \<in> nodes (from_FSM M q2)"
    using fsm_transition_target[OF assms] fsm_transition_source[OF assms] unfolding fst_conv snd_conv product_simps by auto

  have "initial ?P1 = initial ?P2"
    using from_FSM_simps(1)[OF fsm_transition_target[OF assms]] 
    unfolding snd_conv 
    unfolding product_simps  

end (*

lemma product_from_next :
  assumes "((q1,q2),x,y,(q1',q2')) \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
  shows "transitions (product (from_FSM M q1') (from_FSM M q2')) = transitions (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2'))"
  using fsm_transition_target[OF assms] unfolding snd_conv 
  using from_FSM_simps(4)[OF ]
proof -
  

  have "q1 \<in> nodes (from_FSM M q1)" and "q2 \<in> nodes (from_FSM M q2)" and "q1' \<in> nodes (from_FSM M q1)" and "q2' \<in> nodes (from_FSM M q2)"
    using fsm_transition_target[OF assms] fsm_transition_source[OF assms] unfolding fst_conv snd_conv product_simps by auto
  
end (*
proof -
  let ?t = "((q1,q2),x,y,(q1',q2'))"


  have "(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
    using wf_transition_target[OF assms] by simp
  then have "q1' \<in> nodes (from_FSM M q1)" and "q2' \<in> nodes (from_FSM M q2)"
    using product_nodes[of "from_FSM M q1" "from_FSM M q2"] by blast+

  have "(q1,x,y,q1') \<in> transitions (from_FSM M q1)" and "(q2,x,y,q2') \<in> transitions (from_FSM M q2)"
    using product_transition_split[OF assms] by auto

  have s1 : "initial (product (from_FSM M q1') (from_FSM M q2')) = (q1',q2')"
    by auto
  have s2 : "initial (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) = (q1',q2')"
    by auto


  have *: "\<And> p . path (product (from_FSM M q1') (from_FSM M q2')) (q1',q2') p = path (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) (q1',q2') p"
  proof -
    fix p show "path (product (from_FSM M q1') (from_FSM M q2')) (q1',q2') p = path (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) (q1',q2') p"
    proof  
      show "path (product (from_FSM M q1') (from_FSM M q2')) (q1', q2') p \<Longrightarrow>
              path (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) (q1', q2') p"
      proof -
        assume "path (product (from_FSM M q1') (from_FSM M q2')) (q1', q2') p"
        then have "path (from_FSM M q1') q1' (left_path p)" and "path (from_FSM M q2') q2' (right_path p)"
          using product_path[of "from_FSM M q1'" "from_FSM M q2'" q1' q2' p] by linarith+

        have "path (from_FSM M q1) q1' (left_path p)"
          using from_FSM_path[OF \<open>q1' \<in> nodes (from_FSM M q1)\<close>, of q1' "left_path p"] \<open>path (from_FSM M q1') q1' (left_path p)\<close> by auto
        have "path (from_FSM M q2) q2' (right_path p)"
          using from_FSM_path[OF \<open>q2' \<in> nodes (from_FSM M q2)\<close>, of q2' "right_path p"] \<open>path (from_FSM M q2') q2' (right_path p)\<close> by auto

        have p3: "(\<exists>p1 p2.
                         path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
                         path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
                         target p1 (initial (from_FSM M q1)) = q1' \<and>
                         target p2 (initial (from_FSM M q2)) = q2' \<and> p_io p1 = p_io p2)" 
        proof -
          have "path (from_FSM M q1) (initial (from_FSM M q1)) [(q1, x, y, q1')]"
            using single_transitions_path[OF \<open>(q1,x,y,q1') \<in> transitions (from_FSM M q1)\<close>] by auto
          moreover have "path (from_FSM M q2) (initial (from_FSM M q2)) [(q2, x, y, q2')]"
            using single_transitions_path[OF \<open>(q2,x,y,q2') \<in> transitions (from_FSM M q2)\<close>] by auto
          moreover have "(target [(q1,x,y,q1')] (initial (from_FSM M q1)) = q1' \<and>
                          target [(q2,x,y,q2')] (initial (from_FSM M q2)) = q2' \<and> 
                          p_io [(q1,x,y,q1')] = p_io [(q2,x,y,q2')])" 
            by auto
          ultimately show ?thesis by meson
        qed
        
        have "path (product (from_FSM M q1) (from_FSM M q2)) (q1',q2') p"
          using product_path[of "from_FSM M q1" "from_FSM M q2" q1' q2' p] \<open>path (from_FSM M q1) q1' (left_path p)\<close> \<open>path (from_FSM M q2) q2' (right_path p)\<close> p3 by presburger

        then show "path (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) (q1',q2') p"
          using from_FSM_path_rev_initial by metis
      qed
      show "path (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) (q1', q2') p \<Longrightarrow>
              path (product (from_FSM M q1') (from_FSM M q2')) (q1', q2') p"
      proof -
        assume "path (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) (q1', q2') p"
        then have "path (product (from_FSM M q1) (from_FSM M q2)) (q1',q2') p"
          using from_FSM_path[OF \<open>(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))\<close>] by metis
        then have "path (from_FSM M q1) q1' (left_path p)" 
              and "path (from_FSM M q2) q2' (right_path p)"
              and "(\<exists>p1 p2.
                     path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
                     path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
                     target p1 (initial (from_FSM M q1)) = q1' \<and>
                     target p2 (initial (from_FSM M q2)) = q2' \<and> p_io p1 = p_io p2)"
          using product_path[of "from_FSM M q1" "from_FSM M q2" q1' q2' p] by presburger+

        have "path (from_FSM M q1') q1' (left_path p)"
          using from_FSM_path_rev_initial[OF \<open>path (from_FSM M q1) q1' (left_path p)\<close>] by auto
        moreover have "path (from_FSM M q2') q2' (right_path p)"
          using from_FSM_path_rev_initial[OF \<open>path (from_FSM M q2) q2' (right_path p)\<close>] by auto
        moreover have p3: "(\<exists>p1 p2.
                         path (from_FSM M q1') (initial (from_FSM M q1')) p1 \<and>
                         path (from_FSM M q2') (initial (from_FSM M q2')) p2 \<and>
                         target p1 (initial (from_FSM M q1')) = q1' \<and>
                         target p2 (initial (from_FSM M q2')) = q2' \<and> p_io p1 = p_io p2)" 
        proof -
          have "path (from_FSM M q1') (initial (from_FSM M q1')) []" 
            using path.nil[OF nodes.initial] by metis
          moreover have "path (from_FSM M q2') (initial (from_FSM M q2')) []"
            using path.nil[OF nodes.initial] by metis
          moreover have "(target [] (initial (from_FSM M q1')) = q1' \<and>
                          target [] (initial (from_FSM M q2')) = q2' \<and> 
                          p_io [] = p_io [])" 
            by auto
          ultimately show ?thesis by blast
        qed
        
        ultimately show " path (product (from_FSM M q1') (from_FSM M q2')) (q1', q2') p"
          using product_path[of "from_FSM M q1'" "from_FSM M q2'" q1' q2' p] by presburger        
      qed
    qed
  qed

  show ?thesis using * h_from_paths s1 s2 by metis
qed
   

end (* lemma submachine_transition_product_from :
  assumes "is_submachine S (product (from_FSM M q1) (from_FSM M q2))"
      and "((q1,q2),x,y,(q1',q2')) \<in> transitions S"
 shows "is_submachine (from_FSM S (q1',q2')) (product (from_FSM M q1') (from_FSM M q2'))"
proof -
  have "((q1,q2),x,y,(q1',q2')) \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
    using submachine_h[OF assms(1)] assms(2) by blast
  have "(q1',q2') \<in> nodes S" using wf_transition_target[OF assms(2)] by auto 
  show ?thesis 
    using product_from_next[OF \<open>((q1,q2),x,y,(q1',q2')) \<in> transitions (product (from_FSM M q1) (from_FSM M q2))\<close>]
          submachine_from[OF assms(1) \<open>(q1',q2') \<in> nodes S\<close>]
  proof -
    have "initial (from_FSM S (q1', q2')) = initial (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) \<and> set (wf_transitions (from_FSM S (q1', q2'))) \<subseteq> set (wf_transitions (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2'))) \<and> inputs (from_FSM S (q1', q2')) = inputs (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')) \<and> outputs (from_FSM S (q1', q2')) = outputs (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2'))"
      using \<open>is_submachine (from_FSM S (q1', q2')) (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2'))\<close> is_submachine.simps by blast
    then show ?thesis
      by (metis (no_types) \<open>set (wf_transitions (product (from_FSM M q1') (from_FSM M q2'))) = set (wf_transitions (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1', q2')))\<close> from_FSM_simps(1) from_FSM_simps(2) from_FSM_simps(3) is_submachine.simps product_simps(1) product_simps(2) product_simps(3))
  qed
qed

end (* lemma submachine_transition_complete_product_from :
  assumes "is_submachine S (product (from_FSM M q1) (from_FSM M q2))"
      and "completely_specified S"
      and "((q1,q2),x,y,(q1',q2')) \<in> transitions S"
 shows "completely_specified (from_FSM S (q1',q2'))"
proof -
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"
  let ?P' = "(product (from_FSM M q1') (from_FSM M q2'))"
  let ?F = "(from_FSM S (q1',q2'))"  
  
  have "initial ?P = (q1,q2)"
    by auto
  then have "initial S = (q1,q2)" 
    using assms(1) by (metis is_submachine.simps) 
  then have "(q1',q2') \<in> nodes S"
    using assms(3)
    using wf_transition_target by fastforce 
  then have "nodes ?F \<subseteq> nodes S"
    using from_FSM_nodes by metis
  moreover have "inputs ?F = inputs S"
    by auto
  ultimately show "completely_specified ?F" 
    using assms(2) unfolding completely_specified.simps
    using from_FSM_nodes_transitions[of _ S "(q1',q2')"]
    using contra_subsetD by fastforce
qed


end (* lemma from_FSM_product_inputs :
  "set (inputs (product (from_FSM M q1) (from_FSM M q2))) = set (inputs M)"
  unfolding product.simps from_FSM.simps by auto

end (* lemma from_FSM_product_outputs :
  "set (outputs (product (from_FSM M q1) (from_FSM M q2))) = set (outputs M)"
  unfolding product.simps from_FSM.simps by auto

end (* lemma from_FSM_product_initial : 
  "initial (product (from_FSM M q1) (from_FSM M q2)) = (q1,q2)" by auto



end (* lemma product_from_next' :
  assumes "t \<in> transitions (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))"
    shows "h (from_FSM (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (fst (t_target t),snd (t_target t))) = h (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t))))"
proof -
  have "t = ((fst (t_source t),snd (t_source t)),t_input t, t_output t,(fst (t_target t),snd (t_target t)))"
    by (metis prod.collapse)
  then have *: "((fst (t_source t),snd (t_source t)),t_input t, t_output t,(fst (t_target t),snd (t_target t))) \<in> transitions (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))"
    using assms by presburger
  
  show ?thesis using product_from_next[OF *] by blast
qed



end (* lemma product_from_next'_path :
  assumes "t \<in> transitions (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t))))"
  shows "path (from_FSM (product (from_FSM M (fst (t_source t))) (from_FSM M (snd (t_source t)))) (fst (t_target t),snd (t_target t))) (fst (t_target t),snd (t_target t)) p = path (product (from_FSM M (fst (t_target t))) (from_FSM M (snd (t_target t)))) (fst (t_target t),snd (t_target t)) p" 
    (is "path ?P1 ?q p = path ?P2 ?q p")
proof -
  have i1: "initial ?P1 = ?q" by auto
  have i2: "initial ?P2 = ?q" by auto
  have h12: "h ?P1 = h ?P2" using product_from_next'[OF assms] by assumption
  
  show ?thesis proof (induction p rule: rev_induct)
    case Nil
    then show ?case
      by (metis (full_types) i1 i2 nodes.initial path.nil)
  next
    case (snoc t p)
    show ?case by (meson h12 h_equivalence_path path_begin_node path_prefix snoc.IH)
  qed
qed


end (* lemma product_from_transition_subset:
  assumes "(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))" 
  shows "h (product (from_FSM M q1') (from_FSM M q2')) \<subseteq> h (product (from_FSM M q1) (from_FSM M q2))" (is "h ?P' \<subseteq> h ?P")
proof 
  fix t assume "t \<in> transitions ?P'"
  then have "t_source t \<in> nodes ?P'" by (metis wf_transition_simp)
  then obtain p' where "path ?P' (initial ?P') p'" and "target p' (initial ?P') = t_source t"
    by (metis path_to_node)

  have "path (from_FSM M q1') q1' (left_path p')"
       "path (from_FSM M q2') q2' (right_path p')"
       "(\<exists>p1 p2.
           path (from_FSM M q1') (initial (from_FSM M q1')) p1 \<and>
           path (from_FSM M q2') (initial (from_FSM M q2')) p2 \<and>
           target p1 (initial (from_FSM M q1')) = q1' \<and> target p2 (initial (from_FSM M q2')) = q2' \<and> p_io p1 = p_io p2)"
    using product_path[of "from_FSM M q1'" "from_FSM M q2'" q1' q2' p'] \<open>path ?P' (initial ?P') p'\<close> by auto
  
  have          "(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> set (wf_transitions (from_FSM M q1'))"
       and      "(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> set (wf_transitions (from_FSM M q2'))"
       and p'': "(\<exists>p1 p2.
                   path (from_FSM M q1') (initial (from_FSM M q1')) p1 \<and>
                   path (from_FSM M q2') (initial (from_FSM M q2')) p2 \<and>
                   target p1 (initial (from_FSM M q1')) = fst (t_source t) \<and>
             target p2 (initial (from_FSM M q2')) = snd (t_source t) \<and> p_io p1 = p_io p2)"
    using product_transition_t[of t "from_FSM M q1'" "from_FSM M q2'"] \<open>t \<in> transitions ?P'\<close> by presburger+



  obtain p where "path ?P (initial ?P) p" and "target p (initial ?P) = (q1',q2')"
    by (metis assms path_to_node)
  have "path (from_FSM M q1) q1 (left_path p)"
       "path (from_FSM M q2) q2 (right_path p)"
       "(\<exists>p1 p2.
           path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
           path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
           target p1 (initial (from_FSM M q1)) = q1 \<and> target p2 (initial (from_FSM M q2)) = q2 \<and> p_io p1 = p_io p2)"
    using product_path[of "from_FSM M q1" "from_FSM M q2" q1 q2 p] \<open>path ?P (initial ?P) p\<close> by auto

  have "target q1 (left_path p) = q1'" and "target q2 (right_path p) = q2'"
    using product_target_split[of p q1 q2 q1' q2'] \<open>target p (initial ?P) = (q1',q2')\<close> by auto

  have "q1' \<in> nodes (from_FSM M q1)"
    using path_target_is_node[OF \<open>path (from_FSM M q1) q1 (left_path p)\<close>] \<open>target q1 (left_path p) = q1'\<close> by metis
  have "h (from_FSM M q1') \<subseteq> h (from_FSM M q1)"
    using from_FSM_h[OF \<open>q1' \<in> nodes (from_FSM M q1)\<close>] by simp
  then have *: "(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> transitions (from_FSM M q1)"
    using \<open>(fst (t_source t), t_input t, t_output t, fst (t_target t)) \<in> transitions (from_FSM M q1')\<close> by blast

  have "q2' \<in> nodes (from_FSM M q2)"
    using path_target_is_node[OF \<open>path (from_FSM M q2) q2 (right_path p)\<close>] \<open>target q2 (right_path p) = q2'\<close> by metis
  have "h (from_FSM M q2') \<subseteq> h (from_FSM M q2)"
    using from_FSM_h[OF \<open>q2' \<in> nodes (from_FSM M q2)\<close>] by simp
  then have **: "(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> transitions (from_FSM M q2)"
    using \<open>(snd (t_source t), t_input t, t_output t, snd (t_target t)) \<in> transitions (from_FSM M q2')\<close> by blast

  have ***: "(\<exists>p1 p2.
               path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
               path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
               target p1 (initial (from_FSM M q1)) = fst (t_source t) \<and>
               target p2 (initial (from_FSM M q2)) = snd (t_source t) \<and> p_io p1 = p_io p2)"
  proof -
    obtain p1' p2' where "path (from_FSM M q1') q1' p1'"
                     and "path (from_FSM M q2') q2' p2'"
                     and "target p1' q1' = fst (t_source t)"
                     and "target p2' q2' = snd (t_source t)" 
                     and "p_io p1' = p_io p2'"
      using p'' by auto

    have "path (from_FSM M q1) q1' p1'"
      using from_FSM_path \<open>q1' \<in> nodes (from_FSM M q1)\<close> \<open>path (from_FSM M q1') q1' p1'\<close> by (metis from_from)
    have "path (from_FSM M q2) q2' p2'"
      using from_FSM_path \<open>q2' \<in> nodes (from_FSM M q2)\<close> \<open>path (from_FSM M q2') q2' p2'\<close> by (metis from_from)

    have "path (from_FSM M q1) (initial (from_FSM M q1)) ((left_path p)@p1')" 
      using path_append[OF \<open>path (from_FSM M q1) q1 (left_path p)\<close>, of p1']  \<open>target q1 (left_path p) = q1'\<close> \<open>path (from_FSM M q1) q1' p1'\<close> by auto
    moreover have "path (from_FSM M q2) (initial (from_FSM M q2)) ((right_path p)@p2')" 
      using path_append[OF \<open>path (from_FSM M q2) q2 (right_path p)\<close>, of p2']  \<open>target q2 (right_path p) = q2'\<close> \<open>path (from_FSM M q2) q2' p2'\<close> by auto
    moreover have "target ((left_path p)@p1') (initial (from_FSM M q1)) = fst (t_source t)"
      using path_target_append[OF \<open>target q1 (left_path p) = q1'\<close> \<open>target p1' q1' = fst (t_source t)\<close>] by auto
    moreover have "target ((right_path p)@p2') (initial (from_FSM M q2)) = snd (t_source t)"
      using path_target_append[OF \<open>target q2 (right_path p) = q2'\<close> \<open>target p2' q2' = snd (t_source t)\<close>] by auto
    moreover have "p_io ((left_path p)@p1') = p_io ((right_path p)@p2')"
      using \<open>p_io p1' = p_io p2'\<close> by auto
    ultimately show ?thesis by blast
  qed

  show "t \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
    using product_transition_t[of t "from_FSM M q1" "from_FSM M q2"] * ** *** by blast
qed



end (* lemma product_from_path:
  assumes "(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))" 
      and "path (product (from_FSM M q1') (from_FSM M q2')) (q1',q2') p" 
    shows "path (product (from_FSM M q1) (from_FSM M q2)) (q1',q2') p"
using h_subset_path[OF product_from_transition_subset[OF assms(1)] assms(2) assms(1)] by assumption


end (* lemma product_from_path_previous :
  assumes "path (product (from_FSM M (fst (t_target t))) 
                         (from_FSM M (snd (t_target t))))
                (t_target t) p"                                           (is "path ?Pt (t_target t) p")
      and "t \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
    shows "path (product (from_FSM M q1) (from_FSM M q2)) (t_target t) p" (is "path ?P (t_target t) p")
proof -
  have *: "(t_target t) \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
    using wf_transition_target[OF assms(2)] by (metis)
  then have **: "(fst (t_target t), snd (t_target t)) \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
    by (metis prod.collapse)
  have ***: "h ?Pt \<subseteq> h ?P" 
    using product_from_transition_subset[OF **] by assumption
  show ?thesis
    using h_subset_path[OF *** assms(1) *] by assumption
qed


end (* lemma product_from_transition_shared_node :
  assumes "t \<in> transitions (product (from_FSM M q1') (from_FSM M q2'))"
  and  "(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))" 
shows "t \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
  by (meson assms(1) assms(2) contra_subsetD product_from_transition_subset)

    

end (* lemma product_from_not_completely_specified :
  assumes "\<not> completely_specified_state (product (from_FSM M q1) (from_FSM M q2)) (q1',q2')"
      and "(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
    shows  "\<not> completely_specified_state (product (from_FSM M q1') (from_FSM M q2')) (q1',q2')"
  using assms(1) assms(2) from_FSM_product_inputs[of M q1 q2] from_FSM_product_inputs[of M q1' q2'] product_from_transition_shared_node[OF _ assms(2)] 
  unfolding completely_specified_state.simps by metis

end (* lemma from_product_initial_paths_ex :
  "(\<exists>p1 p2.
         path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
         path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
         target p1 (initial (from_FSM M q1)) = q1 \<and>
         target p2 (initial (from_FSM M q2)) = q2 \<and> p_io p1 = p_io p2)"
proof -
  have "path (from_FSM M q1) (initial (from_FSM M q1)) []" by blast
  moreover have "path (from_FSM M q2) (initial (from_FSM M q2)) []" by blast
  moreover have "
         target [] (initial (from_FSM M q1)) = q1 \<and>
         target [] (initial (from_FSM M q2)) = q2 \<and> p_io [] = p_io []" by auto
  ultimately show ?thesis by blast
qed

(* TODO: move *)
end (* lemma product_observable :
  assumes "observable M1"
  and     "observable M2"
shows "observable (product M1 M2)" (is "observable ?P")
proof -
  have "\<And> t1 t2 . t1 \<in> transitions ?P \<Longrightarrow> t2 \<in> transitions ?P \<Longrightarrow> t_source t1 = t_source t2 \<Longrightarrow> t_input t1 = t_input t2 \<Longrightarrow> t_output t1 = t_output t2 \<Longrightarrow> t_target t1 = t_target t2"
  proof -
    fix t1 t2 assume "t1 \<in> transitions ?P" and "t2 \<in> transitions ?P" and "t_source t1 = t_source t2" and "t_input t1 = t_input t2" and "t_output t1 = t_output t2"

    let ?t1L = "(fst (t_source t1), t_input t1, t_output t1, fst (t_target t1))"
    let ?t1R = "(snd (t_source t1), t_input t1, t_output t1, snd (t_target t1))"
    let ?t2L = "(fst (t_source t2), t_input t2, t_output t2, fst (t_target t2))"
    let ?t2R = "(snd (t_source t2), t_input t2, t_output t2, snd (t_target t2))"

    have "t_target ?t1L = t_target ?t2L"
      using product_transition_split(1)[OF \<open>t1 \<in> transitions ?P\<close>]
            product_transition_split(1)[OF \<open>t2 \<in> transitions ?P\<close>]
            \<open>observable M1\<close> 
            \<open>t_source t1 = t_source t2\<close>
            \<open>t_input t1 = t_input t2\<close>
            \<open>t_output t1 = t_output t2\<close> by auto
    moreover have "t_target ?t1R = t_target ?t2R"
      using product_transition_split(2)[OF \<open>t1 \<in> transitions ?P\<close>]
            product_transition_split(2)[OF \<open>t2 \<in> transitions ?P\<close>]
            \<open>observable M2\<close> 
            \<open>t_source t1 = t_source t2\<close>
            \<open>t_input t1 = t_input t2\<close>
            \<open>t_output t1 = t_output t2\<close> by auto
    ultimately show "t_target t1 = t_target t2"
      by (metis prod.exhaust_sel snd_conv) 
  qed
  then show ?thesis unfolding observable.simps by blast
qed


end (* lemma product_observable_self_transitions :
  assumes "q \<in> nodes (product M M)"
  and     "observable M"
shows "fst q = snd q"
proof -
  let ?P = "product M M"
  

  have "\<And> p . path ?P (initial ?P) p \<Longrightarrow> fst (target p (initial ?P)) = snd (target p (initial ?P))"
  proof -
    fix p assume "path ?P (initial ?P) p"
    then show "fst (target p (initial ?P)) = snd (target p (initial ?P))"
    proof (induction p rule: rev_induct)
      case Nil
      then show ?case
        by (metis append.right_neutral path_append_target path_nil_elim path_to_node product_simps(1) snd_swap swap_simp) 
    next
      case (snoc t p)

      have "path ?P (initial ?P) p" and "path ?P (target p (initial ?P)) [t]"
        using path_append_elim[of ?P "initial ?P" p "[t]", OF \<open>path (product M M) (initial (product M M)) (p @ [t])\<close>] by blast+
      then have "t \<in> transitions ?P" 
        by blast
      have "t_source t = target p (initial ?P)"
        by (metis \<open>path (product M M) (target p (initial (product M M))) [t]\<close> list.distinct(1) list.sel(1) path.simps)
        
      let ?t1 = "(fst (t_source t), t_input t, t_output t, fst (t_target t))"
      let ?t2 = "(snd (t_source t), t_input t, t_output t, snd (t_target t))"
      have "?t1 \<in> transitions M" and "?t2 \<in> transitions M"
        using product_transition_split[OF \<open>t \<in> transitions ?P\<close>] by auto
      moreover have "t_source ?t1 = t_source ?t2" 
        using \<open>t_source t = target p (initial ?P)\<close> snoc.IH[OF \<open>path ?P (initial ?P) p\<close>]
        by (metis fst_conv)
      moreover have "t_input ?t1 = t_input ?t2"
        by auto
      moreover have "t_output ?t1 = t_output ?t2"
        by auto
      ultimately have "t_target ?t1 = t_target ?t2"
        using \<open>observable M\<close> unfolding observable.simps by blast
      then have "fst (t_target t) = snd (t_target t)"
        by auto
      then show ?case unfolding target.simps visited_states.simps
      proof -
        show "fst (last (initial (product M M) # map t_target (p @ [t]))) = snd (last (initial (product M M) # map t_target (p @ [t])))"
          using \<open>fst (t_target t) = snd (t_target t)\<close> last_map last_snoc length_append_singleton length_map by force
      qed
    qed
  qed

  then show ?thesis
    by (metis assms(1) path_to_node)
qed

end (* lemma zip_path_eq_left :
  assumes "length xs1 = length xs2"
  and     "length xs2 = length ys1"
  and     "length ys1 = length ys2"
  and     "zip_path xs1 xs2 = zip_path ys1 ys2"
shows "xs1 = ys1"
  using assms by (induction xs1 xs2 ys1 ys2 rule: list_induct4; auto)



end (* lemma zip_path_eq_right :
  assumes "length xs1 = length xs2"
  and     "length xs2 = length ys1"
  and     "length ys1 = length ys2"
  and     "p_io xs2 = p_io ys2"
  and     "zip_path xs1 xs2 = zip_path ys1 ys2"
shows "xs2 = ys2"
  using assms by (induction xs1 xs2 ys1 ys2 rule: list_induct4; auto)


(* TODO: check *)
declare from_FSM.simps[simp del]
declare product.simps[simp del]
declare from_FSM_simps[simp del]
declare product_simps[simp del]


end (* lemma zip_path_merge :
  "(zip_path (left_path p) (right_path p)) = p"
  by (induction p; auto)

end (* lemma product_from_path' :
  assumes "path (product (from_FSM M q1) (from_FSM M q2)) (q1', q2') p"
shows "path (product (from_FSM M q1') (from_FSM M q2')) (q1', q2') p"
  using assms proof (induction p rule: rev_induct)
  case Nil
  show ?case using product_simps(1) from_FSM_simps(1) nodes.initial
    by (metis nil)
next
  case (snoc t p)

  let ?P' = "(product (from_FSM M q1') (from_FSM M q2'))"

  have "path (from_FSM M q1) q1' (left_path (p@[t]))" 
       "path (from_FSM M q2) q2' (right_path (p@[t]))" 
    using snoc.prems product_path[of "(from_FSM M q1)" "(from_FSM M q2)" q1' q2' "p@[t]"] by simp+

  have "path (from_FSM M q1') (initial (from_FSM M q1'))  (left_path (p@[t]))"
    using from_FSM_path_rev_initial[OF \<open>path (from_FSM M q1) q1' (left_path (p@[t]))\<close>] by (simp add: from_FSM_simps)
  moreover have "path (from_FSM M q2') (initial (from_FSM M q2')) (right_path (p@[t]))"
    using from_FSM_path_rev_initial[OF \<open>path (from_FSM M q2) q2' (right_path (p@[t]))\<close>] by (simp add: from_FSM_simps)
  moreover have "p_io (left_path (p@[t])) = p_io (right_path (p@[t]))"
    by auto
  ultimately have "path ?P' (initial ?P') (zip_path (left_path (p@[t])) (right_path (p@[t])))"
    using product_path_from_paths(1) by blast
  then show "path ?P' (q1',q2') (p@[t])"
    by (simp add: product_simps(1) from_FSM_simps(1) zip_path_merge)
qed
    


end (* lemma from_product_from_h :
  assumes "(q1',q2') \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
shows "h (product (from_FSM M q1') (from_FSM M q2')) = h (from_FSM (product (from_FSM M q1) (from_FSM M q2)) (q1',q2'))" 
      (is "h ?P' = h ?Pf")
proof -
  let ?P = "(product (from_FSM M q1) (from_FSM M q2))"

  have "\<And> t . t \<in> transitions ?P' \<Longrightarrow> t \<in> transitions ?Pf"
  proof -
    fix t assume "t \<in> transitions ?P'"
    then have "t_source t \<in> nodes ?P'" by auto
    then obtain p where "path ?P' (q1',q2') p" and "target p (q1',q2') = t_source t"
      using product_simps(1) from_FSM_simps(1)
      by (metis path_to_node) 
    then have "path ?P' (q1',q2') (p@[t])"
      using \<open>t \<in> transitions ?P'\<close> \<open>t_source t \<in> nodes ?P'\<close> by auto
    then have "path ?P (q1',q2') (p@[t])" 
      using product_from_path[OF assms] by auto 
    then have "path ?Pf (q1',q2') (p@[t])"
      by (simp add: from_FSM_path_rev_initial)  
    then show "t \<in> transitions ?Pf"
      by auto
  qed
  moreover have "\<And> t . t \<in> transitions ?Pf \<Longrightarrow> t \<in> transitions ?P'"
  proof -
    fix t assume "t \<in> transitions ?Pf"
    then have "t_source t \<in> nodes ?Pf" by auto
    then obtain p where "path ?Pf (q1',q2') p" and "target p (q1',q2') = t_source t"
      using from_FSM_simps(1)
      by (metis path_to_node) 
    then have "path ?Pf (q1',q2') (p@[t])"
      using \<open>t \<in> transitions ?Pf\<close> \<open>t_source t \<in> nodes ?Pf\<close> by auto
    then have "path ?P (q1',q2') (p@[t])"
      by (meson assms from_FSM_path) 
    then have "path ?P' (q1',q2') (p@[t])"
      using product_from_path' by metis
    then show "t \<in> transitions ?P'"
      by auto
  qed
  ultimately show ?thesis by blast
qed 




end (* lemma product_deadlock :
  assumes "\<not> (\<exists> t \<in> transitions (product (from_FSM M q1) (from_FSM M q2)).
               t_source t = qq \<and> t_input t = x)"
  and "qq \<in> nodes (product (from_FSM M q1) (from_FSM M q2))"
  and "x \<in> set (inputs M)"
shows "\<not> (\<exists> t1 \<in> transitions M. \<exists> t2 \<in> transitions M.
                 t_source t1 = fst qq \<and>
                 t_source t2 = snd qq \<and>
                 t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2)" 
proof 
  assume "\<exists> t1 \<in> transitions M. \<exists> t2 \<in> transitions M.
                 t_source t1 = fst qq \<and>
                 t_source t2 = snd qq \<and>
                 t_input t1 = x \<and> t_input t2 = x \<and> t_output t1 = t_output t2"
  then obtain t1 t2 where "t1 \<in> transitions M"
                      and "t2 \<in> transitions M"
                      and "t_source t1 = fst qq"
                      and "t_source t2 = snd qq"
                      and "t_input t1 = x"
                      and "t_input t2 = x" 
                      and "t_output t1 = t_output t2"
    by blast

  have "fst qq \<in> nodes (from_FSM M q1)" and "snd qq \<in> nodes (from_FSM M q2)"
    using product_nodes assms(2)
    by fastforce+

 
  have "t_source t1 \<in> nodes (from_FSM M q1)"
    using \<open>fst qq \<in> nodes (from_FSM M q1)\<close> \<open>t_source t1 = fst qq\<close> by simp
  then have *: "(fst qq, x, t_output t1, t_target t1) \<in> transitions (from_FSM M q1)"
    using from_FSM_nodes_transitions[OF \<open>t1 \<in> transitions M\<close>] \<open>t_input t1 = x\<close> \<open>t_source t1 = fst qq\<close>
    by (metis prod.collapse) 

  have "t_source t2 \<in> nodes (from_FSM M q2)"
    using \<open>snd qq \<in> nodes (from_FSM M q2)\<close> \<open>t_source t2 = snd qq\<close> by simp
  have **: "(snd qq, x, t_output t1, t_target t2) \<in> transitions (from_FSM M q2)"
    using from_FSM_nodes_transitions[OF \<open>t2 \<in> transitions M\<close> \<open>t_source t2 \<in> nodes (from_FSM M q2)\<close>] \<open>t_source t2 = snd qq\<close> \<open>t_input t1 = x\<close> \<open>t_input t2 = x\<close> \<open>t_source t2 = snd qq\<close> \<open>t_output t1 = t_output t2\<close> 
    by (metis prod.collapse)

  have ***: "(\<exists>p1 p2.
        path (from_FSM M q1) (initial (from_FSM M q1)) p1 \<and>
        path (from_FSM M q2) (initial (from_FSM M q2)) p2 \<and>
        target p1 (initial (from_FSM M q1)) = fst qq \<and>
        target p2 (initial (from_FSM M q2)) = snd qq \<and> p_io p1 = p_io p2)"
    using assms(2) product_node_from_path[of "fst qq" "snd qq" "from_FSM M q1" "from_FSM M q2"]
          prod.collapse[of qq] 
    by auto
  
  have "(qq, x, t_output t1, (t_target t1, t_target t2)) \<in> transitions (product (from_FSM M q1) (from_FSM M q2))"
    using product_transition[of "fst qq" "snd qq" "x" "t_output t1" "t_target t1" "t_target t2" "from_FSM M q1" "from_FSM M q2"]
    using * ** *** prod.collapse[of qq] by auto
  moreover have "t_source (qq, x, t_output t1, (t_target t1, t_target t2)) = qq"
            and "t_input (qq, x, t_output t1, (t_target t1, t_target t2)) = x"
    by auto
  ultimately show "False"
    using assms(1) by blast
qed

(* TODO: check *)
declare from_FSM.simps[simp]
declare product.simps[simp]
declare from_FSM_simps[simp]
declare product_simps[simp]
    

end