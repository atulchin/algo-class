#include <iostream>
#include <bits/stdc++.h>
using namespace std;

map<pair<int,int>, int> bestCost;

int getBestCost(int target, int idx, const vector<vector<int>> &costs){
    //base case: all items have been bought
    if (idx == costs.size()) return 0;

    //memoizing on pair: {target, idx}
    if(bestCost.find({target,idx}) != bestCost.end()){
        return bestCost[{target,idx}];
    }

    int best = INT_MIN;
    //iterate through all options at current item
    for (auto& it : costs[idx]) {
        //if possible to buy, try buying it
        if (target - it >= 0) {
            best = max(best, it + getBestCost(target - it, idx+1, costs));
        }
    }
    bestCost[{target,idx}] = best;
    return best;
}

int main(){
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    int target, desserts;
    cin >> target >> desserts;

    vector<int> eachDessert(desserts); 

    vector<vector<int>> costs(desserts, vector<int>());

    for(int i = 0; i < desserts; i++){
        int dessertCnt;
        cin >> dessertCnt;
        eachDessert[i] = dessertCnt;
        for(int j = 0; j < dessertCnt; j++){
            int k;
            cin >> k;
            costs[i].push_back(k);
        }
        // sort dessert costs in descending order
        sort(costs[i].begin(),costs[i].end(), greater<int>());
    }
    int bestCost = getBestCost(target, 0, costs);

    if(bestCost <= 0){
        cout << "no solution" << endl;
    }
    else{
        cout << bestCost << endl;
    }

    return 0;
}