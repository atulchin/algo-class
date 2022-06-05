#include <iostream>
#include <vector>
#include <map>
#include <queue>
#include <utility>

using namespace std;

//Monk = pair: monk id, queue of doctor ids
typedef pair<int, queue<int>> Monk;

//need this in order to make a priority queue of monks (bizarre syntax, but that's how it works):
struct CustomCompare {
    bool operator()(const Monk& lhs, const Monk& rhs) {
        //greater-than so that lower numbers count as higher priority
        return lhs.first > rhs.first;
    }
};

//monkQ == priority queue of monks, smallest monk id first
typedef priority_queue<Monk, vector<Monk>, CustomCompare> monkQ;

//Doctor = the doctor's schedule = map of arrival time => priority queue of monks
typedef map<const int, monkQ> Doctor;

//adds a monk to a doctor's schedule
//doc passed by reference (will be modified), monk passed by const reference (not modified) 
//  (objects should always be passed by reference, otherwise constructor will be called to make a copy)
void add_monk(Doctor& doc, int t, const Monk& monk) {
    //accessing a nonexistent key in a map should (according to c++ docs) insert an 
    //     empty default value for that key (in this case a monk queue)
    //q is declared as a reference to a monk queue, just to be sure we're working with the 
    //     actual map value and not a copy (not sure if this is necessary but it works fine)
    monkQ& q = doc[t];
    q.push(monk);
}

//pull the first monk from the specified doc's schedule and add them to the next doc in their queue
void process_first(Doctor* docarray, int docid, int current_time) {
    cout << "processing doc# " << docid << " time " << current_time << endl;
    //**doc must be declared as a reference, otherwise it will make a copy and original 
    //   array element is not modified** (I tested this)
    Doctor& doc = docarray[docid];
    //make sure this doc's schedule is not empty
    if (doc.empty()) {
        cout << "doc# " << docid << " is empty" << endl;
        return;
        }
    //c++ maps are sorted by key, so this returns the earliest time slot
    auto it = doc.begin();
    int arrival_time = it->first;
    cout << "earliest arrival time is " << arrival_time << endl;
    //make sure we don't process events scheduled for the future
    if (arrival_time <= current_time) {
        //declaring monk queue as a reference just to be sure we're not making a copy
        monkQ& q = it->second;
        //top() returns a const reference, not a copy of the object
        // **if we destroy the underlying object, the reference will segfault**
        const Monk& monkref = q.top();
        //have to make a copy of the monk before popping it from the queue, because pop() calls destructor
        //  (could avoid this by using a queue of pointers intead, or a queue of integer keys to a look-up map)
        //                                                                ^^^^^^^^^^^^^^^^^^^^^^^^^
        //                                                     I think I would prefer doing it this way
        //                                                     but I'm curious to get the current solution working
        Monk monkcopy(monkref.first, monkref.second);
        //now it's ok to pop()
        q.pop();
        //monk's doctor queue must be declared as a reference,
        //   otherwise it will make a copy and original is unmodified by pop() below (I tested this)
        queue<int> &docq = monkcopy.second;
        //if docs remain in the doc queue, add this monk to the next doctor's schedule
        if (!docq.empty()) {
            int next_doc = docq.front();
            docq.pop(); //remove current doctor from queue
            cout << "adding monk# " << monkcopy.first << " to doc# " << next_doc << " for time " << current_time + 1 << endl;
            add_monk(docarray[next_doc], current_time+1, monkcopy);
        }

        //if there are no more monks remaining in the time slot, we should erase the time slot from the map
        //  (it's safe to do this here because monks only get added to future time slots)
        if (q.empty()) {
            cout << "erasing time slot " << arrival_time << " from doc# " << docid << endl;
            doc.erase(it); //erasing using the iterator
        }
    }
}

//if you are using a raw pointer array, there doesn't seem to be a good way to get the
//  size of the array for iteration
//   (some refs say there's size() fn in <iterator> but it doesn't seem to actually exist when I try it)
//for easier iteration, should use std::vector instead
bool all_docs_done(Doctor* docarray, int ndocs) {
    for (int i = 1; i <= ndocs; i++) {
        if (!docarray[i].empty()) {return false;}
    }
    return true;
}


int main() {

int nmonks, ndocs;
cin >> nmonks >> ndocs;
//doctors[0] will not be used, to avoid numbering confusion
Doctor doctors[ndocs + 1];

int arrival, nvisits, firstdoc, docid;
//read the input for each monk
for (int i=1; i<=nmonks; i++) {
    //the monk will be added to the first doc's schedule
    cin >> arrival >> nvisits >> firstdoc;
    //any remaining docs will be added to the monk's queue
    queue<int> docQ;
    for (int j=2; j<=nvisits; j++) {
        cin >> docid;
        docQ.push(docid);
    }
    //construct the monk and add to the first doctor's schedule
    Monk m(i, docQ);
    add_monk(doctors[firstdoc], arrival, m);
}

//at each time step, process all doctors' schedules
// end when all schedules are empty
int t = 0;
while (!all_docs_done(doctors, ndocs)) {
    for (int i = 1; i<=ndocs; i++) {
        process_first(doctors, i, t);
    }
    t++;
}
cout << "end time = " << t << endl;

}
