#import "../agregyst.typ" : tableau, dev, recap, item

#set document(title: [Management and Coordination of multiple execution thread @MOS])
#show : tableau

// CODLY
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

#codly(languages: codly-languages)
#codly(number-format: none,   )


#set text(lang: "en")


/ Goals: Understand how multithreading and multiprocess applications are build and how they work on top of the operating system.

= Process @MOS[2.1.1]
#item("Definition")[A process][
  is an instance of an executing program, including the current values of the program counter, registers, and variables. It also has an address space an thread of execution associated to it.
]

#item("Definition")[The memory of a process][
  is divided into four parts :
  - the *data* segment that stores global variable
  - the *text* segment for the code of the program
  - the *stack* which is used for static allocation (like local variable)
  - the *heap* where dynamic allocated memory lives.
]

#item("Definition")[Multiprogramming.][
  If multiple processes are present on an operating system the OS can switch back and forth from one to an other for execution. This is called multiprogramming.
]

#item("Example")[][
  Multiprogramming four programs.
  Conceptual model of four independant processes.
  Only one program is active at once.
  #align(center, image("multiprogramming_interleaving.png", width: 330pt))
]



#item("Definition")[A daemon][
  is a process that works continuously in the background. Email, Web spages, printing are examples of daemons. It is not directly used by the user.
]

#item("Remark")[The Process Table][
  is where OS keep track of important information about the processes states. It is divided in process, memory and file management. Those contains information like the User ID, the registers or a pointer to the data segment.
]

#item("Remark")[Context Switch.][
  To manage different processes the OS have to operate *context switch* to execute one process at a time (on a given cpu core). This is costly and should be done on moment where a process is waiting for IO or a web request for example.
]

#item("Property")[IPC.][
  Processes can communicate with each other using the pipe operator, direct memory mapping, signals.
]

= Thread @MOS[2.2.2]
#let thread_definition = item("Definition")[A thread][
  (also called light weight process) is a way to parallelized execution while keeping the same context and so the same address space.
]

#let three_thread_ex = item("Example")[A word processor with three thread][
  #align(center, image("word_processor_thread.png", width: 200pt))
]

#let thread_stack = item("Remark")[Thread Stack][
  is not shared and so is allocated separately for each new thread created by a process.
]

#grid(columns : (45%, 50%), column-gutter: 1em,
  stack(dir:ttb, spacing: 0.6em,
    thread_definition,
    thread_stack,
  ),
  three_thread_ex
)

#item("Implementation")[POSIX API][
  is a set of function that aims to make more portable software. It defines some function for thread management that are supported by most UNIX system.
  #align(center, image("posix_thread_api.png", width: 80%))
]

#let kernel_space_thread = item("Implementation")[Kernel space thread.][
  Threads can be implemented at the kernel level where they can achieve real parallelisation. Its the OS that manage the scheduling.
]

#let user_space_thread = item("Implementation")[User space thread][
  only do *interleaving* but can be much lighter and adaptable. Only on thread at a time can actually execute.
]

#let hybrid_implem_remark = item("Remark")[Hybrid implemen-tation][
   exist and potentially offer the best of both worlds. They are usually not used because of their complexity.
]

#let user_kernel_image = align(center, image("user_kernel_thread.png", width: 110%))

#grid(columns: (45%, 1fr), column-gutter: 1em,
stack(dir: ttb, spacing: 1em,
  hybrid_implem_remark,
  kernel_space_thread,
),
stack(dir: ttb, spacing: 0.5em,
  user_kernel_image,
  user_space_thread,
)
)

#dev[
#item("Thread")[@COR3[27.3] Multithreaded Merge Sort.][
  Divide and conquer algorithm are typically algorithm that can be multithreaded. Each recursive call can be a new thread but this is a pretty naïve approach.
]
]

= Synchronisation @MOS[2.4]
== Initial problem

#item("Problem")[Race Condition.][
  When asking for the same ressource all of the means for communicating between threads and processus can produce race condition.
]

#item("Remark")[][
  Multithreaded code execution is non deterministic and depends on the OS scheduling. So race condition error are complicated to debug because they do not appear in every run of the program.
]

#item("Example")[Counter example.][
  This example never crash but does not output always the same result. The expected behavior is for the program to return `20 000`.
```C
int cpt = 0;
void* incr(void*) {
  for (int i = 0; i < 10 000; i++) cpt ++;
}
int main() { pthread_t thread0, thread1;
  pthread_create(&thread0, NULL, incr, NULL);
  pthread_create(&thread1, NULL, incr, NULL);
  pthread_join(thread0, NULL); pthread_join(thread1, NULL);
  return cpt;
}
```
]

#item("Definition")[Critical Section][
  is where threads interacts with shared memory.
]

#item("Definition")[Mutual exclusion][
  is when not two thread are in critical section together.
]

== Algorithmic Solution

#item("Algorithm")[Peterson Algorithm][
  achieve mutual exclusion.
```C
#define N 2
int turn;
int interested[N];
void enter_region(int process) {
  int other;           // number other process
  other = 1 - process; // show that you are interested
  turn = process;      // set flag
  while (turn == process && interested[other] == true)
    processing(); // critical section
  interested[process] = false;
}

```
]

#item("Property")[][
  This algorithm does work and prevent 2 thread from race condition. However it uses busy waiting which uses CPU time continuously.
]

#item("Remark")[In pratice][
  this approach does not work. With modern hardware reodering of instruction made by the compiler and CPU can break this algorithm. Fences is the way to prevent but are much more complicated to use and hardware dependent.
]

== Hardware Solution @MOS[2.4.4]

#item("Definition")[Atomic operations][
  is any program code that indivisible in the sense that the CPU *must* execute it all in one go.
]

#item("Definition")[Test and Set lock][
  is a hardware primitive. There are hardware instruction that execute in an atomic way.
]

#item("Synchronization")[Semaphore][
  is a concept introduce by Dijstra in 1965. Two operations are available _P_ and _V_ on a semaphore _m_ initialized to 0.
  - _V(m)_ increase the value of _m_ by 1.
  - _P(m)_ blocks if _m_ equals 0 and decrease _m_ otherwise.
]

#item("Example")[][
  For mutual exclusion we usually initialize semaphores to 0 :
```C
s0, s1 = sema(0), sema(0)
```
]

#item("Remark")[Passive Waiting.][
  _P_ can block the current thread. However this lock is passive, so the OS can schedule an other thread during that wait : no CPU is wasted.
]

#item("Application")[][
  Semaphore function can be created using `test and lock` primitive an simple integer.
]

#item("Definition")[Mutex][
  is a special type of binary semaphore. They can only be locked or unlocked.
]

#dev[
  #item("Definition")[A Thread safe structure][
    is a structure when any function of the structure are using mutual exclusion. It is achieved using mutex, however this isn't always enough.
  ]
]

== DeadLocks

#item("Problem")[DeadLock.][
  If two thread are locking the same mutexes in different order, they could be waiting forever in some cases. It is named a *DeadLock*.
]


#item("Example")[Example of a Deadlock][

#grid(columns: (50%, 50%),
```C
P(s0)
P(s1) // possibly blocked
...   // critical section
```,
```C
P(s1)
P(s0) // possibly blocked
...  // critical section
```
)
]

#item("Theorem")[][
  If all threads lock always in the same order the semaphores then deadlocks are impossible.
]

== Synchronization pattern

#dev[
#item("Exemple")[@SEMA Philosophes Diner.][
   Some philosophes are around a table. They wish to et together. However the cutlery is shared between them. The left knife of a philosophers with the right one of his neighbour. How can they manage to all eat as fast as possible with so few knives ?
]
]

#item("Definition")[@SEMA Meeting between Threads.][
  Sometimes we want to make sure that two threads pass some point together in the code.
#grid(columns : (1fr, 1fr),
```C
V(s0)
P(s1) // has to wait V(s1)
```,
```C
V(s1)
P(s0) // has to wait V(s0)
```
)
]

#item("Remark")[][
  Using mutex with the POSIX API, we can wait for a thread to finish by using the `pthread_join` function. Usually one thread is in charged of terminating all of the threads, this main thread is the one doing the `pthread_join` call.
]

#item("Definition")[@SEMA Producter Consumer.][
  We suppose that all semaphores are initialized to 0.
#grid(columns : (1fr, 1fr),
[
#align(center)[Producer]
```C
event = waitForEvent()
P(mutex)
  buffer.add(event)
V(items) // nb element buffer
V(mutex)
```
],
[
#align(center)[Consumer]
```C
P(items)
P(mutex)
  event = buffer.get()
V(mutex)
event.process()
```
],
)
]

#item("Remark")[Equality and Fairness.][
  Here we only try to avoid deadlock however other criteria can be interesting. Even if no thread ever deadlock, does every thread has it's equal time of CPU to do what is has to do ?
]


#recap()

==== Au programme

- Prepa :
  - Notions de processus
  - Notions de fils d'éxécution
  - Les concepts sont illustrés sur des schémas de synchronisation classiques : rendez-vous, producteur-consommateur. Les étudiants sont également sensibilisés au non-déterminisme et aux problèmes d’interblocage et d’équité d’accès, illustrables sur le problème classique du dîner des philosophes.
- Complémentaire : Concurrence : modèles de cohérence (forte, faible, PRAM et au relâchement) et d’équité. Construction des mutex et sémaphores à partir des instructions atomiques test and set. Schéma lecteurs rédacteurs.

#bibliography(read("bib.yaml", encoding: none))

#align(center + bottom)[Paul Adam]
