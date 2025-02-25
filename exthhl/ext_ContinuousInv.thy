theory ext_ContinuousInv
  imports ext_BigStepContinuous
begin
lemma chainrule:
  assumes "\<forall>x. ((\<lambda>v. g (vec2state v)) has_derivative g' (vec2state x)) (at x within UNIV)"
    and "ODEsol ode p d"
    and "t \<in> {0 .. d}"
  shows "((\<lambda>t. g (p t)) has_derivative (\<lambda>s. g' (p t) (s *\<^sub>R ODE2Vec ode (p t)))) (at t within {0 .. d})"
proof -
  have 1: "(\<And>x. x \<in> UNIV \<Longrightarrow> ((\<lambda>v. g (vec2state v)) has_derivative g' (vec2state x)) (at x))"
    using assms(1) by auto
  have 2: "0 \<le> t \<and> t \<le> d"
    using assms(3) by auto
  have 3: "((\<lambda>t. state2vec(p t)) has_derivative (\<lambda>s. s *\<^sub>R ODE2Vec ode (p t))) (at t within {0..d})"
    using 2 assms(2) using ODEsol_old[OF assms(2)]unfolding ODEsol_def has_vderiv_on_def has_vector_derivative_def by auto
  show ?thesis
  using 1 2 3 has_derivative_in_compose2[of UNIV "(\<lambda>v. g (vec2state v))" "(\<lambda>v. g' (vec2state v))" "(\<lambda>t. state2vec (p t))" "{0 .. d}" t "(\<lambda>s. s *\<^sub>R ODE2Vec ode (p t))"]
  by auto
qed

lemma chainrule':
  assumes "\<forall>x. ((\<lambda>v. g (vec2state v)) has_derivative g' (vec2state x)) (at x within UNIV)"
    and "((\<lambda>t. state2vec (p t)) has_vderiv_on (\<lambda>t. ODE2Vec ode (p t))) {-e .. d+e}"
    and "e>0"
    and "t \<in> {-e .. d+e}"
  shows "((\<lambda>t. g (p t)) has_derivative (\<lambda>s. g' (p t) (s *\<^sub>R ODE2Vec ode (p t)))) (at t within {-e .. d+e})"
proof -
  have 1: "(\<And>x. x \<in> UNIV \<Longrightarrow> ((\<lambda>v. g (vec2state v)) has_derivative g' (vec2state x)) (at x))"
    using assms(1) by auto
  have 2: "-e \<le> t \<and> t \<le> d+e"
    using assms(3) assms(4) by auto
  have 3: "((\<lambda>t. state2vec(p t)) has_derivative (\<lambda>s. s *\<^sub>R ODE2Vec ode (p t))) (at t within {-e .. d+e})"
    using 2 assms(2) unfolding ODEsol_def has_vderiv_on_def has_vector_derivative_def by auto
  show ?thesis
  using 1 2 3 has_derivative_in_compose2[of UNIV "(\<lambda>v. g (vec2state v))" "(\<lambda>v. g' (vec2state v))" "(\<lambda>t. state2vec (p t))" "{-e .. d+e}" t "(\<lambda>s. s *\<^sub>R ODE2Vec ode (p t))"]
  by auto
qed

theorem Valid_inv:
  fixes inv :: "state \<Rightarrow> real"
  assumes "\<forall>x. ((\<lambda>v. inv (vec2state v)) has_derivative g' x) (at x within UNIV)"
      and "\<forall>S. b S \<longrightarrow> g' (state2vec S) (ODE2Vec ode S) = 0"
    shows "\<Turnstile> {\<lambda>(a,s) tr. inv s = r \<and> tr = tra \<and> b s}
       Cont ode b
      {\<lambda>(a,s) tr. (\<exists>p d. tr = tra @ [WaitBlk d (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})] \<and> (\<forall>t\<in>{0..d}. inv (p t) = r))}"
  unfolding Valid_def
  apply (auto elim!: contE)
  subgoal for d p
    apply (rule exI[where x=p])
    apply (rule exI[where x=d])
    apply auto
    subgoal premises pre for \<tau>
    proof-
      have 1: "\<forall>t\<in>{0 .. d}. ((\<lambda>t. inv(p t)) has_derivative  (\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)))) (at t within {0 .. d})"
        using pre assms
        using chainrule[of inv "\<lambda>x. g'(state2vec x)" ode p d] 
        by auto
      have 2: "\<forall>s. g' (state2vec(p t)) ((s *\<^sub>R 1) *\<^sub>R ODE2Vec ode (p t)) = s *\<^sub>R g' (state2vec(p t)) (1 *\<^sub>R ODE2Vec ode (p t))" if "t\<in>{0 .. d}" for t
        using 1 unfolding has_derivative_def bounded_linear_def 
        using that linear_iff[of "(\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)))"]
        by blast
      have 3: "\<forall>s. (s *\<^sub>R 1) = s" by simp
      have 4: "\<forall>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)) = s *\<^sub>R g' (state2vec(p t)) (ODE2Vec ode (p t))" if "t\<in>{0 .. d}" for t
        using 2 3 that by auto
      have 5: "\<forall>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t))= 0" if "t\<in>{0 ..<d}" for t
        using 4 assms(2) that pre by auto
      show ?thesis
        using mvt_real_eq[of d "(\<lambda>t. inv(p t))""\<lambda>t. (\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)))" \<tau>]
        using 1 5 pre by auto
    qed
    done
  done


text \<open>ODE with invariant\<close>
inductive ode_inv_assn :: "(state \<Rightarrow> bool) \<Rightarrow> 'a tassn" where
  "\<forall>t\<in>{0..d::real}. f (p t) \<Longrightarrow> ode_inv_assn f [WaitBlk d (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})]"

lemmas ode_inv_assn_induct = ode_inv_assn.induct[split_format(complete)]

inductive_cases ode_inv_assn_elim: "ode_inv_assn f tr"

theorem Valid_inv':
  fixes inv :: "state \<Rightarrow> real"
  assumes "\<forall>x. ((\<lambda>v. inv (vec2state v)) has_derivative g' (x)) (at x within UNIV)"
      and "\<forall>S. b S \<longrightarrow> g' (state2vec S) (ODE2Vec ode S) = 0"
  shows "\<Turnstile> {\<lambda>(a,s) tr. inv s = r \<and> P tr \<and> b s}
     Cont ode b
    {\<lambda>(a,s) tr. (P @\<^sub>t ode_inv_assn (\<lambda>s. inv s = r)) tr}"
  unfolding Valid_def
  apply (auto elim!: contE)
  subgoal for tr1 d p
    apply(simp add: join_assn_def)
    apply(rule exI [where x="tr1"])
    apply auto
    apply (auto intro!: ode_inv_assn.intros)
  subgoal premises pre for \<tau>
    proof-
      have 1: "\<forall>t\<in>{0 .. d}. ((\<lambda>t. inv(p t)) has_derivative  (\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)))) (at t within {0 .. d})"
        using pre assms
        using chainrule[of inv "\<lambda>x. g'(state2vec x)" ode p d] 
        by auto
      have 2: "\<forall>s. g' (state2vec(p t)) ((s *\<^sub>R 1) *\<^sub>R ODE2Vec ode (p t)) = s *\<^sub>R g' (state2vec(p t)) (1 *\<^sub>R ODE2Vec ode (p t))" if "t\<in>{0 .. d}" for t
        using 1 unfolding has_derivative_def bounded_linear_def 
        using that linear_iff[of "(\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)))"]
        by blast
      have 3: "\<forall>s. (s *\<^sub>R 1) = s" by simp
      have 4: "\<forall>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)) = s *\<^sub>R g' (state2vec(p t)) (ODE2Vec ode (p t))" if "t\<in>{0 .. d}" for t
        using 2 3 that by auto
      have 5: "\<forall>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t))= 0" if "t\<in>{0 ..<d}" for t
        using 4 assms(2) that pre by auto
      show ?thesis
        using mvt_real_eq[of d "(\<lambda>t. inv(p t))""\<lambda>t. (\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec ode (p t)))" \<tau>]
        using 1 5 pre by auto
    qed
    done
  done

theorem Valid_ode_supp:
  assumes "ode_supp (ODE ode) \<subseteq> VS" 
  shows "\<Turnstile> {\<lambda>(a,s) tr. supp s \<subseteq> VS}
     Cont (ODE ode) b
    {\<lambda>(a,s) tr. supp s \<subseteq> VS}"
  unfolding Valid_def
  apply (auto elim!: contE)
 subgoal for v d p 
    unfolding supp_def apply auto
    subgoal premises pre
    proof(rule ccontr)
      assume cond:"v \<notin> VS"
     have 1:"p 0 v = 0" using pre cond by auto
     have 2:"ode v = (\<lambda>_. 0)"
       using assms cond by auto
     have 3:"((\<lambda>t. p t v) has_vderiv_on (\<lambda>t. 0)) {0 .. d}"
       using ODEsol_old[OF pre(4)]
       using has_vderiv_on_proj[of "(\<lambda>t. state2vec (p t))" "(\<lambda>t. ODE2Vec (ODE ode) (p t))"  "{0 .. d}" v]
       apply auto
       unfolding state2vec_def apply auto
       using 2 by auto
     then have 4:"p 0 v = p d v"
       unfolding has_vderiv_on_def has_vector_derivative_def
       using mvt_real_eq[of d "(\<lambda>t. p t v)" "\<lambda>t. (\<lambda>x. x *\<^sub>R 0)" d] 
       using pre by auto
     then show False using 1 pre by auto
   qed
   done
  done



theorem Valid_inv_barrier_s_tr_le:
  fixes inv :: "state \<Rightarrow> real"
  assumes "\<forall>x. ((\<lambda>v. inv (vec2state v)) has_derivative g' (x)) (at x within UNIV)"
    and "\<forall>S. (b S)\<longrightarrow> ((inv S = 0) \<longrightarrow> g' (state2vec S) (ODE2Vec (ODE ode) S) < 0)"
  shows "\<Turnstile> {\<lambda>(a,s) tr. inv s \<le> 0 \<and> b s \<and> P tr}
     Cont (ODE ode) b
    {\<lambda>(a,s) tr. inv s \<le> 0 \<and> (P @\<^sub>t ode_inv_assn (\<lambda>s. inv s \<le> 0)) tr}"
  unfolding Valid_def
  apply (auto elim!: contE)
 subgoal premises pre for tr1 d p
    proof-
     obtain e where e: "e > 0" "((\<lambda>t. state2vec (p t)) has_vderiv_on (\<lambda>t. ODE2Vec (ODE ode) (p t))) {-e .. d+e}"
       using pre unfolding ODEsol_def by auto
    have 1: "\<forall>t\<in>{-e .. d+e}. ((\<lambda>t. inv(p t)) has_derivative  (\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec (ODE ode) (p t)))) (at t within {-e .. d+e})"
        using pre assms e
        using chainrule'[of inv "\<lambda>x. g'(state2vec x)" p "(ODE ode)" e d] 
        by auto
    have 2: "\<forall>s. g' (state2vec(p t)) ((s *\<^sub>R 1) *\<^sub>R ODE2Vec (ODE ode) (p t)) = s *\<^sub>R g' (state2vec(p t)) (1 *\<^sub>R ODE2Vec (ODE ode) (p t))" if "t\<in>{-e .. d+e}" for t
        using 1 unfolding has_derivative_def bounded_linear_def 
        using that linear_iff[of "(\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec (ODE ode) (p t)))"]
        by blast
    have 3: "(s *\<^sub>R 1) = s" and "(1 *\<^sub>R s) = s" 
      apply simp by simp
      have 4: "\<forall>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec (ODE ode) (p t)) = s *\<^sub>R g' (state2vec(p t)) (ODE2Vec (ODE ode) (p t))" if "t\<in>{-e .. d+e}" for t
        using 2 3 that by auto
      have 5: "\<forall>t\<in>{0..<d}. inv(p t) = 0 \<longrightarrow>  g' (state2vec(p t)) (ODE2Vec (ODE ode) (p t))< 0" if "t\<in>{0 ..<d}" for t
        using 4 assms(2) that pre by auto
      show ?thesis
        using real_inv_le[OF 1, of 0]
        using pre 5 e 3 by auto
    qed
  subgoal for tr1 d p
    apply(simp add: join_assn_def)
    apply(rule exI [where x="tr1"])
    apply auto
   apply (auto intro!: ode_inv_assn.intros)
   subgoal premises pre for \<tau>
   proof-
     obtain e where e: "e > 0" "((\<lambda>t. state2vec (p t)) has_vderiv_on (\<lambda>t. ODE2Vec (ODE ode) (p t))) {-e .. d+e}"
       using pre unfolding ODEsol_def by auto
    have 1: "\<forall>t\<in>{-e .. d+e}. ((\<lambda>t. inv(p t)) has_derivative  (\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec (ODE ode) (p t)))) (at t within {-e .. d+e})"
        using pre assms e
        using chainrule'[of inv "\<lambda>x. g'(state2vec x)" p "(ODE ode)" e d] 
        by auto
    have 2: "\<forall>s. g' (state2vec(p t)) ((s *\<^sub>R 1) *\<^sub>R ODE2Vec (ODE ode) (p t)) = s *\<^sub>R g' (state2vec(p t)) (1 *\<^sub>R ODE2Vec (ODE ode) (p t))" if "t\<in>{-e .. d+e}" for t
        using 1 unfolding has_derivative_def bounded_linear_def 
        using that linear_iff[of "(\<lambda>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec (ODE ode) (p t)))"]
        by blast
    have 3: "(s *\<^sub>R 1) = s" and "(1 *\<^sub>R s) = s" 
      apply simp by simp
      have 4: "\<forall>s. g' (state2vec(p t)) (s *\<^sub>R ODE2Vec (ODE ode) (p t)) = s *\<^sub>R g' (state2vec(p t)) (ODE2Vec (ODE ode) (p t))" if "t\<in>{-e .. d+e}" for t
        using 2 3 that by auto
      have 5: "inv(p t) = 0 \<longrightarrow>  g' (state2vec(p t)) (ODE2Vec (ODE ode) (p t))< 0" if "t\<in>{0 ..<d}" for t
        using 4 assms(2) that pre by auto
      show ?thesis
        using real_inv_le[OF 1, of 0] 
        using pre 5 e 3 by auto
    qed
    done
  done
        
theorem DC:
  assumes "\<Turnstile> {\<lambda>(a,s) tr. init s \<and> P tr \<and> b s}
     Cont ode b
    {\<lambda>(a,s) tr. (P @\<^sub>t ode_inv_assn c) tr}"
      and "\<Turnstile> {\<lambda>(a,s) tr. init s \<and> P tr \<and> (\<lambda>s. b s \<and> c s) s}
     Cont ode (\<lambda>s. b s \<and> c s)
    {\<lambda>(a,s) tr. (P @\<^sub>t ode_inv_assn d) tr}"
    shows "\<Turnstile> {\<lambda>(a,s) tr. init s \<and> P tr \<and> b s}
     Cont ode b
    {\<lambda>(a,s) tr. (P @\<^sub>t ode_inv_assn d) tr}"
unfolding Valid_def
  apply (auto elim!: contE)
  subgoal premises pre for tr T p a
  proof-
    have 1:"big_step (Cont ode b) (a,p 0) [WaitBlk T (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})] (a,p T)"
      apply (rule big_step.intros)
      using pre by auto
    have 2:"(P @\<^sub>t ode_inv_assn c) (tr @ [WaitBlk T (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})])"
      using assms(1) 1
      unfolding Valid_def using pre by auto
    obtain tra1 tra2 where tra1:"P tra1" and tra2:"ode_inv_assn c tra2" and tra3:"tra1 @ tra2 = (tr @ [WaitBlk T (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})])"
      using 2 unfolding join_assn_def by auto
    obtain T' p' where Tp:"tra2 = [WaitBlk T' (\<lambda>\<tau>. EState (a,p' \<tau>)) ({}, {})]"
      using tra2 tra3 apply (induct rule: ode_inv_assn.induct)
      by auto
    have 3:"ode_inv_assn c [WaitBlk T (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})]"
      using Tp tra3 tra2 by auto
    have 4: "\<forall>t\<in>{0..T}. c (p t)"
      using 3 apply (elim ode_inv_assn_elim)
      apply auto
      subgoal for d p' t
        apply (frule WaitBlk_cong)
        apply (frule WaitBlk_cong2)
        by auto
      done
    have 5:"big_step (Cont ode (\<lambda>s. b s \<and> c s)) (a,p 0) [WaitBlk T (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})] (a,p T)"
      apply (rule big_step.intros)
      using pre 4 by auto
    show ?thesis
      using assms(2) 
      unfolding Valid_def 
      using pre 4 5
      by (smt (verit, best) atLeastAtMost_iff case_prod_conv)
  qed
  done
  



end
