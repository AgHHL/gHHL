# hhlprover
## usage
   1. Install Isabelle2023 from:<br>
        https://isabelle.in.tum.de/website-Isabelle2023/index.html  <br>
   2. Make AFP available to Isabelle from:<br>
	https://www.isa-afp.org/ <br>
      add the afp path into the roots of Isabelle2023 <br>
   3. Change logic session to "Ordinary_Differential_Equations" (change requires restart) <br>
   4. Open the ".thy" files in this package in Isabelle2023 <br>

## simple intrudction of theories
There are two folders of theories hhl and exthhl, the latter one is a extension by adding a new part into state to deal with more types of variables like lists
### Analysis_more.thy
  * some results about derivatives   
  * some lemmas in real functions like MVT and IVT  
  * definitions of state, ode and ode solution
      
### BigStepSimple.thy
  * Big-step semantics 
  * Assertions for single process
  * Hoare rules for discrete process
      
### BigStepContinuous.thy
  * Hoare rules for ode and ode interrupt
      
### BigStepParallel.thy
  * combination of traces
  * Assertions for parallel process
      
### Complementlemma.thy and ContinuousInv.thy
  * Some useful lemmas about differential invariants and trace assertions

## cases
  1. hhl/C.thy	   case of the cruise control system
  2. hhl/Lander2.thy	case of the Lunar lander
  3. exthhl/combinep.thy	case of the scheduler


