# hhlprover
## Usage
   1. Install Isabelle2023 from:<br>
        https://isabelle.in.tum.de/website-Isabelle2023/index.html  <br>
   2. Make AFP available to Isabelle from:<br>
	https://www.isa-afp.org/ <br>
      add the afp path into the roots of Isabelle2023 <br>
   3. Change logic session to "Ordinary_Differential_Equations" (change requires restart) <br>
   4. Open the ".thy" files in this package in Isabelle2023 <br>

## Simple intrudction of theories
There are two folders of theories hhl and exthhl, the latter is a extension of the former by adding a new part into state to deal with more types of variables like Bool, List, Set or other freely defined variables 
### Analysis_more.thy
  * some results about derivatives   
  * some lemmas in real functions like MVT and IVT  
  * definitions of state, ode and ode solution
      
### BigStepSimple.thy
  * Big-step semantics 
  * Assertions for single process
  * Inference rules for discrete process
      
### BigStepContinuous.thy
  * Inference rules for ode and ode interrupt
      
### BigStepParallel.thy
  * combination of traces
  * Assertions for parallel process
  * Inference rules for parallel process
      
### Complementlemma.thy and ContinuousInv.thy
  * Some useful lemmas about differential invariants and trace synchronization

## Cases
  1. case of the cruise control system <br>
       hhl/C.thy
  2. case of the Lunar lander <br>
       hhl/Lander2.thy
  3. case of the scheduler <br>
       exthhl/combinep.thy


