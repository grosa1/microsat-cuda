
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <string>

 #define DB_MAX_MEM 412000;
//#define DB_MAX_MEM 100000;
#define CLAUSE_LEARN_MAX_MEM 100000;
// #define INITIAL_MAX_LEMMAS 100; //initial max learnt clauses
#define INITIAL_MAX_LEMMAS 2000; //initial max learnt clauses

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char* file, int line, bool abort = true)
{
	if (code != cudaSuccess)
	{
		fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
		if (abort) exit(code);
	}
}

struct solver { // The variables in the struct are described in the allocate procedure
	int* DB, nVars, nClauses, mem_used, mem_fixed, mem_max, maxLemmas, nLemmas, * buffer, nConflicts, * model,
		* reason, * falseStack, * _false, * first, * forced, * processed, * assigned, * next, * prev, head, res, fast, slow,
		result, file_id;
};

typedef struct {
	int files_count;
	double parse_time;
	double init_time;
	double solve_time;
	double tot_time;
} Metrics;

enum { END = -9, UNSAT = 0, SAT = 1, MARK = 2, IMPLIED = 6 };

__device__
int* getMemory(struct solver* S, int mem_size) {                  // Allocate memory of size mem_size
	if (S->mem_used + mem_size > S->mem_max) {                       // In case the code is used within a code base
		printf("c out of memory\n");
		return 0;
	}
	int* store = (S->DB + S->mem_used);                              // Compute a pointer to the new memory location
	S->mem_used += mem_size;                                         // Update the size of the used memory
	return store;
}                                                  // Return the pointer

__device__
void unassign(struct solver* S, int lit) { S->_false[lit] = 0; }   // Unassign the literal

__device__
void restart(struct solver* S) {                                  // Perform a restart (i.e., unassign all variables)
	while (S->assigned > S->forced) unassign(S, *(--S->assigned));  // Remove all unforced false lits from falseStack
	S->processed = S->forced;
}                                      // Reset the processed pointer

__device__
void assign(struct solver* S, int* reason, int forced) {          // Make the first literal of the reason true
	int lit = reason[0];                                             // Let lit be the first ltieral in the reason
	S->_false[-lit] = forced ? IMPLIED : 1;                           // Mark lit as true and IMPLIED if forced
	*(S->assigned++) = -lit;                                         // Push it on the assignment stack
	S->reason[abs(lit)] = 1 + (int)((reason)-S->DB);               // Set the reason clause of lit
	S->model[abs(lit)] = (lit > 0);
}                              // Mark the literal as true in the model

__device__
void addWatch(struct solver* S, int lit, int mem) {               // Add a watch pointer to a cfor entry function '_Z5solveP6solver' containing lit
	S->DB[mem] = S->first[lit]; S->first[lit] = mem;
}               // By updating the database afor entry function '_Z5solveP6solver'e pointers

__device__
int* addClause(struct solver* S, int* buffer, int size, int irr) {    // Adds a clause stored in *in of size size
	int i, used = S->mem_used;                                       // Store a pointer to the beginning of the clause
	int* clause = getMemory(S, size + 3) + 2;                       // Allocate memory for the clause in the database
	if (size > 1) {
		addWatch(S, buffer[0], used);                    // If the clause is not unit, then add
		addWatch(S, buffer[1], used + 1);
	}                  // Two watch pointers to the datastructure
	for (i = 0; i < size; i++) clause[i] = buffer[i]; clause[i] = 0;     // Copy the clause from the buffer to the database
	if (irr) S->mem_fixed = S->mem_used; else S->nLemmas++;          // Update the statistics
	return clause;
}                                                 // Return the pointer to the clause is the database

__device__
void reduceDB(struct solver* S, int k) {                     // Removes "less useful" lemmas from DB
	//printf("Start reduceDB function\n");
	while (S->nLemmas > S->maxLemmas) S->maxLemmas += 300;      // Allow more lemmas in the future
	S->nLemmas = 0;                                             // Reset the number of lemmas

	int i; for (i = -S->nVars; i <= S->nVars; i++) {            // Loop over the variables
		if (i == 0) continue; int* watch = &S->first[i];          // Get the pointer to the first watched clause
		while (*watch != END)                                     // As long as there are watched clauses
			if (*watch < S->mem_fixed) watch = (S->DB + *watch);    // Remove the watch if it points to a lemma
			else                      *watch = S->DB[*watch];
	}  // Otherwise (meaning an input clause) go to next watch

	int old_used = S->mem_used; S->mem_used = S->mem_fixed;     // Virtually remove all lemmas
	for (i = S->mem_fixed + 2; i < old_used; i += 3) {          // While the old memory contains lemmas
		int count = 0, head = i;                                  // Get the lemma to which the head is pointing
		while (S->DB[i]) {
			int lit = S->DB[i++];                  // Count the number of literals
			if ((lit > 0) == S->model[abs(lit)]) count++;
		}        // That are satisfied by the current model
		if (count < k) addClause(S, S->DB + head, i - head, 0);
	}
}  // If the latter is smaller than k, add it back

__device__
void bump(struct solver* S, int lit) {                       // Move the variable to the front of the decision list
	//printf("Start bump function\n");
	if (S->_false[lit] != IMPLIED) {
		S->_false[lit] = MARK;       // MARK the literal as involved if not a top-level unit
		int var = abs(lit); if (var != S->head) {                // In case var is not already the head of the list
			S->prev[S->next[var]] = S->prev[var];                   // Update the prev link, and
			S->next[S->prev[var]] = S->next[var];                   // Update the next link, and
			S->next[S->head] = var;                                 // Add a next link to the head, and
			S->prev[var] = S->head; S->head = var;
		}
	}
}            // Make var the new head

__device__
int implied(struct solver* S, int lit) {                  // Check if lit(eral) is implied by MARK literals
//	printf("Start implied function\n");
	if (S->_false[lit] > MARK) return (S->_false[lit] & MARK); // If checked before return old result
	if (!S->reason[abs(lit)]) return 0;                     // In case lit is a decision, it is not implied
	int* p = (S->DB + S->reason[abs(lit)] - 1);             // Get the reason of lit(eral)
	while (*(++p))                                           // While there are literals in the reason
		if ((S->_false[*p] ^ MARK) && !implied(S, *p)) {       // Recursively check if non-MARK literals are implied
			S->_false[lit] = IMPLIED - 1; return 0;
		}             // Mark and return not implied (denoted by IMPLIED - 1)
	S->_false[lit] = IMPLIED; return 1;
}                     // Mark and return that the literal is implied

__device__
int* analyze(struct solver* S, int* clause) {         // Compute a resolvent from falsified clause
//	printf("Start analyze\n");
	S->res++; S->nConflicts++;                           // Bump restarts and update the statistic
	while (*clause) bump(S, *(clause++));               // MARK all literals in the falsified clause
	while (S->reason[abs(*(--S->assigned))]) {          // Loop on variables on falseStack until the last decision
		if (S->_false[*S->assigned] == MARK) {              // If the tail of the stack is MARK
			int* check = S->assigned;                        // Pointer to check if first-UIP is reached
			while (S->_false[*(--check)] != MARK)             // Check for a MARK literal before decision
				if (!S->reason[abs(*check)]) goto build;       // Otherwise it is the first-UIP so break
			clause = S->DB + S->reason[abs(*S->assigned)];  // Get the reason and ignore first literal
			while (*clause) bump(S, *(clause++));
		}         // MARK all literals in reason
		unassign(S, *S->assigned);
	}                      // Unassign the tail of the stack

build:; int size = 0, lbd = 0, flag = 0;             // Build conflict clause; Empty the clause buffer
	int* p = S->processed = S->assigned;                 // Loop from tail to front
	while (p >= S->forced) {                             // Only literals on the stack can be MARKed
		if ((S->_false[*p] == MARK) && !implied(S, *p)) {  // If MARKed and not implied
			S->buffer[size++] = *p; flag = 1;
		}              // Add literal to conflict clause buffer
		if (!S->reason[abs(*p)]) {
			lbd += flag; flag = 0; // Increase LBD for a decision with a true flag
			if (size == 1) S->processed = p;
		}               // And update the processed pointer
		S->_false[*(p--)] = 1;
	}                            // Reset the MARK flag for all variables on the stack

	S->fast -= S->fast >> 5; S->fast += lbd << 15;      // Update the fast moving average
	S->slow -= S->slow >> 15; S->slow += lbd << 5;      // Update the slow moving average

	while (S->assigned > S->processed)                   // Loop over all unprocessed literals
		unassign(S, *(S->assigned--));                    // Unassign all lits between tail & head
	unassign(S, *S->assigned);                          // Assigned now equal to processed
	S->buffer[size] = 0;                                 // Terminate the buffer (and potentially print clause)
	return addClause(S, S->buffer, size, 0);
}          // Add new conflict clause to redundant DB

__device__
int propagate(struct solver* S) {                  // Performs unit propagation
	int forced = S->reason[abs(*S->processed)];      // Initialize forced flag
	while (S->processed < S->assigned) {              // While unprocessed false literals
		int lit = *(S->processed++);                    // Get first unprocessed literal
		int* watch = &S->first[lit];                    // Obtain the first watch pointer
		while (*watch != END) {                         // While there are watched clauses (watched by lit)
			int i, unit = 1;                              // Let's assume that the clause is unit
			int* clause = (S->DB + *watch + 1);	    // Get the clause from DB
			if (clause[-2] == 0) clause++;              // Set the pointer to the first literal in the clause
			if (clause[0] == lit) clause[0] = clause[1]; // Ensure that the other watched literal is in front
			for (i = 2; unit && clause[i]; i++)           // Scan the non-watched literals
				if (!S->_false[clause[i]]) {                 // When clause[i] is not false, it is either true or unset
					clause[1] = clause[i]; clause[i] = lit;   // Swap literals
					int store = *watch; unit = 0;             // Store the old watch
					*watch = S->DB[*watch];                   // Remove the watch from the list of lit
					//printf("add watch\n");
					addWatch(S, clause[1], store);
				}         // Add the watch to the list of clause[1]
			if (unit) {                                   // If the clause is indeed unit

				//printf("unit\n");
				clause[1] = lit; watch = (S->DB + *watch);  // Place lit at clause[1] and update next watch
				if (S->_false[-clause[0]]) continue;        // If the other watched literal is satisfied continue
				if (!S->_false[clause[0]]) {                // If the other watched literal is falsified,
					assign(S, clause, forced);
				}             // A unit clause is found, and the reason is set
				else {
					if (forced) {		// Found a root level conflict -> UNSAT
						//S->result = 0;
						return UNSAT;
					}
					int* lemma = analyze(S, clause);	    // Analyze the conflict return a conflict clause
					if (!lemma[1]) forced = 1;                // In case a unit clause is found, set forced flag
					assign(S, lemma, forced); break;
				}
			}
		}
	} // Assign the conflict clause as a unit

	if (forced) S->forced = S->processed;	            // Set S->forced if applicable
	//S->result = 1;
	return SAT;
}	                                    // Finally, no conflict was found

__global__
void solve(struct solver** multi_s) {    // Determine satisfiability
	struct solver* S = multi_s[threadIdx.x];

	int decision = S->head; S->res = 0;                               // Initialize the solver
	for (;;) {                                                        // Main solve loop
		int old_nLemmas = S->nLemmas;                                   // Store nLemmas to see whether propagate adds lemmas
		int res = propagate(S);
		if (res == UNSAT) {
			printf("file_%d=UNSAT,vars=%i,clauses=%i,mem=%i,conflicts=%i,lemmas=%i\n", S->file_id,S->nVars,S->nClauses,S->mem_used,S->nConflicts,S->maxLemmas);
			multi_s[threadIdx.x]->result = UNSAT;
			//printf("result -->", S->result);
			return;
		}                                                               // Propagation returns UNSAT for a root level conflict

		if (S->nLemmas > old_nLemmas) {                                 // If the last decision caused a conflict
			decision = S->head;                                           // Reset the decision heuristic to head
			if (S->fast > (S->slow / 100) * 125) {                        // If fast average is substantially larger than slow average
	  //        printf("c restarting after %i conflicts (%i %i) %i\n", S->res, S->fast, S->slow, S->nLemmas > S->maxLemmas);
				S->res = 0; S->fast = (S->slow / 100) * 125; restart(S);   // Restart and update the averages
				if (S->nLemmas > S->maxLemmas) reduceDB(S, 6);
			}
		}         // Reduce the DB when it contains too many lemmas

		while (S->_false[decision] || S->_false[-decision]) {             // As long as the temporay decision is assigned
			decision = S->prev[decision];
		}
		//printf("decision: %d \n", decision);                               // Replace it with the next variable in the decision list
		if (decision == 0) {
			printf("file_%d=SAT,vars=%i,clauses=%i,mem=%i,conflicts=%i,lemmas=%i\n", S->file_id,S->nVars,S->nClauses,S->mem_used,S->nConflicts,S->maxLemmas);
			multi_s[threadIdx.x]->result = SAT;
			//printf("result -->", S->result );
			return;                                  // If the end of the list is reached, then a solution is found
		}
		decision = S->model[decision] ? decision : -decision;           // Otherwise, assign the decision variable based on the model
		S->_false[-decision] = 1;                                        // Assign the decision literal to true (change to IMPLIED-1?)
		*(S->assigned++) = -decision;                                   // And push it on the assigned stack
		decision = abs(decision); S->reason[decision] = 0;
	}
}          // Decisions have no reason clauses

__global__
void init(struct solver* S, int* dev_elements, int nElements, int nVars, int nClauses, int* db, int*file_id) {                            // Parse the formula and initialize
	int verb = 0;
	if (verb)("\n init \n");
	S->file_id = *file_id;
	S->nVars=nVars;
	if (verb)printf("\n S->nVars -> %d\n", S->nVars);
	S->nClauses= nClauses;
	if (verb)printf("\n S->nClauses -> %d\n", S->nClauses);

	//S->mem_max = 100000;            // Set the initial maximum memory
	S->mem_max = DB_MAX_MEM;            // Set the initial maximum memory
	if (verb)printf("\n S->mem_max -> %d\n", S->mem_max);
	S->mem_used = 0;                  // The number of integers allocated in the DB
	if (verb)printf("\n S->mem_used -> %d\n", S->mem_used);
	S->nLemmas = 0;                  // The number of learned clauses -- redundant means learned
	if (verb)printf("\n S->nLemmas -> %d\n", S->nLemmas);
	S->nConflicts = 0;                  // Under of conflicts which is used to updates scores
	if (verb)printf("\n S->nConflicts -> %d\n", S->nConflicts);
	S->maxLemmas = INITIAL_MAX_LEMMAS;               // Initial maximum number of learnt clauses
	if (verb)printf("\n S->maxLemmas -> %d\n", S->maxLemmas);
	//S->fast = S->slow = 1 << 24;            // Initialize the fast and slow moving averages
	S->fast = S->slow = CLAUSE_LEARN_MAX_MEM;            // Initialize the fast and slow moving averages
	if (verb)printf("\n S->fast -> %d\n", S->fast);
	if (verb)printf("\n S->slow -> %d\n", S->slow);
	S->result = -1;
	if (verb)printf("\n S->result -> %d\n", S->result);

	S->DB = db;
	if (verb)printf("\n S->DB -> %d \n", S->DB);

	S->model = getMemory(S, S->nVars + 1); // Full assignment of the (Boolean) variables (initially set to false)
	if (verb)printf("\n S->model -> %d \n", S->model);

	S->next = getMemory(S, S->nVars + 1); // Next variable in the heuristic order
	if (verb)printf("\n S->next -> %d \n", S->next);

	S->prev = getMemory(S, S->nVars + 1); // Previous variable in the heuristic order
	if (verb)printf("\n S->prev -> %d \n", S->prev);

	S->buffer = getMemory(S, S->nVars); // A buffer to store a temporary clause
	if (verb)printf("\n S->buffer -> %d \n", S->buffer);

	S->reason = getMemory(S, S->nVars + 1); // Array of clauses
	if (verb)printf("\n S->reason -> %d \n", S->reason);

	S->falseStack = getMemory(S, S->nVars + 1); // Stack of falsified literals -- this pointer is never changed
	if (verb)printf("\n S->falseStack -> %d \n", S->falseStack);

	S->forced = S->falseStack;      // Points inside *falseStack at first decision (unforced literal)
	if (verb)printf("\n S->forced -> %d \n", S->forced);
	S->processed = S->falseStack;      // Points inside *falseStack at first unprocessed literal
	if (verb)printf("\n S->processed -> %d \n", S->processed);
	S->assigned = S->falseStack;      // Points inside *falseStack at last unprocessed literal
	if (verb)printf("\n S->assigned -> %d \n", S->assigned);

	S->_false = getMemory(S, 2 * S->nVars + 1);
	S->_false += S->nVars; // Labels for variables, non-zero means false
	if (verb)printf("\n S->_false -> %d \n", S->_false);

	S->first = getMemory(S, 2 * S->nVars + 1);
	S->first += S->nVars; // Offset of the first watched clause
	if (verb)printf("\n S->first -> %d \n", S->first);

	S->DB[S->mem_used++] = 0;            // Make sure there is a 0 before the clauses are loaded.
	if (verb)printf("\n S->DB[S->mem_used] -> %d \n", S->DB[S->mem_used-1]);

	if (verb)printf("\n elements \n");
	int i; for (i = 1; i <= S->nVars; i++) {							// Initialize the main datastructes:
		S->prev[i] = i - 1;
		if (verb)printf("\n S->prev[i] -> %d \n", S->prev[i]);

		S->next[i - 1] = i;
		if (verb)printf("\n S->next[i-1] -> %d \n", S->next[i - 1]);

		S->model[i] = S->_false[-i] = S->_false[i] = 0;
		if (verb)printf("\n S->model[i] -> %d \n", S->model[i]);
		if (verb)printf("\n S->_false[i] -> %d \n", S->_false[i]);
		if (verb)printf("\n S->_false[-i] -> %d \n", S->_false[-i]);

		S->first[i] = S->first[-i] = END;						// and first (watch pointers).
		if (verb)printf("\n S->first[i] -> %d \n", S->first[i]);
		if (verb)printf("\n S->first[i] -> %d \n", S->first[-i]);
		S->head = S->nVars;												// Initialize the head of the double-linked list
		if (verb)printf("\n S->head -> %d \n", S->head);
	}


	int nZeros = S->nClauses, size = 0;                      // Initialize the number of clauses to read
	if (verb)printf("\n nZeros -> %d \n", nZeros);
	for (int i = 0; i < nElements;i++) {                                     // While there are elements
		int lit = 0;
		lit= dev_elements[i];
		if (verb)printf("\n lit -> %d \n", lit);

		if (!lit) {                                            // If reaching the end of the clause
			if (verb)printf("\n addClause \n");
			int* clause = addClause(S, S->buffer, size, 1);     // Then add the clause to data_base
			if (verb)printf("\n clause -> %d \n", clause);

			if (verb)printf("\n size -> %d \n", size);
			if (verb)printf("\n S->_false[clause[0]] -> %d \n", S->_false[clause[0]]);
			if (!size || ((size == 1) && S->_false[clause[0]])) {  // Check for empty clause or conflicting unit

				printf("\n + UNSAT + \n");
				S->result = 1;
				return;
			}                                     // If either is found return UNSAT
			if ((size == 1) && !S->_false[-clause[0]]) {          // Check for a new unit
				if (verb)printf("\n assign \n");
				assign(S, clause, 1);
			}                           // Directly assign new units (forced = 1)
			size = 0; --nZeros;
		}
		else S->buffer[size++] = lit;
	}
	//printf("\n INITIALIZED \n");
}                                            // Return that no conflict was observed

__host__
static void read_until_new_line(FILE* input) {
	int ch;
	while ((ch = getc(input)) != '\n')
		if (ch == EOF) { printf("parse error: unexpected EOF"); exit(1); }
}

 int main(int argc, char** argv) {
	//char* directory = "C://microsat//sat";
	char* directory = argv[1];
	int num_file =0;
	int nVars = 0;
	int nClauses = 0;
	Metrics exec_metrics = {0, 0, 0, 0, 0};

	int db_max_mem =DB_MAX_MEM;
	int clause_learn_max_mem = CLAUSE_LEARN_MAX_MEM;
	int initial_max_mem =  INITIAL_MAX_LEMMAS;
    printf("DB_MAX_MEM: %d\n", db_max_mem);
    printf("CLAUSE_LEARN_MAX_MEM: %d\n", clause_learn_max_mem);
    printf("INITIAL_MAX_LEMMAS: %d\n", initial_max_mem);
    
	clock_t start, end;
	printf(" Start\n");
	start = clock();
    
	DIR* dirp;
	struct dirent* entry;
	dirp = opendir(directory);
	while ((entry = readdir(dirp)) != NULL) {
		if (entry->d_type == DT_REG) { /* If the entry is a regular file */
			num_file++;
		}
	}
	closedir(dirp);
	exec_metrics.files_count = num_file;
	//printf(" num file -> %d\n",num_file);

	solver** h_multi_struct;
	h_multi_struct = (solver**)malloc(num_file * sizeof(solver*));
	solver** d_multi_struct;
	gpuErrchk(cudaMalloc((void**)&d_multi_struct, num_file * sizeof(solver*)));


	if (NULL == (dirp = opendir(directory)))
	{
		printf("Error : Failed to open input directory \n");
		return 1;
	}

	clock_t start_parse = clock();

	int count = 0;
	while ((entry = readdir(dirp)))
	{
		if (!strcmp(entry->d_name, "."))
			continue;
		if (!strcmp(entry->d_name, ".."))
			continue;

		char path[100] = ""; //TODO: magic number
		strcpy(path, directory);
		strcat(path, "//");
		strcat(path, entry->d_name);
		printf("file_%d=%s\n", count, entry->d_name);

		FILE* input = fopen(path, "r");
		if (input == NULL)
		{
			printf("Error : Failed to open entry file \n");
			fclose(input);
			return 1;
		}

		struct solver* dev_s;
		gpuErrchk(cudaMalloc((void**)&dev_s, sizeof(solver)));

		int* db;
		//int mem = 100000; //TODO: allocazione dinamica della memoria
		int mem = DB_MAX_MEM; //TODO: allocazione dinamica della memoria
		gpuErrchk(cudaMalloc((void**)&db, sizeof(int) * mem));

		struct stat st;
		stat(path, &st);
		int size = st.st_size;
		//printf("\n size -> %d\n", size);

		int* buffer = 0;
		buffer = (int*)malloc(size * sizeof(int));

		/********* FILE PARSER **************/
		int tmp;
		while ((tmp = getc(input)) == 'c') read_until_new_line(input);
		ungetc(tmp, input);
		do {
			tmp = fscanf(input, " p cnf %i %i \n", &nVars, &nClauses);
			if (tmp > 0 && tmp != EOF) break; tmp = fscanf(input, "%*s\n");
		} while (tmp != 2 && tmp != EOF);

		int nElements = 0;
		do {
			int ch = getc(input);
			if(ch == '\%') break; //we have % as EOF in some dimacs files
			if ( ch == ' ' || ch == '\n') continue;
			if (ch == 'c') { read_until_new_line(input); continue; }
			ungetc(ch, input);
			int lit = 0;
			tmp = fscanf(input, " %i ", &lit);
			buffer[nElements] = lit;
			//printf("%d ", lit);
			nElements++;
		} while (tmp != EOF);

		nElements--; // TO CHECK
		int* elements = 0;
		elements = (int*)malloc(nElements * sizeof(int));
		for (int i = 0; i < nElements; i++) {
			elements[i] = buffer[i];
		}
		fclose(input);
		/********* FILE PARSER **************/

		int* dev_file_id;
		cudaMalloc((void**)&dev_file_id, sizeof(int));
		cudaMemcpy(dev_file_id, &count, sizeof(int), cudaMemcpyHostToDevice);

		int* dev_elements;
		cudaMalloc((void**)&dev_elements, nElements * sizeof(int));
		cudaMemcpy(dev_elements, elements, nElements * sizeof(int), cudaMemcpyHostToDevice);

		free(buffer);
		free(elements);

		cudaDeviceSetLimit(cudaLimitMallocHeapSize, 128 * 1024 * 1024);

		//printf("\n INIT \n");
		cudaEvent_t d_start_init, d_stop_init;
		cudaEventCreate(&d_start_init);
		cudaEventCreate(&d_stop_init);

		cudaEventRecord(d_start_init, 0);
		init << <1, 1 >> > (dev_s,dev_elements,nElements,nVars,nClauses,db,dev_file_id);
		cudaEventRecord(d_stop_init, 0);
		cudaEventSynchronize(d_stop_init);

		float elapsedTime;
		cudaEventElapsedTime(&elapsedTime, d_start_init, d_stop_init); // that's our time!
		exec_metrics.init_time += elapsedTime;
		// Clean up:
		cudaEventDestroy(d_start_init);
		cudaEventDestroy(d_stop_init);

		//printf("parsing_file -> %s\n", entry->d_name);
		//printf("device_time -> %f s\n", elapsedTime / 1000000);
		//exec_metrics.init_time += elapsedTime / 1000000;

		cudaDeviceSynchronize();

		//temp
		//printf("\n dev_s -> %p\n",dev_s);
		h_multi_struct[count] = dev_s;
		count++;
	}
/*********** end init and parse ***********/
exec_metrics.parse_time = (clock() - start_parse);


	cudaMemcpy(d_multi_struct, h_multi_struct, num_file * sizeof(solver*), cudaMemcpyHostToDevice);
	//temp end

	printf("\n SOLVE \n");
	cudaEvent_t d_start, d_stop;
	cudaEventCreate(&d_start);
	cudaEventCreate(&d_stop);

	cudaEventRecord(d_start, 0);
	solve<< <1, num_file >> > (d_multi_struct);
	cudaEventRecord(d_stop, 0);
	cudaEventSynchronize(d_stop);

	float elapsedTime;
	cudaEventElapsedTime(&elapsedTime, d_start, d_stop); // that's our time!
	// Clean up:
	cudaEventDestroy(d_start);
	cudaEventDestroy(d_stop);

	//printf("\n total solve time -> %f s\n", elapsedTime / 1000000);
	exec_metrics.solve_time = elapsedTime;
	cudaDeviceSynchronize();

	cudaDeviceReset();

	end = clock();
	//printf("\n total time: %f s\n", (float)(end - start) / 1000000);
	exec_metrics.tot_time = (float)(end - start);
	printf("\n+++ metrics (ms)+++\nfiles count: %d\nparse time: %f\ncuda init time: %f\ncuda solve time: %f\ntot time: %f\n\n", exec_metrics.files_count, exec_metrics.parse_time/CLOCKS_PER_SEC, exec_metrics.init_time/1000, exec_metrics.solve_time/1000, exec_metrics.tot_time/CLOCKS_PER_SEC);
	//printf ("c statistics of %s: mem: %i conflicts: %i max_lemmas: %i\n", argv[1], S.mem_used, S.nConflicts, S.maxLemmas);
	//printf("\n END \n");
	return 0;
}
