section \<open>Finite State Machines\<close>

text \<open>This theory defines well-formed finite state machines and introduces various closely related 
      notions, as well as a selection of basic properties and definitions.\<close>

theory FSM
  imports FSM_Impl "HOL-Library.Quotient_Type"
begin


subsection \<open>Well-formed Finite State Machines\<close>

text \<open>A value of type @{text "fsm_impl"} constitutes a well-formed FSM if its contained sets are 
      finite and the initial state and the components of each transition are contained in their 
      respective sets.\<close>

abbreviation(input) "well_formed_fsm (M :: ('state, 'input, 'output) fsm_impl) \<equiv> (initial M \<in> nodes M
      \<and> finite (nodes M)
      \<and> finite (inputs M)
      \<and> finite (outputs M)
      \<and> finite (transitions M)
      \<and> (\<forall> t \<in> transitions M . t_source t \<in> nodes M \<and> 
                                t_input t \<in> inputs M \<and> 
                                t_target t \<in> nodes M \<and> 
                                t_output t \<in> outputs M)) " 

typedef ('state, 'input, 'output) fsm = 
  "{ M :: ('state, 'input, 'output) fsm_impl . well_formed_fsm M}"
  morphisms fsm_impl Fsm
proof -
  obtain q :: 'state where "True" by blast
  define M :: "('state, 'input, 'output) fsm_impl" where 
    "M = \<lparr> initial = q, nodes = {q}, inputs = {}, outputs = {}, transitions = {} \<rparr>"
  then have "initial M \<in> nodes M
              \<and> finite (nodes M)
              \<and> finite (inputs M)
              \<and> finite (outputs M)
              \<and> finite (transitions M)
              \<and> (\<forall> t \<in> transitions M . t_source t \<in> nodes M \<and> t_input t \<in> inputs M \<and> 
                                        t_target t \<in> nodes M \<and> t_output t \<in> outputs M)"
    by auto
  then show ?thesis by blast
qed


setup_lifting type_definition_fsm

lift_definition initial :: "('state, 'input, 'output) fsm \<Rightarrow> 'state" is FSM_Impl.initial done
lift_definition nodes :: "('state, 'input, 'output) fsm \<Rightarrow> 'state set" is FSM_Impl.nodes done
lift_definition inputs :: "('state, 'input, 'output) fsm \<Rightarrow> 'input set" is FSM_Impl.inputs done
lift_definition outputs :: "('state, 'input, 'output) fsm \<Rightarrow> 'output set" is FSM_Impl.outputs done
lift_definition transitions :: 
  "('state, 'input, 'output) fsm \<Rightarrow> ('state \<times> 'input \<times> 'output \<times> 'state) set" 
  is FSM_Impl.transitions done

lift_definition fsm_from_list :: "'a \<Rightarrow> ('a \<times> 'b \<times> 'c \<times> 'a) list \<Rightarrow> ('a, 'b, 'c) fsm" 
  is FSM_Impl.fsm_impl_from_list 
proof -
  fix q  :: 'a 
  fix ts :: "('a \<times> 'b \<times> 'c \<times> 'a) list"
  show "well_formed_fsm (fsm_impl_from_list q ts)" 
    by (induction ts; auto)
qed



lemma fsm_initial[intro]: "initial M \<in> nodes M" 
  by (transfer; blast)
lemma fsm_nodes_finite: "finite (nodes M)" 
  by (transfer; blast)
lemma fsm_inputs_finite: "finite (inputs M)" 
  by (transfer; blast)
lemma fsm_outputs_finite: "finite (outputs M)" 
  by (transfer; blast)
lemma fsm_transitions_finite: "finite (transitions M)" 
  by (transfer; blast)
lemma fsm_transition_source[intro]: "\<And> t . t \<in> (transitions M) \<Longrightarrow> t_source t \<in> nodes M" 
  by (transfer; blast)
lemma fsm_transition_target[intro]: "\<And> t . t \<in> (transitions M) \<Longrightarrow> t_target t \<in> nodes M" 
  by (transfer; blast)
lemma fsm_transition_input[intro]: "\<And> t . t \<in> (transitions M) \<Longrightarrow> t_input t \<in> inputs M" 
  by (transfer; blast)
lemma fsm_transition_output[intro]: "\<And> t . t \<in> (transitions M) \<Longrightarrow> t_output t \<in> outputs M" 
  by (transfer; blast)


instantiation fsm :: (type,type,type) equal
begin                                  
definition equal_fsm :: "('a, 'b, 'c) fsm \<Rightarrow> ('a, 'b, 'c) fsm \<Rightarrow> bool" where
  "equal_fsm x y = (initial x = initial y \<and> nodes x = nodes y \<and> inputs x = inputs y \<and> outputs x = outputs y \<and> transitions x = transitions y)"

instance
  apply (intro_classes)
  unfolding equal_fsm_def 
  apply transfer by auto
end 



subsubsection \<open>Example FSMs\<close>


definition m_ex_H :: "(integer,integer,integer) fsm" where
  "m_ex_H = fsm_from_list 0 [ (1,0,0,2),
                              (1,0,1,4),
                              (1,1,1,4),
                              (2,0,0,2),
                              (2,1,1,4),
                              (3,0,1,4),
                              (3,1,0,1),
                              (3,1,1,3),
                              (4,0,0,3),
                              (4,1,0,1)]"


definition m_ex_9 :: "(integer,integer,integer) fsm" where
  "m_ex_9 = fsm_from_list 0 [ (0,0,2,2),
                              (0,0,3,2),
                              (0,1,0,3),
                              (0,1,1,3),
                              (1,0,3,2),
                              (1,1,1,3),
                              (2,0,2,2),
                              (2,1,3,3),
                              (3,0,2,2),
                              (3,1,0,2),
                              (3,1,1,1)]"

definition m_ex_DR :: "(integer,integer,integer) fsm" where
  "m_ex_DR = fsm_from_list 0  [(0,0,0,100),
                               (100,0,0,101), 
                               (100,0,1,101),
                               (101,0,0,102),
                               (101,0,1,102),
                               (102,0,0,103),
                               (102,0,1,103),
                               (103,0,0,104),
                               (103,0,1,104),
                               (104,0,0,100),
                               (104,0,1,100),
                               (104,1,0,400),
                               (0,0,2,200),
                               (200,0,2,201),
                               (201,0,2,202),
                               (202,0,2,203),
                               (203,0,2,200),
                               (203,1,0,400),
                               (0,1,0,300),
                               (100,1,0,300),
                               (101,1,0,300),
                               (102,1,0,300),
                               (103,1,0,300),
                               (200,1,0,300),
                               (201,1,0,300),
                               (202,1,0,300),
                               (300,0,0,300),
                               (300,1,0,300),
                               (400,0,0,300),
                               (400,1,0,300)]"


subsection \<open>Transition Function h\<close>

text \<open>Function @{text "h"} represents the classical view of the transition relation of an FSM @{text "M"} as a
      function: given a state @{text "q"} and an input @{text "x"}, @{text "(h M) (q,x)"} returns all
      possibly reactions @{text "(y,q')"} of @{text "M"} in state @{text "q"} to @{text "x"}, where
      @{text "y"} is the produced output and @{text "q'"} the target state of the reaction transition.\<close>

fun h :: "('state, 'input, 'output) fsm \<Rightarrow> ('state \<times> 'input) \<Rightarrow> ('output \<times> 'state) set" where
  "h M (q,x) = { (y,q') . (q,x,y,q') \<in> transitions M }"


lemma h_code[code] : 
  "h M (q,x) = (let m = set_as_map (image (\<lambda>(q,x,y,q') . ((q,x),y,q')) (transitions M)) 
                 in (case m (q,x) of Some yqs \<Rightarrow> yqs | None \<Rightarrow> {}))"
  unfolding set_as_map_def by force


fun defined_inputs' :: "(('a \<times>'b) \<Rightarrow> ('c\<times>'a) set) \<Rightarrow> 'b set \<Rightarrow> 'a \<Rightarrow> 'b set" where
  "defined_inputs' hM iM q = {x \<in> iM . hM (q,x) \<noteq> {}}"

fun defined_inputs :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> 'b set" where
  "defined_inputs M q = defined_inputs' (h M) (inputs M) q"

lemma defined_inputs_set : "defined_inputs M q = {x \<in> inputs M . h M (q,x) \<noteq> {} }"
  by auto

fun transitions_from' :: "(('a \<times>'b) \<Rightarrow> ('c\<times>'a) set) \<Rightarrow> 'b set \<Rightarrow> 'a \<Rightarrow> ('a,'b,'c) transition set" where
  "transitions_from' hM iM q = \<Union>(image (\<lambda>x . image (\<lambda>(y,q') . (q,x,y,q')) (hM (q,x))) iM)"

fun transitions_from :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> ('a,'b,'c) transition set" where
  "transitions_from M q = transitions_from' (h M) (inputs M) q"


lemma transitions_from_set : 
  assumes "q \<in> nodes M" 
  shows "transitions_from M q = {t \<in> transitions M . t_source t = q}"
proof -
  have "\<And> t . t \<in> transitions_from M q \<Longrightarrow> t \<in> transitions M \<and> t_source t = q" by auto
  moreover have "\<And> t . t \<in> transitions M \<Longrightarrow> t_source t = q \<Longrightarrow> t \<in> transitions_from M q" 
  proof -
    fix t assume "t \<in> transitions M" and "t_source t = q"
    then have "(t_output t, t_target t) \<in> h M (q,t_input t)" and "t_input t \<in> inputs M" by auto
    then have "t_input t \<in> defined_inputs' (h M) (inputs M) q" 
      unfolding defined_inputs'.simps \<open>t_source t = q\<close> by blast

    have "(q, t_input t, t_output t, t_target t) \<in> transitions M"
      using \<open>t_source t = q\<close> \<open>t \<in> transitions M\<close> by auto
    then have "(q, t_input t, t_output t, t_target t) \<in> (\<lambda>(y, q'). (q, t_input t, y, q')) ` h M (q, t_input t)"
      using \<open>(t_output t, t_target t) \<in> h M (q,t_input t)\<close>
      unfolding h.simps
      by (metis (no_types, lifting) image_iff prod.case_eq_if surjective_pairing)
    then have "t \<in> (\<lambda>(y, q'). (q, t_input t, y, q')) ` h M (q, t_input t)"
      using \<open>t_source t = q\<close> by (metis prod.collapse) 
    then show "t \<in> transitions_from M q" 
       
      unfolding transitions_from.simps transitions_from'.simps 
      using \<open>t_input t \<in> defined_inputs' (h M) (inputs M) q\<close>
      using \<open>t_input t \<in> FSM.inputs M\<close> by blast
  qed
  ultimately show ?thesis by blast
qed


fun h_from :: "('state, 'input, 'output) fsm \<Rightarrow> 'state \<Rightarrow> ('input \<times> 'output \<times> 'state) set" where
  "h_from M q = { (x,y,q') . (q,x,y,q') \<in> transitions M }"


lemma h_from[code] : "h_from M q = (let m = set_as_map (transitions M) 
                                     in (case m q of Some yqs \<Rightarrow> yqs | None \<Rightarrow> {}))"
  unfolding set_as_map_def by force


fun h_out :: "('a,'b,'c) fsm \<Rightarrow> ('a \<times> 'b) \<Rightarrow> 'c set" where
  "h_out M (q,x) = {y . \<exists> q' . (q,x,y,q') \<in> transitions M}"

lemma h_out_code[code]: 
  "h_out M = (\<lambda>qx . (case (set_as_map (image (\<lambda>(q,x,y,q') . ((q,x),y)) (transitions M))) qx of 
                            Some yqs \<Rightarrow> yqs | 
                            None \<Rightarrow> {}))"
proof -
  

  let ?f = "(\<lambda>qx . (case (set_as_map (image (\<lambda>(q,x,y,q') . ((q,x),y)) (transitions M))) qx of Some yqs \<Rightarrow> yqs | None \<Rightarrow> {}))"
  
  have "\<And> qx . (\<lambda>qx . (case (set_as_map (image (\<lambda>(q,x,y,q') . ((q,x),y)) (transitions M))) qx of Some yqs \<Rightarrow> yqs | None \<Rightarrow> {})) qx = (\<lambda> qx . {z. (qx, z) \<in> (\<lambda>(q, x, y, q'). ((q, x), y)) ` (transitions M)}) qx"
    unfolding set_as_map_def by auto
  
  moreover have "\<And> qx . (\<lambda> qx . {z. (qx, z) \<in> (\<lambda>(q, x, y, q'). ((q, x), y)) ` (transitions M)}) qx = (\<lambda> qx . {y | y . \<exists> q' . (fst qx, snd qx, y, q') \<in> (transitions M)}) qx" 
    by force
    
  ultimately have "?f = (\<lambda> qx . {y | y . \<exists> q' . (fst qx, snd qx, y, q') \<in> (transitions M)})" 
    by blast
  then have "?f = (\<lambda> (q,x) . {y | y . \<exists> q' . (q, x, y, q') \<in> (transitions M)})" by force
  
  then show ?thesis by force 
qed

lemma h_out_alt_def : 
  "h_out M (q,x) = {t_output t | t . t \<in> transitions M \<and> t_source t = q \<and> t_input t = x}"
  unfolding h_out.simps
  by auto


subsection \<open>Size\<close>

instantiation fsm  :: (type,type,type) size 
begin

definition size where [simp, code]: "size (m::('a, 'b, 'c) fsm) = card (nodes m)"

instance ..

end



subsection \<open>Paths\<close>

inductive path :: "('state, 'input, 'output) fsm \<Rightarrow> 'state \<Rightarrow> ('state, 'input, 'output) path \<Rightarrow> bool" 
  where
  nil[intro!] : "q \<in> nodes M \<Longrightarrow> path M q []" |
  cons[intro!] : "t \<in> transitions M \<Longrightarrow> path M (t_target t) ts \<Longrightarrow> path M (t_source t) (t#ts)"

inductive_cases path_nil_elim[elim!]: "path M q []"
inductive_cases path_cons_elim[elim!]: "path M q (t#ts)"

fun visited_nodes :: "'state \<Rightarrow> ('state, 'input, 'output) path \<Rightarrow> 'state list" where
  "visited_nodes q p = (q # map t_target p)"

fun target :: "'state \<Rightarrow> ('state, 'input, 'output) path \<Rightarrow> 'state" where
  "target q p = last (visited_nodes q p)"

lemma[simp] : "target q [] = q" by auto
lemma[simp] : "target q (p@[t]) = t_target t" by auto


lemma path_begin_node :
  assumes "path M q p"
  shows   "q \<in> nodes M" 
  using assms by (cases; auto) 

lemma path_append[intro!] :
  assumes "path M q p1"
      and "path M (target q p1) p2"
  shows "path M q (p1@p2)"
  using assms by (induct p1 arbitrary: p2; auto) 

lemma path_target_is_node :
  assumes "path M q p"
  shows   "target q p \<in> nodes M"
using assms by (induct p; auto)

lemma path_suffix :
  assumes "path M q (p1@p2)"
  shows "path M (target q p1) p2"
using assms by (induction p1 arbitrary: q; auto)

lemma path_prefix :
  assumes "path M q (p1@p2)"
  shows "path M q p1"
using assms by (induction p1 arbitrary: q; auto; (metis path_begin_node))

lemma path_append_elim[elim!] :
  assumes "path M q (p1@p2)"
  obtains "path M q p1"
      and "path M (target q p1) p2"
  by (meson assms path_prefix path_suffix)

lemma path_append_target:
  "target q (p1@p2) = target (target q p1) p2" 
  by (induction p1) (simp+)

lemma path_append_target_hd :
  assumes "length p > 0"
  shows "target q p = target (t_target (hd p)) (tl p)"
using assms by (induction p) (simp+)

lemma path_transitions :
  assumes "path M q p"
  shows "set p \<subseteq> transitions M"
  using assms by (induct p arbitrary: q; fastforce)

lemma path_append_transition[intro!] :
  assumes "path M q p"
  and     "t \<in> transitions M"
  and     "t_source t = target q p" 
shows "path M q (p@[t])"
  by (metis assms(1) assms(2) assms(3) cons fsm_transition_target nil path_append)

lemma path_append_transition_elim[elim!] :
  assumes "path M q (p@[t])"
shows "path M q p"
and   "t \<in> transitions M"
and   "t_source t = target q p" 
  using assms by auto

lemma path_prepend_t : "path M q' p \<Longrightarrow> (q,x,y,q') \<in> transitions M \<Longrightarrow> path M q ((q,x,y,q')#p)" 
  by (metis (mono_tags, lifting) fst_conv path.intros(2) prod.sel(2)) 

lemma path_target_append : "target q1 p1 = q2 \<Longrightarrow> target q2 p2 = q3 \<Longrightarrow> target q1 (p1@p2) = q3" 
  by auto

lemma single_transition_path : "t \<in> transitions M \<Longrightarrow> path M (t_source t) [t]" by auto

lemma path_source_target_index :
  assumes "Suc i < length p"
  and     "path M q p"
shows "t_target (p ! i) = t_source (p ! (Suc i))"
  using assms proof (induction p rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc t ps)
  then have "path M q ps" and "t_source t = target q ps" and "t \<in> transitions M" by auto
  
  show ?case proof (cases "Suc i < length ps")
    case True
    then have "t_target (ps ! i) = t_source (ps ! Suc i)" 
      using snoc.IH \<open>path M q ps\<close> by auto
    then show ?thesis
      by (simp add: Suc_lessD True nth_append) 
  next
    case False
    then have "Suc i = length ps"
      using snoc.prems(1) by auto
    then have "(ps @ [t]) ! Suc i = t"
      by auto

    show ?thesis proof (cases "ps = []")
      case True
      then show ?thesis using \<open>Suc i = length ps\<close> by auto
    next
      case False
      then have "target q ps = t_target (last ps)"
        unfolding target.simps visited_nodes.simps
        by (simp add: last_map) 
      then have "target q ps = t_target (ps ! i)"
        using \<open>Suc i = length ps\<close>
        by (metis False diff_Suc_1 last_conv_nth) 
      then show ?thesis 
        using \<open>t_source t = target q ps\<close>
        by (metis \<open>(ps @ [t]) ! Suc i = t\<close> \<open>Suc i = length ps\<close> lessI nth_append) 
    qed
  qed   
qed

lemma paths_finite : "finite { p . path M q p \<and> length p \<le> k }"
proof -
  have "{ p . path M q p \<and> length p \<le> k } \<subseteq> {xs . set xs \<subseteq> transitions M \<and> length xs \<le> k}"
    by (metis (no_types, lifting) Collect_mono path_transitions)     
  then show "finite { p . path M q p \<and> length p \<le> k }"
    using finite_lists_length_le[OF fsm_transitions_finite[of M], of k]
    by (metis (mono_tags) finite_subset) 
qed

lemma visited_nodes_prefix :
  assumes "q' \<in> set (visited_nodes q p)"
  shows   "\<exists> p1 p2 . p = p1@p2 \<and> target q p1 = q'"
using assms proof (induction p arbitrary: q)
  case Nil
  then show ?case by auto
next
  case (Cons a p)
  then show ?case 
  proof (cases "q' \<in> set (visited_nodes (t_target a) p)")
    case True
    then obtain p1 p2 where "p = p1 @ p2 \<and> target (t_target a) p1 = q'"
      using Cons.IH by blast
    then have "(a#p) = (a#p1)@p2 \<and> target q (a#p1) = q'"
      by auto
    then show ?thesis by blast
  next
    case False
    then have "q' = q" 
      using Cons.prems by auto     
    then show ?thesis
      by auto 
  qed
qed 

lemma visited_nodes_are_nodes :
  assumes "path M q1 p"
  shows "set (visited_nodes q1 p) \<subseteq> nodes M" 
  by (metis assms path_prefix path_target_is_node subsetI visited_nodes_prefix) 
  
lemma transition_subset_path : 
  assumes "transitions A \<subseteq> transitions B"
  and "path A q p"
  and "q \<in> nodes B"
shows "path B q p"
using assms(2) proof (induction p rule: rev_induct)
  case Nil
  show ?case using assms(3) by auto
next
  case (snoc t p)
  then show ?case using assms(1) path_suffix
    by fastforce   
qed

subsubsection \<open>Paths of fixed length\<close>

fun paths_of_length' :: "('a,'b,'c) path \<Rightarrow> 'a \<Rightarrow> (('a \<times>'b) \<Rightarrow> ('c\<times>'a) set) \<Rightarrow> 'b set \<Rightarrow> nat \<Rightarrow> ('a,'b,'c) path set" 
  where
  "paths_of_length' prev q hM iM 0 = {prev}" |
  "paths_of_length' prev q hM iM (Suc k) = 
    (let hF = transitions_from' hM iM q
      in \<Union> (image (\<lambda> t . paths_of_length' (prev@[t]) (t_target t) hM iM k) hF))"

fun paths_of_length :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> nat \<Rightarrow> ('a,'b,'c) path set" where
  "paths_of_length M q k = paths_of_length' [] q (h M) (inputs M) k"



subsubsection \<open>Paths up to fixed length\<close>

fun paths_up_to_length' :: "('a,'b,'c) path \<Rightarrow> 'a \<Rightarrow> (('a \<times>'b) \<Rightarrow> (('c\<times>'a) set)) \<Rightarrow> 'b set \<Rightarrow> nat \<Rightarrow> ('a,'b,'c) path set" 
  where
  "paths_up_to_length' prev q hM iM 0 = {prev}" |
  "paths_up_to_length' prev q hM iM (Suc k) = 
    (let hF = transitions_from' hM iM q
      in insert prev (\<Union> (image (\<lambda> t . paths_up_to_length' (prev@[t]) (t_target t) hM iM k) hF)))"

fun paths_up_to_length :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> nat \<Rightarrow> ('a,'b,'c) path set" where
  "paths_up_to_length M q k = paths_up_to_length' [] q (h M) (inputs M) k"


lemma paths_up_to_length'_set :
  assumes "q \<in> nodes M"
  and     "path M q prev"
shows "paths_up_to_length' prev (target q prev) (h M) (inputs M) k 
        = {(prev@p) | p . path M (target q prev) p \<and> length p \<le> k}"
using assms(2) proof (induction k arbitrary: prev)
  case 0
  show ?case unfolding paths_up_to_length'.simps using path_target_is_node[OF "0.prems"(1)] by auto
next
  case (Suc k)
  
  have "\<And> p . p \<in> paths_up_to_length' prev (target q prev) (h M) (inputs M) (Suc k) 
          \<Longrightarrow> p \<in> {(prev@p) | p . path M (target q prev) p \<and> length p \<le> Suc k}"
  proof -
    fix p assume "p \<in> paths_up_to_length' prev (target q prev) (h M) (inputs M) (Suc k)"
    then show "p \<in> {(prev@p) | p . path M (target q prev) p \<and> length p \<le> Suc k}" 
    proof (cases "p = prev")
      case True
      show ?thesis using path_target_is_node[OF Suc.prems(1)] unfolding True by (simp add: nil) 
    next
      case False
      then have "p \<in> (\<Union> (image (\<lambda>t. paths_up_to_length' (prev@[t]) (t_target t) (h M) (inputs M) k) 
                                (transitions_from' (h M) (inputs M) (target q prev))))"
        using \<open>p \<in> paths_up_to_length' prev (target q prev) (h M) (inputs M) (Suc k)\<close>
        unfolding paths_up_to_length'.simps Let_def by blast
      then obtain t where "t \<in> \<Union>(image (\<lambda>x . image (\<lambda>(y,q') . ((target q prev),x,y,q')) 
                                                    (h M ((target q prev),x))) (inputs M))"
                    and   "p \<in> paths_up_to_length' (prev@[t]) (t_target t) (h M) (inputs M) k"
        unfolding transitions_from'.simps by blast

      have "t \<in> transitions M" and "t_source t = (target q prev)"
        using \<open>t \<in> \<Union>(image (\<lambda>x . image (\<lambda>(y,q') . ((target q prev),x,y,q')) 
                                        (h M ((target q prev),x))) (inputs M))\<close> by auto
      then have "path M q (prev@[t])"
        using Suc.prems(1) using path_append_transition by simp

      have "(target q (prev @ [t])) = t_target t" by auto
      

      show ?thesis 
        using \<open>p \<in> paths_up_to_length' (prev@[t]) (t_target t) (h M) (inputs M) k\<close>
        using Suc.IH[OF \<open>path M q (prev@[t])\<close>] 
        unfolding \<open>(target q (prev @ [t])) = t_target t\<close>
        using \<open>path M q (prev @ [t])\<close> by auto 
    qed
  qed

  moreover have "\<And> p . p \<in> {(prev@p) | p . path M (target q prev) p \<and> length p \<le> Suc k} 
                  \<Longrightarrow> p \<in> paths_up_to_length' prev (target q prev) (h M) (inputs M) (Suc k)"
  proof -
    fix p assume "p \<in> {(prev@p) | p . path M (target q prev) p \<and> length p \<le> Suc k}"
    then obtain p' where "p = prev@p'"
                   and   "path M (target q prev) p'" 
                   and   "length p' \<le> Suc k"
      by blast

    have "prev@p' \<in> paths_up_to_length' prev (target q prev) (h M) (inputs M) (Suc k)"
    proof (cases p')
      case Nil
      then show ?thesis by auto
    next
      case (Cons t p'')

      then have "t \<in> transitions M" and "t_source t = (target q prev)"
        using \<open>path M (target q prev) p'\<close> by auto
      then have "path M q (prev@[t])"
        using Suc.prems(1) using path_append_transition by simp
      
      have "(target q (prev @ [t])) = t_target t" by auto

      have "length p'' \<le> k" using \<open>length p' \<le> Suc k\<close> Cons by auto
      moreover have "path M (target q (prev@[t])) p''"
        using \<open>path M (target q prev) p'\<close> unfolding Cons
        by auto
      ultimately have "p \<in> paths_up_to_length' (prev @ [t]) (t_target t) (h M) (FSM.inputs M) k"
        using Suc.IH[OF \<open>path M q (prev@[t])\<close>] 
        unfolding \<open>(target q (prev @ [t])) = t_target t\<close> \<open>p = prev@p'\<close> Cons by simp
      then have "prev@t#p'' \<in> paths_up_to_length' (prev @ [t]) (t_target t) (h M) (FSM.inputs M) k"
        unfolding \<open>p = prev@p'\<close> Cons by auto

      have "t \<in> (\<lambda>(y, q'). (t_source t, t_input t, y, q')) ` 
                              {(y, q'). (t_source t, t_input t, y, q') \<in> FSM.transitions M}"
        using \<open>t \<in> transitions M\<close>
        by (metis (no_types, lifting) case_prodI mem_Collect_eq pair_imageI surjective_pairing)  
      then have "t \<in> transitions_from' (h M) (inputs M) (target q prev)"
        unfolding transitions_from'.simps 
        using fsm_transition_input[OF \<open>t \<in> transitions M\<close>] 
        unfolding \<open>t_source t = (target q prev)\<close>[symmetric] h.simps 
        by blast

      then show ?thesis 
        using \<open>prev @ t # p'' \<in> paths_up_to_length' (prev@[t]) (t_target t) (h M) (FSM.inputs M) k\<close> 
        unfolding \<open>p = prev@p'\<close> Cons paths_up_to_length'.simps Let_def by blast
    qed
    then show "p \<in> paths_up_to_length' prev (target q prev) (h M) (inputs M) (Suc k)"
      unfolding \<open>p = prev@p'\<close> by assumption
  qed

  ultimately show ?case by blast
qed


lemma paths_up_to_length_set :
  assumes "q \<in> nodes M"
shows "paths_up_to_length M q k = {p . path M q p \<and> length p \<le> k}" 
  unfolding paths_up_to_length.simps 
  using paths_up_to_length'_set[OF assms nil[OF assms], of k]  by auto




subsubsection \<open>Calculating Acyclic Paths\<close>

fun acyclic_paths_up_to_length' :: "('a,'b,'c) path \<Rightarrow> 'a \<Rightarrow> ('a  \<Rightarrow> (('b\<times>'c\<times>'a) set)) \<Rightarrow> 'a set \<Rightarrow> nat \<Rightarrow> ('a,'b,'c) path set" 
  where
  "acyclic_paths_up_to_length' prev q hF visitedNodes 0 = {prev}" |
  "acyclic_paths_up_to_length' prev q hF visitedNodes (Suc k) = 
    (let tF = Set.filter (\<lambda> (x,y,q') . q' \<notin> visitedNodes) (hF q)
      in (insert prev (\<Union> (image (\<lambda> (x,y,q') . acyclic_paths_up_to_length' (prev@[(q,x,y,q')]) q' hF (insert q' visitedNodes) k) tF))))"


fun p_source :: "'a \<Rightarrow> ('a,'b,'c) path \<Rightarrow> 'a"
  where "p_source q p = hd (visited_nodes q p)"

lemma acyclic_paths_up_to_length'_prev : 
  "p' \<in> acyclic_paths_up_to_length' (prev@prev') q hF visitedNodes k \<Longrightarrow> \<exists> p'' . p' = prev@p''" 
  by (induction k arbitrary: p' q visitedNodes prev'; auto)

lemma acyclic_paths_up_to_length'_set :
  assumes "path M (p_source q prev) prev"
  and     "\<And> q' . hF q' = {(x,y,q'') | x y q'' . (q',x,y,q'') \<in> transitions M}"
  and     "distinct (visited_nodes (p_source q prev) prev)"
  and     "visitedNodes = set (visited_nodes (p_source q prev) prev)"
shows "acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes k 
        = { prev@p | p . path M (p_source q prev) (prev@p) 
                          \<and> length p \<le> k 
                          \<and> distinct (visited_nodes (p_source q prev) (prev@p)) }"
using assms proof (induction k arbitrary: q hF prev visitedNodes)
  case 0
  then show ?case by auto
next
  case (Suc k)

  let ?tgt = "(target (p_source q prev) prev)"

  have "\<And> p . (prev@p) \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k) 
            \<Longrightarrow> path M (p_source q prev) (prev@p) 
                \<and> length p \<le> Suc k 
                \<and> distinct (visited_nodes (p_source q prev) (prev@p))"
  proof -
    fix p assume "(prev@p) \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k)"
    then consider (a) "(prev@p) = prev" |
                  (b) "(prev@p) \<in> (\<Union> (image (\<lambda> (x,y,q') . acyclic_paths_up_to_length' (prev@[(?tgt,x,y,q')]) q' hF (insert q' visitedNodes) k) 
                                             (Set.filter (\<lambda> (x,y,q') . q' \<notin> visitedNodes) (hF (target (p_source q prev) prev)))))"
      by auto
    then show "path M (p_source q prev) (prev@p) \<and> length p \<le> Suc k \<and> distinct (visited_nodes (p_source q prev) (prev@p))"
    proof (cases)
      case a
      then show ?thesis using Suc.prems(1,3) by auto
    next
      case b
      then obtain x y q' where *: "(x,y,q') \<in> Set.filter (\<lambda> (x,y,q') . q' \<notin> visitedNodes) (hF ?tgt)"
                         and   **:"(prev@p) \<in> acyclic_paths_up_to_length' (prev@[(?tgt,x,y,q')]) q' hF (insert q' visitedNodes) k"
        by auto

      let ?t = "(?tgt,x,y,q')"

      from * have "?t \<in> transitions M" and "q' \<notin> visitedNodes"
        using Suc.prems(2)[of ?tgt] by simp+ 
      moreover have "t_source ?t = target (p_source q prev) prev"
        by simp
      moreover have "p_source (p_source q prev) (prev@[?t]) = p_source q prev"
        by auto
      ultimately have p1: "path M (p_source (p_source q prev) (prev@[?t])) (prev@[?t])" 
        using Suc.prems(1)
        by (simp add: path_append_transition) 
      
      
      have "q' \<notin> set (visited_nodes (p_source q prev) prev)"
        using \<open>q' \<notin> visitedNodes\<close> Suc.prems(4) by auto
      then have p2: "distinct (visited_nodes (p_source (p_source q prev) (prev@[?t])) (prev@[?t]))"
        using Suc.prems(3) by auto

      have p3: "(insert q' visitedNodes) 
                  = set (visited_nodes (p_source (p_source q prev) (prev@[?t])) (prev@[?t]))"
        using Suc.prems(4) by auto

      have ***: "(target (p_source (p_source q prev) (prev @ [(target (p_source q prev) prev, x, y, q')])) 
                         (prev @ [(target (p_source q prev) prev, x, y, q')])) 
                  = q'"
        by auto

      show ?thesis
        using Suc.IH[OF p1 Suc.prems(2) p2 p3] ** 
        unfolding *** 
        unfolding \<open>p_source (p_source q prev) (prev@[?t]) = p_source q prev\<close>
      proof -
        assume "acyclic_paths_up_to_length' (prev @ [(target (p_source q prev) prev, x, y, q')]) q' hF (insert q' visitedNodes) k 
                  = {(prev @ [(target (p_source q prev) prev, x, y, q')]) @ p |p. 
                        path M (p_source q prev) ((prev @ [(target (p_source q prev) prev, x, y, q')]) @ p) 
                        \<and> length p \<le> k 
                        \<and> distinct (visited_nodes (p_source q prev) ((prev @ [(target (p_source q prev) prev, x, y, q')]) @ p))}"
        then have "\<exists>ps. prev @ p = (prev @ [(target (p_source q prev) prev, x, y, q')]) @ ps 
                        \<and> path M (p_source q prev) ((prev @ [(target (p_source q prev) prev, x, y, q')]) @ ps) 
                        \<and> length ps \<le> k 
                        \<and> distinct (visited_nodes (p_source q prev) ((prev @ [(target (p_source q prev) prev, x, y, q')]) @ ps))"
          using \<open>prev @ p \<in> acyclic_paths_up_to_length' (prev @ [(target (p_source q prev) prev, x, y, q')]) q' hF (insert q' visitedNodes) k\<close> 
          by blast
        then show ?thesis
          by (metis (no_types) Suc_le_mono append.assoc append.right_neutral append_Cons length_Cons same_append_eq)
      qed 
    qed
  qed
  moreover have "\<And> p' . p' \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k) 
                        \<Longrightarrow> \<exists> p'' . p' = prev@p''"
    using acyclic_paths_up_to_length'_prev[of _ prev "[]" "target (p_source q prev) prev" hF visitedNodes "Suc k"] 
    by force
  ultimately have fwd: "\<And> p' . p' \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k) 
                          \<Longrightarrow> p' \<in> { prev@p | p . path M (p_source q prev) (prev@p) 
                                                    \<and> length p \<le> Suc k 
                                                    \<and> distinct (visited_nodes (p_source q prev) (prev@p)) }"
    by blast

  have "\<And> p . path M (p_source q prev) (prev@p) 
                \<Longrightarrow> length p \<le> Suc k 
                \<Longrightarrow> distinct (visited_nodes (p_source q prev) (prev@p)) 
                \<Longrightarrow> (prev@p) \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k)"
  proof -
    fix p assume "path M (p_source q prev) (prev@p)"
          and    "length p \<le> Suc k"
          and    "distinct (visited_nodes (p_source q prev) (prev@p))"

    show "(prev@p) \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k)"
    proof (cases p)
      case Nil
      then show ?thesis by auto
    next
      case (Cons t p')

      then have "t_source t = target (p_source q (prev)) (prev)" and "t \<in> transitions M"
        using \<open>path M (p_source q prev) (prev@p)\<close> by auto
      
      have "path M (p_source q (prev@[t])) ((prev@[t])@p')"
      and  "path M (p_source q (prev@[t])) ((prev@[t]))"
        using Cons \<open>path M (p_source q prev) (prev@p)\<close> by auto
      have "length p' \<le> k"
        using Cons \<open>length p \<le> Suc k\<close> by auto
      have "distinct (visited_nodes (p_source q (prev@[t])) ((prev@[t])@p'))"
      and  "distinct (visited_nodes (p_source q (prev@[t])) ((prev@[t])))" 
        using Cons \<open>distinct (visited_nodes (p_source q prev) (prev@p))\<close> by auto
      then have "t_target t \<notin> visitedNodes"
        using Suc.prems(4) by auto

      let ?vN = "insert (t_target t) visitedNodes"
      have "?vN = set (visited_nodes (p_source q (prev @ [t])) (prev @ [t]))"
        using Suc.prems(4) by auto

      have "prev@p = prev@([t]@p')"
        using Cons by auto

      have "(prev@[t])@p' \<in> acyclic_paths_up_to_length' (prev @ [t]) (target (p_source q (prev @ [t])) (prev @ [t])) hF (insert (t_target t) visitedNodes) k" 
        using Suc.IH[of q "prev@[t]", OF \<open>path M (p_source q (prev@[t])) ((prev@[t]))\<close> Suc.prems(2)
                                         \<open>distinct (visited_nodes (p_source q (prev@[t])) ((prev@[t])))\<close> 
                                         \<open>?vN = set (visited_nodes (p_source q (prev @ [t])) (prev @ [t]))\<close> ]
        using \<open>path M (p_source q (prev@[t])) ((prev@[t])@p')\<close>
              \<open>length p' \<le> k\<close>
              \<open>distinct (visited_nodes (p_source q (prev@[t])) ((prev@[t])@p'))\<close> 
        by force

      then have "(prev@[t])@p' \<in> acyclic_paths_up_to_length' (prev@[t]) (t_target t) hF ?vN k"
        by auto
      moreover have "(t_input t,t_output t, t_target t) \<in> Set.filter (\<lambda> (x,y,q') . q' \<notin> visitedNodes) (hF (t_source t))"
        using Suc.prems(2)[of "t_source t"] \<open>t \<in> transitions M\<close> \<open>t_target t \<notin> visitedNodes\<close>
      proof -
        have "\<exists>b c a. snd t = (b, c, a) \<and> (t_source t, b, c, a) \<in> FSM.transitions M"
          by (metis (no_types) \<open>t \<in> FSM.transitions M\<close> prod.collapse)
        then show ?thesis
          using \<open>hF (t_source t) = {(x, y, q'') |x y q''. (t_source t, x, y, q'') \<in> FSM.transitions M}\<close> 
                \<open>t_target t \<notin> visitedNodes\<close> 
          by fastforce
      qed 
      ultimately have "\<exists> (x,y,q') \<in> (Set.filter (\<lambda> (x,y,q') . q' \<notin> visitedNodes) (hF (target (p_source q prev) prev))) .
                        (prev@[t])@p' \<in> (acyclic_paths_up_to_length' (prev@[((target (p_source q prev) prev),x,y,q')]) q' hF (insert q' visitedNodes) k)"
        unfolding \<open>t_source t = target (p_source q (prev)) (prev)\<close>
        by (metis (no_types, lifting) \<open>t_source t = target (p_source q prev) prev\<close> case_prodI prod.collapse) 
       
      then show ?thesis unfolding \<open>prev@p = prev@[t]@p'\<close> 
        unfolding acyclic_paths_up_to_length'.simps Let_def by force
    qed
  qed
  then have rev: "\<And> p' . p' \<in> {prev@p | p . path M (p_source q prev) (prev@p) 
                                              \<and> length p \<le> Suc k 
                                              \<and> distinct (visited_nodes (p_source q prev) (prev@p))} 
                        \<Longrightarrow> p' \<in> acyclic_paths_up_to_length' prev (target (p_source q prev) prev) hF visitedNodes (Suc k)"
    by blast
  
  show ?case
    using fwd rev by blast
qed 


fun acyclic_paths_up_to_length :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> nat \<Rightarrow> ('a,'b,'c) path set" where
  "acyclic_paths_up_to_length M q k = {p. path M q p \<and> length p \<le> k \<and> distinct (visited_nodes q p)}"

lemma acyclic_paths_up_to_length_code[code] :
  "acyclic_paths_up_to_length M q k = (if q \<in> nodes M 
      then acyclic_paths_up_to_length' [] q (m2f (set_as_map (transitions M))) {q} k
      else {})"
proof (cases "q \<in> nodes M")
  case False
  then have "acyclic_paths_up_to_length M q k = {}" 
    using path_begin_node by fastforce
  then show ?thesis using False by auto
next
  case True
  then have *: "path M (p_source q []) []" by auto
  have **: "(\<And>q'. (m2f (set_as_map (transitions M))) q' = {(x, y, q'') |x y q''. (q', x, y, q'') \<in> FSM.transitions M})"
    unfolding set_as_map_def by auto 
  have ***: "distinct (visited_nodes (p_source q []) [])"
    by auto
  have ****: "{q} = set (visited_nodes (p_source q []) [])"
    by auto
  
  show ?thesis
    using acyclic_paths_up_to_length'_set[OF * ** *** ****, of k ] 
    using True by auto
qed


lemma path_map_target : "target (f4 q) (map (\<lambda> t . (f1 (t_source t), f2 (t_input t), f3 (t_output t), f4 (t_target t))) p) = f4 (target q p)" 
  by (induction p; auto)


lemma path_length_sum :
  assumes "path M q p" 
  shows "length p = (\<Sum> q \<in> nodes M . length (filter (\<lambda>t. t_target t = q) p))"
  using assms
proof (induction p rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc x xs)
  then have "length xs = (\<Sum>q\<in>nodes M. length (filter (\<lambda>t. t_target t = q) xs))"
    by auto
  
  have *: "t_target x \<in> nodes M"
    using \<open>path M q (xs @ [x])\<close> by auto
  then have **: "length (filter (\<lambda>t. t_target t = t_target x) (xs @ [x])) 
                  = Suc (length (filter (\<lambda>t. t_target t = t_target x) xs))"
    by auto

  have "\<And> q . q \<in> nodes M \<Longrightarrow> q \<noteq> t_target x 
          \<Longrightarrow> length (filter (\<lambda>t. t_target t = q) (xs @ [x])) = length (filter (\<lambda>t. t_target t = q) xs)"
    by simp
  then have ***: "(\<Sum>q\<in>nodes M - {t_target x}. length (filter (\<lambda>t. t_target t = q) (xs @ [x]))) 
                  = (\<Sum>q\<in>nodes M - {t_target x}. length (filter (\<lambda>t. t_target t = q) xs))"
    using fsm_nodes_finite[of M]
    by (metis (no_types, lifting) DiffE insertCI sum.cong)

  have "(\<Sum>q\<in>nodes M. length (filter (\<lambda>t. t_target t = q) (xs @ [x]))) 
          = (\<Sum>q\<in>nodes M - {t_target x}. length (filter (\<lambda>t. t_target t = q) (xs @ [x]))) 
              + (length (filter (\<lambda>t. t_target t = t_target x) (xs @ [x])))"
    using * fsm_nodes_finite[of M]
  proof -
    have "(\<Sum>a\<in>insert (t_target x) (nodes M). length (filter (\<lambda>p. t_target p = a) (xs @ [x]))) 
            = (\<Sum>a\<in>nodes M. length (filter (\<lambda>p. t_target p = a) (xs @ [x])))"
      by (simp add: \<open>t_target x \<in> nodes M\<close> insert_absorb)
    then show ?thesis
      by (simp add: \<open>finite (nodes M)\<close> sum.insert_remove)
  qed  
  moreover have "(\<Sum>q\<in>nodes M. length (filter (\<lambda>t. t_target t = q) xs)) 
                  = (\<Sum>q\<in>nodes M - {t_target x}. length (filter (\<lambda>t. t_target t = q) xs)) 
                      + (length (filter (\<lambda>t. t_target t = t_target x) xs))"
    using * fsm_nodes_finite[of M]
  proof -
    have "(\<Sum>a\<in>insert (t_target x) (nodes M). length (filter (\<lambda>p. t_target p = a) xs)) 
            = (\<Sum>a\<in>nodes M. length (filter (\<lambda>p. t_target p = a) xs))"
      by (simp add: \<open>t_target x \<in> nodes M\<close> insert_absorb)
    then show ?thesis
      by (simp add: \<open>finite (nodes M)\<close> sum.insert_remove)
  qed  

  ultimately have "(\<Sum>q\<in>nodes M. length (filter (\<lambda>t. t_target t = q) (xs @ [x]))) 
                    = Suc (\<Sum>q\<in>nodes M. length (filter (\<lambda>t. t_target t = q) xs))"
    using ** *** by auto
    
  then show ?case
    by (simp add: \<open>length xs = (\<Sum>q\<in>nodes M. length (filter (\<lambda>t. t_target t = q) xs))\<close>) 
qed


lemma path_loop_cut :
  assumes "path M q p"
  and     "t_target (p ! i) = t_target (p ! j)"
  and     "i < j"
  and     "j < length p"
shows "path M q ((take (Suc i) p) @ (drop (Suc j) p))"
and   "target q ((take (Suc i) p) @ (drop (Suc j) p)) = target q p"
and   "length ((take (Suc i) p) @ (drop (Suc j) p)) < length p"
and   "path M (target q (take (Suc i) p)) (drop (Suc i) (take (Suc j) p))"
and   "target (target q (take (Suc i) p)) (drop (Suc i) (take (Suc j) p)) = (target q (take (Suc i) p))"
proof -
    
  have "p = (take (Suc j) p) @ (drop (Suc j) p)"
    by auto
  also have "\<dots> = ((take (Suc i) (take (Suc j) p)) @ (drop (Suc i) (take (Suc j) p))) @ (drop (Suc j) p)"
    by (metis append_take_drop_id)
  also have "\<dots> = ((take (Suc i) p) @ (drop (Suc i) (take (Suc j) p))) @ (drop (Suc j) p)"
    using \<open>i < j\<close> by (simp add: min.strict_order_iff) 
  finally have "p = (take (Suc i) p) @ (drop (Suc i) (take (Suc j) p)) @ (drop (Suc j) p)"
    by simp

  then have "path M q ((take (Suc i) p) @ (drop (Suc i) (take (Suc j) p)) @ (drop (Suc j) p))"
       and  "path M q (((take (Suc i) p) @ (drop (Suc i) (take (Suc j) p))) @ (drop (Suc j) p))"
    using \<open>path M q p\<close> by auto

  have "path M q (take (Suc i) p)" and "path M (target q (take (Suc i) p)) (drop (Suc i) (take (Suc j) p) @ drop (Suc j) p)"
    using path_append_elim[OF \<open>path M q ((take (Suc i) p) @ (drop (Suc i) (take (Suc j) p)) @ (drop (Suc j) p))\<close>] 
    by blast+

  
  have *: "(take (Suc i) p @ drop (Suc i) (take (Suc j) p)) = (take (Suc j) p)"
      using \<open>i < j\<close> append_take_drop_id
      by (metis \<open>(take (Suc i) (take (Suc j) p) @ drop (Suc i) (take (Suc j) p)) @ drop (Suc j) p = (take (Suc i) p @ drop (Suc i) (take (Suc j) p)) @ drop (Suc j) p\<close> append_same_eq)

  have "path M q (take (Suc j) p)" and "path M (target q (take (Suc j) p)) (drop (Suc j) p)"
    using path_append_elim[OF \<open>path M q (((take (Suc i) p) @ (drop (Suc i) (take (Suc j) p))) @ (drop (Suc j) p))\<close>] 
    unfolding *
    by blast+

  have **: "(target q (take (Suc j) p)) = (target q (take (Suc i) p))"
  proof -
    have "p ! i = last (take (Suc i) p)"
      by (metis Suc_lessD assms(3) assms(4) less_trans_Suc take_last_index)
    moreover have "p ! j = last (take (Suc j) p)"
      by (simp add: assms(4) take_last_index)
    ultimately show ?thesis
      using assms(2) unfolding * target.simps visited_nodes.simps
      by (simp add: last_map) 
  qed

  show "path M q ((take (Suc i) p) @ (drop (Suc j) p))"
    using \<open>path M q (take (Suc i) p)\<close> \<open>path M (target q (take (Suc j) p)) (drop (Suc j) p)\<close> unfolding ** by auto

  show "target q ((take (Suc i) p) @ (drop (Suc j) p)) = target q p"
    by (metis "**" append_take_drop_id path_append_target)
    
  show "length ((take (Suc i) p) @ (drop (Suc j) p)) < length p"
  proof -
    have ***: "length p = length ((take (Suc j) p) @ (drop (Suc j) p))"
      by auto

    have "length (take (Suc i) p) < length (take (Suc j) p)"
      using assms(3,4)
      by (simp add: min_absorb2) 

    have scheme: "\<And> a b c . length a < length b \<Longrightarrow> length (a@c) < length (b@c)"
      by auto
    
    show ?thesis 
      unfolding *** using scheme[OF \<open>length (take (Suc i) p) < length (take (Suc j) p)\<close>, of "(drop (Suc j) p)"]
      by assumption
  qed

  show "path M (target q (take (Suc i) p)) (drop (Suc i) (take (Suc j) p))"
    using \<open>path M (target q (take (Suc i) p)) (drop (Suc i) (take (Suc j) p) @ drop (Suc j) p)\<close> by blast

  show "target (target q (take (Suc i) p)) (drop (Suc i) (take (Suc j) p)) = (target q (take (Suc i) p))"
    by (metis "*" "**" path_append_target) 
qed
      

lemma path_prefix_take :
  assumes "path M q p"
  shows "path M q (take i p)"
proof -
  have "p = (take i p)@(drop i p)" by auto
  then have "path M q ((take i p)@(drop i p))" using assms by auto
  then show ?thesis
    by blast 
qed



subsection \<open>Acyclic Paths\<close>

lemma cyclic_path_loop :
  assumes "path M q p"
  and     "\<not> distinct (visited_nodes q p)"
shows "\<exists> p1 p2 p3 . p = p1@p2@p3 \<and> p2 \<noteq> [] \<and> target q p1 = target q (p1@p2)"
using assms proof (induction p arbitrary: q)
  case (nil M q)
  then show ?case by auto
next
  case (cons t M ts)
  then show ?case 
  proof (cases "distinct (visited_nodes (t_target t) ts)")
    case True
    then have "q \<in> set (visited_nodes (t_target t) ts)"
      using cons.prems by simp 
    then obtain p2 p3 where "ts = p2@p3" and "target (t_target t) p2 = q" 
      using visited_nodes_prefix[of q "t_target t" ts] by blast
    then have "(t#ts) = []@(t#p2)@p3 \<and> (t#p2) \<noteq> [] \<and> target q [] = target q ([]@(t#p2))"
      using cons.hyps by auto
    then show ?thesis by blast
  next
    case False
    then obtain p1 p2 p3 where "ts = p1@p2@p3" and "p2 \<noteq> []" 
                           and "target (t_target t) p1 = target (t_target t) (p1@p2)" 
      using cons.IH by blast
    then have "t#ts = (t#p1)@p2@p3 \<and> p2 \<noteq> [] \<and> target q (t#p1) = target q ((t#p1)@p2)"
      by simp
    then show ?thesis by blast    
  qed
qed


lemma cyclic_path_pumping :
  assumes "path M (initial M) p" 
      and "\<not> distinct (visited_nodes (initial M) p)"
  shows "\<exists> p . path M (initial M) p \<and> length p \<ge> n"
proof -
  from assms obtain p1 p2 p3 where "p = p1 @ p2 @ p3" and "p2 \<noteq> []" 
                               and "target (initial M) p1 = target (initial M) (p1 @ p2)"
    using cyclic_path_loop[of M "initial M" p] by blast
  then have "path M (target (initial M) p1) p3"
    using path_suffix[of M "initial M" "p1@p2" p3] \<open>path M (initial M) p\<close> by auto
  
  have "path M (initial M) p1"
    using path_prefix[of M "initial M" p1 "p2@p3"] \<open>path M (initial M) p\<close> \<open>p = p1 @ p2 @ p3\<close> 
    by auto
  have "path M (initial M) ((p1@p2)@p3)"
    using \<open>path M (initial M) p\<close> \<open>p = p1 @ p2 @ p3\<close> 
    by auto
  have "path M (target (initial M) p1) p2" 
    using path_suffix[of M "initial M" p1 p2, OF path_prefix[of M "initial M" "p1@p2" p3, OF \<open>path M (initial M) ((p1@p2)@p3)\<close>]] 
    by assumption
  have "target (target (initial M) p1) p2 = (target (initial M) p1)"
    using path_append_target \<open>target (initial M) p1 = target (initial M) (p1 @ p2)\<close> 
    by auto
  
  have "path M (initial M) (p1 @ (concat (replicate n p2)) @ p3)"  
  proof (induction n)
    case 0 
    then show ?case 
      using path_append[OF \<open>path M (initial M) p1\<close> \<open>path M (target (initial M) p1) p3\<close>]  
      by auto
  next
    case (Suc n)
    then show ?case
      using \<open>path M (target (initial M) p1) p2\<close> \<open>target (target (initial M) p1) p2 = target (initial M) p1\<close> 
      by auto 
  qed
  moreover have "length (p1 @ (concat (replicate n p2)) @ p3) \<ge> n"
  proof -
    have "length (concat (replicate n p2)) = n * (length p2)" 
      using concat_replicate_length by metis
    moreover have "length p2 > 0"
      using \<open>p2 \<noteq> []\<close> by auto
    ultimately have "length (concat (replicate n p2)) \<ge> n"
      by (simp add: Suc_leI)
    then show ?thesis by auto
  qed
  ultimately show "\<exists> p . path M (initial M) p \<and> length p \<ge> n" by blast
qed


lemma cyclic_path_shortening : 
  assumes "path M q p"
  and     "\<not> distinct (visited_nodes q p)"
shows "\<exists> p' . path M q p' \<and> target q p' = target q p \<and> length p' < length p"
proof -
  obtain p1 p2 p3 where *: "p = p1@p2@p3 \<and> p2 \<noteq> [] \<and> target q p1 = target q (p1@p2)" 
    using cyclic_path_loop[OF assms] by blast
  then have "path M q (p1@p3)"
    using assms(1) by force
  moreover have "target q (p1@p3) = target q p"
    by (metis (full_types) * path_append_target)
  moreover have "length (p1@p3) < length p"
    using * by auto
  ultimately show ?thesis by blast
qed


lemma acyclic_path_from_cyclic_path :
  assumes "path M q p"
  and     "\<not> distinct (visited_nodes q p)"
obtains p' where "path M q p'" and "target q p = target q p'" and "distinct (visited_nodes q p')"
proof -
  
  let ?paths = "{p' . (path M q p' \<and> target q p' = target q p \<and> length p' \<le> length p)}"
  let ?minPath = "arg_min length (\<lambda> io . io \<in> ?paths)" 
  
  have "?paths \<noteq> empty" 
    using assms(1) by auto
  moreover have "finite ?paths" 
    using paths_finite[of M q "length p"]
    by (metis (no_types, lifting) Collect_mono rev_finite_subset)
  ultimately have minPath_def : "?minPath \<in> ?paths \<and> (\<forall> p' \<in> ?paths . length ?minPath \<le> length p')" 
    by (meson arg_min_nat_lemma equals0I)
  then have "path M q ?minPath" and "target q ?minPath = target q p" 
    by auto
  
  moreover have "distinct (visited_nodes q ?minPath)"
  proof (rule ccontr)
    assume "\<not> distinct (visited_nodes q ?minPath)"
    have "\<exists> p' . path M q p' \<and> target q p' = target q p \<and> length p' < length ?minPath" 
      using cyclic_path_shortening[OF \<open>path M q ?minPath\<close> \<open>\<not> distinct (visited_nodes q ?minPath)\<close>] minPath_def
            \<open>target q ?minPath= target q p\<close> by auto
    then show "False" 
      using minPath_def using arg_min_nat_le dual_order.strict_trans1 by auto 
  qed

  ultimately show ?thesis
    by (simp add: that)
qed    


lemma acyclic_path_length_limit :
  assumes "path M q p"
  and     "distinct (visited_nodes q p)"
shows "length p < size M"
proof (rule ccontr)
  assume *: "\<not> length p < size M"
  then have "length p \<ge> card (nodes M)"
    using size_def by auto
  then have "length (visited_nodes q p) > card (nodes M)"
    by auto
  moreover have "set (visited_nodes q p) \<subseteq> nodes M"
    by (metis assms(1) path_prefix path_target_is_node subsetI visited_nodes_prefix)
  ultimately have "\<not> distinct (visited_nodes q p)"
    using distinct_card[OF assms(2)] 
    using List.finite_set[of "visited_nodes q p"]
    by (metis card_mono fsm_nodes_finite leD) 
  then show "False" using assms(2) by blast
qed





subsection \<open>Reachable Nodes\<close>

definition reachable :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> bool" where
  "reachable M q = (\<exists> p . path M (initial M) p \<and> target (initial M) p = q)"

definition reachable_nodes :: "('a,'b,'c) fsm \<Rightarrow> 'a set" where
  "reachable_nodes M  = {target (initial M) p | p . path M (initial M) p }"

abbreviation "size_r M \<equiv> card (reachable_nodes M)"

lemma acyclic_paths_set :
  "acyclic_paths_up_to_length M q (size M - 1) = {p . path M q p \<and> distinct (visited_nodes q p)}"
  unfolding acyclic_paths_up_to_length.simps using acyclic_path_length_limit[of M q]
  by (metis (no_types, lifting) One_nat_def Suc_pred cyclic_path_shortening leD list.size(3) 
       not_less_eq_eq not_less_zero path.intros(1) path_begin_node) 


(* inefficient calculation, as a node may be target of a large number of acyclic paths *)
lemma reachable_nodes_code[code] : 
  "reachable_nodes M = image (target (initial M)) (acyclic_paths_up_to_length M (initial M) (size M - 1))"
proof -
  have "\<And> q' . q' \<in> reachable_nodes M 
            \<Longrightarrow> q' \<in> image (target (initial M)) (acyclic_paths_up_to_length M (initial M) (size M - 1))"
  proof -
    fix q' assume "q' \<in> reachable_nodes M"
    then obtain p where "path M (initial M) p" and "target (initial M) p = q'"
      unfolding reachable_nodes_def by blast
    
    obtain p' where "path M (initial M) p'" and "target (initial M) p' = q'" 
                and "distinct (visited_nodes (initial M) p')"
    proof (cases "distinct (visited_nodes (initial M) p)")
      case True
      then show ?thesis using \<open>path M (initial M) p\<close> \<open>target (initial M) p = q'\<close> that by auto
    next
      case False
      then show ?thesis 
        using acyclic_path_from_cyclic_path[OF \<open>path M (initial M) p\<close>] 
        unfolding \<open>target (initial M) p = q'\<close> using that by blast
    qed
    then show "q' \<in> image (target (initial M)) (acyclic_paths_up_to_length M (initial M) (size M - 1))"
      unfolding acyclic_paths_set by force
  qed
  moreover have "\<And> q' . q' \<in> image (target (initial M)) (acyclic_paths_up_to_length M (initial M) (size M - 1)) 
                    \<Longrightarrow> q' \<in> reachable_nodes M"
    unfolding reachable_nodes_def acyclic_paths_set by blast
  ultimately show ?thesis by blast
qed



lemma reachable_nodes_intro[intro!] :
  assumes "path M (initial M) p"
  shows "target (initial M) p \<in> reachable_nodes M"
  using assms unfolding reachable_nodes_def by auto


lemma reachable_nodes_initial :
  "initial M \<in> reachable_nodes M"
  unfolding reachable_nodes_def by auto


lemma reachable_nodes_next : 
  assumes "q \<in> reachable_nodes M" and "t \<in> transitions M" and "t_source t = q" 
  shows "t_target t \<in> reachable_nodes M" 
proof -
  from \<open>q \<in> reachable_nodes M\<close> obtain p where * :"path M (initial M) p"
                                        and   **:"target (initial M) p = q"
    unfolding reachable_nodes_def by auto

  then have "path M (initial M) (p@[t])" using assms(2,3) path_append_transition by metis
  moreover have "target (initial M) (p@[t]) = t_target t" by auto
  ultimately show ?thesis 
    unfolding reachable_nodes_def
    by (metis (mono_tags, lifting) mem_Collect_eq)
qed


lemma reachable_nodes_path :
  assumes "q \<in> reachable_nodes M"
  and     "path M q p"
  and     "t \<in> set p"
shows "t_source t \<in> reachable_nodes M"
using assms unfolding reachable_nodes_def proof (induction p arbitrary: q)
  case Nil
  then show ?case by auto
next
  case (Cons t' p')
  then show ?case proof (cases "t = t'")
    case True
    then show ?thesis using Cons.prems(1,2) by force
  next
    case False then show ?thesis using Cons
      by (metis (mono_tags, lifting) path_cons_elim reachable_nodes_def reachable_nodes_next 
            set_ConsD) 
  qed
qed


lemma reachable_nodes_initial_or_target :
  assumes "q \<in> reachable_nodes M"
  shows "q = initial M \<or> (\<exists> t \<in> transitions M . t_source t \<in> reachable_nodes M \<and> t_target t = q)"
proof -
  obtain p where "path M (initial M) p" and "target (initial M) p = q"
    using assms unfolding reachable_nodes_def by auto 
  
  show ?thesis proof (cases p rule: rev_cases)
    case Nil
    then show ?thesis using \<open>path M (initial M) p\<close> \<open>target (initial M) p = q\<close> by auto
  next
    case (snoc p' t)
    
    have "t \<in> transitions M"
      using \<open>path M (initial M) p\<close> unfolding snoc by auto
    moreover have "t_target t = q"
      using \<open>target (initial M) p = q\<close> unfolding snoc by auto
    moreover have "t_source t \<in> reachable_nodes M"
      using \<open>path M (initial M) p\<close> unfolding snoc
      by (metis append_is_Nil_conv last_in_set last_snoc not_Cons_self2 reachable_nodes_initial reachable_nodes_path) 

    ultimately show ?thesis
      by blast 
  qed 
qed


subsection \<open>Language\<close>

abbreviation "p_io (p :: ('state,'input,'output) path) \<equiv> map (\<lambda> t . (t_input t, t_output t)) p"

fun language_state_for_input :: "('state,'input,'output) fsm \<Rightarrow> 'state \<Rightarrow> 'input list \<Rightarrow> ('input \<times> 'output) list set" where
  "language_state_for_input M q xs = {p_io p | p . path M q p \<and> map fst (p_io p) = xs}"

fun LS\<^sub>i\<^sub>n :: "('state,'input,'output) fsm \<Rightarrow> 'state \<Rightarrow> 'input list set \<Rightarrow> ('input \<times> 'output) list set" where
  "LS\<^sub>i\<^sub>n M q xss = {p_io p | p . path M q p \<and> map fst (p_io p) \<in> xss}"

abbreviation(input) "L\<^sub>i\<^sub>n M \<equiv> LS\<^sub>i\<^sub>n M (initial M)"

lemma language_state_for_input_inputs : 
  assumes "io \<in> language_state_for_input M q xs"
  shows "map fst io = xs" 
  using assms by auto

lemma language_state_for_inputs_inputs : 
  assumes "io \<in> LS\<^sub>i\<^sub>n M q xss"
  shows "map fst io \<in> xss" using assms by auto 


fun LS :: "('state,'input,'output) fsm \<Rightarrow> 'state \<Rightarrow> ('input \<times> 'output) list set" where
  "LS M q = { p_io p | p . path M q p }"

abbreviation "L M \<equiv> LS M (initial M)"

lemma language_state_containment :
  assumes "path M q p"
  and     "p_io p = io"
shows "io \<in> LS M q"
  using assms by auto

lemma language_prefix : 
  assumes "io1@io2 \<in> LS M q"
  shows "io1 \<in> LS M q"
proof -
  obtain p where "path M q p" and "p_io p = io1@io2" 
    using assms by auto
  let ?tp = "take (length io1) p"
  have "path M q ?tp"
    by (metis (no_types) \<open>path M q p\<close> append_take_drop_id path_prefix) 
  moreover have "p_io ?tp = io1"
    using \<open>p_io p = io1@io2\<close> by (metis append_eq_conv_conj take_map) 
  ultimately show ?thesis
    by force 
qed

lemma language_contains_empty_sequence : "[] \<in> L M" 
  by auto


lemma language_state_split :
  assumes "io1 @ io2 \<in> LS M q1"
  obtains  p1 p2 where "path M q1 p1" 
                   and "path M (target q1 p1) p2"  
                   and "p_io p1 = io1" 
                   and "p_io p2 = io2"
proof -
  obtain p12 where "path M q1 p12" and "p_io p12 = io1 @ io2"
    using assms unfolding LS.simps by auto

  let ?p1 = "take (length io1) p12"
  let ?p2 = "drop (length io1) p12"

  have "p12 = ?p1 @ ?p2" 
    by auto
  then have "path M q1 (?p1 @ ?p2)"
    using \<open>path M q1 p12\<close> by auto

  have "path M q1 ?p1" and "path M (target q1 ?p1) ?p2"
    using path_append_elim[OF \<open>path M q1 (?p1 @ ?p2)\<close>] by blast+
  moreover have "p_io ?p1 = io1"
    using \<open>p12 = ?p1 @ ?p2\<close> \<open>p_io p12 = io1 @ io2\<close>
    by (metis append_eq_conv_conj take_map)
  moreover have "p_io ?p2 = io2"
    using \<open>p12 = ?p1 @ ?p2\<close> \<open>p_io p12 = io1 @ io2\<close>
    by (metis (no_types) \<open>p_io p12 = io1 @ io2\<close> append_eq_conv_conj drop_map) 
  ultimately show ?thesis using that by blast
qed


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


lemma language_split :
  assumes "io1@io2 \<in> L M"
  obtains p1 p2 where "path M (initial M) (p1@p2)" and "p_io p1 = io1" and "p_io p2 = io2"
proof -
  from assms obtain p where "path M (initial M) p" and "p_io p = io1 @ io2"
    by auto

  let ?p1 = "take (length io1) p"
  let ?p2 = "drop (length io1) p"

  have "path M (initial M) (?p1@?p2)"
    using \<open>path M (initial M) p\<close> by simp 
  moreover have "p_io ?p1 = io1" 
    using \<open>p_io p = io1 @ io2\<close>
    by (metis append_eq_conv_conj take_map) 
  moreover have "p_io ?p2 = io2" 
    using \<open>p_io p = io1 @ io2\<close>
    by (metis append_eq_conv_conj drop_map)
  ultimately show ?thesis using that by blast
qed

lemma language_io : 
  assumes "io \<in> L M"
  and     "(x,y) \<in> set io"
shows "x \<in> (inputs M)"
and   "y \<in> outputs M"
proof -
  obtain p where "path M (initial M) p" and "p_io p = io"
    using \<open>io \<in> L M\<close> by auto
  then obtain t where "t \<in> set p" and "t_input t = x" and "t_output t = y"
    using \<open>(x,y) \<in> set io\<close> by auto
  
  have "t \<in> transitions M"
    using \<open>path M (initial M) p\<close> \<open>t \<in> set p\<close>
    by (induction p; auto)

  show "x \<in> (inputs M)"
    using \<open>t \<in> transitions M\<close> \<open>t_input t = x\<close> by auto

  show "y \<in> outputs M"
    using \<open>t \<in> transitions M\<close> \<open>t_output t = y\<close> by auto
qed


lemma path_io_split :
  assumes "path M q p"
  and     "p_io p = io1@io2"
shows "path M q (take (length io1) p)"
and   "p_io (take (length io1) p) = io1"
and   "path M (target q (take (length io1) p)) (drop (length io1) p)"
and   "p_io (drop (length io1) p) = io2"
proof -
  have "length io1 \<le> length p"
    using \<open>p_io p = io1@io2\<close> 
    unfolding length_map[of "(\<lambda> t . (t_input t, t_output t))", symmetric]
    by auto

  have "p = (take (length io1) p)@(drop (length io1) p)"
    by simp
  then have *: "path M q ((take (length io1) p)@(drop (length io1) p))"
    using \<open>path M q p\<close> by auto

  show "path M q (take (length io1) p)"
       and  "path M (target q (take (length io1) p)) (drop (length io1) p)"
    using path_append_elim[OF *] by blast+

  show "p_io (take (length io1) p) = io1"
    using \<open>p = (take (length io1) p)@(drop (length io1) p)\<close> \<open>p_io p = io1@io2\<close>
    by (metis append_eq_conv_conj take_map) 

  show "p_io (drop (length io1) p) = io2"
    using \<open>p = (take (length io1) p)@(drop (length io1) p)\<close> \<open>p_io p = io1@io2\<close>
    by (metis append_eq_conv_conj drop_map)
qed


lemma language_intro :
  assumes "path M q p"
  shows "p_io p \<in> LS M q"
  using assms unfolding LS.simps by auto


lemma language_prefix_append :
  assumes "io1 @ (p_io p) \<in> L M"
shows   "io1 @ p_io (take i p) \<in> L M"
proof -
  fix i
  have "p_io p = (p_io (take i p)) @ (p_io (drop i p))"
    by (metis append_take_drop_id map_append) 
  then have "(io1 @ (p_io (take i p))) @ (p_io (drop i p)) \<in> L M"
    using \<open>io1 @ p_io p \<in> L M\<close> by auto
  show "io1 @ p_io (take i p) \<in> L M" 
    using language_prefix[OF \<open>(io1 @ (p_io (take i p))) @ (p_io (drop i p)) \<in> L M\<close>] 
    by assumption
qed


lemma language_finite: "finite {io . io \<in> L M \<and> length io \<le> k}"
proof -
  have "{io . io \<in> L M \<and> length io \<le> k} \<subseteq> p_io  ` {p. path M (FSM.initial M) p \<and> length p \<le> k}"
    by auto
  then show ?thesis
    using paths_finite[of M "initial M" k]
    using finite_surj by auto 
qed


subsection \<open>Basic FSM Properties\<close>

subsubsection \<open>Completely Specified\<close>

fun completely_specified :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "completely_specified M = (\<forall> q \<in> nodes M . \<forall> x \<in> inputs M . \<exists> t \<in> transitions M . t_source t = q \<and> t_input t = x)"


lemma completely_specified_alt_def : 
  "completely_specified M = (\<forall> q \<in> nodes M . \<forall> x \<in> inputs M . \<exists> q' y . (q,x,y,q') \<in> transitions M)"
  by force

lemma completely_specified_alt_def_h : 
  "completely_specified M = (\<forall> q \<in> nodes M . \<forall> x \<in> inputs M . h M (q,x) \<noteq> {})"
  by force



fun completely_specified_state :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> bool" where
  "completely_specified_state M q = (\<forall> x \<in> inputs M . \<exists> t \<in> transitions M . t_source t = q \<and> t_input t = x)"

lemma completely_specified_states :
  "completely_specified M = (\<forall> q \<in> nodes M . completely_specified_state M q)"
  unfolding completely_specified.simps completely_specified_state.simps by force

lemma completely_specified_state_alt_def_h : 
  "completely_specified_state M q = (\<forall> x \<in> inputs M . h M (q,x) \<noteq> {})"
  by force


lemma completely_specified_path_extension : 
  assumes "completely_specified M"
  and     "q \<in> nodes M"
  and     "path M q p"
  and     "x \<in> (inputs M)"
obtains t where "t \<in> transitions M" and "t_input t = x" and "t_source t = target q p"
proof -
  have "target q p \<in> nodes M"
    using path_target_is_node \<open>path M q p\<close> by metis
  then obtain t where "t \<in> transitions M" and "t_input t = x" and "t_source t = target q p"
    using \<open>completely_specified M\<close> \<open>x \<in> (inputs M)\<close> 
    unfolding completely_specified.simps by blast
  then show ?thesis using that by blast
qed


lemma completely_specified_language_extension :
  assumes "completely_specified M"
  and     "q \<in> nodes M"
  and     "io \<in> LS M q"
  and     "x \<in> (inputs M)"
obtains y where "io@[(x,y)] \<in> LS M q"
proof -
  obtain p where "path M q p" and "p_io p = io"
    using \<open>io \<in> LS M q\<close> by auto
  
  moreover obtain t where "t \<in> transitions M" and "t_input t = x" and "t_source t = target q p"
    using completely_specified_path_extension[OF assms(1,2) \<open>path M q p\<close> assms(4)] by blast

  ultimately have "path M q (p@[t])" and "p_io (p@[t]) = io@[(x,t_output t)]"
    by (simp add: path_append_transition)+
    
  then have "io@[(x,t_output t)] \<in> LS M q"
    using language_state_containment[of M q "p@[t]" "io@[(x,t_output t)]"] by auto
  then show ?thesis using that by blast
qed
  

lemma path_of_length_ex :
  assumes "completely_specified M"
  and     "q \<in> nodes M"
  and     "inputs M \<noteq> {}"
shows "\<exists> p . path M q p \<and> length p = k" 
using assms(2) proof (induction k arbitrary: q)
  case 0
  then show ?case by auto
next
  case (Suc k)

  obtain t where "t_source t = q" and "t \<in> transitions M"
    by (meson Suc.prems assms(1) assms(3) completely_specified.simps equals0I)
  then have "t_target t \<in> nodes M"
    using fsm_transition_target by blast
  then obtain p where "path M (t_target t) p \<and> length p = k"
    using Suc.IH by blast
  then show ?case 
    using \<open>t_source t = q\<close> \<open>t \<in> transitions M\<close>
    by auto 
qed


subsubsection \<open>Deterministic\<close>

fun deterministic :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "deterministic M = (\<forall> t1 \<in> transitions M . 
                        \<forall> t2 \<in> transitions M . 
                          (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2) 
                          \<longrightarrow> (t_output t1 = t_output t2 \<and> t_target t1 = t_target t2))" 

lemma deterministic_alt_def : 
  "deterministic M = (\<forall> q1 x y' y''  q1' q1'' . (q1,x,y',q1') \<in> transitions M \<and> (q1,x,y'',q1'') \<in> transitions M \<longrightarrow> y' = y'' \<and> q1' = q1'')" 
  by auto

lemma deterministic_alt_def_h : 
  "deterministic M = (\<forall> q1 x yq yq' . (yq \<in> h M (q1,x) \<and> yq' \<in> h M (q1,x)) \<longrightarrow> yq = yq')"
  by auto



subsubsection \<open>Observable\<close>

fun observable :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "observable M = (\<forall> t1 \<in> transitions M . 
                    \<forall> t2 \<in> transitions M . 
                      (t_source t1 = t_source t2 \<and> t_input t1 = t_input t2 \<and> t_output t1 = t_output t2) 
                        \<longrightarrow> t_target t1 = t_target t2)" 

lemma observable_alt_def : 
  "observable M = (\<forall> q1 x y q1' q1'' . (q1,x,y,q1') \<in> transitions M \<and> (q1,x,y,q1'') \<in> transitions M \<longrightarrow> q1' = q1'')" 
  by auto

lemma observable_alt_def_h : 
  "observable M = (\<forall> q1 x yq yq' . (yq \<in> h M (q1,x) \<and> yq' \<in> h M (q1,x)) \<longrightarrow> fst yq = fst yq' \<longrightarrow> snd yq = snd yq')"
  by auto


lemma language_append_path_ob :
  assumes "io@[(x,y)] \<in> L M"
  obtains p t where "path M (initial M) (p@[t])" and "p_io p = io" and "t_input t = x" and "t_output t = y"
proof -
  obtain p p2 where "path M (initial M) p" and "path M (target (initial M) p) p2"  and "p_io p = io" and "p_io p2 = [(x,y)]"
    using language_state_split[OF assms] by blast

  obtain t where "p2 = [t]" and "t_input t = x" and "t_output t = y"
    using \<open>p_io p2 = [(x,y)]\<close> by auto

  have "path M (initial M) (p@[t])"
    using \<open>path M (initial M) p\<close> \<open>path M (target (initial M) p) p2\<close> unfolding \<open>p2 = [t]\<close> by auto
  then show ?thesis using that[OF _ \<open>p_io p = io\<close> \<open>t_input t = x\<close> \<open>t_output t = y\<close>]
    by simp 
qed


subsubsection \<open>Single Input\<close>

(* each state has at most one input, but may have none *)
fun single_input :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "single_input M = (\<forall> t1 \<in> transitions M . 
                      \<forall> t2 \<in> transitions M . 
                        t_source t1 = t_source t2 \<longrightarrow> t_input t1 = t_input t2)" 


lemma single_input_alt_def : 
  "single_input M = (\<forall> q1 x x' y y' q1' q1'' . (q1,x,y,q1') \<in> transitions M \<and> (q1,x',y',q1'') \<in> transitions M \<longrightarrow> x = x')"
  by fastforce

lemma single_input_alt_def_h : 
  "single_input M = (\<forall> q x x' . (h M (q,x) \<noteq> {} \<and> h M (q,x') \<noteq> {}) \<longrightarrow> x = x')"
  by force
    

subsubsection \<open>Output Complete\<close>

fun output_complete :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "output_complete M = (\<forall> t \<in> transitions M . 
                          \<forall> y \<in> outputs M . 
                            \<exists> t' \<in> transitions M . t_source t = t_source t' \<and> 
                                                    t_input t = t_input t' \<and> 
                                                    t_output t' = y)" 

lemma output_complete_alt_def : 
  "output_complete M = (\<forall> q x . (\<exists> y q' . (q,x,y,q') \<in> transitions M) \<longrightarrow> (\<forall> y \<in> (outputs M) . \<exists> q' . (q,x,y,q') \<in> transitions M))" 
  by force

lemma output_complete_alt_def_h : 
  "output_complete M = (\<forall> q x . h M (q,x) \<noteq> {} \<longrightarrow> (\<forall> y \<in> outputs M . \<exists> q' . (y,q') \<in> h M (q,x)))"
  by force



subsubsection \<open>Acyclic\<close>

fun acyclic :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "acyclic M = (\<forall> p . path M (initial M) p \<longrightarrow> distinct (visited_nodes (initial M) p))"


lemma visited_nodes_length : "length (visited_nodes q p) = Suc (length p)" by auto

lemma visited_nodes_take : 
  "(take (Suc n) (visited_nodes q p)) = (visited_nodes q (take n p))"
proof (induction p rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc x xs)
  then show ?case by (cases "n \<le> length xs"; auto)
qed


(* very inefficient calculation *)
lemma acyclic_code[code] : 
  "acyclic M = (\<not>(\<exists> p \<in> (acyclic_paths_up_to_length M (initial M) (size M - 1)) . 
                    \<exists> t \<in> transitions M . t_source t = target (initial M) p \<and> 
                                           t_target t \<in> set (visited_nodes (initial M) p)))"
proof -
  have "(\<exists> p \<in> (acyclic_paths_up_to_length M (initial M) (size M - 1)) . 
          \<exists> t \<in> transitions M . t_source t = target (initial M) p \<and> 
                t_target t \<in> set (visited_nodes (initial M) p)) 
        \<Longrightarrow> \<not> FSM.acyclic M"
  proof -
    assume "(\<exists> p \<in> (acyclic_paths_up_to_length M (initial M) (size M - 1)) . 
              \<exists> t \<in> transitions M . t_source t = target (initial M) p \<and> 
                                    t_target t \<in> set (visited_nodes (initial M) p))"
    then obtain p t where "path M (initial M) p"
                    and   "distinct (visited_nodes (initial M) p)"
                    and   "t \<in> transitions M"
                    and   "t_source t = target (initial M) p" 
                    and   "t_target t \<in> set (visited_nodes (initial M) p)"
      unfolding acyclic_paths_set by blast
    then have "path M (initial M) (p@[t])"
      by (simp add: path_append_transition) 
    moreover have "\<not> (distinct (visited_nodes (initial M) (p@[t])))"
      using \<open>t_target t \<in> set (visited_nodes (initial M) p)\<close> by auto
    ultimately show "\<not> FSM.acyclic M"
      by (meson acyclic.elims(2))
  qed
  moreover have "\<not> FSM.acyclic M \<Longrightarrow> 
                  (\<exists> p \<in> (acyclic_paths_up_to_length M (initial M) (size M - 1)) . 
                    \<exists> t \<in> transitions M . t_source t = target (initial M) p \<and> 
                                          t_target t \<in> set (visited_nodes (initial M) p))"
  proof -
    assume "\<not> FSM.acyclic M"
    then obtain p where "path M (initial M) p"
                  and   "\<not> distinct (visited_nodes (initial M) p)"
      by auto
    then obtain n where "distinct (take (Suc n) (visited_nodes (initial M) p))"
                  and   "\<not> distinct (take (Suc (Suc n)) (visited_nodes (initial M) p))"
      using maximal_distinct_prefix by blast
    then have "distinct (visited_nodes (initial M) (take n p))"
         and   "\<not> distinct (visited_nodes (initial M)(take (Suc n) p))"
      unfolding visited_nodes_take by simp+

    then obtain p' t' where *: "take n p = p'"
                      and   **: "take (Suc n) p = p' @ [t']"
      by (metis Suc_less_eq \<open>\<not> distinct (visited_nodes (FSM.initial M) p)\<close> 
            le_imp_less_Suc not_less_eq_eq take_all take_hd_drop)
    
    have ***: "visited_nodes (FSM.initial M) (p' @ [t']) = (visited_nodes (FSM.initial M) p')@[t_target t']"
      by auto

    have "path M (initial M) p'"
      using * \<open>path M (initial M) p\<close>
      by (metis append_take_drop_id path_prefix)
    then have "p' \<in> (acyclic_paths_up_to_length M (initial M) (size M - 1))"
      using \<open>distinct (visited_nodes (initial M) (take n p))\<close>
      unfolding * acyclic_paths_set by blast
    moreover have "t' \<in> transitions M \<and> t_source t' = target (initial M) p'"
      using * ** \<open>path M (initial M) p\<close>
      by (metis append_take_drop_id path_append_elim path_cons_elim)
       
    moreover have "t_target t' \<in> set (visited_nodes (initial M) p')"
      using \<open>distinct (visited_nodes (initial M) (take n p))\<close> 
            \<open>\<not> distinct (visited_nodes (initial M)(take (Suc n) p))\<close>
      unfolding * ** *** by auto 
    ultimately show "(\<exists> p \<in> (acyclic_paths_up_to_length M (initial M) (size M - 1)) . 
                      \<exists> t \<in> transitions M . t_source t = target (initial M) p \<and> 
                                            t_target t \<in> set (visited_nodes (initial M) p))"
      by blast
  qed
  ultimately show ?thesis by blast
qed




lemma acyclic_alt_def : "acyclic M = finite (L M)"
proof 
  show "acyclic M \<Longrightarrow> finite (L M)"
  proof -
    assume "acyclic M"
    then have "{ p . path M (initial M) p} \<subseteq> (acyclic_paths_up_to_length M (initial M) (size M - 1))"
      unfolding acyclic_paths_set by auto
    moreover have "finite (acyclic_paths_up_to_length M (initial M) (size M - 1))"
      unfolding acyclic_paths_up_to_length.simps using paths_finite[of M "initial M" "size M - 1"]
      by (metis (mono_tags, lifting) Collect_cong \<open>FSM.acyclic M\<close> acyclic.elims(2)) 
    ultimately have "finite { p . path M (initial M) p}"
      using finite_subset by blast
    then show "finite (L M)"
      unfolding LS.simps by auto
  qed

  show "finite (L M) \<Longrightarrow> acyclic M"
  proof (rule ccontr)
    assume "finite (L M)"
    assume "\<not> acyclic M"
    
    obtain max_io_len where "\<forall>io \<in> L M . length io < max_io_len"
      using finite_maxlen[OF \<open>finite (L M)\<close>] by blast
    then have "\<And> p . path M (initial M) p \<Longrightarrow> length p < max_io_len"
    proof -
      fix p assume "path M (initial M) p"
      show "length p < max_io_len"
      proof (rule ccontr)
        assume "\<not> length p < max_io_len"
        then have "\<not> length (p_io p) < max_io_len" by auto
        moreover have "p_io p \<in> L M"
          unfolding LS.simps using \<open>path M (initial M) p\<close> by blast
        ultimately show "False"
          using \<open>\<forall>io \<in> L M . length io < max_io_len\<close> by blast
      qed
    qed

    obtain p where "path M (initial M) p" and "\<not> distinct (visited_nodes (initial M) p)"
      using \<open>\<not> acyclic M\<close> unfolding acyclic.simps by blast
    then obtain pL where "path M (initial M) pL" and "max_io_len \<le> length pL"
      using cyclic_path_pumping[of M p max_io_len] by blast
    then show "False"
      using \<open>\<And> p . path M (initial M) p \<Longrightarrow> length p < max_io_len\<close>
      using not_le by blast 
  qed
qed


lemma acyclic_finite_paths_from_reachable_node :
  assumes "acyclic M"
  and     "path M (initial M) p" 
  and     "target (initial M) p = q"
    shows "finite {p . path M q p}"
proof -
  from assms have "{ p . path M (initial M) p} \<subseteq> (acyclic_paths_up_to_length M (initial M) (size M - 1))"
    unfolding acyclic_paths_set by auto
  moreover have "finite (acyclic_paths_up_to_length M (initial M) (size M - 1))"
    unfolding acyclic_paths_up_to_length.simps using paths_finite[of M "initial M" "size M - 1"]
    by (metis (mono_tags, lifting) Collect_cong \<open>FSM.acyclic M\<close> acyclic.elims(2)) 
  ultimately have "finite { p . path M (initial M) p}"
    using finite_subset by blast

  show "finite {p . path M q p}"
  proof (cases "q \<in> nodes M")
    case True
        
    have "image (\<lambda>p' . p@p') {p' . path M q p'} \<subseteq> {p' . path M (initial M) p'}"
    proof 
      fix x assume "x \<in> image (\<lambda>p' . p@p') {p' . path M q p'}"
      then obtain p' where "x = p@p'" and "p' \<in> {p' . path M q p'}"
        by blast
      then have "path M q p'" by auto
      then have "path M (initial M) (p@p')"
        using path_append[OF \<open>path M (initial M) p\<close>] \<open>target (initial M) p = q\<close> by auto
      then show "x \<in> {p' . path M (initial M) p'}" using \<open>x = p@p'\<close> by blast
    qed
    
    then have "finite (image (\<lambda>p' . p@p') {p' . path M q p'})"
      using \<open>finite { p . path M (initial M) p}\<close> finite_subset by auto 
    show ?thesis using finite_imageD[OF \<open>finite (image (\<lambda>p' . p@p') {p' . path M q p'})\<close>]
      by (meson inj_onI same_append_eq) 
  next
    case False
    then show ?thesis
      by (meson not_finite_existsD path_begin_node) 
  qed
qed


lemma acyclic_paths_from_reachable_nodes :
  assumes "acyclic M" 
  and     "path M (initial M) p'" 
  and     "target (initial M) p' = q"
  and     "path M q p"
shows "distinct (visited_nodes q p)"
proof -
  have "path M (initial M) (p'@p)"
    using assms(2,3,4) path_append by metis
  then have "distinct (visited_nodes (initial M) (p'@p))"
    using assms(1) unfolding acyclic.simps by blast
  then have "distinct (initial M # (map t_target p') @ map t_target p)"
    by auto
  moreover have "initial M # (map t_target p') @ map t_target p 
                  = (butlast (initial M # map t_target p')) @ ((last (initial M # map t_target p')) # map t_target p)"
    by auto
  ultimately have "distinct ((last (initial M # map t_target p')) # map t_target p)"
    by auto
  then show ?thesis 
    using \<open>target (initial M) p' = q\<close> unfolding visited_nodes.simps target.simps by simp
qed

definition LS_acyclic :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> ('b \<times> 'c) list set" where
  "LS_acyclic M q = {p_io p | p .  path M q p \<and> distinct (visited_nodes q p)}"

lemma LS_acyclic_code[code] : 
  "LS_acyclic M q = image p_io (acyclic_paths_up_to_length M q (size M - 1))"
  unfolding acyclic_paths_set LS_acyclic_def by blast

lemma LS_from_LS_acyclic : 
  assumes "acyclic M" 
  shows "L M = LS_acyclic M (initial M)"
proof -
  obtain pps :: "(('b \<times> 'c) list \<Rightarrow> bool) \<Rightarrow> (('b \<times> 'c) list \<Rightarrow> bool) \<Rightarrow> ('b \<times> 'c) list" where
    f1: "\<forall>p pa. (\<not> p (pps pa p)) = pa (pps pa p) \<or> Collect p = Collect pa"
    by (metis (no_types) Collect_cong)
  have "\<forall>ps. \<not> path M (FSM.initial M) ps \<or> distinct (visited_nodes (FSM.initial M) ps)"
    using acyclic.simps assms by blast
  then have "(\<nexists>ps. pps (\<lambda>ps. \<exists>psa. ps = p_io psa \<and> path M (FSM.initial M) psa) 
                       (\<lambda>ps. \<exists>psa. ps = p_io psa \<and> path M (FSM.initial M) psa 
                                    \<and> distinct (visited_nodes (FSM.initial M) psa)) 
                  = p_io ps \<and> path M (FSM.initial M) ps \<and> distinct (visited_nodes (FSM.initial M) ps)) 
            \<noteq> (\<exists>ps. pps (\<lambda>ps. \<exists>psa. ps = p_io psa \<and> path M (FSM.initial M) psa) 
                        (\<lambda>ps. \<exists>psa. ps = p_io psa \<and> path M (FSM.initial M) psa 
                                    \<and> distinct (visited_nodes (FSM.initial M) psa)) 
                  = p_io ps \<and> path M (FSM.initial M) ps)"
    by blast
  then have "{p_io ps |ps. path M (FSM.initial M) ps \<and> distinct (visited_nodes (FSM.initial M) ps)} 
              = {p_io ps |ps. path M (FSM.initial M) ps}"
    using f1 
    by (meson \<open>\<forall>ps. \<not> path M (FSM.initial M) ps \<or> distinct (visited_nodes (FSM.initial M) ps)\<close>) 
  then show ?thesis
    by (simp add: LS_acyclic_def)
qed



lemma cyclic_cycle :
  assumes "\<not> acyclic M"
  shows "\<exists> q p . path M q p \<and> p \<noteq> [] \<and> target q p = q" 
proof -
  from \<open>\<not> acyclic M\<close> obtain p t where "path M (initial M) (p@[t])" 
                                  and "\<not>distinct (visited_nodes (initial M) (p@[t]))"
    by (metis (no_types, hide_lams) Nil_is_append_conv acyclic.simps append_take_drop_id 
          maximal_distinct_prefix rev_exhaust visited_nodes_take)
     

  show ?thesis
  proof (cases "initial M \<in> set (map t_target (p@[t]))")
    case True
    then obtain i where "last (take i (map t_target (p@[t]))) = initial M" 
                    and "i \<le> length (map t_target (p@[t]))" and "0 < i"
      using list_contains_last_take by metis

    let ?p = "take i (p@[t])"
    have "path M (initial M) (?p@(drop i (p@[t])))" 
      using \<open>path M (initial M) (p@[t])\<close>
      by (metis append_take_drop_id)  
    then have "path M (initial M) ?p" by auto
    moreover have "?p \<noteq> []" using \<open>0 < i\<close> by auto
    moreover have "target (initial M) ?p = initial M"
      using \<open>last (take i (map t_target (p@[t]))) = initial M\<close> 
      unfolding target.simps visited_nodes.simps
      by (metis (no_types, lifting) calculation(2) last_ConsR list.map_disc_iff take_map) 
    ultimately show ?thesis by blast
  next
    case False
    then have "\<not> distinct (map t_target (p@[t]))"
      using \<open>\<not>distinct (visited_nodes (initial M) (p@[t]))\<close> 
      unfolding visited_nodes.simps 
      by auto
    then obtain i j where "i < j" and "j < length (map t_target (p@[t]))" 
                      and "(map t_target (p@[t])) ! i = (map t_target (p@[t])) ! j"
      using non_distinct_repetition_indices by blast

    let ?pre_i = "take (Suc i) (p@[t])"
    let ?p = "take ((Suc j)-(Suc i)) (drop (Suc i) (p@[t]))"
    let ?post_j = "drop ((Suc j)-(Suc i)) (drop (Suc i) (p@[t]))"

    have "p@[t] = ?pre_i @ ?p @ ?post_j"
      using \<open>i < j\<close> \<open>j < length (map t_target (p@[t]))\<close>
      by (metis append_take_drop_id) 
    then have "path M (target (initial M) ?pre_i) ?p" 
      using \<open>path M (initial M) (p@[t])\<close>
      by (metis path_prefix path_suffix) 

    have "?p \<noteq> []"
      using \<open>i < j\<close> \<open>j < length (map t_target (p@[t]))\<close> by auto

    have "i < length (map t_target (p@[t]))"
      using \<open>i < j\<close> \<open>j < length (map t_target (p@[t]))\<close> by auto
    have "(target (initial M) ?pre_i) = (map t_target (p@[t])) ! i"
      unfolding target.simps visited_nodes.simps  
      using take_last_index[OF \<open>i < length (map t_target (p@[t]))\<close>]
      by (metis (no_types, lifting) \<open>i < length (map t_target (p @ [t]))\<close> 
          last_ConsR snoc_eq_iff_butlast take_Suc_conv_app_nth take_map) 
    
    have "?pre_i@?p = take (Suc j) (p@[t])"
      by (metis (no_types) \<open>i < j\<close> add_Suc add_diff_cancel_left' less_SucI less_imp_Suc_add take_add)
    moreover have "(target (initial M) (take (Suc j) (p@[t]))) = (map t_target (p@[t])) ! j"
      unfolding target.simps visited_nodes.simps  
      using take_last_index[OF \<open>j < length (map t_target (p@[t]))\<close>]
      by (metis (no_types, lifting) \<open>j < length (map t_target (p @ [t]))\<close> 
            last_ConsR snoc_eq_iff_butlast take_Suc_conv_app_nth take_map) 
    ultimately have "(target (initial M) (?pre_i@?p)) = (map t_target (p@[t])) ! j"
      by auto
    then have "(target (initial M) (?pre_i@?p)) = (map t_target (p@[t])) ! i"
      using \<open>(map t_target (p@[t])) ! i = (map t_target (p@[t])) ! j\<close> by simp
    moreover have "(target (initial M) (?pre_i@?p)) = (target (target (initial M) ?pre_i) ?p)"
      unfolding target.simps visited_nodes.simps last.simps by auto
    ultimately have "(target (target (initial M) ?pre_i) ?p) = (map t_target (p@[t])) ! i"
      by auto
    then have "(target (target (initial M) ?pre_i) ?p) = (target (initial M) ?pre_i)"
      using \<open>(target (initial M) ?pre_i) = (map t_target (p@[t])) ! i\<close> by auto

    show ?thesis
      using \<open>path M (target (initial M) ?pre_i) ?p\<close> \<open>?p \<noteq> []\<close> 
            \<open>(target (target (initial M) ?pre_i) ?p) = (target (initial M) ?pre_i)\<close>
      by blast
  qed
qed


lemma cyclic_cycle_rev :
  fixes M :: "('a,'b,'c) fsm"
  assumes "path M (initial M) p'"
  and     "target (initial M) p' = q" 
  and     "path M q p"
  and     "p \<noteq> []"
  and     "target q p = q"
shows "\<not> acyclic M"
  using assms unfolding acyclic.simps target.simps visited_nodes.simps
  using distinct.simps(2) by fastforce

lemma acyclic_initial :
  assumes "acyclic M"
  shows "\<not> (\<exists> t \<in> transitions M . t_target t = initial M \<and> 
                                  (\<exists> p . path M (initial M) p \<and> target (initial M) p = t_source t))"
  by (metis append_Cons assms cyclic_cycle_rev list.distinct(1) path.simps 
        path_append path_append_transition_elim(3) single_transition_path) 

lemma cyclic_path_shift : 
  assumes "path M q p"
  and     "target q p = q"
shows "path M (target q (take i p)) ((drop i p) @ (take i p))"
  and "target (target q (take i p)) ((drop i p) @ (take i p)) = (target q (take i p))"
proof -
  show "path M (target q (take i p)) ((drop i p) @ (take i p))"
    by (metis append_take_drop_id assms(1) assms(2) path_append path_append_elim path_append_target)
  show "target (target q (take i p)) ((drop i p) @ (take i p)) = (target q (take i p))"
    by (metis append_take_drop_id assms(2) path_append_target)
qed


lemma cyclic_path_transition_nodes_property :
  assumes "\<exists> t \<in> set p . P (t_source t)"
  and     "\<forall> t \<in> set p . P (t_source t) \<longrightarrow> P (t_target t)"
  and     "path M q p"
  and     "target q p = q"
shows "\<forall> t \<in> set p . P (t_source t)"
  and "\<forall> t \<in> set p . P (t_target t)"
proof -
  obtain t0 where "t0 \<in> set p" and "P (t_source t0)"
    using assms(1) by blast
  then obtain i where "i < length p" and "p ! i = t0"
    by (meson in_set_conv_nth)

  let ?p = "(drop i p @ take i p)"
  have "path M (target q (take i p)) ?p"
    using cyclic_path_shift(1)[OF assms(3,4), of i] by assumption
  
  have "set ?p = set p"
  proof -
    have "set ?p = set (take i p @ drop i p)" 
      using list_set_sym by metis
    then show ?thesis by auto
  qed
  then have "\<And> t . t \<in> set ?p \<Longrightarrow> P (t_source t) \<Longrightarrow> P (t_target t)"
    using assms(2) by blast
  
  have "\<And> j . j < length ?p \<Longrightarrow> P (t_source (?p ! j))"
  proof -
    fix j assume "j < length ?p"
    then show "P (t_source (?p ! j))"
    proof (induction j)
      case 0
      then show ?case 
        using \<open>p ! i = t0\<close> \<open>P (t_source t0)\<close>
        by (metis \<open>i < length p\<close> drop_eq_Nil hd_append2 hd_conv_nth hd_drop_conv_nth leD 
              length_greater_0_conv)  
    next
      case (Suc j)
      then have "P (t_source (?p ! j))"
        by auto
      then have "P (t_target (?p ! j))"
        using Suc.prems \<open>\<And> t . t \<in> set ?p \<Longrightarrow> P (t_source t) \<Longrightarrow> P (t_target t)\<close>[of "?p ! j"]
        using Suc_lessD nth_mem by blast 
      moreover have "t_target (?p ! j) = t_source (?p ! (Suc j))"
        using path_source_target_index[OF Suc.prems \<open>path M (target q (take i p)) ?p\<close>] 
        by assumption
      ultimately show ?case 
        using \<open>\<And> t . t \<in> set ?p \<Longrightarrow> P (t_source t) \<Longrightarrow> P (t_target t)\<close>[of "?p ! j"]
        by simp
    qed
  qed
  then have "\<forall> t \<in> set ?p . P (t_source t)"
    by (metis in_set_conv_nth)
  then show "\<forall> t \<in> set p . P (t_source t)"
    using \<open>set ?p = set p\<close> by blast
  then show "\<forall> t \<in> set p . P (t_target t)"
    using assms(2) by blast
qed


lemma cycle_incoming_transition_ex :
  assumes "path M q p"
  and     "p \<noteq> []"
  and     "target q p = q"
  and     "t \<in> set p"
shows "\<exists> tI \<in> set p . t_target tI = t_source t"
proof -
  obtain i where "i < length p" and "p ! i = t"
    using assms(4) by (meson in_set_conv_nth)

  let ?p = "(drop i p @ take i p)"
  have "path M (target q (take i p)) ?p"
  and  "target (target q (take i p)) ?p = target q (take i p)"
    using cyclic_path_shift[OF assms(1,3), of i] by linarith+

  have "p = (take i p @ drop i p)" by auto
  then have "path M (target q (take i p)) (drop i p)" 
    using path_suffix assms(1) by metis
  moreover have "t = hd (drop i p)"
    using \<open>i < length p\<close> \<open>p ! i = t\<close>
    by (simp add: hd_drop_conv_nth) 
  ultimately have "path M (target q (take i p)) [t]"
    by (metis \<open>i < length p\<close> append_take_drop_id assms(1) path_append_elim take_hd_drop)
  then have "t_source t = (target q (take i p))"
    by auto  
  moreover have "t_target (last ?p) = (target q (take i p))" 
    using \<open>path M (target q (take i p)) ?p\<close> \<open>target (target q (take i p)) ?p = target q (take i p)\<close> 
          assms(2)
    unfolding target.simps visited_nodes.simps last.simps
    by (metis (no_types, lifting) \<open>p = take i p @ drop i p\<close> append_is_Nil_conv last_map 
          list.map_disc_iff)
    
  
  moreover have "set ?p = set p"
  proof -
    have "set ?p = set (take i p @ drop i p)" 
      using list_set_sym by metis
    then show ?thesis by auto
  qed

  ultimately show ?thesis
    by (metis \<open>i < length p\<close> append_is_Nil_conv drop_eq_Nil last_in_set leD) 
qed


lemma acyclic_paths_finite :
  "finite {p . path M q p \<and> distinct (visited_nodes q p) }"
proof -
  have "\<And> p . path M q p \<Longrightarrow> distinct (visited_nodes q p) \<Longrightarrow> distinct p"
  proof -
    fix p assume "path M q p" and "distinct (visited_nodes q p)"
    then have "distinct (map t_target p)" by auto
    then show "distinct p" by (simp add: distinct_map) 
  qed
  
  then show ?thesis
    using distinct_lists_finite[OF fsm_transitions_finite, of M]  path_transitions[of M q]
    by (metis (no_types, lifting) infinite_super mem_Collect_eq path_transitions subsetI)
qed


lemma acyclic_no_self_loop :
  assumes "acyclic M"
  and     "q \<in> reachable_nodes M"
shows "\<not> (\<exists> x y . (q,x,y,q) \<in> transitions M)" 
proof 
  assume "\<exists>x y. (q, x, y, q) \<in> FSM.transitions M"
  then obtain x y where "(q, x, y, q) \<in> FSM.transitions M" by blast
  moreover obtain p where "path M (initial M) p" and "target (initial M) p = q"
    using assms(2) unfolding reachable_nodes_def by blast
  ultimately have "path M (initial M) (p@[(q,x,y,q)])" 
    by (simp add: path_append_transition) 
  moreover have "\<not> (distinct (visited_nodes (initial M) (p@[(q,x,y,q)])))"
    using \<open>target (initial M) p = q\<close> unfolding visited_nodes.simps target.simps by (cases p rule: rev_cases; auto)
  ultimately show "False"
    using assms(1) unfolding acyclic.simps
    by meson 
qed


subsubsection \<open>Deadlock Nodes\<close>

fun deadlock_state :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> bool" where 
  "deadlock_state M q = (\<not>(\<exists> t \<in> transitions M . t_source t = q))"

lemma deadlock_state_alt_def : "deadlock_state M q = (LS M q \<subseteq> {[]})" 
proof 
  show "deadlock_state M q \<Longrightarrow> LS M q \<subseteq> {[]}" 
  proof -
    assume "deadlock_state M q"
    moreover have "\<And> p . deadlock_state M q \<Longrightarrow> path M q p \<Longrightarrow> p = []"
      unfolding deadlock_state.simps by (metis path.cases) 
    ultimately show "LS M q \<subseteq> {[]}"
      unfolding LS.simps by blast
  qed
  show "LS M q \<subseteq> {[]} \<Longrightarrow> deadlock_state M q"
    unfolding LS.simps deadlock_state.simps using path.cases[of M q] by blast
qed

lemma deadlock_state_alt_def_h : "deadlock_state M q = (\<forall> x \<in> inputs M . h M (q,x) = {})" 
  unfolding deadlock_state.simps h.simps 
  using fsm_transition_input by force

lemma reachable_node_is_node : 
  "q \<in> reachable_nodes M \<Longrightarrow> q \<in> nodes M" 
  unfolding reachable_nodes_def using path_target_is_node by fastforce 

lemma acyclic_deadlock_reachable :
  assumes "acyclic M"
  shows "\<exists> q \<in> reachable_nodes M . deadlock_state M q"
proof (rule ccontr)
  assume "\<not> (\<exists>q\<in>reachable_nodes M. deadlock_state M q)"
  then have *: "\<And> q . q \<in> reachable_nodes M \<Longrightarrow> (\<exists> t \<in> transitions M . t_source t = q)"
    unfolding deadlock_state.simps by blast

  let ?p = "arg_max_on length {p. path M (initial M) p}"
  

  have "finite {p. path M (initial M) p}" 
    by (metis Collect_cong acyclic_finite_paths_from_reachable_node assms eq_Nil_appendI fsm_initial 
          nil path_append path_append_elim) 
    
  moreover have "{p. path M (initial M) p} \<noteq> {}" 
    by auto
  ultimately obtain p where "path M (initial M) p" 
                        and "\<And> p' . path M (initial M) p' \<Longrightarrow> length p' \<le> length p" 
    using max_length_elem
    by (metis mem_Collect_eq not_le_imp_less)

  then obtain t where "t \<in> transitions M" and "t_source t = target (initial M) p"
    using *[of "target (initial M) p"] unfolding reachable_nodes_def
    by blast

  then have "path M (initial M) (p@[t])"
    using \<open>path M (initial M) p\<close>
    by (simp add: path_append_transition)

  then show "False"
    using \<open>\<And> p' . path M (initial M) p' \<Longrightarrow> length p' \<le> length p\<close>
    by (metis impossible_Cons length_rotate1 rotate1.simps(2)) 
qed

lemma deadlock_prefix :
  assumes "path M q p"
  and     "t \<in> set (butlast p)"
shows "\<not> (deadlock_state M (t_target t))"
  using assms proof (induction p rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc t' p')
  
  show ?case proof (cases "t \<in> set (butlast p')")
    case True
    show ?thesis 
      using snoc.IH[OF _ True] snoc.prems(1)
      by blast 
  next
    case False
    then have "p' = (butlast p')@[t]"
      using snoc.prems(2) by (metis append_butlast_last_id append_self_conv2 butlast_snoc 
                                in_set_butlast_appendI list_prefix_elem set_ConsD)
    then have "path M q ((butlast p'@[t])@[t'])"
      using snoc.prems(1)
      by auto 
    
    have "t' \<in> transitions M" and "t_source t' = target q (butlast p'@[t])"
      using path_suffix[OF \<open>path M q ((butlast p'@[t])@[t'])\<close>]
      by auto
    then have "t' \<in> transitions M \<and> t_source t' = t_target t"
      unfolding target.simps visited_nodes.simps by auto
    then show ?thesis 
      unfolding deadlock_state.simps using \<open>t' \<in> transitions M\<close> by blast
  qed
qed


lemma nodes_initial_deadlock :
  assumes "deadlock_state M (initial M)"
  shows "reachable_nodes M = {initial M}"
  
proof -
  have "\<And> q . q \<in> reachable_nodes M \<Longrightarrow> q = initial M"
  proof -
    fix q assume "q \<in> reachable_nodes M"
    then obtain p where "path M (initial M) p" and "target (initial M) p = q"
      unfolding reachable_nodes_def by auto
    
    show "q = initial M" proof (cases p)
      case Nil
      then show ?thesis using \<open>target (initial M) p = q\<close> by auto
    next
      case (Cons t p')
      then have "False" using assms \<open>path M (initial M) p\<close> unfolding deadlock_state.simps
        by auto 
      then show ?thesis by simp
    qed
  qed
  then show ?thesis
    using reachable_nodes_initial[of M] by blast
qed

subsubsection \<open>Other\<close>

fun completed_path :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> ('a,'b,'c) path \<Rightarrow> bool" where
  "completed_path M q p = deadlock_state M (target q p)"

fun minimal :: "('a,'b,'c) fsm \<Rightarrow> bool" where
  "minimal M = (\<forall> q \<in> nodes M . \<forall> q' \<in> nodes M . q \<noteq> q' \<longrightarrow> LS M q \<noteq> LS M q')"

definition retains_outputs_for_states_and_inputs :: "('a,'b,'c) fsm \<Rightarrow> ('a,'b,'c) fsm \<Rightarrow> bool" where
  "retains_outputs_for_states_and_inputs M S 
    = (\<forall> tS \<in> transitions S . 
        \<forall> tM \<in> transitions M . 
          (t_source tS = t_source tM \<and> t_input tS = t_input tM) \<longrightarrow> tM \<in> transitions S)"





subsection \<open>IO Targets and Observability\<close>

fun paths_for_io' :: "(('a \<times> 'b) \<Rightarrow> ('c \<times> 'a) set) \<Rightarrow> ('b \<times> 'c) list \<Rightarrow> 'a \<Rightarrow> ('a,'b,'c) path \<Rightarrow> ('a,'b,'c) path set" where
  "paths_for_io' f [] q prev = {prev}" |
  "paths_for_io' f ((x,y)#io) q prev = \<Union>(image (\<lambda>yq' . paths_for_io' f io (snd yq') (prev@[(q,x,y,(snd yq'))])) (Set.filter (\<lambda>yq' . fst yq' = y) (f (q,x))))"

lemma paths_for_io'_set :
  assumes "q \<in> nodes M"
  shows   "paths_for_io' (h M) io q prev = {prev@p | p . path M q p \<and> p_io p = io}"
using assms proof (induction io arbitrary: q prev)
  case Nil
  then show ?case by auto
next
  case (Cons xy io)
  obtain x y where "xy = (x,y)"
    by (meson surj_pair) 

  let ?UN = "\<Union>(image (\<lambda>yq' . paths_for_io' (h M) io (snd yq') (prev@[(q,x,y,(snd yq'))])) 
                      (Set.filter (\<lambda>yq' . fst yq' = y) (h M (q,x))))"

  have "?UN = {prev@p | p . path M q p \<and> p_io p = (x,y)#io}"
  proof 
    have "\<And> p . p \<in> ?UN \<Longrightarrow> p \<in> {prev@p | p . path M q p \<and> p_io p = (x,y)#io}"
    proof -
      fix p assume "p \<in> ?UN"
      then obtain q' where "(y,q') \<in> (Set.filter (\<lambda>yq' . fst yq' = y) (h M (q,x)))"
                     and   "p \<in> paths_for_io' (h M) io q' (prev@[(q,x,y,q')])"
        by auto
      
      from \<open>(y,q') \<in> (Set.filter (\<lambda>yq' . fst yq' = y) (h M (q,x)))\<close> have "q' \<in> nodes M" 
                                                                     and "(q,x,y,q') \<in> transitions M"
        using fsm_transition_target unfolding h.simps by auto

      have "p \<in> {(prev @ [(q, x, y, q')]) @ p |p. path M q' p \<and> p_io p = io}"
        using \<open>p \<in> paths_for_io' (h M) io q' (prev@[(q,x,y,q')])\<close>
        unfolding Cons.IH[OF \<open>q' \<in> nodes M\<close>] by assumption
      moreover have "{(prev @ [(q, x, y, q')]) @ p |p. path M q' p \<and> p_io p = io} 
                      \<subseteq> {prev@p | p . path M q p \<and> p_io p = (x,y)#io}"
        using \<open>(q,x,y,q') \<in> transitions M\<close>
        using cons by force 
      ultimately show "p \<in> {prev@p | p . path M q p \<and> p_io p = (x,y)#io}" 
        by blast
    qed
    then show "?UN \<subseteq> {prev@p | p . path M q p \<and> p_io p = (x,y)#io}"
      by blast

    have "\<And> p . p \<in> {prev@p | p . path M q p \<and> p_io p = (x,y)#io} \<Longrightarrow> p \<in> ?UN"
    proof -
      fix pp assume "pp \<in> {prev@p | p . path M q p \<and> p_io p = (x,y)#io}"
      then obtain p where "pp = prev@p" and "path M q p" and "p_io p = (x,y)#io"
        by fastforce
      then obtain t p' where "p = t#p'" and "path M q (t#p')" and "p_io (t#p') = (x,y)#io" 
                         and "p_io p' = io"
        by (metis (no_types, lifting) map_eq_Cons_D)
      then have "path M (t_target t) p'" and "t_source t = q" and "t_input t = x" 
                                         and "t_output t = y" and "t_target t \<in> nodes M"
                                         and "t \<in> transitions M"
        by auto

      have "(y,t_target t) \<in> Set.filter (\<lambda>yq'. fst yq' = y) (h M (q, x))"
        using \<open>t \<in> transitions M\<close> \<open>t_output t = y\<close> \<open>t_input t = x\<close> \<open>t_source t = q\<close>
        unfolding h.simps
        by auto 
      moreover have "(prev@p) \<in> paths_for_io' (h M) io (snd (y,t_target t)) (prev @ [(q, x, y, snd (y,t_target t))])"
        using Cons.IH[OF \<open>t_target t \<in> nodes M\<close>, of "prev@[(q, x, y, t_target t)]"]
        using \<open>p = t # p'\<close> \<open>p_io p' = io\<close> \<open>path M (t_target t) p'\<close> \<open>t_input t = x\<close> 
              \<open>t_output t = y\<close> \<open>t_source t = q\<close> 
        by auto

      ultimately show "pp \<in> ?UN" unfolding \<open>pp = prev@p\<close>
        by blast 
    qed
    then show "{prev@p | p . path M q p \<and> p_io p = (x,y)#io} \<subseteq> ?UN"
      by (meson subsetI) 
  qed

  then show ?case
    by (simp add: \<open>xy = (x, y)\<close>) 
qed



definition paths_for_io :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> ('b \<times> 'c) list \<Rightarrow> ('a,'b,'c) path set" where
  "paths_for_io M q io = {p . path M q p \<and> p_io p = io}"

lemma paths_for_io_set_code[code] :
  "paths_for_io M q io = (if q \<in> nodes M then paths_for_io' (h M) io q [] else {})"
  using paths_for_io'_set[of q M io "[]"]
  unfolding paths_for_io_def
proof -
  have "{[] @ ps |ps. path M q ps \<and> p_io ps = io} = (if q \<in> FSM.nodes M then paths_for_io' (h M) io q [] else {}) 
        \<longrightarrow> {ps. path M q ps \<and> p_io ps = io} = (if q \<in> FSM.nodes M then paths_for_io' (h M) io q [] else {})"
    by auto
  moreover
    { assume "{[] @ ps |ps. path M q ps \<and> p_io ps = io} \<noteq> (if q \<in> FSM.nodes M then paths_for_io' (h M) io q [] else {})"
      then have "q \<notin> FSM.nodes M"
        using \<open>q \<in> FSM.nodes M \<Longrightarrow> paths_for_io' (h M) io q [] = {[] @ p |p. path M q p \<and> p_io p = io}\<close> by force
      then have "{ps. path M q ps \<and> p_io ps = io} = (if q \<in> FSM.nodes M then paths_for_io' (h M) io q [] else {})"
      using path_begin_node by force }
  ultimately show "{ps. path M q ps \<and> p_io ps = io} = (if q \<in> FSM.nodes M then paths_for_io' (h M) io q [] else {})"
    by linarith
qed 


fun io_targets :: "('a,'b,'c) fsm \<Rightarrow> ('b \<times> 'c) list \<Rightarrow> 'a \<Rightarrow> 'a set" where
  "io_targets M io q = {target q p | p . path M q p \<and> p_io p = io}"

lemma io_targets_code[code] : "io_targets M io q = image (target q) (paths_for_io M q io)"
  unfolding io_targets.simps paths_for_io_def by blast

lemma io_targets_nodes :
  "io_targets M io q \<subseteq> nodes M"
  using path_target_is_node by fastforce



lemma observable_transition_unique :
  assumes "observable M"
      and "t \<in> transitions M"
    shows "\<exists>! t' \<in> transitions M . t_source t' = t_source t \<and> 
                                    t_input t' = t_input t \<and> 
                                    t_output t' = t_output t"
  by (metis assms observable.elims(2) prod.expand)

lemma observable_path_unique :
  assumes "observable M"
  and     "path M q p"
  and     "path M q p'"
  and     "p_io p = p_io p'"
shows "p = p'"
proof -
  have "length p = length p'"
    using assms(4) map_eq_imp_length_eq by blast 
  then show ?thesis
    using \<open>p_io p = p_io p'\<close> \<open>path M q p\<close> \<open>path M q p'\<close>
  proof (induction p p' arbitrary: q rule: list_induct2)
    case Nil
    then show ?case by auto
  next
    case (Cons x xs y ys)
    then have *: "x \<in> transitions M \<and> y \<in> transitions M \<and> t_source x = t_source y 
                                    \<and> t_input x = t_input y \<and> t_output x = t_output y" 
      by auto
    then have "t_target x = t_target y" 
      using assms(1) observable.elims(2) by blast 
    then have "x = y"
      by (simp add: "*" prod.expand) 
      

    have "p_io xs = p_io ys" 
      using Cons by auto

    moreover have "path M (t_target x) xs" 
      using Cons by auto
    moreover have "path M (t_target x) ys"
      using Cons \<open>t_target x = t_target y\<close> by auto
    ultimately have "xs = ys" 
      using Cons by auto

    then show ?case 
      using \<open>x = y\<close> by simp
  qed
qed


lemma observable_io_targets : 
  assumes "observable M"
  and "io \<in> LS M q"
obtains q'
where "io_targets M io q = {q'}"
proof -

  obtain p where "path M q p" and "p_io p = io" 
    using assms(2) by auto 
  then have "target q p \<in> io_targets M io q"
    by auto   

  have "\<exists> q' . io_targets M io q = {q'}"
  proof (rule ccontr)
    assume "\<not>(\<exists>q'. io_targets M io q = {q'})"
    then have "\<exists> q' . q' \<noteq> target q p \<and> q' \<in> io_targets M io q"
    proof -
      have "\<not> io_targets M io q \<subseteq> {target q p}"
        using \<open>\<not>(\<exists>q'. io_targets M io q = {q'})\<close> \<open>target q p \<in> io_targets M io q\<close> by blast
      then show ?thesis
        by blast
    qed       
    then obtain q' where "q' \<noteq> target q p" and "q' \<in> io_targets M io q" 
      by blast
    then obtain p' where "path M q p'" and "target q p' = q'" and "p_io p' = io"
      by auto 
    then have "p_io p = p_io p'" 
      using \<open>p_io p = io\<close> by simp
    then have "p = p'"
      using observable_path_unique[OF assms(1) \<open>path M q p\<close> \<open>path M q p'\<close>] by simp
    then show "False"
      using \<open>q' \<noteq> target q p\<close> \<open>target q p' = q'\<close> by auto
  qed

  then show ?thesis using that by blast
qed


lemma observable_path_io_target : 
  assumes "observable M"
  and     "path M q p"
shows "io_targets M (p_io p) q = {target q p}"
  using observable_io_targets[OF assms(1) language_state_containment[OF assms(2)], of "p_io p"] 
        singletonD[of "target q p"]
  unfolding io_targets.simps
proof -
  assume a1: "\<And>a. target q p \<in> {a} \<Longrightarrow> target q p = a"
  assume "\<And>thesis. \<lbrakk>p_io p = p_io p; \<And>q'. {target q pa |pa. path M q pa \<and> p_io pa = p_io p} = {q'} \<Longrightarrow> thesis\<rbrakk> \<Longrightarrow> thesis"
  then obtain aa :: 'a where "\<And>b. {target q ps |ps. path M q ps \<and> p_io ps = p_io p} = {aa} \<or> b"
    by meson
  then show "{target q ps |ps. path M q ps \<and> p_io ps = p_io p} = {target q p}"
    using a1 assms(2) by blast
qed


lemma completely_specified_io_targets : 
  assumes "completely_specified M"
  shows "\<forall> q \<in> io_targets M io (initial M) . \<forall> x \<in> (inputs M) . \<exists> t \<in> transitions M . t_source t = q \<and> t_input t = x"
  by (meson assms completely_specified.elims(2) io_targets_nodes subsetD)
  


lemma observable_path_language_step :
  assumes "observable M"
      and "path M q p"
      and "\<not> (\<exists>t\<in>transitions M.
               t_source t = target q p \<and>
               t_input t = x \<and> t_output t = y)"
    shows "(p_io p)@[(x,y)] \<notin> LS M q"
using assms proof (induction p rule: rev_induct)
  case Nil
  show ?case proof
    assume "p_io [] @ [(x, y)] \<in> LS M q"
    then obtain p' where "path M q p'" and "p_io p' = [(x,y)]" unfolding LS.simps
      by force 
    then obtain t where "p' = [t]" by blast
    
    have "t\<in>transitions M" and "t_source t = target q []"
      using \<open>path M q p'\<close> \<open>p' = [t]\<close> by auto
    moreover have "t_input t = x \<and> t_output t = y"
      using \<open>p_io p' = [(x,y)]\<close> \<open>p' = [t]\<close> by auto
    ultimately show "False"
      using Nil.prems(3) by blast
  qed
next
  case (snoc t p)
  
  from \<open>path M q (p @ [t])\<close> have "path M q p" and "t_source t = target q p" 
                                              and "t \<in> transitions M" 
    by auto

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

    have "t_source t' = target q p''" and "t' \<in> transitions M"
      using \<open>path M q p'\<close> \<open>p' = p''@[t']@[t'']\<close> by auto
    then have "t_source t' = t_source t"
      using \<open>p'' = p\<close> \<open>t_source t = target q p\<close> by auto 
    moreover have "t_input t' = t_input t \<and> t_output t' = t_output t"
      using \<open>p_io p' = p_io (p @ [t]) @ [(x, y)]\<close> \<open>p' = p''@[t']@[t'']\<close> \<open>p'' = p\<close> by auto
    ultimately have "t' = t"
      using \<open>t \<in> transitions M\<close> \<open>t' \<in> transitions M\<close> assms(1) unfolding observable.simps 
      by (meson prod.expand) 

    have "t'' \<in> transitions M" and "t_source t'' = target q (p@[t])"
      using \<open>path M q p'\<close> \<open>p' = p''@[t']@[t'']\<close> \<open>p'' = p\<close> \<open>t' = t\<close> by auto
    moreover have "t_input t'' = x \<and> t_output t'' = y"
      using \<open>p_io p' = p_io (p @ [t]) @ [(x, y)]\<close> \<open>p' = p''@[t']@[t'']\<close> by auto
    ultimately show "False"
      using snoc.prems(3) by blast
  qed
qed

lemma observable_io_targets_language :
  assumes "io1 @ io2 \<in> LS M q1"
  and     "observable M"
  and     "q2 \<in> io_targets M io1 q1"
shows "io2 \<in> LS M q2" 
proof -
  obtain p1 p2 where "path M q1 p1" and "path M (target q1 p1) p2"  
                 and "p_io p1 = io1" and "p_io p2 = io2"
    using language_state_split[OF assms(1)] by blast
  then have "io1 \<in> LS M q1" and "io2 \<in> LS M (target q1 p1)"
    by auto
  
  have "target q1 p1 \<in> io_targets M io1 q1"
    using \<open>path M q1 p1\<close> \<open>p_io p1 = io1\<close>
    unfolding io_targets.simps by blast
  then have "target q1 p1 = q2"
    using observable_io_targets[OF assms(2) \<open>io1 \<in> LS M q1\<close>]
    by (metis assms(3) singletonD) 
  then show ?thesis
    using \<open>io2 \<in> LS M (target q1 p1)\<close> by auto
qed


lemma io_targets_language_append :
  assumes "q1 \<in> io_targets M io1 q"
  and     "io2 \<in> LS M q1"
shows "io1@io2 \<in> LS M q" 
proof -
  obtain p1 where "path M q p1" and "p_io p1 = io1" and "target q p1 = q1" 
    using assms(1) by auto
  moreover obtain p2 where "path M q1 p2" and "p_io p2 = io2" 
    using assms(2) by auto
  ultimately have "path M q (p1@p2)" and "p_io (p1@p2) = io1@io2"
    by auto
  then show ?thesis 
    using language_state_containment[of M q "p1@p2" "io1@io2"] by simp
qed


lemma io_targets_next :
  assumes "t \<in> transitions M"
  shows "io_targets M io (t_target t) \<subseteq> io_targets M (p_io [t] @ io) (t_source t)"
unfolding io_targets.simps
proof 
  fix q assume "q \<in> {target (t_target t) p |p. path M (t_target t) p \<and> p_io p = io}"
  then obtain p where "path M (t_target t) p \<and> p_io p = io \<and> target (t_target t) p = q"
    by auto
  then have "path M (t_source t) (t#p) \<and> p_io (t#p) = p_io [t] @ io \<and> target (t_source t) (t#p) = q"
    using FSM.path.cons[OF assms] by auto
  then show "q \<in> {target (t_source t) p |p. path M (t_source t) p \<and> p_io p = p_io [t] @ io}"
    by blast
qed


lemma observable_io_targets_next :
  assumes "observable M"
  and     "t \<in> transitions M"
shows "io_targets M (p_io [t] @ io) (t_source t) = io_targets M io (t_target t)" 
proof 
  show "io_targets M (p_io [t] @ io) (t_source t) \<subseteq> io_targets M io (t_target t)"
  proof 
    fix q assume "q \<in> io_targets M (p_io [t] @ io) (t_source t)"
    then obtain p where "q = target (t_source t) p" 
                    and "path M (t_source t) p"
                    and "p_io p = p_io [t] @ io"
      unfolding io_targets.simps by blast
    then have "q = t_target (last p)" unfolding target.simps visited_nodes.simps
      using last_map by auto 

    obtain t' p' where "p = t' # p'"
      using \<open>p_io p = p_io [t] @ io\<close> by auto
    then have "t' \<in> transitions M" and "t_source t' = t_source t"
      using \<open>path M (t_source t) p\<close> by auto
    moreover have "t_input t' = t_input t" and "t_output t' = t_output t"
      using \<open>p = t' # p'\<close> \<open>p_io p = p_io [t] @ io\<close> by auto
    ultimately have "t' = t"
      using \<open>t \<in> transitions M\<close> \<open>observable M\<close> unfolding observable.simps
      by (meson prod.expand) 

    then have "path M (t_target t) p'"
      using \<open>path M (t_source t) p\<close> \<open>p = t' # p'\<close> by auto
    moreover have "p_io p' = io"
      using \<open>p_io p = p_io [t] @ io\<close> \<open>p = t' # p'\<close> by auto
    moreover have "q = target (t_target t) p'"
      using \<open>q = target (t_source t) p\<close> \<open>p = t' # p'\<close> \<open>t' = t\<close> by auto
    ultimately show "q \<in> io_targets M io (t_target t)"
      by auto
  qed

  show "io_targets M io (t_target t) \<subseteq> io_targets M (p_io [t] @ io) (t_source t)"
    using io_targets_next[OF assms(2)] by assumption
qed



lemma observable_language_target :
  assumes "observable M"
  and     "q \<in> io_targets M io1 (initial M)"
  and     "t \<in> io_targets T io1 (initial T)"
  and     "L T \<subseteq> L M"
shows "LS T t \<subseteq> LS M q"
proof 
  fix io2 assume "io2 \<in> LS T t"
  then obtain pT2 where "path T t pT2" and "p_io pT2 = io2"
    by auto  
  
  obtain pT1 where "path T (initial T) pT1" and "p_io pT1 = io1" and "target (initial T) pT1 = t"
    using \<open>t \<in> io_targets T io1 (initial T)\<close> by auto
  then have "path T (initial T) (pT1@pT2)" 
    using \<open>path T t pT2\<close> using path_append by metis
  moreover have "p_io (pT1@pT2) = io1@io2"
    using \<open>p_io pT1 = io1\<close> \<open>p_io pT2 = io2\<close> by auto
  ultimately have "io1@io2 \<in> L T"
    using language_state_containment[of T] by auto
  then have "io1@io2 \<in> L M"
    using \<open>L T \<subseteq> L M\<close> by blast
  then obtain pM where "path M (initial M) pM" and "p_io pM = io1@io2"
    by auto

  let ?pM1 = "take (length io1) pM"
  let ?pM2 = "drop (length io1) pM"

  have "path M (initial M) (?pM1@?pM2)"
    using \<open>path M (initial M) pM\<close> by auto
  then have "path M (initial M) ?pM1" and "path M (target (initial M) ?pM1) ?pM2"
    by blast+
  
  have "p_io ?pM1 = io1"
    using \<open>p_io pM = io1@io2\<close> 
    by (metis append_eq_conv_conj take_map)
  have "p_io ?pM2 = io2"
    using \<open>p_io pM = io1@io2\<close> 
    by (metis append_eq_conv_conj drop_map)

  obtain pM1 where "path M (initial M) pM1" and "p_io pM1 = io1" and "target (initial M) pM1 = q"
    using \<open>q \<in> io_targets M io1 (initial M)\<close> by auto

  have "pM1 = ?pM1"
    using observable_path_unique[OF \<open>observable M\<close> \<open>path M (initial M) pM1\<close> \<open>path M (initial M) ?pM1\<close>]
    unfolding \<open>p_io pM1 = io1\<close> \<open>p_io ?pM1 = io1\<close> by simp

  then have "path M q ?pM2"
    using \<open>path M (target (initial M) ?pM1) ?pM2\<close> \<open>target (initial M) pM1 = q\<close> by auto
  then show "io2 \<in> LS M q"
    using language_state_containment[OF _ \<open>p_io ?pM2 = io2\<close>, of M] by auto
qed


lemma observable_language_target_failure :
  assumes "observable M"
  and     "q \<in> io_targets M io1 (initial M)"
  and     "t \<in> io_targets T io1 (initial T)"
  and     "\<not> LS T t \<subseteq> LS M q"
shows "\<not> L T \<subseteq> L M"
  using observable_language_target[OF assms(1,2,3)] assms(4) by blast
    

lemma language_path_append_transition_observable :
  assumes "(p_io p) @ [(x,y)] \<in> LS M q"
  and     "path M q p"
  and     "observable M"
  obtains t where "path M q (p@[t])" and "t_input t = x" and "t_output t = y"
proof -
  obtain p' t where "path M q (p'@[t])" and "p_io (p'@[t]) = (p_io p) @ [(x,y)]"
    using language_path_append_transition[OF assms(1)] by blast
  then have "path M q p'" and "p_io p' = p_io p" and "t_input t = x" and "t_output t = y"
    by auto

  have "p' = p"
    using observable_path_unique[OF assms(3) \<open>path M q p'\<close> \<open>path M q p\<close> \<open>p_io p' = p_io p\<close>] by assumption
  then have "path M q (p@[t])"
    using \<open>path M q (p'@[t])\<close> by auto
  then show ?thesis using that \<open>t_input t = x\<close> \<open>t_output t = y\<close> by metis
qed


lemma language_io_target_append :
  assumes "q' \<in> io_targets M io1 q"
  and     "io2 \<in> LS M q'"
shows "(io1@io2) \<in> LS M q"
proof - 
  obtain p2 where "path M q' p2" and "p_io p2 = io2"
    using assms(2) by auto

  moreover obtain p1 where "q' = target q p1" and "path M q p1" and "p_io p1 = io1"
    using assms(1) by auto

  ultimately show ?thesis unfolding LS.simps
    by (metis (mono_tags, lifting) map_append mem_Collect_eq path_append) 
qed


lemma observable_path_suffix :
  assumes "(p_io p)@io \<in> LS M q"
  and     "path M q p"
  and     "observable M"
obtains p' where "path M (target q p) p'" and "p_io p' = io"
proof -
  obtain p1 p2 where "path M q p1" and "path M (target q p1) p2"  and "p_io p1 = p_io p" and "p_io p2 = io"
    using language_state_split[OF assms(1)] by blast

  have "p1 = p"
    using observable_path_unique[OF assms(3,2) \<open>path M q p1\<close> \<open>p_io p1 = p_io p\<close>[symmetric]]
    by simp

  show ?thesis using that[of p2] \<open>path M (target q p1) p2\<close> \<open>p_io p2 = io\<close> unfolding \<open>p1 = p\<close>
    by blast
qed


lemma io_targets_finite :
  "finite (io_targets M io q)"
proof -
  have "(io_targets M io q) \<subseteq> {target q p | p . path M q p \<and> length p \<le> length io}"
    unfolding io_targets.simps length_map[of "(\<lambda> t . (t_input t, t_output t))", symmetric] by force
  moreover have "finite {target q p | p . path M q p \<and> length p \<le> length io}"
    using paths_finite[of M q "length io"]
    by simp 
  ultimately show ?thesis
    using rev_finite_subset by blast 
qed


subsection \<open>Conformity Relations\<close>

fun is_io_reduction_state :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> ('d,'b,'c) fsm \<Rightarrow> 'd \<Rightarrow> bool" where
  "is_io_reduction_state A a B b = (LS A a \<subseteq> LS B b)"

abbreviation(input) "is_io_reduction A B \<equiv> is_io_reduction_state A (initial A) B (initial B)" 
notation 
  is_io_reduction ("_ \<preceq> _")


fun is_io_reduction_state_on_inputs :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> 'b list set \<Rightarrow> ('d,'b,'c) fsm \<Rightarrow> 'd \<Rightarrow> bool" where
  "is_io_reduction_state_on_inputs A a U B b = (LS\<^sub>i\<^sub>n A a U \<subseteq> LS\<^sub>i\<^sub>n B b U)"

abbreviation(input) "is_io_reduction_on_inputs A U B \<equiv> is_io_reduction_state_on_inputs A (initial A) U B (initial B)" 
notation 
  is_io_reduction_on_inputs ("_ \<preceq>\<lbrakk>_\<rbrakk> _")


subsection \<open>A Pass Relation for Test Represented as Sets of Input-Output Sequences\<close>

definition pass_io_set :: "('a,'b,'c) fsm \<Rightarrow> ('b \<times> 'c) list set \<Rightarrow> bool" where
  "pass_io_set M ios = (\<forall> io x y . io@[(x,y)] \<in> ios \<longrightarrow> (\<forall> y' . io@[(x,y')] \<in> L M \<longrightarrow> io@[(x,y')] \<in> ios))"

definition pass_io_set_maximal :: "('a,'b,'c) fsm \<Rightarrow> ('b \<times> 'c) list set \<Rightarrow> bool" where
  "pass_io_set_maximal M ios = (\<forall> io x y io' . io@[(x,y)]@io' \<in> ios \<longrightarrow> (\<forall> y' . io@[(x,y')] \<in> L M \<longrightarrow> (\<exists> io''. io@[(x,y')]@io'' \<in> ios)))"


lemma pass_io_set_from_pass_io_set_maximal :
  "pass_io_set_maximal M ios = pass_io_set M {io' . \<exists> io io'' . io = io'@io'' \<and> io \<in> ios}"
proof -
  have "\<And> io x y io' . io@[(x,y)]@io' \<in> ios \<Longrightarrow> io@[(x,y)] \<in> {io' . \<exists> io io'' . io = io'@io'' \<and> io \<in> ios}"
    by auto
  moreover have "\<And> io x y . io@[(x,y)] \<in> {io' . \<exists> io io'' . io = io'@io'' \<and> io \<in> ios} \<Longrightarrow> \<exists> io' . io@[(x,y)]@io' \<in> ios"
    by auto
  ultimately show ?thesis
    unfolding pass_io_set_def pass_io_set_maximal_def
    by meson 
qed


lemma pass_io_set_maximal_from_pass_io_set :
  assumes "finite ios"
  and     "\<And> io' io'' . io'@io'' \<in> ios \<Longrightarrow> io' \<in> ios"
shows "pass_io_set M ios = pass_io_set_maximal M {io' \<in> ios . \<not> (\<exists> io'' . io'' \<noteq> [] \<and> io'@io'' \<in> ios)}"
proof -
  have "\<And> io x y . io@[(x,y)] \<in> ios \<Longrightarrow> \<exists> io' . io@[(x,y)]@io' \<in> {io'' \<in> ios . \<not> (\<exists> io''' . io''' \<noteq> [] \<and> io''@io''' \<in> ios)}"
  proof -
    fix io x y assume "io@[(x,y)] \<in> ios"
    show "\<exists> io' . io@[(x,y)]@io' \<in> {io'' \<in> ios . \<not> (\<exists> io''' . io''' \<noteq> [] \<and> io''@io''' \<in> ios)}"
      using finite_set_elem_maximal_extension_ex[OF \<open>io@[(x,y)] \<in> ios\<close> assms(1)] by force
  qed
  moreover have "\<And> io x y io' . io@[(x,y)]@io' \<in> {io'' \<in> ios . \<not> (\<exists> io''' . io''' \<noteq> [] \<and> io''@io''' \<in> ios)} \<Longrightarrow> io@[(x,y)] \<in> ios"
    using \<open>\<And> io' io'' . io'@io'' \<in> ios \<Longrightarrow> io' \<in> ios\<close> by force
  ultimately show ?thesis
    unfolding pass_io_set_def pass_io_set_maximal_def 
    by meson 
qed


subsection \<open>Submachines\<close>

fun is_submachine :: "('a,'b,'c) fsm \<Rightarrow> ('a,'b,'c) fsm \<Rightarrow> bool" where 
  "is_submachine A B = (initial A = initial B \<and> transitions A \<subseteq> transitions B \<and> inputs A = inputs B \<and> outputs A = outputs B \<and> nodes A \<subseteq> nodes B)"
  

lemma submachine_path_initial :
  assumes "is_submachine A B"
  and     "path A (initial A) p"
shows "path B (initial B) p"
  using assms proof (induction p rule: rev_induct)
  case Nil
  then show ?case by auto
next
  case (snoc a p)
  then show ?case
    by fastforce
qed
   

lemma submachine_path :
  assumes "is_submachine A B"
  and     "path A q p"
shows "path B q p"
  by (meson assms(1) assms(2) is_submachine.elims(2) path_begin_node subsetD transition_subset_path)
  

lemma submachine_reduction : 
  assumes "is_submachine A B"
  shows "is_io_reduction A B"
  using submachine_path[OF assms] assms by auto 


lemma complete_submachine_initial :
  assumes "is_submachine A B"
      and "completely_specified A"
  shows "completely_specified_state B (initial B)"
  using assms(1) assms(2) fsm_initial subset_iff by fastforce


lemma submachine_language :
  assumes "is_submachine S M"
  shows "L S \<subseteq> L M"
  by (meson assms is_io_reduction_state.elims(2) submachine_reduction)


lemma submachine_observable :
  assumes "is_submachine S M"
  and     "observable M"
shows "observable S"
  using assms unfolding is_submachine.simps observable.simps by blast


lemma submachine_transitive :
  assumes "is_submachine S M"
  and     "is_submachine S' S"
shows "is_submachine S' M"
  using assms unfolding is_submachine.simps by force


lemma transitions_subset_path :
  assumes "set p \<subseteq> transitions M"
  and     "p \<noteq> []"
  and     "path S q p"
shows "path M q p"
  using assms by (induction p arbitrary: q; auto)


lemma transition_subset_paths :
  assumes "transitions S \<subseteq> transitions M"
  and "initial S \<in> nodes M"
  and "inputs S = inputs M"
  and "outputs S = outputs M"
  and "path S (initial S) p"
shows "path M (initial S) p"
  using assms(5) proof (induction p rule: rev_induct)
case Nil
  then show ?case using assms(2) by auto
next
  case (snoc t p)
  then have "path S (initial S) p" 
        and "t \<in> transitions S" 
        and "t_source t = target (initial S) p" 
        and "path M (initial S) p"
    by auto

  have "t \<in> transitions M"
    using assms(1) \<open>t \<in> transitions S\<close> by auto
  moreover have "t_source t \<in> nodes M"
    using \<open>t_source t = target (initial S) p\<close> \<open>path M (initial S) p\<close>
    using path_target_is_node by fastforce 
  ultimately have "t \<in> transitions M"
    using \<open>t \<in> transitions S\<close> assms(3,4) by auto
  then show ?case
    using \<open>path M (initial S) p\<close>
    using snoc.prems by auto 
qed 


lemma submachine_reachable_subset :
  assumes "is_submachine A B"
shows "reachable_nodes A \<subseteq> reachable_nodes B" 
  using assms submachine_path_initial[OF assms] 
  unfolding is_submachine.simps reachable_nodes_def by force


lemma submachine_simps :
  assumes "is_submachine A B"
shows "initial A = initial B"
and   "nodes A \<subseteq> nodes B"
and   "inputs A = inputs B"
and   "outputs A = outputs B"
and   "transitions A \<subseteq> transitions B"
  using assms unfolding is_submachine.simps by blast+


lemma submachine_deadlock :
  assumes "is_submachine A B"
      and "deadlock_state B q"
    shows "deadlock_state A q"
  using assms(1) assms(2) in_mono by auto 



subsection \<open>Changing Initial States\<close>

lift_definition from_FSM :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> ('a,'b,'c) fsm" is FSM_Impl.from_FSM
  by simp 

lemma from_FSM_simps[simp]:
  assumes "q \<in> nodes M"
  shows
  "initial (from_FSM M q) = q"  
  "inputs (from_FSM M q) = inputs M"
  "outputs (from_FSM M q) = outputs M"
  "transitions (from_FSM M q) = transitions M"
  "nodes (from_FSM M q) = nodes M" using assms by (transfer; simp)+


lemma from_FSM_path_initial :
  assumes "q \<in> nodes M"
  shows "path M q p = path (from_FSM M q) (initial (from_FSM M q)) p"
  by (metis assms from_FSM_simps(1) from_FSM_simps(4) from_FSM_simps(5) order_refl 
        transition_subset_path)


lemma from_FSM_path :
  assumes "q \<in> nodes M"
      and "path (from_FSM M q) q' p"
    shows "path M q' p"
  using assms(1) assms(2) path_transitions transitions_subset_path by fastforce


lemma from_FSM_reachable_nodes :
  assumes "q \<in> reachable_nodes M"
  shows "reachable_nodes (from_FSM M q) \<subseteq> reachable_nodes M"
proof
  from assms obtain p where "path M (initial M) p" and "target (initial M) p = q"
    unfolding reachable_nodes_def by blast
  then have "q \<in> nodes M"
    by (meson path_target_is_node)

  fix q' assume "q' \<in> reachable_nodes (from_FSM M q)"
  then obtain p' where "path (from_FSM M q) q p'" and "target q p' = q'"
    unfolding reachable_nodes_def from_FSM_simps[OF \<open>q \<in> nodes M\<close>] by blast
  then have "path M (initial M) (p@p')" and "target (initial M) (p@p') = q'"
    using from_FSM_path[OF \<open>q \<in> nodes M\<close> ] \<open>path M (initial M) p\<close>
    using \<open>target (FSM.initial M) p = q\<close> by auto

  then show "q' \<in> reachable_nodes M"
    unfolding reachable_nodes_def by blast
qed
  

lemma submachine_from :
  assumes "is_submachine S M"
      and "q \<in> nodes S"
  shows "is_submachine (from_FSM S q) (from_FSM M q)"
proof -
  have "path S q []"
    using assms(2) by blast
  then have "path M q []"
    by (meson assms(1) submachine_path)
  then show ?thesis
    using assms(1) assms(2) by force
qed


lemma from_FSM_path_rev_initial :
  assumes "path M q p"
  shows "path (from_FSM M q) q p"
  by (metis (no_types) assms from_FSM_path_initial from_FSM_simps(1) path_begin_node)


lemma from_from[simp] :  
  assumes "q1 \<in> nodes M"
  and     "q1' \<in> nodes M"
shows "from_FSM (from_FSM M q1) q1' = from_FSM M q1'" (is "?M = ?M'") 
proof -
  have *: "q1' \<in> nodes (from_FSM M q1)"
    using assms(2) unfolding from_FSM_simps(5)[OF assms(1)] by assumption
  
  have "initial ?M = initial ?M'"
  and  "nodes ?M = nodes ?M'"
  and  "inputs ?M = inputs ?M'"
  and  "outputs ?M = outputs ?M'"
  and  "transitions ?M = transitions ?M'"
    unfolding  from_FSM_simps[OF *] from_FSM_simps[OF assms(1)] from_FSM_simps[OF assms(2)] by simp+

  then show ?thesis by (transfer; force)
qed


lemma from_FSM_completely_specified : 
  assumes "completely_specified M"
shows "completely_specified (from_FSM M q)" proof (cases "q \<in> nodes M")
  case True
  then show ?thesis
    using assms by auto 
next
  case False
  then have "from_FSM M q = M" by (transfer; auto)
  then show ?thesis using assms by auto
qed


lemma from_FSM_single_input : 
  assumes "single_input M"
shows "single_input (from_FSM M q)" proof (cases "q \<in> nodes M")
  case True
  then show ?thesis
    using assms
    by (metis from_FSM_simps(4) single_input.elims(1))  
next
  case False
  then have "from_FSM M q = M" by (transfer; auto)
  then show ?thesis using assms
    by presburger 
qed


lemma from_FSM_acyclic :
  assumes "q \<in> reachable_nodes M"
  and     "acyclic M"
shows "acyclic (from_FSM M q)"
  using assms(1)
        acyclic_paths_from_reachable_nodes[OF assms(2), of _ q]
        from_FSM_path[of q M q]
        path_target_is_node
        reachable_node_is_node[OF assms(1)]
        from_FSM_simps(1)
  unfolding acyclic.simps
            reachable_nodes_def
  by force
  


lemma from_FSM_observable :
  assumes "observable M"
shows "observable (from_FSM M q)"
proof (cases "q \<in> nodes M")
  case True
  then show ?thesis
    using assms
  proof -
    have f1: "\<forall>f. observable f = (\<forall>a b c aa ab. ((a::'a, b::'b, c::'c, aa) \<notin> FSM.transitions f \<or> (a, b, c, ab) \<notin> FSM.transitions f) \<or> aa = ab)"
      by force
    have "\<forall>a f. a \<notin> FSM.nodes (f::('a, 'b, 'c) fsm) \<or> FSM.transitions (FSM.from_FSM f a) = FSM.transitions f"
      by (meson from_FSM_simps(4))
    then show ?thesis
      using f1 True assms by presburger
  qed  
next
  case False
  then have "from_FSM M q = M" by (transfer; auto)
  then show ?thesis using assms by presburger
qed


lemma observable_language_next :
  assumes "io#ios \<in> LS M (t_source t)"
  and     "observable M"
  and     "t \<in> transitions M"
  and     "t_input t = fst io"
  and     "t_output t = snd io"
shows "ios \<in> L (from_FSM M (t_target t))"
proof -
  obtain p where "path M (t_source t) p" and "p_io p = io#ios"
    using assms(1)
  proof -
    assume a1: "\<And>p. \<lbrakk>path M (t_source t) p; p_io p = io # ios\<rbrakk> \<Longrightarrow> thesis"
    obtain pps :: "('a \<times> 'b) list \<Rightarrow> 'c \<Rightarrow> ('c, 'a, 'b) fsm \<Rightarrow> ('c \<times> 'a \<times> 'b \<times> 'c) list" where
      "\<forall>x0 x1 x2. (\<exists>v3. x0 = p_io v3 \<and> path x2 x1 v3) = (x0 = p_io (pps x0 x1 x2) \<and> path x2 x1 (pps x0 x1 x2))"
      by moura
    then have "\<exists>ps. path M (t_source t) ps \<and> p_io ps = io # ios"
      using assms(1) by auto
    then show ?thesis
      using a1 by meson
  qed
  then obtain t' p' where "p = t' # p'"
    by auto
  then have "t' \<in> transitions M" and "t_source t' = t_source t" and "t_input t' = fst io" and "t_output t' = snd io" 
    using \<open>path M (t_source t) p\<close> \<open>p_io p = io#ios\<close> by auto
  then have "t = t'"
    using assms(2,3,4,5) unfolding observable.simps
    by (metis (no_types, hide_lams) prod.expand) 

  then have "path M (t_target t) p'" and "p_io p' = ios"
    using \<open>p = t' # p'\<close> \<open>path M (t_source t) p\<close> \<open>p_io p = io#ios\<close> by auto
  then have "path (from_FSM M (t_target t)) (initial (from_FSM M (t_target t))) p'"
    by (meson assms(3) from_FSM_path_initial fsm_transition_target)

  then show ?thesis using \<open>p_io p' = ios\<close> by auto
qed


lemma from_FSM_language :
  assumes "q \<in> nodes M"
  shows "L (from_FSM M q) = LS M q"
  using assms unfolding LS.simps by (meson from_FSM_path_initial)


lemma language_state_prepend_transition : 
  assumes "io \<in> LS (from_FSM A (t_target t)) (initial (from_FSM A (t_target t)))"
  and     "t \<in> transitions A"
shows "p_io [t] @ io \<in> LS A (t_source t)" 
proof -
  obtain p where "path (from_FSM A (t_target t)) (initial (from_FSM A (t_target t))) p"
           and   "p_io p = io"
    using assms(1) unfolding LS.simps by blast
  then have "path A (t_target t) p"
    by (meson assms(2) from_FSM_path_initial fsm_transition_target)
  then have "path A (t_source t) (t # p)"
    using assms(2) by auto
  then show ?thesis 
    using \<open>p_io p = io\<close> unfolding LS.simps
    by force 
qed



subsection \<open>Further Reachability Formalisations\<close>

(* nodes that are reachable in at most k transitions *)
fun reachable_k :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> nat \<Rightarrow> 'a set" where
  "reachable_k M q n = {target q p | p . path M q p \<and> length p \<le> n}" 


lemma reachable_k_0_initial : "reachable_k M (initial M) 0 = {initial M}" 
  by auto

lemma reachable_k_nodes : "reachable_nodes M = reachable_k M (initial M) ( size M - 1)"
proof -
  have "\<And>q. q \<in> reachable_nodes M \<Longrightarrow> q \<in> reachable_k M (initial M) ( size M - 1)"
  proof -
    fix q assume "q \<in> reachable_nodes M"
    then obtain p where "path M (initial M) p" and "target (initial M) p = q"
      unfolding reachable_nodes_def by blast
    then obtain p' where "path M (initial M) p'"
                     and "target (initial M) p' = target (initial M) p" 
                     and "length p' < size M"
      by (metis acyclic_path_from_cyclic_path acyclic_path_length_limit)
    then show "q \<in> reachable_k M (initial M) ( size M - 1)"
      using \<open>target (FSM.initial M) p = q\<close> less_trans by auto
  qed

  moreover have "\<And>x. x \<in> reachable_k M (initial M) ( size M - 1) \<Longrightarrow> x \<in> reachable_nodes M"
    unfolding reachable_nodes_def reachable_k.simps by blast
  
  ultimately show ?thesis by blast
qed


  
subsubsection \<open>Induction Schemes\<close>


  
lemma acyclic_induction [consumes 1, case_names reachable_node]:
  assumes "acyclic M"
      and "\<And> q . q \<in> reachable_nodes M \<Longrightarrow> (\<And> t . t \<in> transitions M \<Longrightarrow> ((t_source t = q) \<Longrightarrow> P (t_target t))) \<Longrightarrow> P q"
    shows "\<forall> q \<in> reachable_nodes M . P q"
proof 
  fix q assume "q \<in> reachable_nodes M"

  let ?k = "Max (image length {p . path M q p})"
  have "finite {p . path M q p}" using acyclic_finite_paths_from_reachable_node[OF assms(1)] 
    using \<open>q \<in> reachable_nodes M\<close> unfolding reachable_nodes_def by force
  then have k_prop: "(\<forall> p . path M q p \<longrightarrow> length p \<le> ?k)" by auto

  moreover have "\<And> q k . q \<in> reachable_nodes M \<Longrightarrow> (\<forall> p . path M q p \<longrightarrow> length p \<le> k) \<Longrightarrow> P q"
  proof -
    fix q k assume "q \<in> reachable_nodes M" and "(\<forall> p . path M q p \<longrightarrow> length p \<le> k)"
    then show "P q" 
    proof (induction k arbitrary: q)
      case 0
      then have "{p . path M q p} = {[]}" using reachable_node_is_node[OF \<open>q \<in> reachable_nodes M\<close>]
        by blast  
      then have "LS M q \<subseteq> {[]}" unfolding LS.simps by blast
      then have "deadlock_state M q" using deadlock_state_alt_def by metis
      then show ?case using assms(2)[OF \<open>q \<in> reachable_nodes M\<close>] unfolding deadlock_state.simps by blast
    next
      case (Suc k)
      have "\<And> t . t \<in> transitions M \<Longrightarrow> (t_source t = q) \<Longrightarrow> P (t_target t)"
      proof -
        fix t assume "t \<in> transitions M" and "t_source t = q" 
        then have "t_target t \<in> reachable_nodes M"
          using \<open>q \<in> reachable_nodes M\<close> using reachable_nodes_next by metis
        moreover have "\<forall>p. path M (t_target t) p \<longrightarrow> length p \<le> k"
          using Suc.prems(2) \<open>t \<in> transitions M\<close> \<open>t_source t = q\<close> by auto
        ultimately show "P (t_target t)" 
          using Suc.IH unfolding reachable_nodes_def by blast 
      qed
      then show ?case using assms(2)[OF Suc.prems(1)] by blast
    qed
  qed

  ultimately show "P q" using \<open>q \<in> reachable_nodes M\<close> by blast
qed



subsection \<open>Further Path Enumeration Algorithms\<close>

fun paths_for_input' :: "('a \<Rightarrow> ('b \<times> 'c \<times> 'a) set) \<Rightarrow> 'b list \<Rightarrow> 'a \<Rightarrow> ('a,'b,'c) path \<Rightarrow> ('a,'b,'c) path set" where
  "paths_for_input' f [] q prev = {prev}" |
  "paths_for_input' f (x#xs) q prev = \<Union>(image (\<lambda>(x',y',q') . paths_for_input' f xs q' (prev@[(q,x,y',q')])) (Set.filter (\<lambda>(x',y',q') . x' = x) (f q)))"

lemma paths_for_input'_set :
  assumes "q \<in> nodes M"
  shows   "paths_for_input' (h_from M) xs q prev = {prev@p | p . path M q p \<and> map fst (p_io p) = xs}"
using assms proof (induction xs arbitrary: q prev)
  case Nil
  then show ?case by auto
next
  case (Cons x xs)

  let ?UN = "\<Union>(image (\<lambda>(x',y',q') . paths_for_input' (h_from M) xs q' (prev@[(q,x,y',q')])) (Set.filter (\<lambda>(x',y',q') . x' = x) (h_from M q)))"

  have "?UN = {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs}"
  proof 
    have "\<And> p . p \<in> ?UN \<Longrightarrow> p \<in> {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs}"
    proof -
      fix p assume "p \<in> ?UN"
      then obtain y' q' where "(x,y',q') \<in> (Set.filter (\<lambda>(x',y',q') . x' = x) (h_from M q))"
                     and   "p \<in> paths_for_input' (h_from M) xs q' (prev@[(q,x,y',q')])"
        by auto
      
      from \<open>(x,y',q') \<in> (Set.filter (\<lambda>(x',y',q') . x' = x) (h_from M q))\<close> have "q' \<in> nodes M" and "(q,x,y',q') \<in> transitions M"
        using fsm_transition_target unfolding h.simps by auto

      have "p \<in> {(prev @ [(q, x, y', q')]) @ p |p. path M q' p \<and> map fst (p_io p) = xs}"
        using \<open>p \<in> paths_for_input' (h_from M) xs q' (prev@[(q,x,y',q')])\<close>
        unfolding Cons.IH[OF \<open>q' \<in> nodes M\<close>] by assumption
      moreover have "{(prev @ [(q, x, y', q')]) @ p |p. path M q' p \<and> map fst (p_io p) = xs} 
                      \<subseteq> {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs}"
        using \<open>(q,x,y',q') \<in> transitions M\<close>
        using cons by force 
      ultimately show "p \<in> {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs}" 
        by blast
    qed
    then show "?UN \<subseteq> {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs}"
      by blast

    have "\<And> p . p \<in> {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs} \<Longrightarrow> p \<in> ?UN"
    proof -
      fix pp assume "pp \<in> {prev@p | p . path M q p \<and> map fst (p_io p) = x#xs}"
      then obtain p where "pp = prev@p" and "path M q p" and "map fst (p_io p) = x#xs"
        by fastforce
      then obtain t p' where "p = t#p'" and "path M q (t#p')" and "map fst (p_io (t#p')) = x#xs" and "map fst (p_io p') = xs"
        by (metis (no_types, lifting) map_eq_Cons_D)
      then have "path M (t_target t) p'" and "t_source t = q" and "t_input t = x" and "t_target t \<in> nodes M" and "t \<in> transitions M"
        by auto

      have "(x,t_output t,t_target t) \<in> (Set.filter (\<lambda>(x',y',q') . x' = x) (h_from M q))"
        using \<open>t \<in> transitions M\<close> \<open>t_input t = x\<close> \<open>t_source t = q\<close>
        unfolding h.simps by auto 
      moreover have "(prev@p) \<in> paths_for_input' (h_from M) xs (t_target t) (prev@[(q,x,t_output t,t_target t)])"
        using Cons.IH[OF \<open>t_target t \<in> nodes M\<close>, of "prev@[(q, x, t_output t, t_target t)]"]
        using \<open>\<And>thesis. (\<And>t p'. \<lbrakk>p = t # p'; path M q (t # p'); map fst (p_io (t # p')) = x # xs; map fst (p_io p') = xs\<rbrakk> \<Longrightarrow> thesis) \<Longrightarrow> thesis\<close> 
              \<open>p = t # p'\<close> 
              \<open>paths_for_input' (h_from M) xs (t_target t) (prev @ [(q, x, t_output t, t_target t)]) 
                = {(prev @ [(q, x, t_output t, t_target t)]) @ p |p. path M (t_target t) p \<and> map fst (p_io p) = xs}\<close> 
              \<open>t_input t = x\<close> 
              \<open>t_source t = q\<close> 
        by fastforce

      ultimately show "pp \<in> ?UN" unfolding \<open>pp = prev@p\<close>
        by blast 
    qed
    then show "{prev@p | p . path M q p \<and> map fst (p_io p) = x#xs} \<subseteq> ?UN"
      by (meson subsetI) 
  qed

  then show ?case
    by (metis paths_for_input'.simps(2)) 
    
qed


definition paths_for_input :: "('a,'b,'c) fsm \<Rightarrow> 'a \<Rightarrow> 'b list \<Rightarrow> ('a,'b,'c) path set" where
  "paths_for_input M q xs = {p . path M q p \<and> map fst (p_io p) = xs}"

lemma paths_for_input_set_code[code] :
  "paths_for_input M q xs = (if q \<in> nodes M then paths_for_input' (h_from M) xs q [] else {})"
  using paths_for_input'_set[of q M xs "[]"] 
  unfolding paths_for_input_def
  by (cases "q \<in> nodes M"; auto; simp add: path_begin_node)


fun paths_up_to_length_or_condition_with_witness' :: 
    "('a \<Rightarrow> ('b \<times> 'c \<times> 'a) set) \<Rightarrow> (('a,'b,'c) path \<Rightarrow> 'd option) \<Rightarrow> ('a,'b,'c) path \<Rightarrow> nat \<Rightarrow> 'a \<Rightarrow> (('a,'b,'c) path \<times> 'd) set" 
  where
  "paths_up_to_length_or_condition_with_witness' f P prev 0 q = (case P prev of Some w \<Rightarrow> {(prev,w)} | None \<Rightarrow> {})" |
  "paths_up_to_length_or_condition_with_witness' f P prev (Suc k) q = (case P prev of 
    Some w \<Rightarrow> {(prev,w)} | 
    None \<Rightarrow> (\<Union>(image (\<lambda>(x,y,q') . paths_up_to_length_or_condition_with_witness' f P (prev@[(q,x,y,q')]) k q') (f q))))"



lemma paths_up_to_length_or_condition_with_witness'_set :
  assumes "q \<in> nodes M"
  shows   "paths_up_to_length_or_condition_with_witness' (h_from M) P prev k q 
            = {(prev@p,x) | p x . path M q p 
                                  \<and> length p \<le> k 
                                  \<and> P (prev@p) = Some x 
                                  \<and> (\<forall> p' p'' . (p = p'@p'' \<and> p'' \<noteq> []) \<longrightarrow> P (prev@p') = None)}"
using assms proof (induction k arbitrary: q prev)
  case 0
  then show ?case proof (cases "P prev")
    case None then show ?thesis by auto
  next
    case (Some w) 
    then show ?thesis by (simp add: "0.prems" nil)
  qed
next
  case (Suc k) 
  then show ?case proof (cases "P prev")
    case (Some w) 
    then have "(prev,w) \<in> {(prev@p,x) | p x . path M q p 
                                              \<and> length p \<le> Suc k 
                                              \<and> P (prev@p) = Some x 
                                              \<and> (\<forall> p' p'' . (p = p'@p'' \<and> p'' \<noteq> []) \<longrightarrow> P (prev@p') = None)}"
      by (simp add: Suc.prems nil) 
    then have "{(prev@p,x) | p x . path M q p 
                                    \<and> length p \<le> Suc k 
                                    \<and> P (prev@p) = Some x 
                                    \<and> (\<forall> p' p'' . (p = p'@p'' \<and> p'' \<noteq> []) \<longrightarrow> P (prev@p') = None)} 
              = {(prev,w)}"
      using Some by fastforce
      
    then show ?thesis using Some by auto
  next
    case None 

    have "(\<Union>(image (\<lambda>(x,y,q') . paths_up_to_length_or_condition_with_witness' (h_from M) P (prev@[(q,x,y,q')]) k q') (h_from M q))) 
            = {(prev@p,x) | p x . path M q p 
                                  \<and> length p \<le> Suc k 
                                  \<and> P (prev@p) = Some x 
                                  \<and> (\<forall> p' p'' . (p = p'@p'' \<and> p'' \<noteq> []) \<longrightarrow> P (prev@p') = None)}"
         (is "?UN = ?PX")
    proof -
      have *: "\<And> pp . pp \<in> ?UN \<Longrightarrow> pp \<in> ?PX"
      proof -
        fix pp assume "pp \<in> ?UN"
        then obtain x y q' where "(x,y,q') \<in> h_from M q"
                           and   "pp \<in> paths_up_to_length_or_condition_with_witness' (h_from M) P (prev@[(q,x,y,q')]) k q'"
          by blast
        then have "(q,x,y,q') \<in> transitions M" by auto
        then have "q' \<in> nodes M" using fsm_transition_target by auto
        
        obtain p w where "pp = ((prev@[(q,x,y,q')])@p,w)" 
                   and   "path M q' p"
                   and   "length p \<le> k"
                   and   "P ((prev @ [(q, x, y, q')]) @ p) = Some w"
                   and   "\<And> p' p''. p = p' @ p'' \<Longrightarrow> p'' \<noteq> [] \<Longrightarrow> P ((prev @ [(q, x, y, q')]) @ p') = None"
          using \<open>pp \<in> paths_up_to_length_or_condition_with_witness' (h_from M) P (prev@[(q,x,y,q')]) k q'\<close> 
          unfolding Suc.IH[OF \<open>q' \<in> nodes M\<close>, of "prev@[(q,x,y,q')]"] 
          by blast
        
        have "path M q ((q,x,y,q')#p)" 
          using \<open>path M q' p\<close> \<open>(q,x,y,q') \<in> transitions M\<close> by (simp add: path_prepend_t) 
        moreover have "length ((q,x,y,q')#p) \<le> Suc k" 
          using \<open>length p \<le> k\<close> by auto
        moreover have "P (prev @ ([(q, x, y, q')] @ p)) = Some w" 
          using \<open>P ((prev @ [(q, x, y, q')]) @ p) = Some w\<close> by auto
        moreover have "\<And> p' p''. ((q,x,y,q')#p) = p' @ p'' \<Longrightarrow> p'' \<noteq> [] \<Longrightarrow> P (prev @ p') = None" 
          using \<open>\<And> p' p''. p = p' @ p'' \<Longrightarrow> p'' \<noteq> [] \<Longrightarrow> P ((prev @ [(q, x, y, q')]) @ p') = None\<close>
          using None 
          by (metis (no_types, hide_lams) append.simps(1) append_Cons append_Nil2 append_assoc 
                list.inject neq_Nil_conv) 

        ultimately show "pp \<in> ?PX" 
          unfolding \<open>pp = ((prev@[(q,x,y,q')])@p,w)\<close> by auto  
      qed
      
      have **: "\<And> pp . pp \<in> ?PX \<Longrightarrow> pp \<in> ?UN"
      proof -
        fix pp assume "pp \<in> ?PX"
        then obtain p' w where "pp = (prev @ p', w)"
                        and   "path M q p'"
                        and   "length p' \<le> Suc k"
                        and   "P (prev @ p') = Some w"
                        and   "\<And> p' p''. p' = p' @ p'' \<Longrightarrow> p'' \<noteq> [] \<Longrightarrow> P (prev @ p') = None"
          by blast
        moreover obtain t p where "p' = t#p" using \<open>P (prev @ p') = Some w\<close> using None
          by (metis append_Nil2 list.exhaust option.distinct(1)) 
        
        
        have "pp = ((prev @ [t])@p, w)" 
          using \<open>pp = (prev @ p', w)\<close> unfolding \<open>p' = t#p\<close> by auto
        have "path M q (t#p)" 
          using \<open>path M q p'\<close> unfolding \<open>p' = t#p\<close> by auto
        have p2: "length (t#p) \<le> Suc k" 
          using \<open>length p' \<le> Suc k\<close> unfolding \<open>p' = t#p\<close> by auto
        have p3: "P ((prev @ [t])@p) = Some w" 
          using \<open>P (prev @ p') = Some w\<close> unfolding \<open>p' = t#p\<close> by auto
        have p4: "\<And> p' p''. p = p' @ p'' \<Longrightarrow> p'' \<noteq> [] \<Longrightarrow> P ((prev@[t]) @ p') = None"
          using \<open>\<And> p' p''. p' = p' @ p'' \<Longrightarrow> p'' \<noteq> [] \<Longrightarrow> P (prev @ p') = None\<close> \<open>pp \<in> ?PX\<close> 
          unfolding \<open>pp = ((prev @ [t]) @ p, w)\<close> \<open>p' = t#p\<close> 
          by auto

        have "t \<in> transitions M" and p1: "path M (t_target t) p" and "t_source t = q"
          using \<open>path M q (t#p)\<close> by auto
        then have "t_target t \<in> nodes M" 
              and "(t_input t, t_output t, t_target t) \<in> h_from M q" 
              and "t_source t = q"
          using fsm_transition_target by auto
        then have "t = (q,t_input t, t_output t, t_target t)"
          by auto

        have "((prev @ [t])@p, w) \<in> paths_up_to_length_or_condition_with_witness' (h_from M) P (prev@[t]) k (t_target t)"
          unfolding Suc.IH[OF \<open>t_target t \<in> nodes M\<close>, of "prev@[t]"]
          using p1 p2 p3 p4 by auto
          

        then show "pp \<in> ?UN"
          unfolding \<open>pp = ((prev @ [t])@p, w)\<close>  
        proof -
          have "paths_up_to_length_or_condition_with_witness' (h_from M) P (prev @ [t]) k (t_target t) 
                = paths_up_to_length_or_condition_with_witness' (h_from M) P (prev @ [(q, t_input t, t_output t, t_target t)]) k (t_target t)"
            using \<open>t = (q, t_input t, t_output t, t_target t)\<close> by presburger
          then show "((prev @ [t]) @ p, w) \<in> (\<Union>(b, c, a)\<in>h_from M q. paths_up_to_length_or_condition_with_witness' (h_from M) P (prev @ [(q, b, c, a)]) k a)"
            using \<open>((prev @ [t]) @ p, w) \<in> paths_up_to_length_or_condition_with_witness' (h_from M) P (prev @ [t]) k (t_target t)\<close> 
                  \<open>(t_input t, t_output t, t_target t) \<in> h_from M q\<close> 
            by blast
        qed
      qed

      show ?thesis
        using subsetI[of ?UN ?PX, OF *] subsetI[of ?PX ?UN, OF **] subset_antisym by blast
    qed

    then show ?thesis 
      using None unfolding paths_up_to_length_or_condition_with_witness'.simps by simp
  qed
qed


definition paths_up_to_length_or_condition_with_witness :: 
  "('a,'b,'c) fsm \<Rightarrow> (('a,'b,'c) path \<Rightarrow> 'd option) \<Rightarrow> nat \<Rightarrow> 'a \<Rightarrow> (('a,'b,'c) path \<times> 'd) set" 
  where
  "paths_up_to_length_or_condition_with_witness M P k q 
    = {(p,x) | p x . path M q p 
                      \<and> length p \<le> k 
                      \<and> P p = Some x 
                      \<and> (\<forall> p' p'' . (p = p'@p'' \<and> p'' \<noteq> []) \<longrightarrow> P p' = None)}"


lemma paths_up_to_length_or_condition_with_witness_code[code] :
  "paths_up_to_length_or_condition_with_witness M P k q 
    = (if q \<in> nodes M then paths_up_to_length_or_condition_with_witness' (h_from M) P [] k q
                      else {})" 
proof (cases "q \<in> nodes M")
  case True
  then show ?thesis 
    unfolding paths_up_to_length_or_condition_with_witness_def 
              paths_up_to_length_or_condition_with_witness'_set[OF True] 
    by auto
next
  case False
  then show ?thesis 
    unfolding paths_up_to_length_or_condition_with_witness_def
    using path_begin_node by fastforce 
qed


lemma paths_up_to_length_or_condition_with_witness_finite : 
  "finite (paths_up_to_length_or_condition_with_witness M P k q)"
proof -
  have "paths_up_to_length_or_condition_with_witness M P k q 
          \<subseteq> {(p, the (P p)) | p . path M q p \<and> length p \<le> k}"
    unfolding paths_up_to_length_or_condition_with_witness_def
    by auto 
  moreover have "finite {(p, the (P p)) | p . path M q p \<and> length p \<le> k}" 
    using paths_finite[of M q k]
    by simp 
  ultimately show ?thesis
    using rev_finite_subset by auto 
qed

  


subsection \<open>More Acyclicity Properties\<close>


lemma maximal_path_target_deadlock :
  assumes "path M (initial M) p"
  and     "\<not>(\<exists> p' . path M (initial M) p' \<and> is_prefix p p' \<and> p \<noteq> p')"
shows "deadlock_state M (target (initial M) p)"
proof -
  have "\<not>(\<exists> t \<in> transitions M . t_source t = target (initial M) p)"
    using assms(2) unfolding is_prefix_prefix
    by (metis append_Nil2 assms(1) not_Cons_self2 path_append_transition same_append_eq)
  then show ?thesis by auto
qed

lemma path_to_deadlock_is_maximal :
  assumes "path M (initial M) p"
  and     "deadlock_state M (target (initial M) p)"
shows "\<not>(\<exists> p' . path M (initial M) p' \<and> is_prefix p p' \<and> p \<noteq> p')"
proof 
  assume "\<exists>p'. path M (initial M) p' \<and> is_prefix p p' \<and> p \<noteq> p'"
  then obtain p' where "path M (initial M) p'" and "is_prefix p p'" and "p \<noteq> p'" by blast
  then have "length p' > length p"
    unfolding is_prefix_prefix by auto
  then obtain t p2 where "p' = p @ [t] @ p2"
    using \<open>is_prefix p p'\<close> unfolding is_prefix_prefix
    by (metis \<open>p \<noteq> p'\<close> append.left_neutral append_Cons append_Nil2 non_sym_dist_pairs'.cases) 
  then have "path M (initial M) (p@[t])"
    using \<open>path M (initial M) p'\<close> by auto
  then have "t \<in> transitions M" and "t_source t = target (initial M) p"
    by auto
  then show "False"
    using \<open>deadlock_state M (target (initial M) p)\<close> unfolding deadlock_state.simps by blast
qed



definition maximal_acyclic_paths :: "('a,'b,'c) fsm \<Rightarrow> ('a,'b,'c) path set" where
  "maximal_acyclic_paths M = {p . path M (initial M) p 
                                  \<and> distinct (visited_nodes (initial M) p) 
                                  \<and> \<not>(\<exists> p' . p' \<noteq> [] \<and> path M (initial M) (p@p') 
                                              \<and> distinct (visited_nodes (initial M) (p@p')))}"


(* very inefficient construction *)
lemma maximal_acyclic_paths_code[code] :  
  "maximal_acyclic_paths M = (let ps = acyclic_paths_up_to_length M (initial M) (size M - 1)
                               in Set.filter (\<lambda>p . \<not> (\<exists> p' \<in> ps . p' \<noteq> p \<and> is_prefix p p')) ps)"
proof -
  have scheme1: "\<And> P p . (\<exists> p' . p' \<noteq> [] \<and> P (p@p')) = (\<exists> p' \<in> {p . P p} . p' \<noteq> p \<and> is_prefix p p')"
    unfolding is_prefix_prefix by blast

  have scheme2: "\<And> p . (path M (FSM.initial M) p 
                          \<and> length p \<le> FSM.size M - 1 
                          \<and> distinct (visited_nodes (FSM.initial M) p)) 
                      = (path M (FSM.initial M) p \<and> distinct (visited_nodes (FSM.initial M) p))"
    using acyclic_path_length_limit by fastforce 

  show ?thesis
    unfolding maximal_acyclic_paths_def acyclic_paths_up_to_length.simps Let_def 
    unfolding scheme1[of "\<lambda>p . path M (initial M) p \<and> distinct (visited_nodes (initial M) p)"]
    unfolding scheme2 by fastforce
qed



lemma maximal_acyclic_path_deadlock :
  assumes "acyclic M"
  and     "path M (initial M) p"
shows "\<not>(\<exists> p' . p' \<noteq> [] \<and> path M (initial M) (p@p') \<and> distinct (visited_nodes (initial M) (p@p'))) 
        = deadlock_state M (target (initial M) p)"
proof -
  have "deadlock_state M (target (initial M) p) \<Longrightarrow> \<not>(\<exists> p' . p' \<noteq> [] \<and> path M (initial M) (p@p') 
          \<and> distinct (visited_nodes (initial M) (p@p')))"
    unfolding deadlock_state.simps 
    using assms(2) by (metis path.cases path_suffix) 
  then show ?thesis
    by (metis acyclic.elims(2) assms(1) assms(2) is_prefix_prefix maximal_path_target_deadlock 
          self_append_conv) 
qed
  

lemma maximal_acyclic_paths_deadlock_targets : 
  assumes "acyclic M"
  shows "maximal_acyclic_paths M 
          = { p . path M (initial M) p \<and> deadlock_state M (target (initial M) p)}"
  using maximal_acyclic_path_deadlock[OF assms] 
  unfolding maximal_acyclic_paths_def
  by (metis (no_types, lifting) acyclic.elims(2) assms)


lemma cycle_from_cyclic_path :
  assumes "path M q p"
  and     "\<not> distinct (visited_nodes q p)"
obtains i j where
  "take j (drop i p) \<noteq> []"
  "target (target q (take i p)) (take j (drop i p)) = (target q (take i p))"
  "path M (target q (take i p)) (take j (drop i p))"
proof -
  obtain i j where "i < j" and "j < length (visited_nodes q p)" 
               and "(visited_nodes q p) ! i = (visited_nodes q p) ! j"
    using assms(2) non_distinct_repetition_indices by blast 

  have "(target q (take i p)) = (visited_nodes q p) ! i"
    using \<open>i < j\<close> \<open>j < length (visited_nodes q p)\<close>
    by (metis less_trans take_last_index target.simps visited_nodes_take)

  then have "(target q (take i p)) = (visited_nodes q p) ! j"
    using \<open>(visited_nodes q p) ! i = (visited_nodes q p) ! j\<close> by auto

  have p1: "take (j-i) (drop i p) \<noteq> []"
    using \<open>i < j\<close> \<open>j < length (visited_nodes q p)\<close> by auto 

  have "target (target q (take i p)) (take (j-i) (drop i p)) = (target q (take j p))"
    using \<open>i < j\<close> by (metis add_diff_inverse_nat less_asym' path_append_target take_add)
  then have p2: "target (target q (take i p)) (take (j-i) (drop i p)) = (target q (take i p))"
    using \<open>(target q (take i p)) = (visited_nodes q p) ! i\<close>
    using \<open>(target q (take i p)) = (visited_nodes q p) ! j\<close>
    by (metis \<open>j < length (visited_nodes q p)\<close> take_last_index target.simps visited_nodes_take)

  have p3: "path M (target q (take i p)) (take (j-i) (drop i p))"
    by (metis append_take_drop_id assms(1) path_append_elim)

  show ?thesis using p1 p2 p3 that by blast
qed



lemma acyclic_single_deadlock_reachable :
  assumes "acyclic M"
  and     "\<And> q' . q' \<in> reachable_nodes M \<Longrightarrow> q' = qd \<or> \<not> deadlock_state M q'"
shows "qd \<in> reachable_nodes M"
  using acyclic_deadlock_reachable[OF assms(1)]
  using assms(2) by auto 


lemma acyclic_paths_to_single_deadlock :
  assumes "acyclic M"
  and     "\<And> q' . q' \<in> reachable_nodes M \<Longrightarrow> q' = qd \<or> \<not> deadlock_state M q'"
  and     "q \<in> reachable_nodes M"
obtains p where "path M q p" and "target q p = qd"
proof -
  have "q \<in> nodes M" using assms(3) reachable_node_is_node by metis
  have "acyclic (from_FSM M q)"
    using from_FSM_acyclic[OF assms(3,1)] by assumption

  have *: "(\<And>q'. q' \<in> reachable_nodes (FSM.from_FSM M q) 
                \<Longrightarrow> q' = qd \<or> \<not> deadlock_state (FSM.from_FSM M q) q')"
    using assms(2) from_FSM_reachable_nodes[OF assms(3)] 
    unfolding deadlock_state.simps from_FSM_simps[OF \<open>q \<in> nodes M\<close>] by blast

  obtain p where "path (from_FSM M q) q p" and "target q p = qd"
    using acyclic_single_deadlock_reachable[OF \<open>acyclic (from_FSM M q)\<close> *]
    unfolding reachable_nodes_def from_FSM_simps[OF \<open>q \<in> nodes M\<close>]
    by blast 

  then show ?thesis
    using that by (metis \<open>q \<in> FSM.nodes M\<close> from_FSM_path) 
qed



subsection \<open>Nodes and Inputs as List\<close>

fun nodes_as_list :: "('a :: linorder, 'b, 'c) fsm \<Rightarrow> 'a list" where
  "nodes_as_list M = sorted_list_of_set (nodes M)"

lemma nodes_as_list_distinct : "distinct (nodes_as_list M)" by auto

lemma nodes_as_list_set : "set (nodes_as_list M) = nodes M"
  by (simp add: fsm_nodes_finite)


fun reachable_nodes_as_list :: "('a :: linorder, 'b, 'c) fsm \<Rightarrow> 'a list" where
  "reachable_nodes_as_list M = sorted_list_of_set (reachable_nodes M)"

lemma reachable_nodes_as_list_distinct : "distinct (reachable_nodes_as_list M)" by auto

lemma reachable_nodes_as_list_set : "set (reachable_nodes_as_list M) = reachable_nodes M"
  by (metis fsm_nodes_finite infinite_super reachable_node_is_node reachable_nodes_as_list.simps 
        set_sorted_list_of_set subsetI)  


fun inputs_as_list :: "('a, 'b :: linorder, 'c) fsm \<Rightarrow> 'b list" where
  "inputs_as_list M = sorted_list_of_set (inputs M)"

lemma inputs_as_list_set : "set (inputs_as_list M) = inputs M"
  by (simp add: fsm_inputs_finite)

lemma inputs_as_list_distinct : "distinct (inputs_as_list M)" by auto



subsection \<open>Filtering Transitions\<close>

lift_definition filter_transitions :: 
  "('a,'b,'c) fsm \<Rightarrow> (('a \<times> 'b \<times> 'c \<times> 'a) \<Rightarrow> bool) \<Rightarrow> ('a,'b,'c) fsm" is FSM_Impl.filter_transitions 
proof -
  fix M  :: "('a,'b,'c) fsm_impl"
  fix P  :: "('a \<times> 'b \<times> 'c \<times> 'a) \<Rightarrow> bool"
  assume "well_formed_fsm M"
  then show "well_formed_fsm (FSM_Impl.filter_transitions M P)" 
    unfolding FSM_Impl.filter_transitions.simps by force
qed


lemma filter_transitions_simps[simp] :
  "initial (filter_transitions M P) = initial M"
  "nodes (filter_transitions M P) = nodes M"
  "inputs (filter_transitions M P) = inputs M"
  "outputs (filter_transitions M P) = outputs M"
  "transitions (filter_transitions M P) = {t \<in> transitions M . P t}"
  by (transfer;auto)+


lemma filter_transitions_submachine :
  "is_submachine (filter_transitions M P) M" 
  unfolding filter_transitions_simps by fastforce


lemma filter_transitions_path :
  assumes "path (filter_transitions M P) q p"
  shows "path M q p"
  using path_begin_node[OF assms] 
        transition_subset_path[of "filter_transitions M P" M, OF _ assms]
  unfolding filter_transitions_simps by blast

lemma filter_transitions_reachable_nodes :
  assumes "q \<in> reachable_nodes (filter_transitions M P)"
  shows "q \<in> reachable_nodes M"
  using assms unfolding reachable_nodes_def filter_transitions_simps 
  using filter_transitions_path[of M P "initial M"]
  by blast


subsection \<open>Filtering Nodes\<close>

lift_definition filter_nodes :: "('a,'b,'c) fsm \<Rightarrow> ('a \<Rightarrow> bool) \<Rightarrow> ('a,'b,'c) fsm" 
  is FSM_Impl.filter_nodes 
proof -
  fix M  :: "('a,'b,'c) fsm_impl"
  fix P  :: "'a \<Rightarrow> bool"
  assume *: "well_formed_fsm M"

  then show "well_formed_fsm (FSM_Impl.filter_nodes M P)" 
    by (cases "P (FSM_Impl.initial M)"; auto)
qed

lemma filter_nodes_simps[simp] :
  assumes "P (initial M)"
shows "initial (filter_nodes M P) = initial M"
      "nodes (filter_nodes M P) = Set.filter P (nodes M)"
      "inputs (filter_nodes M P) = inputs M"
      "outputs (filter_nodes M P) = outputs M"
      "transitions (filter_nodes M P) = {t \<in> transitions M . P (t_source t) \<and> P (t_target t)}"
  using assms by (transfer;auto)+


lemma filter_nodes_submachine :
  assumes "P (initial M)"
  shows "is_submachine (filter_nodes M P) M" 
  using filter_nodes_simps[of P M, OF assms] by fastforce



fun restrict_to_reachable_nodes :: "('a,'b,'c) fsm \<Rightarrow> ('a,'b,'c) fsm" where
  "restrict_to_reachable_nodes M = filter_nodes M (\<lambda> q . q \<in> reachable_nodes M)"


lemma restrict_to_reachable_nodes_simps[simp] :
shows "initial (restrict_to_reachable_nodes M) = initial M"
      "nodes (restrict_to_reachable_nodes M) = reachable_nodes M"
      "inputs (restrict_to_reachable_nodes M) = inputs M"
      "outputs (restrict_to_reachable_nodes M) = outputs M"
      "transitions (restrict_to_reachable_nodes M) 
          = {t \<in> transitions M . (t_source t) \<in> reachable_nodes M}"
proof -
  show "initial (restrict_to_reachable_nodes M) = initial M"
       "nodes (restrict_to_reachable_nodes M) = reachable_nodes M"
       "inputs (restrict_to_reachable_nodes M) = inputs M"
       "outputs (restrict_to_reachable_nodes M) = outputs M"
      
    using filter_nodes_simps[of "(\<lambda> q . q \<in> reachable_nodes M)", OF reachable_nodes_initial] 
    using reachable_node_is_node[of _ M] by auto

  have "transitions (restrict_to_reachable_nodes M) 
          = {t \<in> transitions M. (t_source t) \<in> reachable_nodes M \<and> (t_target t) \<in> reachable_nodes M}"
    using filter_nodes_simps[of "(\<lambda> q . q \<in> reachable_nodes M)", OF reachable_nodes_initial] 
    by auto
  then show "transitions (restrict_to_reachable_nodes M) 
              = {t \<in> transitions M . (t_source t) \<in> reachable_nodes M}"
    using reachable_nodes_next[of _ M] by auto
qed


lemma restrict_to_reachable_nodes_path :
  assumes "q \<in> reachable_nodes M"
  shows "path M q p = path (restrict_to_reachable_nodes M) q p"
proof 
  show "path M q p \<Longrightarrow> path (restrict_to_reachable_nodes M) q p"
  proof -
    assume "path M q p"
    then show "path (restrict_to_reachable_nodes M) q p" 
    using assms proof (induction p arbitrary: q rule: list.induct)
      case Nil
      then show ?case
        using restrict_to_reachable_nodes_simps(2) by fastforce 
    next
      case (Cons t' p')
      then have "path M (t_target t') p'" by auto
      moreover have "t_target t' \<in> reachable_nodes M" using Cons.prems
        by (metis path_cons_elim reachable_nodes_next) 
      ultimately show ?case using Cons.IH
        by (metis (no_types, lifting) Cons.prems(1) Cons.prems(2) mem_Collect_eq path.simps 
              path_cons_elim restrict_to_reachable_nodes_simps(5))        
    qed
  qed

  show "path (restrict_to_reachable_nodes M) q p \<Longrightarrow> path M q p"
    by (metis (no_types, lifting) assms mem_Collect_eq reachable_node_is_node 
          restrict_to_reachable_nodes_simps(5) subsetI transition_subset_path)
qed




subsection \<open>Adding Transitions\<close>

lift_definition create_unconnected_fsm :: "'a \<Rightarrow> 'a set \<Rightarrow> 'b set \<Rightarrow> 'c set \<Rightarrow> ('a,'b,'c) fsm" 
  is FSM_Impl.create_unconnected_fsm by (transfer; simp)

lemma create_unconnected_fsm_simps :
  assumes "finite ns" and "finite ins" and "finite outs" and "q \<in> ns"
  shows "initial (create_unconnected_fsm q ns ins outs) = q"
        "nodes (create_unconnected_fsm q ns ins outs)   = ns"
        "inputs (create_unconnected_fsm q ns ins outs)  = ins"
        "outputs (create_unconnected_fsm q ns ins outs) = outs"
        "transitions (create_unconnected_fsm q ns ins outs) = {}"
  using assms by (transfer; auto)+


lift_definition add_transitions :: "('a,'b,'c) fsm \<Rightarrow> ('a \<times> 'b \<times> 'c \<times> 'a) set \<Rightarrow> ('a,'b,'c) fsm" 
  is FSM_Impl.add_transitions 
proof -
  fix M  :: "('a,'b,'c) fsm_impl"
  fix ts :: "('a \<times> 'b \<times> 'c \<times> 'a) set"
  assume *: "well_formed_fsm M"

  then show "well_formed_fsm (FSM_Impl.add_transitions M ts)" 
  proof (cases "\<forall> t \<in> ts . t_source t \<in> FSM_Impl.nodes M \<and> t_input t \<in> FSM_Impl.inputs M 
                            \<and> t_output t \<in> FSM_Impl.outputs M \<and> t_target t \<in> FSM_Impl.nodes M")
    case True
    then have "ts \<subseteq> FSM_Impl.nodes M \<times> FSM_Impl.inputs M \<times> FSM_Impl.outputs M \<times> FSM_Impl.nodes M" 
      by fastforce
    moreover have "finite (FSM_Impl.nodes M \<times> FSM_Impl.inputs M \<times> FSM_Impl.outputs M \<times> FSM_Impl.nodes M)" 
      using * by blast
    ultimately have "finite ts"
      using rev_finite_subset by auto 
    then show ?thesis using * by auto
  next
    case False
    then show ?thesis using * by auto
  qed
qed


lemma add_transitions_simps :
  assumes "\<forall> t \<in> ts . t_source t \<in> nodes M \<and> t_input t \<in> inputs M \<and> t_output t \<in> outputs M \<and> t_target t \<in> nodes M"
  shows "initial (add_transitions M ts) = initial M"
        "nodes (add_transitions M ts)   = nodes M"
        "inputs (add_transitions M ts)  = inputs M"
        "outputs (add_transitions M ts) = outputs M"
        "transitions (add_transitions M ts) = transitions M \<union> ts"
  using assms by (transfer; auto)+


end