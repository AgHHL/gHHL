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
There are
### Analysis_more.thy
  * some results about derivatives   
  * some lemmas in real functions like MVT and IVT  
  * definitions of state, ode and ode solution
      
### BigStepSequential.thy
  * Big-step semantics 
  * Assertions for single process
  * Hoare rules for discrete process
      
### BigStepContinuous.thy
  * Hoare rules for ode and ode interrupt
      
### BigStepParallel.thy
  * combination of traces
  * Assertions for parallel process
  * Hoare rules for parallel without continuous assertions
      
### BigStepContParallel.thy
  * combination of traces
  * Hoare rules for parallel between continuous assertions and discrete assertions

### BigStepInterryptParallel.thy
  * combination of traces
  * Hoare rules for parallel between interrupt assertions

### BigstepEx.thy and BigStepContinuousEx.thy and InterruptEx.thy
  * some simple examples

