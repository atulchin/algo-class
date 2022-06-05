#include <iostream>
#include <vector>
#include <string>

using namespace std;

//a node is a dam or camp
struct node {
    int down_min; //minimum required to break this dam and all downstream dams (including camp)
    int down_avail; //total initial water in this dam plus all downstream dams

    //constructor to initialize amounts based on downstream node
    node(struct node downstream, int dam_size, int water) {
        //down_min can't be smaller than downstream node's
        if (downstream.down_min > dam_size) {down_min = downstream.down_min;}
        else {down_min = dam_size;}
        //down_avail keeps a path sum as dams are added downstream-to-upstream
        down_avail = downstream.down_avail + water;
    }

    //constructor to use just for the camp
    node(int dam_size, int water) {
        down_min = dam_size;
        down_avail = water;
    }
};

//the "tree" is just a vector of nodes; this constructs a node and appends it to the tree
void add_node(vector<node> &tree, int downstream_idx, int dam_size, int water) {
    tree.push_back(node(tree[downstream_idx], dam_size, water));
}

//min_rain would be one line of code in a functional language
void min_rain(vector<node> &tree) {
    int idx_min = 0;
    int min_amt = tree[0].down_min - tree[0].down_avail;
    for (int i=0; i<tree.size(); i++) {
        int rain_amt = tree[i].down_min - tree[i].down_avail;
        if (rain_amt < min_amt) {
            idx_min = i;
            min_amt = rain_amt;
        }
    }
    cout << "Rain " << min_amt << " at dam # " << idx_min << endl;
}

int main()
{
    vector<node> tree;
    int n_dams;
    int camp_min;
    cin >> n_dams >> camp_min;

    node camp(camp_min, 0);
    tree.push_back(camp); //the camp is tree[0]

    int down_idx;
    int dam_size;
    int water;
    for (int i=0; i<n_dams; i++){
        cin >> down_idx >> dam_size >> water;
        add_node(tree, down_idx, dam_size, water);
    }
    min_rain(tree);

}
