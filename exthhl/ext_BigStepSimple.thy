theory ext_BigStepSimple
  imports ext_Analysis_More
begin

type_synonym 'a ext_state = "'a \<times> state"

type_synonym 'a ext_exp = "'a ext_state \<Rightarrow> real"

type_synonym 'a ext_fform = "'a ext_state \<Rightarrow> bool"

type_synonym cname = string

type_synonym rdy_info = "cname set \<times> cname set"

datatype scheduler =
  sch (pool:"(int \<times> string) list")

datatype 'a comm =
  Send cname "'a ext_exp"        ("_[!]_" [110,108] 100)
  | Receive cname var     ("_[?]_" [110,108] 100)


datatype 'a proc =
  Cm "'a comm"
| Skip
| Assign var "'a ext_exp"             ("_ ::= _" [99,95] 94)
| Basic "'a \<Rightarrow> state \<Rightarrow> 'a"
| Seq "'a proc" "'a proc"           ("_; _" [91,90] 90)
| Cond "'a ext_fform" "'a proc" "'a proc"        ("IF _ THEN _ ELSE _ FI" [95,94] 93)
| Wait "'a ext_exp"
| IChoice "'a proc" "'a proc"  \<comment> \<open>Nondeterminism\<close>
| EChoice "('a comm \<times> 'a proc) list"  \<comment> \<open>External choice\<close>
| Rep "'a proc"   \<comment> \<open>Nondeterministic repetition\<close>
| Cont ODE fform  \<comment> \<open>ODE with boundary\<close>
| Interrupt ODE fform "('a comm \<times> 'a proc) list"  \<comment> \<open>Interrupt\<close>



datatype 'a gstate =
  EState "'a ext_state"
| ParState "'a gstate"  "'a gstate"

type_synonym 'a g_exp = "'a gstate \<Rightarrow> real"

fun exp_lift :: "'a ext_exp \<Rightarrow> 'a g_exp" where
  "exp_lift e (EState s) = e s"
| "exp_lift e (ParState s s') = undefined"

datatype 'a pproc =
  Single "'a proc"
| Parallel "'a pproc" "cname set" "'a pproc"


datatype comm_type = In | Out | IO

datatype 'a trace_block =
  CommBlock comm_type cname real
| WaitBlock real "real \<Rightarrow> 'a gstate" rdy_info

abbreviation "InBlock ch v \<equiv> CommBlock In ch v"
abbreviation "OutBlock ch v \<equiv> CommBlock Out ch v"
abbreviation "IOBlock ch v \<equiv> CommBlock IO ch v"

fun WaitBlk :: "real \<Rightarrow> (real \<Rightarrow> 'a gstate) \<Rightarrow> rdy_info \<Rightarrow> 'a trace_block" where
  "WaitBlk d p rdy = WaitBlock d (\<lambda>\<tau>\<in>{0..d}. p \<tau>) rdy"


lemma WaitBlk_simps [simp]:
  "WaitBlk d p rdy = WaitBlock d (\<lambda>\<tau>\<in>{0..d}. p \<tau>) rdy"
  apply auto
  done

declare WaitBlk.simps [simp del]

lemma WaitBlk_not_Comm [simp]:
  "WaitBlk d p rdy \<noteq> CommBlock ch_type ch v"
  "CommBlock ch_type ch v \<noteq> WaitBlk d p rdy"
  by (auto)+


lemma restrict_cong_to_eq:
  fixes x :: real
  shows "restrict p1 {0..t} = restrict p2 {0..t} \<Longrightarrow> 0 \<le> x \<Longrightarrow> x \<le> t \<Longrightarrow> p1 x = p2 x"
  apply (auto simp add: restrict_def) by metis

lemma restrict_cong_to_eq2:
  fixes x :: real
  shows "restrict p1 {0..} = restrict p2 {0..} \<Longrightarrow> 0 \<le> x \<Longrightarrow> p1 x = p2 x"
  apply (auto simp add: restrict_def) by metis

lemma WaitBlk_ext:
  fixes t1 t2 :: real
    and hist1 hist2 :: "real \<Rightarrow> 'a gstate"
  shows "t1 = t2 \<Longrightarrow>
   (\<And>\<tau>::real. 0 \<le> \<tau> \<Longrightarrow> \<tau> \<le> t1 \<Longrightarrow> hist1 \<tau> = hist2 \<tau>) \<Longrightarrow> rdy1 = rdy2 \<Longrightarrow>
   WaitBlk t1 hist1 rdy1 = WaitBlk t2 hist2 rdy2"
  by auto

lemma WaitBlk_ext_real:
  fixes t1 :: real
    and t2 :: real
  shows "t1 = t2 \<Longrightarrow> (\<And>\<tau>. 0 \<le> \<tau> \<Longrightarrow> \<tau> \<le> t1 \<Longrightarrow> hist1 \<tau> = hist2 \<tau>) \<Longrightarrow> rdy1 = rdy2 \<Longrightarrow>
         WaitBlk t1 hist1 rdy1 = WaitBlk t2 hist2 rdy2"
  by (auto simp add: restrict_def)

lemma WaitBlk_cong:
  "WaitBlk t1 hist1 rdy1 = WaitBlk t2 hist2 rdy2 \<Longrightarrow> t1 = t2 \<and> rdy1 = rdy2"
  by (auto)+

lemma WaitBlk_cong2:
  assumes "WaitBlk t1 hist1 rdy1 = WaitBlk t2 hist2 rdy2"
    and "0 \<le> t" "t \<le> t1"
  shows "hist1 t = hist2 t"
proof -
  have a: "t1 = t2" "rdy1 = rdy2"
    using assms WaitBlk_cong 
    by blast+
  show ?thesis
    using restrict_cong_to_eq assms 
    by auto
qed

lemma WaitBlk_split1:
  fixes t1 :: real
  assumes "WaitBlk t p1 rdy = WaitBlk t p2 rdy"
    and "0 < t1" "t1 < t"
  shows "WaitBlk t1 p1 rdy = WaitBlk t1 p2 rdy"
  apply auto apply (rule ext) subgoal for x
      using assms[unfolded ] 
      using restrict_cong_to_eq[of p1 t p2 x] 
      apply auto
    done
  done

lemma WaitBlk_split2:
  fixes t1 :: real
  assumes "WaitBlk t p1 rdy = WaitBlk t p2 rdy"
    and "0 < t1" "t1 < t"
  shows "WaitBlk (t - t1) (\<lambda>\<tau>::real. p1 (\<tau> + t1)) rdy =
         WaitBlk (t - t1) (\<lambda>\<tau>::real. p2 (\<tau> + t1)) rdy"
  apply auto apply (rule ext) subgoal for x
      using assms[unfolded ]
      using restrict_cong_to_eq[of p1 t p2 "x + t1"] by auto
    done

lemmas WaitBlk_split = WaitBlk_split1 WaitBlk_split2
declare WaitBlk_simps [simp del]

type_synonym 'a trace = "'a trace_block list"

type_synonym 'a tassn = "'a trace \<Rightarrow> bool"

subsection \<open>Big-step semantics\<close>

text \<open>Compute list of ready communications for an external choice.\<close>
fun rdy_of_echoice :: "('a comm \<times> 'a proc) list \<Rightarrow> rdy_info" where
  "rdy_of_echoice [] = ({}, {})"
| "rdy_of_echoice ((ch[!]e, _) # rest) = (
    let rdy = rdy_of_echoice rest in
      (insert ch (fst rdy), snd rdy))"
| "rdy_of_echoice ((ch[?]var, _) # rest) = (
    let rdy = rdy_of_echoice rest in
      (fst rdy, insert ch (snd rdy)))"

text \<open>big_step p s1 tr s2 means executing p starting from state s1 results
in a trace tr and final state s2.\<close>


inductive big_step :: "'a proc \<Rightarrow> 'a ext_state \<Rightarrow> 'a trace \<Rightarrow> 'a ext_state \<Rightarrow> bool" where
  skipB: "big_step Skip s [] s"
| assignB: "big_step (var ::= e) (a,s) [] (a,s(var := e (a,s)))"
| seqB: "big_step p1 s1 tr1 s2 \<Longrightarrow>
         big_step p2 s2 tr2 s3 \<Longrightarrow>
         big_step (p1; p2) s1 (tr1 @ tr2) s3"
| basicB: "big_step (Basic f) (a,s) [] (f a s, s)"
| sendB1: "big_step (Cm (ch[!]e)) s [OutBlock ch (e s)] s"
| sendB2: "(d::real) > 0 \<Longrightarrow> big_step (Cm (ch[!]e)) s
            [WaitBlk d (\<lambda>_. EState s) ({ch}, {}),
             OutBlock ch (e s)] s"
| receiveB1: "big_step (Cm (ch[?]var)) (a,s) [InBlock ch v] (a,s(var := v))"
| receiveB2: "(d::real) > 0 \<Longrightarrow> big_step (Cm (ch[?]var)) (a,s)
            [WaitBlk d (\<lambda>_. EState (a,s)) ({}, {ch}),
             InBlock ch v] (a,s(var := v))"
| condB1: "b s1 \<Longrightarrow> big_step p1 s1 tr s2 \<Longrightarrow> big_step (IF b THEN p1 ELSE p2 FI) s1 tr s2"
| condB2: "\<not> b s1 \<Longrightarrow> big_step p2 s1 tr s2 \<Longrightarrow> big_step (IF b THEN p1 ELSE p2 FI) s1 tr s2"
| waitB1: "e s > 0 \<Longrightarrow> big_step (Wait e) s [WaitBlk (e s) (\<lambda>_. EState s) ({}, {})] s"
| waitB2: "\<not> e s > 0 \<Longrightarrow> big_step (Wait e) s [] s"
| IChoiceB1: "big_step p1 s1 tr s2 \<Longrightarrow> big_step (IChoice p1 p2) s1 tr s2"
| IChoiceB2: "big_step p2 s1 tr s2 \<Longrightarrow> big_step (IChoice p1 p2) s1 tr s2"
| EChoiceSendB1: "i < length cs \<Longrightarrow> cs ! i = (Send ch e, p2) \<Longrightarrow>
    big_step p2 s1 tr2 s2 \<Longrightarrow>
    big_step (EChoice cs) s1 (OutBlock ch (e s1) # tr2) s2"
| EChoiceSendB2: "(d::real) > 0 \<Longrightarrow> i < length cs \<Longrightarrow> cs ! i = (Send ch e, p2) \<Longrightarrow>
    big_step p2 s1 tr2 s2 \<Longrightarrow>
    big_step (EChoice cs) s1 (WaitBlk d (\<lambda>_. EState s1) (rdy_of_echoice cs) #
                              OutBlock ch (e s1) # tr2) s2"
| EChoiceReceiveB1: "i < length cs \<Longrightarrow> cs ! i = (Receive ch var, p2) \<Longrightarrow>
    big_step p2 (a1,s1(var := v)) tr2 s2 \<Longrightarrow>
    big_step (EChoice cs) (a1,s1) (InBlock ch v # tr2) s2"
| EChoiceReceiveB2: "(d::real) > 0 \<Longrightarrow> i < length cs \<Longrightarrow> cs ! i = (Receive ch var, p2) \<Longrightarrow>
    big_step p2 (a1,s1(var := v)) tr2 s2 \<Longrightarrow>
    big_step (EChoice cs) (a1,s1) (WaitBlk d (\<lambda>_. EState (a1,s1)) (rdy_of_echoice cs) #
                              InBlock ch v # tr2) s2"
| RepetitionB1: "big_step (Rep p) s [] s"
| RepetitionB2: "big_step p s1 tr1 s2 \<Longrightarrow> big_step (Rep p) s2 tr2 s3 \<Longrightarrow>
    tr = tr1 @ tr2 \<Longrightarrow>
    big_step (Rep p) s1 tr s3"
| ContB1: "\<not>b s \<Longrightarrow> big_step (Cont ode b) (a,s) [] (a,s)"
| ContB2: "d > 0 \<Longrightarrow> ODEsol ode p d \<Longrightarrow>
    (\<forall>t. t \<ge> 0 \<and> t < d \<longrightarrow> b (p t)) \<Longrightarrow>
    \<not>b (p d) \<Longrightarrow> p 0 = s1 \<Longrightarrow>
    big_step (Cont ode b) (a,s1) [WaitBlk d (\<lambda>\<tau>. EState (a,p \<tau>)) ({}, {})] (a,p d)"
| InterruptSendB1: "i < length cs \<Longrightarrow> cs ! i = (Send ch e, p2) \<Longrightarrow>
    big_step p2 s tr2 s2 \<Longrightarrow>
    big_step (Interrupt ode b cs) s (OutBlock ch (e s) # tr2) s2"
| InterruptSendB2: "d > 0 \<Longrightarrow> ODEsol ode p d \<Longrightarrow> p 0 = s1 \<Longrightarrow>
    (\<forall>t. t \<ge> 0 \<and> t < d \<longrightarrow> b (p t)) \<Longrightarrow>
    i < length cs \<Longrightarrow> cs ! i = (Send ch e, p2) \<Longrightarrow>
    rdy = rdy_of_echoice cs \<Longrightarrow>
    big_step p2 (a,p d) tr2 s2 \<Longrightarrow>
    big_step (Interrupt ode b cs) (a,s1) (WaitBlk d (\<lambda>\<tau>. EState (a,p \<tau>)) rdy #
                                      OutBlock ch (e (a,p d)) # tr2) s2"
| InterruptReceiveB1: "i < length cs \<Longrightarrow> cs ! i = (Receive ch var, p2) \<Longrightarrow>
    big_step p2 (a,s(var := v)) tr2 s2 \<Longrightarrow>
    big_step (Interrupt ode b cs) (a,s) (InBlock ch v # tr2) s2"
| InterruptReceiveB2: "d > 0 \<Longrightarrow> ODEsol ode p d \<Longrightarrow> p 0 = s1 \<Longrightarrow>
    (\<forall>t. t \<ge> 0 \<and> t < d \<longrightarrow> b (p t)) \<Longrightarrow>
    i < length cs \<Longrightarrow> cs ! i = (Receive ch var, p2) \<Longrightarrow>
    rdy = rdy_of_echoice cs \<Longrightarrow>
    big_step p2 (a,(p d)(var := v)) tr2 s2 \<Longrightarrow>
    big_step (Interrupt ode b cs) (a,s1) (WaitBlk d (\<lambda>\<tau>. EState (a,p \<tau>)) rdy #
                                      InBlock ch v # tr2) s2"
| InterruptB1: "\<not>b s \<Longrightarrow> big_step (Interrupt ode b cs) (a,s) [] (a,s)"
| InterruptB2: "d > 0 \<Longrightarrow> ODEsol ode p d \<Longrightarrow>
    (\<forall>t. t \<ge> 0 \<and> t < d \<longrightarrow> b (p t)) \<Longrightarrow>
    \<not>b (p d) \<Longrightarrow> p 0 = s1 \<Longrightarrow> p d = s2 \<Longrightarrow>
    rdy = rdy_of_echoice cs \<Longrightarrow>
    big_step (Interrupt ode b cs) (a,s1) [WaitBlk d (\<lambda>\<tau>. EState (a,p \<tau>)) rdy] (a,s2)"

lemma big_step_cong:
  "big_step c s1 tr s2 \<Longrightarrow> tr = tr' \<Longrightarrow> s2 = s2' \<Longrightarrow> big_step c s1 tr' s2'"
  by auto

inductive_cases skipE: "big_step Skip s1 tr s2"
inductive_cases assignE: "big_step (Assign var e) s1 tr s2"
inductive_cases sendE: "big_step (Cm (ch[!]e)) s1 tr s2"
inductive_cases receiveE: "big_step (Cm (ch[?]var)) s1 tr s2"
inductive_cases seqE: "big_step (Seq p1 p2) s1 tr s2"
inductive_cases condE: "big_step (Cond b p1 p2) s1 tr s2"
inductive_cases basicE: "big_step (Basic f) s1 tr s2"
inductive_cases waitE: "big_step (Wait d) s1 tr s2"
inductive_cases echoiceE: "big_step (EChoice es) s1 tr s2"
inductive_cases ichoiceE: "big_step (IChoice p1 p2) s1 tr s2"
inductive_cases contE: "big_step (Cont ode b) s1 tr s2"
inductive_cases interruptE: "big_step (Interrupt ode b cs) s1 tr s2"

subsection \<open>Validity\<close>

text \<open>Assertion is a predicate on states and traces\<close>

type_synonym 'a assn = "'a ext_state \<Rightarrow> 'a trace \<Rightarrow> bool"

definition Valid :: "'a assn \<Rightarrow> 'a proc \<Rightarrow> 'a assn \<Rightarrow> bool" ("\<Turnstile> ({(1_)}/ (_)/ {(1_)})" 50) where
  "\<Turnstile> {P} c {Q} \<longleftrightarrow> (\<forall>s1 tr1 s2 tr2. P s1 tr1 \<longrightarrow> big_step c s1 tr2 s2 \<longrightarrow> Q s2 (tr1 @ tr2))"

definition entails :: "'a assn \<Rightarrow> 'a assn \<Rightarrow> bool" (infixr "\<Longrightarrow>\<^sub>A" 25) where
  "(P \<Longrightarrow>\<^sub>A Q) \<longleftrightarrow> (\<forall>s tr. P s tr \<longrightarrow> Q s tr)"

lemma entails_refl [simp]:
  "P \<Longrightarrow>\<^sub>A P"
  unfolding entails_def by auto

lemma entails_trans:
  "(P \<Longrightarrow>\<^sub>A Q) \<Longrightarrow> (Q \<Longrightarrow>\<^sub>A R) \<Longrightarrow> (P \<Longrightarrow>\<^sub>A R)"
  unfolding entails_def by auto

lemma Valid_ex_pre:
  "(\<And>v. \<Turnstile> {P v} c {Q}) \<Longrightarrow> \<Turnstile> {\<lambda>s t. \<exists>v. P v s t} c {Q}"
  unfolding Valid_def by auto

lemma Valid_ex_pre':
  "(\<And>v. \<Turnstile> {P v} c {Q}) \<Longrightarrow> \<Turnstile> {\<lambda>(a,s) t. \<exists>v. P v (a,s) t} c {Q}"
  unfolding Valid_def by auto

lemma Valid_ex_post:
  "\<exists>v. \<Turnstile> {P} c {Q v} \<Longrightarrow> \<Turnstile> {P} c {\<lambda>s t. \<exists>v. Q v s t}"
  unfolding Valid_def by blast

lemma Valid_ex_post':
  "\<exists>v. \<Turnstile> {P} c {Q v} \<Longrightarrow> \<Turnstile> {P} c {\<lambda>(a,s) t. \<exists>v. Q v (a,s) t}"
  unfolding Valid_def by blast

lemma Valid_and_pre:
  "(P1 \<Longrightarrow> \<Turnstile> {P} c {Q}) \<Longrightarrow> \<Turnstile> {\<lambda>s t. P1 \<and> P s t} c {Q}"
  unfolding Valid_def by auto

theorem Valid_weaken_pre:
  "P \<Longrightarrow>\<^sub>A P' \<Longrightarrow> \<Turnstile> {P'} c {Q} \<Longrightarrow> \<Turnstile> {P} c {Q}"
  unfolding Valid_def entails_def by blast

theorem Valid_strengthen_post:
  "Q \<Longrightarrow>\<^sub>A Q' \<Longrightarrow> \<Turnstile> {P} c {Q} \<Longrightarrow> \<Turnstile> {P} c {Q'}"
  unfolding Valid_def entails_def by blast

theorem Valid_skip:
  "\<Turnstile> {P} Skip {P}"
  unfolding Valid_def
  by (auto elim: skipE)

theorem Valid_assign:
  "\<Turnstile> {\<lambda>(a,s). Q (a,s(var := e (a,s)))} var ::= e {Q}"
  unfolding Valid_def
  by (auto elim: assignE)

theorem Valid_send:
  "\<Turnstile> {\<lambda>s tr. Q s (tr @ [OutBlock ch (e s)]) \<and>
              (\<forall>d::real>0. Q s (tr @ [WaitBlk d (\<lambda>_. EState s) ({ch}, {}), OutBlock ch (e s)]))}
       Cm (ch[!]e) {Q}"
  unfolding Valid_def
  by (auto elim: sendE)

theorem Valid_receive:
  "\<Turnstile> {\<lambda>(a,s) tr. (\<forall>v. Q (a,s(var := v)) (tr @ [InBlock ch v])) \<and>
              (\<forall>d::real>0. \<forall>v. Q (a,s(var := v))
                (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) ({}, {ch}), InBlock ch v]))}
       Cm (ch[?]var) {Q}"
  unfolding Valid_def
  by (auto elim: receiveE)

theorem Valid_seq:
  "\<Turnstile> {P} c1 {Q} \<Longrightarrow> \<Turnstile> {Q} c2 {R} \<Longrightarrow> \<Turnstile> {P} c1; c2 {R}"
  unfolding Valid_def
  apply (auto elim!: seqE) by fastforce

theorem Valid_basic:
  "\<Turnstile> {\<lambda>(a,s). Q (f a s,s)} Basic f {Q}"
  unfolding Valid_def
  by (auto elim: basicE)

theorem Valid_cond:
  "\<Turnstile> {P1} c1 {Q} \<Longrightarrow> \<Turnstile> {P2} c2 {Q} \<Longrightarrow>
   \<Turnstile> {\<lambda>s. if b s then P1 s else P2 s} IF b THEN c1 ELSE c2 FI {Q}"
  unfolding Valid_def
  by (auto elim: condE)

theorem Valid_wait:
  "\<Turnstile> {\<lambda>s tr. if e s > 0 then 
                Q s (tr @ [WaitBlk (e s) (\<lambda>_. EState s) ({}, {})])
              else Q s tr} Wait e {Q}"
  unfolding Valid_def
  by (auto elim: waitE)

theorem Valid_rep:
  assumes "\<Turnstile> {P} c {P}"
  shows "\<Turnstile> {P} Rep c {P}"
proof -
  have "big_step p s1 tr2 s2 \<Longrightarrow> p = Rep c \<Longrightarrow> \<forall>tr1. P s1 tr1 \<longrightarrow> P s2 (tr1 @ tr2)" for p s1 s2 tr2
    apply (induct rule: big_step.induct, auto)
    by (metis Valid_def append.assoc assms)
  then show ?thesis
    using assms unfolding Valid_def by auto
qed

theorem Valid_ichoice:
  assumes "\<Turnstile> {P1} c1 {Q}"
    and "\<Turnstile> {P2} c2 {Q}"
  shows "\<Turnstile> {\<lambda>s tr. P1 s tr \<and> P2 s tr} IChoice c1 c2 {Q}"
  using assms unfolding Valid_def by (auto elim: ichoiceE)

theorem Valid_ichoice_sp:
  assumes "\<Turnstile> {P} c1 {Q1}"
    and "\<Turnstile> {P} c2 {Q2}"
  shows "\<Turnstile> {P} IChoice c1 c2 {\<lambda>s tr. Q1 s tr \<or> Q2 s tr}"
  using assms unfolding Valid_def by (auto elim: ichoiceE)

theorem Valid_echoice:
  assumes "\<And>i. i<length es \<Longrightarrow>
    case es ! i of
      (ch[!]e, p2) \<Rightarrow>
        (\<exists>Q. \<Turnstile> {Q} p2 {R} \<and>
             (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. Q (a,s) (tr @ [OutBlock ch (e (a,s))]))) \<and>
             (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>d::real>0. Q (a,s) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) (rdy_of_echoice es), OutBlock ch (e (a,s))]))))
    | (ch[?]var, p2) \<Rightarrow>
        (\<exists>Q. \<Turnstile> {Q} p2 {R} \<and>
             (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>v. Q (a,s(var := v)) (tr @ [InBlock ch v]))) \<and>
             (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>d::real>0. \<forall>v. Q (a,s(var := v)) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) (rdy_of_echoice es), InBlock ch v]))))"
  shows "\<Turnstile> {P} EChoice es {R}"
proof -
  have a: "R s2 (tr1 @ (OutBlock ch (e (a1,s1)) # tr2))"
    if *: "P (a1,s1) tr1"
          "i < length es"
          "es ! i = (ch[!]e, p2)"
          "big_step p2 (a1,s1) tr2 s2" for a1 s1 tr1 s2 i ch e p2 tr2
  proof -
    from assms obtain Q where 1:
      "\<Turnstile> {Q} p2 {R}"
      "P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. Q (a,s) (tr @ [OutBlock ch (e (a,s))]))"
      using *(2,3) by fastforce
    have 2: "Q (a1,s1) (tr1 @ [OutBlock ch (e (a1,s1))])"
      using 1(2) *(1) unfolding entails_def by auto
    then show ?thesis
      using *(4) 1(1) unfolding Valid_def by fastforce
  qed
  have b: "R s2 (tr1 @ (WaitBlk d (\<lambda>_. EState (a1,s1)) (rdy_of_echoice es) # OutBlock ch (e (a1,s1)) # tr2))"
    if *: "P (a1,s1) tr1"
          "0 < (d::real)"
          "i < length es"
          "es ! i = (ch[!]e, p2)"
          "big_step p2 (a1,s1) tr2 s2" for a1 s1 tr1 s2 d i ch e p2 tr2
  proof -
    obtain Q where 1:
      "\<Turnstile> {Q} p2 {R}"
      "P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>d::real>0. Q (a,s) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) (rdy_of_echoice es), OutBlock ch (e (a,s))]))"
      using *(3,4) assms by fastforce+
    have 2: "Q (a1,s1) (tr1 @ [WaitBlk d (\<lambda>_. EState (a1,s1)) (rdy_of_echoice es), OutBlock ch (e (a1,s1))])"
      using 1(2) *(1,2) unfolding entails_def by auto
    then show ?thesis
      using *(5) 1(1) unfolding Valid_def by fastforce
  qed
  have c: "R s2 (tr1 @ (InBlock ch v # tr2))"
    if *: "P (a1,s1) tr1"
          "i < length es"
          "es ! i = (ch[?]var, p2)"
          "big_step p2 (a1,s1(var := v)) tr2 s2" for a1 s1 tr1 s2 i ch var p2 v tr2
  proof -
    from assms obtain Q where 1:
      "\<Turnstile> {Q} p2 {R}"
      "P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>v. Q (a,s(var := v)) (tr @ [InBlock ch v]))"
      using *(2,3) by fastforce
    have 2: "Q (a1,s1(var := v)) (tr1 @ [InBlock ch v])"
      using 1(2) *(1) unfolding entails_def by auto
    then show ?thesis
      using *(4) 1(1) unfolding Valid_def by fastforce
  qed
  have d: "R s2 (tr1 @ (WaitBlk d (\<lambda>_. EState (a1,s1)) (rdy_of_echoice es) # InBlock ch v # tr2))"
    if *: "P (a1,s1) tr1"
          "0 < (d::real)"
          "i < length es"
          "es ! i = (ch[?]var, p2)"
          "big_step p2 (a1,s1(var := v)) tr2 s2" for a1 s1 tr1 s2 d i ch var p2 v tr2
  proof -
    from assms obtain Q where 1:
      "\<Turnstile> {Q} p2 {R}"
      "P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>d::real>0. \<forall>v. Q (a,s(var := v)) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) (rdy_of_echoice es), InBlock ch v]))"
      using *(3,4) by fastforce
    have 2: "Q (a1,s1(var := v)) (tr1 @ [WaitBlk d (\<lambda>_. EState (a1,s1)) (rdy_of_echoice es), InBlock ch v])"
      using 1(2) *(1,2) unfolding entails_def by auto
    then show ?thesis
      using *(5) 1(1) unfolding Valid_def by fastforce
  qed
  show ?thesis
    unfolding Valid_def apply auto
    apply (auto elim!: echoiceE) using a b c d by auto
qed

subsection \<open>Assertions on traces\<close>
definition entails_tassn :: "'a tassn \<Rightarrow> 'a tassn \<Rightarrow> bool" (infixr "\<Longrightarrow>\<^sub>t" 25) where
  "(P \<Longrightarrow>\<^sub>t Q) \<longleftrightarrow> (\<forall>tr. P tr \<longrightarrow> Q tr)"

lemma entails_tassn_refl [simp]:
  "P \<Longrightarrow>\<^sub>t P"
  unfolding entails_tassn_def by auto

lemma entails_tassn_trans:
  "(P \<Longrightarrow>\<^sub>t Q) \<Longrightarrow> (Q \<Longrightarrow>\<^sub>t R) \<Longrightarrow> (P \<Longrightarrow>\<^sub>t R)"
  unfolding entails_tassn_def by auto

lemma entails_tassn_ex_pre:
  "(\<And>x. P x \<Longrightarrow>\<^sub>t Q) \<Longrightarrow> (\<lambda>tr. (\<exists>x. P x tr)) \<Longrightarrow>\<^sub>t Q"
  by (auto simp add: entails_tassn_def)

lemma entails_tassn_ex_post:
  "(\<exists>x. P \<Longrightarrow>\<^sub>t Q x) \<Longrightarrow> P \<Longrightarrow>\<^sub>t (\<lambda>tr. (\<exists>x. Q x tr))"
  by (auto simp add: entails_tassn_def)

definition emp_assn :: "'a tassn" ("emp\<^sub>t") where
  "emp\<^sub>t = (\<lambda>tr. tr = [])"

definition join_assn :: "'a tassn \<Rightarrow> 'a tassn \<Rightarrow> 'a tassn" (infixr "@\<^sub>t" 65) where
  "P @\<^sub>t Q = (\<lambda>tr. \<exists>tr1 tr2. P tr1 \<and> Q tr2 \<and> tr = tr1 @ tr2)"

definition magic_wand_assn :: "'a tassn \<Rightarrow> 'a tassn \<Rightarrow> 'a tassn" (infixr "@-" 65) where
  "Q @- P = (\<lambda>tr. \<forall>tr1. Q tr1 \<longrightarrow> P (tr @ tr1))"

definition all_assn :: "('b \<Rightarrow> 'a tassn) \<Rightarrow> 'a tassn" (binder "\<forall>\<^sub>t" 10) where
  "(\<forall>\<^sub>tv. P v) = (\<lambda>tr. \<forall>v. P v tr)"

definition ex_assn :: "('b \<Rightarrow> 'a tassn) \<Rightarrow> 'a tassn" (binder "\<exists>\<^sub>t" 10) where
  "(\<exists>\<^sub>tv. P v) = (\<lambda>tr. \<exists>v. P v tr)"

definition conj_assn :: "'a tassn \<Rightarrow> 'a tassn \<Rightarrow> 'a tassn" (infixr "\<and>\<^sub>t" 35) where
  "(P \<and>\<^sub>t Q) = (\<lambda>tr. P tr \<and> Q tr)"

definition disj_assn :: "'a tassn \<Rightarrow> 'a tassn \<Rightarrow> 'a tassn" (infixr "\<or>\<^sub>t" 25) where
  "(P \<or>\<^sub>t Q) = (\<lambda>tr. P tr \<or> Q tr)"

definition imp_assn :: "'a tassn \<Rightarrow> 'a tassn \<Rightarrow> 'a tassn" (infixr "\<longrightarrow>\<^sub>t" 25) where
  "(P \<longrightarrow>\<^sub>t Q) = (\<lambda>tr. P tr \<longrightarrow> Q tr)"

definition pure_assn :: "bool \<Rightarrow> 'a tassn" ("\<up>") where
  "\<up>b = (\<lambda>_. b)"

inductive out_assn :: "'a gstate \<Rightarrow> cname \<Rightarrow> real \<Rightarrow> 'a tassn" ("Out\<^sub>t") where
  "Out\<^sub>t s ch v [OutBlock ch v]"
| "d > 0 \<Longrightarrow> Out\<^sub>t s ch v [WaitBlk d (\<lambda>_. s) ({ch}, {}), OutBlock ch v]"

inductive in_assn :: "'a gstate \<Rightarrow> cname \<Rightarrow> real \<Rightarrow> 'a tassn" ("In\<^sub>t") where
  "In\<^sub>t s ch v [InBlock ch v]"
| "d > 0 \<Longrightarrow> In\<^sub>t s ch v [WaitBlk d (\<lambda>_. s) ({}, {ch}), InBlock ch v]"

inductive io_assn :: "cname \<Rightarrow> real \<Rightarrow> 'a tassn" ("IO\<^sub>t") where
  "IO\<^sub>t ch v [IOBlock ch v]"

inductive wait_assn :: "real \<Rightarrow> (real \<Rightarrow> 'a gstate) \<Rightarrow> rdy_info \<Rightarrow> 'a tassn" ("Wait\<^sub>t") where
  "d > 0 \<Longrightarrow> Wait\<^sub>t d p rdy [WaitBlk d (\<lambda>\<tau>. p \<tau>) rdy]"
| "d \<le> 0 \<Longrightarrow> Wait\<^sub>t d p rdy []"


lemma emp_unit_left [simp]:
  "(emp\<^sub>t @\<^sub>t P) = P"
  unfolding join_assn_def emp_assn_def by auto

lemma emp_unit_right [simp]:
  "(P @\<^sub>t emp\<^sub>t) = P"
  unfolding join_assn_def emp_assn_def by auto

lemma join_assoc:
  "(P @\<^sub>t Q) @\<^sub>t R = P @\<^sub>t (Q @\<^sub>t R)"
  unfolding join_assn_def by fastforce

lemma entails_mp_emp:
  "emp\<^sub>t \<Longrightarrow>\<^sub>t P @- P"
  unfolding entails_tassn_def emp_assn_def magic_wand_assn_def by auto

lemma entails_mp:
  "Q \<Longrightarrow>\<^sub>t P @- (Q @\<^sub>t P)"
  unfolding entails_tassn_def magic_wand_assn_def join_assn_def by auto

lemma magic_wand_mono:
  "P \<Longrightarrow>\<^sub>t Q \<Longrightarrow> (R @- P) \<Longrightarrow>\<^sub>t (R @- Q)"
  unfolding entails_tassn_def magic_wand_assn_def by auto

definition false_assn :: "'a tassn" ("false\<^sub>A") where
  "false_assn tr = False"

definition true_assn :: "'a tassn" ("true\<^sub>A") where
  "true_assn tr = True"

lemma false_assn_entails [simp]:
  "false\<^sub>A \<Longrightarrow>\<^sub>t P"
  by (simp add: entails_tassn_def false_assn_def)

lemma pure_assn_entails [simp]:
  "(\<up>b \<and>\<^sub>t P \<Longrightarrow>\<^sub>t Q) = (b \<longrightarrow> P \<Longrightarrow>\<^sub>t Q)"
  unfolding entails_tassn_def conj_assn_def pure_assn_def by auto

lemma entails_tassn_cancel_left:
  "Q \<Longrightarrow>\<^sub>t R \<Longrightarrow> P @\<^sub>t Q \<Longrightarrow>\<^sub>t P @\<^sub>t R"
  by (auto simp add: entails_tassn_def join_assn_def)

lemma entails_tassn_cancel_right:
  "P \<Longrightarrow>\<^sub>t Q \<Longrightarrow> P @\<^sub>t R \<Longrightarrow>\<^sub>t Q @\<^sub>t R"
  by (auto simp add: entails_tassn_def join_assn_def)

lemma entails_tassn_cancel_both:
  "P \<Longrightarrow>\<^sub>t Q \<Longrightarrow> R \<Longrightarrow>\<^sub>t S \<Longrightarrow> P @\<^sub>t R \<Longrightarrow>\<^sub>t Q @\<^sub>t S"
  by (auto simp add: entails_tassn_def join_assn_def)

lemma entails_tassn_conj:
  "P \<Longrightarrow>\<^sub>t Q \<Longrightarrow> P \<Longrightarrow>\<^sub>t R \<Longrightarrow> P \<Longrightarrow>\<^sub>t (Q \<and>\<^sub>t R)"
  by (auto simp add: entails_tassn_def conj_assn_def)

lemma entails_tassn_exI:
  "P \<Longrightarrow>\<^sub>t Q x \<Longrightarrow> P \<Longrightarrow>\<^sub>t (\<exists>\<^sub>t x. Q x)"
  unfolding ex_assn_def entails_tassn_def by auto

lemma conj_join_distrib [simp]:
  "(\<up>b \<and>\<^sub>t P) @\<^sub>t Q = (\<up>b \<and>\<^sub>t (P @\<^sub>t Q))"
  by (auto simp add: join_assn_def conj_assn_def pure_assn_def)

lemma conj_join_distrib2 [simp]:
  "(\<lambda>tr. b \<and> P tr) @\<^sub>t Q = (\<up>b \<and>\<^sub>t (P @\<^sub>t Q))"
  by (auto simp add: pure_assn_def conj_assn_def join_assn_def)

lemma false_join:
"Q \<Longrightarrow>\<^sub>t false\<^sub>A \<Longrightarrow> (P @\<^sub>t Q) \<Longrightarrow>\<^sub>t false\<^sub>A"
  by(auto simp add: entails_tassn_def false_assn_def join_assn_def)

lemma wait_le_zero [simp]:
  "d \<le> 0 \<Longrightarrow> Wait\<^sub>t d p rdy = emp\<^sub>t"
  apply (rule ext) subgoal for tr
    apply auto
     apply (cases rule: wait_assn.cases)
    apply (auto simp add: emp_assn_def)
    by (auto intro: wait_assn.intros)
  done

text \<open>Simpler forms of weakest precondition\<close>

text \<open>Simpler forms of weakest precondition\<close>

theorem Valid_send':
  "\<Turnstile> {\<lambda>s. Out\<^sub>t (EState s) ch (e s) @- Q s}
       Cm (ch[!]e)
      {Q}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_send)
  unfolding entails_def magic_wand_assn_def
  by (auto intro: out_assn.intros)

theorem Valid_receive':
  "\<Turnstile> {\<lambda>(a,s). \<forall>\<^sub>tv. In\<^sub>t (EState (a,s)) ch v @- Q (a,s(var := v))}
       Cm (ch[?]var)
      {Q}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_receive)
  unfolding entails_def magic_wand_assn_def all_assn_def
   by (simp add: in_assn.intros(1) in_assn.intros(2))

theorem Valid_wait':
  "\<Turnstile>
    {\<lambda>s. if e s > 0 then Wait\<^sub>t (e s) (\<lambda>_. EState s) ({}, {}) @- Q s else Q s}
      Wait e
    {Q}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_wait)
  unfolding entails_def magic_wand_assn_def
  by (auto intro: wait_assn.intros)


text \<open>Strongest postcondition forms\<close>

theorem Valid_assign_sp:
  "\<Turnstile> {\<lambda>(a,s) t. P (a,s) t}
       Assign var e
      {\<lambda>(a,s) t. \<exists>x. s var = e (a,s(var := x)) \<and> P (a,s(var := x)) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_assign)
  apply (auto simp add: entails_def)
  subgoal for a s tr
    apply (rule exI[where x="s var"])
    by auto
  done

theorem Valid_assign_sp1:
  "\<Turnstile> {\<lambda>s t. P s t}
       Assign var e
      {\<lambda>s t. \<exists>x. (snd s) var = e (fst s,(snd s)(var := x)) \<and> P (fst s,(snd s)(var := x)) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_assign)
  apply (auto simp add: entails_def)
  subgoal for a s tr
    apply (rule exI[where x="s var"])
    by auto
  done


theorem Valid_basic_sp:
  "\<Turnstile> {\<lambda>(a,s) t. P (a,s) t}
       Basic f
      {\<lambda>(a,s) t. \<exists>x. a = f x s \<and> P (x,s) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_basic)
  by (auto simp add: entails_def)


theorem Valid_basic_sp1:
  "\<Turnstile> {\<lambda>s t. P s t}
       Basic f
      {\<lambda>s t. \<exists>x. fst s = f x (snd s) \<and> P (x,snd s) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_basic)
  by (auto simp add: entails_def)
  

theorem Valid_send_sp:
  "\<Turnstile> {\<lambda>s t. P s t}
       Cm (ch[!]e)
     {\<lambda>s t. (P s @\<^sub>t Out\<^sub>t (EState s) ch (e s)) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_send')
  by (auto simp add: entails_def magic_wand_assn_def join_assn_def)

theorem Valid_receive_sp:
  "\<Turnstile> {\<lambda>(a,s) t. P (a,s) t}
       Cm (ch[?]var)
      {\<lambda>(a,s) t. \<exists>x v. (\<up>(s var = v) \<and>\<^sub>t (P(a,s(var := x)) @\<^sub>t In\<^sub>t (EState (a,s(var := x))) ch v)) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_receive)
  unfolding entails_def
  apply (auto simp add: join_assn_def)
  subgoal for a s tr v
    apply (rule exI[where x="s var"])
    apply (rule exI[where x=v])
    apply (auto simp add: conj_assn_def pure_assn_def)
    apply (rule exI[where x=tr]) by (auto intro: in_assn.intros)
  subgoal for a s tr d v
    apply (rule exI[where x="s var"])
    apply (rule exI[where x=v])
    apply (auto simp add: conj_assn_def pure_assn_def)
    apply (rule exI[where x=tr])
    apply auto apply (rule in_assn.intros) by auto
  done

theorem Valid_wait_sp:
  "\<Turnstile> {\<lambda>s t. P s t}
      Wait e
     {\<lambda>s t. (P s @\<^sub>t (if e s > 0 then Wait\<^sub>t (e s) (\<lambda>_. EState s) ({}, {}) else emp\<^sub>t)) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_wait')
  by (auto simp add: entails_def join_assn_def magic_wand_assn_def emp_assn_def)

theorem Valid_wait_sp1:
  "\<Turnstile> {\<lambda>s t. P s t}
      Wait e
     {\<lambda>s t. (P s @\<^sub>t Wait\<^sub>t (e s) (\<lambda>_. EState s) ({}, {}) ) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_wait')
  by (auto simp add: entails_def join_assn_def magic_wand_assn_def emp_assn_def)


theorem Valid_cond_sp:
  assumes "\<Turnstile> {\<lambda>s t. b s \<and> P s t} c1 {Q1}"
    and "\<Turnstile> {\<lambda>s t. \<not>b s \<and> P s t} c2 {Q2}"
  shows "\<Turnstile> {\<lambda>s t. P s t}
             IF b THEN c1 ELSE c2 FI
            {\<lambda>s t. Q1 s t \<or> Q2 s t}"
  using assms unfolding Valid_def
  by (auto elim!: condE)

theorem Valid_cond_sp2:
  assumes "\<Turnstile> {\<lambda>s t. s = st \<and> P s t} c1 {Q1}"
    and "\<Turnstile> {\<lambda>s t. s = st \<and> P s t} c2 {Q2}"
  shows "\<Turnstile> {\<lambda>s t. s = st \<and> P s t}
             IF b THEN c1 ELSE c2 FI
            {\<lambda>s t. if b st then Q1 s t else Q2 s t}"
  using assms unfolding Valid_def
  by (auto elim!: condE)

theorem Valid_if_split:
  assumes "b \<Longrightarrow> \<Turnstile> {P1} c {Q1}"
    and "\<not>b \<Longrightarrow> \<Turnstile> {P2} c {Q2}"
  shows "\<Turnstile> {\<lambda>s t. if b then P1 s t else P2 s t}
             c
            {\<lambda>s t. if b then Q1 s t else Q2 s t}"
  using assms unfolding Valid_def
  by auto

theorem Valid_assign_sp_st:
  "\<Turnstile> {\<lambda>s t. s = (a,st) \<and> P s t}
        x ::= e
      {\<lambda>s t. s = (a,st(x := e (a,st))) \<and> P (a,st) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_assign)
  by (auto simp add: entails_def)

theorem Valid_assign_sp_st':
  "\<Turnstile> {\<lambda>(a,s) t. (a,s) = (aa,st) \<and> P (a,s) t}
        x ::= e
      {\<lambda>(a,s) t. (a,s) = (aa,st(x := e (aa,st))) \<and> P (aa,st) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_assign)
  by (auto simp add: entails_def)

theorem Valid_assign_sp_bst:
  "\<Turnstile> {\<lambda>s t. s = (a,st) \<and> b s \<and> P s t}
        x ::= e
      {\<lambda>s t. s = (a,st(x := e (a,st))) \<and> b (a,st) \<and> P (a,st) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_assign)
  by (auto simp add: entails_def)

theorem Valid_assign_sp_bst':
  "\<Turnstile> {\<lambda>s t. b s \<and> s = (a,st) \<and> P s t}
        x ::= e
      {\<lambda>s t. s = (a,st(x := e (a,st))) \<and> b (a,st) \<and> P (a,st) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_assign)
  by (auto simp add: entails_def)

theorem Valid_send_sp_st:
  "\<Turnstile> {\<lambda>s t. s = (a,st) \<and> P s t}
       Cm (ch[!]e)
      {\<lambda>s t. s = (a,st) \<and> (P (a,st) @\<^sub>t Out\<^sub>t (EState (a,st)) ch (e (a,st))) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_send')
  by (auto simp add: entails_def magic_wand_assn_def join_assn_def)

theorem Valid_send_sp_bst:
  "\<Turnstile> {\<lambda>s t. s = (a,st) \<and> b s \<and> P s t}
       Cm (ch[!]e)
      {\<lambda>s t. s = (a,st) \<and> b s \<and> (P (a,st) @\<^sub>t Out\<^sub>t (EState (a,st)) ch (e (a,st))) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_send')
  by (auto simp add: entails_def magic_wand_assn_def join_assn_def)

theorem Valid_receive_sp_st:
  "\<Turnstile> {\<lambda>s t. s = (a,st) \<and> P s t}
        Cm (ch[?]var)
      {\<lambda>s t. \<exists>v. s = (a,st(var := v)) \<and> (P (a,st) @\<^sub>t In\<^sub>t (EState (a,st)) ch v) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_receive)
  unfolding entails_def
  apply (auto simp add: all_assn_def magic_wand_assn_def emp_assn_def join_assn_def)
  subgoal for tr v
    apply (rule exI[where x=v])
    apply auto apply (rule exI[where x=tr])
    by (simp add: in_assn.intros)
  subgoal for tr d v
    apply (rule exI[where x=v])
    apply auto apply (rule exI[where x=tr])
    using in_assn.intros(2) by auto
  done


theorem Valid_receive_sp_bst:
  "\<Turnstile> {\<lambda>s t. s = (a,st) \<and> b s \<and> P s t}
        Cm (ch[?]var)
      {\<lambda>s t. \<exists>v. s = (a,st(var := v)) \<and> b (a,st) \<and> (P (a,st) @\<^sub>t In\<^sub>t (EState (a,st)) ch v) t}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_receive)
  unfolding entails_def
  apply (auto simp add: all_assn_def magic_wand_assn_def emp_assn_def join_assn_def)
  subgoal for tr v
    apply (rule exI[where x=v])
    apply auto apply (rule exI[where x=tr])
    by (simp add: in_assn.intros)
  subgoal for tr d v
    apply (rule exI[where x=v])
    apply auto apply (rule exI[where x=tr])
    using in_assn.intros(2) by auto
  done


theorem Valid_wait_sp_st:
  "\<Turnstile>
    {\<lambda>s tr. s = (a,st) \<and> P s tr}
      Wait e
    {\<lambda>s tr. s = (a,st) \<and> (P (a,st) @\<^sub>t (if e (a,st) > 0 then Wait\<^sub>t (e (a,st)) (\<lambda>_. EState (a,st)) ({}, {}) else emp\<^sub>t)) tr}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_wait')
  by (auto simp add: entails_def join_assn_def magic_wand_assn_def emp_assn_def)


theorem Valid_wait_sp_bst:
  "\<Turnstile>
    {\<lambda>s tr. s = (a,st) \<and> b s \<and> P s tr}
      Wait e
    {\<lambda>s tr. s = (a,st) \<and> b s \<and> (P (a,st) @\<^sub>t (if e (a,st) > 0 then Wait\<^sub>t (e (a,st)) (\<lambda>_. EState (a,st)) ({}, {}) else emp\<^sub>t)) tr}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_wait')
  by (auto simp add: entails_def join_assn_def magic_wand_assn_def emp_assn_def)

subsection \<open>Rules for internal and external choice\<close>

text \<open>Additional assertions\<close>

inductive inrdy_assn :: "'a ext_state \<Rightarrow> cname \<Rightarrow> real \<Rightarrow> rdy_info \<Rightarrow> 'a tassn" ("Inrdy\<^sub>t") where
  "Inrdy\<^sub>t s ch v rdy [InBlock ch v]"
| "(d::real) > 0 \<Longrightarrow> Inrdy\<^sub>t s ch v rdy [WaitBlk d (\<lambda>_. EState s) rdy, InBlock ch v]"

inductive outrdy_assn :: "'a ext_state \<Rightarrow> cname \<Rightarrow> real \<Rightarrow> rdy_info \<Rightarrow> 'a tassn" ("Outrdy\<^sub>t") where
  "Outrdy\<^sub>t s ch v rdy [OutBlock ch v]"
| "(d::real) > 0 \<Longrightarrow> Outrdy\<^sub>t s ch v rdy [WaitBlk d (\<lambda>_. EState s) rdy, OutBlock ch v]"

text \<open>Simpler form of weakest precondition\<close>

theorem Valid_echoice':
  assumes "\<And>i. i<length es \<Longrightarrow>
    case es ! i of
      (ch[!]e, p2) \<Rightarrow>
        (\<exists>Q. \<Turnstile> {Q} p2 {R} \<and>
            (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s). Outrdy\<^sub>t (a,s) ch (e (a,s)) (rdy_of_echoice es) @- Q (a,s))))
    | (ch[?]var, p2) \<Rightarrow>
        (\<exists>Q. \<Turnstile> {Q} p2 {R} \<and>
            (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s). \<forall>\<^sub>tv. Inrdy\<^sub>t (a,s) ch v (rdy_of_echoice es) @- Q (a,s(var := v)))))"
  shows "\<Turnstile> {P} EChoice es {R}"
proof -
  have 1: "\<exists>Q. \<Turnstile> {Q} p {R} \<and>
           (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. Q (a,s) (tr @ [OutBlock ch (e (a,s))]))) \<and>
           (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>d::real>0. Q (a,s) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) (rdy_of_echoice es), OutBlock ch (e (a,s))])))"
    if *: "i < length es" "es ! i = (ch[!]e, p)" for i ch e p
  proof -
    from assms obtain Q where
      Q: "\<Turnstile> {Q} p {R} \<and> (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s). Outrdy\<^sub>t (a,s) ch (e (a,s)) (rdy_of_echoice es) @- Q (a,s)))"
      using * by fastforce
    show ?thesis
      apply (rule exI[where x=Q])
      using Q outrdy_assn.intros 
      apply (auto simp add: entails_def magic_wand_assn_def)
       apply (simp add: outrdy_assn.simps)
      by (simp add: outrdy_assn.intros(2))
  qed
  have 2: "\<exists>Q. \<Turnstile> {Q} p {R} \<and>
           (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>v. Q (a,s(var := v)) (tr @ [InBlock ch v]))) \<and>
           (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s) tr. \<forall>d::real>0. \<forall>v. Q (a,s(var := v)) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) (rdy_of_echoice es), InBlock ch v])))"
    if *: "i < length es" "es ! i = (ch[?]var, p)" for i ch var p
  proof -
    from assms obtain Q where
      Q: "\<Turnstile> {Q} p {R} \<and> (P \<Longrightarrow>\<^sub>A (\<lambda>(a,s). \<forall>\<^sub>tv. Inrdy\<^sub>t (a,s) ch v (rdy_of_echoice es) @- Q (a,s(var := v))))"
      using * by fastforce
    show ?thesis
      apply (rule exI[where x=Q])
      using Q inrdy_assn.intros 
      apply (auto simp add: entails_def magic_wand_assn_def all_assn_def)
      by (auto simp add: inrdy_assn.intros)
  qed
  show ?thesis
    apply (rule Valid_echoice)
    subgoal for i apply (cases "es ! i")
      subgoal for ch p apply (cases ch) apply auto
        using 1 2 by auto
      done
    done
qed

text \<open>Strongest postcondition form\<close>

theorem Valid_echoice_sp:
  assumes "\<And>i. i<length es \<Longrightarrow>
    case es ! i of
      (ch[!]e, p2) \<Rightarrow>
        \<Turnstile> {\<lambda>s tr. s = (a,st) \<and> (P s @\<^sub>t Outrdy\<^sub>t s ch (e s) (rdy_of_echoice es)) tr} p2 {Q}
    | (ch[?]var, p2) \<Rightarrow>
        \<Turnstile> {\<lambda>s tr. (\<exists>v. s = (a,st(var := v)) \<and> (P (a,st) @\<^sub>t Inrdy\<^sub>t (a,st) ch v (rdy_of_echoice es)) tr)} p2 {Q}"
  shows "\<Turnstile>
    {\<lambda>s tr. s = (a,st) \<and> P s tr}
      EChoice es
    {Q}"
  apply (rule Valid_echoice')
  subgoal for i
    apply (cases "es ! i") apply auto
    subgoal for comm p2
      apply (cases comm)
      subgoal for ch e
        apply auto
        apply (rule exI[where x="\<lambda>s tr. s = (a,st) \<and> (P s @\<^sub>t Outrdy\<^sub>t s ch (e s) (rdy_of_echoice es)) tr"])
        apply auto
        using assms apply fastforce
        by (auto simp add: entails_def join_assn_def magic_wand_assn_def)
      subgoal for ch var
        apply auto
        apply (rule exI[where x="\<lambda>s tr. (\<exists>v. s = (a,st(var := v)) \<and> (P (a,st) @\<^sub>t Inrdy\<^sub>t (a,st) ch v (rdy_of_echoice es)) tr)"])
        apply auto
        using assms apply fastforce
        by (auto simp add: entails_def magic_wand_assn_def join_assn_def all_assn_def)
      done
    done
  done

text \<open>Some special cases of EChoice\<close>

lemma InIn_lemma:
  assumes "Q ch1 var1 p1"
    and "Q ch2 var2 p2"
    and "i < length [(ch1[?]var1, p1), (ch2[?]var2, p2)]"
  shows "case [(ch1[?]var1, p1), (ch2[?]var2, p2)] ! i of
            (ch[!]e, p1) \<Rightarrow> P ch e p1
          | (ch[?]var, p1) \<Rightarrow> Q ch var p1"
proof -
  have "case comm of ch[!]e \<Rightarrow> P ch e p | ch[?]var \<Rightarrow> Q ch var p"
    if "i < Suc (Suc 0)"
       "[(ch1[?]var1, p1), (ch2[?]var2, p2)] ! i = (comm, p)" for comm p i
  proof -
    have "i = 0 \<or> i = 1"
      using that(1) by auto
    then show ?thesis
      apply (rule disjE)
      using that(2) assms by auto
  qed
  then show ?thesis
    using assms(3) by auto
qed

theorem Valid_echoice_InIn:
  assumes "\<Turnstile> {Q1} p1 {R}"
    and "\<Turnstile> {Q2} p2 {R}"
  shows "\<Turnstile>
    {\<lambda>(a,s) tr. (\<forall>v. Q1 (a,s(var1 := v)) (tr @ [InBlock ch1 v])) \<and>
            (\<forall>d::real>0. \<forall>v. Q1 (a,s(var1 := v)) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) ({}, {ch1, ch2}), InBlock ch1 v])) \<and>
            (\<forall>v. Q2 (a,s(var2 := v)) (tr @ [InBlock ch2 v])) \<and>
            (\<forall>d::real>0. \<forall>v. Q2 (a,s(var2 := v)) (tr @ [WaitBlk d (\<lambda>_. EState (a,s)) ({}, {ch1, ch2}), InBlock ch2 v]))}
      EChoice [(ch1[?]var1, p1), (ch2[?]var2, p2)]
    {R}"
  apply (rule Valid_echoice)
  apply (rule InIn_lemma)
  subgoal apply (rule exI[where x=Q1])
    by (auto simp add: assms entails_def)
  apply (rule exI[where x=Q2])
  by (auto simp add: assms entails_def)

theorem Valid_echoice_InIn':
  assumes "\<Turnstile> {Q1} p1 {R}"
    and "\<Turnstile> {Q2} p2 {R}"
  shows "\<Turnstile>
    {\<lambda>(a,s). (\<forall>\<^sub>tv. ((Inrdy\<^sub>t (a,s) ch1 v ({}, {ch1, ch2})) @- Q1 (a,s(var1 := v)))) \<and>\<^sub>t
         (\<forall>\<^sub>tv. ((Inrdy\<^sub>t (a,s) ch2 v ({}, {ch1, ch2})) @- Q2 (a,s(var2 := v))))}
      EChoice [(ch1[?]var1, p1), (ch2[?]var2, p2)]
    {R}"
  apply (rule Valid_weaken_pre)
   prefer 2 apply (rule Valid_echoice_InIn[OF assms(1-2)])
  apply (auto simp add: entails_def magic_wand_assn_def conj_assn_def all_assn_def)
  by (auto simp add: inrdy_assn.intros)

theorem Valid_echoice_InIn_sp:
  assumes "\<And>v. \<Turnstile> {\<lambda>s tr. s = (a,st(var1 := v)) \<and> (P (a,st) @\<^sub>t Inrdy\<^sub>t (a,st) ch1 v ({}, {ch1, ch2})) tr} p1 {Q1 v}"
    and "\<And>v. \<Turnstile> {\<lambda>s tr. s = (a,st(var2 := v)) \<and> (P (a,st) @\<^sub>t Inrdy\<^sub>t (a,st) ch2 v ({}, {ch1, ch2})) tr} p2 {Q2 v}"
  shows
   "\<Turnstile> {\<lambda>s tr. s = (a,st) \<and> P s tr}
        EChoice [(ch1[?]var1, p1), (ch2[?]var2, p2)]
       {\<lambda>s tr. (\<exists>v. Q1 v s tr) \<or> (\<exists>v. Q2 v s tr)}"
  apply (rule Valid_echoice_sp)
  apply (rule InIn_lemma)
  using assms apply (auto simp add: Valid_def) by blast+

theorem Valid_False:
 "\<Turnstile> {\<lambda> s t. False}
      P
     {\<lambda> s t. False}"
  unfolding Valid_def
  by auto
end

