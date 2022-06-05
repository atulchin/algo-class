module Labs

## this will probably break any code that wants to make a vector of Pairs
##  (doesn't affect Tuples)
Base.vect(x::Pair...)=Dict(x)


## this is a closure that returns a callable function
##  (avoids having global variables)
## the function that is returned is just a 0-1 knapsack solver
##  (it returns a pair: sum of weights, vector of item indices)
function knapsack_solver(items)
    memo = Dict()
    N = lastindex(items)
    calls = 0

    function knapsack(cap, i::Int)
        ##if all items done or sack is full,
        ## return pair(0,{}) as base case
        ## note: use i == N for 0-indexed languages
        i > N && return (0,Int[])
        cap == 0 && return (0,Int[])
        ##memozize on pair: remaining capacity, index
        if haskey(memo, (cap, i))
            return memo[cap,i]
        else
            calls = calls + 1
        end
        
        ## recursively fill the knapsack with current item rejected
        rej = knapsack(cap, i+1)

        ## if the current item doesn't fit, the reject solution is best
        if items[i] > cap
            best = rej
        else
            ## recursively fill the remaining sack if the current item
            ##     were to be accepted
            ## this returns a pair:
            ##   first element is sum of weights in the sack
            ##   second element is vector of idxs of items in the sack
            remain = knapsack(cap-items[i], i+1)
            ## this is the sum of weights if we accept current item:
            acc_sum = items[i] + remain[1]
            ## this is the vector of indices if we accept current item:
            acc_vec = [i; remain[2]]

            ## if the sum of weights is better than the sum of weights
            ##   in the "reject item" solution, accepting is best
            if acc_sum > rej[1]
                ## return value is pair: sum of weights, vector of indices
                best = (acc_sum, acc_vec)
            else
                best = rej
            end
        end
        ## memoize and return the best solution
        memo[cap,i] = best
        return best
    end

    ## this function is returned for convenience
    function f(cap)
        calls = 0
        res = knapsack(cap, 1)
        println(calls)
        return res
    end

    return f
end

function capacity_index(max_size, nums)
    s = 0
    i = 0
    for x in nums
        s += x
        s > max_size && return i
        i += 1
    end
    return i
end

## two knapsacks with equal capacity
##  (note: adjust indices for 0-indexed languages)
function double_knap(size, items)
    done = false
    ##the index of the last item that could possibly fit into the sacks
    last_i = capacity_index(size*2, items)
    idxs1 = Int[]
    idxs2 = Int[]
    ##try solving with current value of last_i
    ## (only consider items up to last_i)
    while last_i > 0 && !done
        ##knap is the knapsack function above
        ## it returns a pair: sum of weight, vector of item indices
        knap = knapsack_solver(items[1:last_i])
        sol = knap(size)
        ##idxs1 are the items in the first box
        idxs1 = sol[2]
        ##put all remaining items in the second box
        idxs2 = setdiff(1:last_i, idxs1)
        ##if the items fit in the second box, done
        ##  otherwise try again with last_i - 1
        sum2 = sum(items[idxs2])
        if sum2 <= size
            done = true
        else
            last_i = last_i - 1
        end
    end
    ## return the indices of the items in each box
    return (idxs1, idxs2)
    ## ...then convert into the required solution format
end

## solves the same problem as above, but without knapsack
## this function is a closure that returns a callable function
##  (avoids having global variables)
## the function it returns produces a single vector of 1's and 2's
##   corresponding to which box each item goes into
function grocery_solver(items)
    memo = Dict()
    N = lastindex(items)
    calls = 0

    ##recursive (top-down) method
    ## initial call is grocery(capacity, capacity, 0) for 0-indexed
    ## cap1&2 are remaining capacity of each box, i is index of current item
    function grocery(cap1, cap2, i::Int)
        ##if all items done, return empty vector as base case
        ##note: use i == N for 0-indexed languages
        i > N && return []
        ##if both boxes are full, return empty vector as base case
        (cap1 == 0 && cap2 == 0) && return []
        ##memoize on a tuple (box1 room left, box2 room left, item index)
        ## (or use nested maps memoized on ints)
        if haskey(memo, (cap1, cap2, i))
            ##this state has been visited, return the memozied value
            return memo[cap1, cap2, i]
        else
            ##not necessary, just testing efficiency
            calls = calls + 1
        end

        ##if the current item fits in box1
        if items[i] <= cap1
            ##return a vector of which box each item is in
            ## this item is in box 1; remaining items placed by recursion
            ##    [1; ] prepends 1 to the vector returned by grocery()
            ##      but it's slightly inefficient
            opt1 = [1; grocery(cap1-items[i], cap2, i+1)]
        else
            ##make opt1 an empty vector so it will not be considered
            opt1 = []
        end

        ##if the current item fits in box2
        if items[i] <= cap2
            ##return a vector of which box each item is in
            ## this item is in box 2; remaining items placed by recursion
            opt2 = [2; grocery(cap1, cap2-items[i], i+1)]
        else
            ##make opt2 an empty vector so it will not be considered
            opt2 = []
        end

        ##if the item doesn't fit into either box,
        ##  then this recursion branch is at a dead end
        ##  return the base case (empty vector)
        if isempty(opt1) && isempty(opt2)
            best = []
        ## otherwise return whichever option allows us to pack the most items
        elseif length(opt2) > length(opt1)
            best = opt2
        else
            best = opt1
        end

        ##memoize the best solution for this state, and return it
        memo[cap1,cap2,i] = best
        return best
    end

    ## this function is returned for convenience
    function f(cap)
        calls = 0
        res = grocery(cap,cap,1)
        println(calls)
        return res
    end

    return f
end

## testing
testlist = rand(1:10,200)
testcap = 500
let r = double_knap(testcap,testlist)
    length(r[1]) + length(r[2])
end

gr = grocery_solver(testlist)
let r = gr(testcap)
    length(r)
end




struct BoardState
    nrows::Int
    ncols::Int  
    rows::BitArray{1}
    cols::BitArray{1}
    squares::BitArray{2}
    curr_row::Int
end

BoardState(vals::Array{<:Real,2}) = 
    BoardState(size(vals)[1],
    size(vals)[2],
    trues(size(vals)[1]),
    trues(size(vals)[2]),
    trues(size(vals)[1],size(vals)[2]),
    0)

function pick_row(s::BoardState, i::Int)
    x=copy(s.rows)
    x[i]=false
    return BoardState(s.nrows,s.ncols,x,s.cols,s.squares,i)
end

function pick_col(s::BoardState, i::Int)
    x=copy(s.cols)
    x[i]=false
    sq=copy(s.squares)
    sq[s.curr_row,i]=false
    return BoardState(s.nrows,s.ncols,s.rows,x,sq,0)
end

function terminal(s::BoardState)
    return !any(s.rows) && !any(s.cols)
end

function keyfrom(s::BoardState)
    return reshape(s.squares, length(s.squares))
    #return s.squares
end

function board_solver(boardvals::Array{<:Real,2})
    memo = Dict()
    function minimax_sum(s::BoardState, mm::Bool)
        val::Float64 = 0.0
        terminal(s) && return val
        if mm 
            haskey(memo,keyfrom(s)) && return -Inf ##another branch is searching
            val = -Inf
            for i in 1:s.nrows
                if s.rows[i]
                    val = max(val, minimax_sum(pick_row(s,i), false))
                end
            end
        else
            val = Inf
            for i in 1:s.ncols
                if s.cols[i]
                    try_state::BoardState = pick_col(s,i)
                    square::Float64 = boardvals[s.curr_row, i]
                    try_val::Float64 = square + minimax_sum(try_state, true)
                    val = min(val, try_val)
                end
            end
        end
        memo[keyfrom(s)] = true
        return val
    end
    function f()
        init_state = BoardState(boardvals)
        return minimax_sum(init_state,true)
    end
    return f
end

b = [10 -5; -5 10]
b = [10 -5; 10 -5]
b = [10 10; -5 -5]
b = [7 0 -7; 5 5 0; 7 1 -10]
b = [7 0 -7 1; 5 5 0 1; 7 1 -10 1; 1 1 1 1]
f = board_solver(b)
f()

function interval_cover(r_tuple, sorted_ivs)
    curr_pos = r_tuple[1]
    right_edge = r_tuple[2]
    idx = 1
    maxidx = lastindex(sorted_ivs)
    solution = []

    while idx < maxidx && curr_pos < right_edge
        #out of the intervals that cover curr_pos, select the one that
        #extends furthest
        candidates = []
        while idx <= maxidx && sorted_ivs[idx][1] <= curr_pos
            push!(candidates, sorted_ivs[idx])
            idx += 1
        end
        if isempty(candidates)
            return [] ##there's a gap
        else
            sort!(candidates, by=x->x[2], rev=true)
            chosen = first(candidates)
            push!(solution, chosen)
            curr_pos = chosen[2]
        end
    end
    if curr_pos >= right_edge
        return solution
    else
        return []
    end
end

function sprinkler_interval(x, r, w)
    if r < w/2
        return (0,0)
    else
        a = sqrt(r*r - w*w/4)
        return (x-a,x+a)
    end
end

function read_sprinklers(filename)
    lines = readlines(filename)
    line1 = parse.(Int, split(lines[1]))
    n_sprink = line1[1]
    field_len = line1[2]
    field_w = line1[3]
    intervals = Tuple{Float64,Float64}[]
    for i in 1:n_sprink
        dat = parse.(Int, split(lines[i+1]))
        push!(intervals, sprinkler_interval(dat[1], dat[2], field_w))
    end
    return (field_len, sort(intervals))
end

flen, ivls = read_sprinklers("test.txt")
interval_cover((0, flen), ivls)




## from Halim text
function coinways_calculator(coinvals)
    memo = Dict{Tuple{Int,Int},Int}()
    N = lastindex(coinvals)
    function ways(coinidx, total)
        total == 0 && return 1
        total < 0 && return 0
        coinidx > N && return 0 ### ==N if zero-indexed
        if haskey(memo, (coinidx,total))
            return memo[(coinidx,total)]
        else
            rejectcoin = ways(coinidx+1, total)
            acceptcoin = ways(coinidx, total-coinvals[coinidx])
            totalways = rejectcoin + acceptcoin
            memo[(coinidx,total)] = totalways
            return totalways
        end
    end
    function f(total)
        return ways(1, total)
    end
    return f
end

kingdom_currency = [5,10,20,50,100,200,500,1000,2000,5000,10000]
kingdom_currency = [10000,5000,2000,1000,500,200,100,50,20,10,5]
kingdom_count = coinways_calculator(kingdom_currency)
kingdom_count(200)


function build_vector(arr, mask)
    s = Vector{eltype(arr)}()
    for i in 1:lastindex(arr)
        if mask[i]
            push!(s,arr[i])
        end
    end
    return sort(s)
end

function set_true(bool_arr, i)
    x = copy(bool_arr)
    x[i] = true
    return x
end

function setsums(target, setvals)
    solutions = Set{Vector{eltype(setvals)}}()
    N = lastindex(setvals)
    initmask = falses(N)

    function try_sets(curr_targ, i, setmask)
        if curr_targ == 0
            push!(solutions,build_vector(setvals,setmask))
            return
        elseif curr_targ < 0 || i > N ## >= N if zero-indexed
            return
        else
            try_sets(curr_targ, i+1, setmask)
            try_sets(curr_targ - setvals[i], i+1, set_true(setmask,i))
        end
    end

    try_sets(target, 1, initmask)
    return solutions
end

setsums(4,[4,3,2,2,1,1])
setsums(5,[2,1,1])
setsums(400,[50 50 50 50 50 50 25 25 25 25 25 25])

## modified from Halim text
function coinways_calc2(coinvals,num_avail)
    memo = Dict()
    N = lastindex(coinvals)
    solutions = Set{Vector{eltype(coinvals)}}()
    function ways(coinidx, total, comp, each_remain)
        if total == 0
            push!(solutions, comp)
            return 1
        end
        total < 0 && return 0
        coinidx > N && return 0 ## ==N if zero-indexed
        if haskey(memo, (comp,total))
            return memo[(comp,total)]
        else
            rejectcoin = ways(coinidx+1, total, copy(comp), copy(each_remain))
            total_if_acc = total-coinvals[coinidx]
            comp_if_acc = sort(push!(copy(comp), coinvals[coinidx]))
            remain_if_acc = copy(each_remain)
            if remain_if_acc[coinidx] == 0
                acceptcoin = 0
            else
                remain_if_acc[coinidx] -= 1
                acceptcoin = ways(coinidx, total_if_acc, comp_if_acc, remain_if_acc)
            end
            totalways = rejectcoin + acceptcoin
            memo[(comp,total)] = totalways
            return totalways
        end
    end
    function f(total)
        nways = ways(1, total, [], num_avail)
        return (nways, solutions)
    end    
    return f
end

k_avail = similar(kingdom_currency)
k_avail .= -1
king_enum = coinways_calc2(kingdom_currency, k_avail)
king_enum(20)

setsums(4,[4,3,2,2,1,1])
setsums(5,[2,1,1])
@time(setsums(400,[50 50 50 50 50 50 25 25 25 25 25 25]))

coinways_calc2([1,2,3,4],[2,2,1,1])(4)
coinways_calc2([4,3,2,1],[1,1,2,2])(4)
coinways_calc2([1,2],[2,1])(5)
@time(coinways_calc2([25,50],[6,6])(400))
coinways_calc2([50,25],[6,6])(400)


## primes, filtered by function f
function primes(n,f)
    ps = []
    ret = []
    for num in 2:n
        p = true
        i = 1
        d = 0
        dmax = sqrt(num)
        imax = lastindex(ps)
        while (p && d<dmax && i<=imax)
            d = ps[i]
            if num%d == 0
                p = false
            end
            i = i + 1
        end
        if p
            push!(ps,num)
            if f(num)
                push!(ret,num)
            end
        end
    end
    return ret
end

function endsin3(n)
    return n%10==3
end

function ntrue(n)
    return true
end

primes(20,ntrue)

primes(1000,endsin3)


## decimal to base b, works with negative bases
function d2b(d,b)
    a = Int[]
    while d!=0
        r = d%b
        if r<0
            r = r-b
            d = d+b
        end
        push!(a,r)
        d=div(d,b)
    end
    join(reverse(a))
end

d2b(7,-2)

## flood puzzle
## don't actually need parent_idxs
mutable struct Node
    parent_idxs::Vector{Int}
    down_min
    down_avail
end

Node(child::Node, min_here, avail_here) = Node(Int[], max(min_here, child.down_min), avail_here + child.down_avail)

function addnode!(tree, child_idx, node_min, node_avail)
    idx = length(tree) + 1
    child = tree[child_idx]
    push!(child.parent_idxs, idx)
    push!(tree, Node(child, node_min, node_avail))
end

function min_rain(tree)
    idx_min = 1
    min_amt = tree[1].down_min - tree[1].down_avail
    for i in 1:length(tree)
        rain_amt = tree[i].down_min - tree[i].down_avail
        if rain_amt < min_amt
            idx_min = i
            min_amt = rain_amt
        end
    end
    Dict("Dam #"=>idx_min, "Rain amt"=>min_amt)
end

tree = Node[]
camp = Node(Int[], 60, 0)
push!(tree, camp)

function tree_from_stdin()
    firstline = split(readline(stdin))
    n_dams = parse(Int, firstline[1])
    tree = Node[]
    camp = Node(Int[], parse(Int, firstline[2]), 0)
    push!(tree, camp)
    for i in 1:n_dams
        line = split(readline(stdin))
        addnode!(tree, 1+parse(Int, line[1]), parse(Int, line[2]), parse(Int, line[3]))
    end
    tree
end

function solve_stdin()
    t = tree_from_stdin()
    min_rain(t)
end


end
