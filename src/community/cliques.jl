##################################################################
#
#   Maximal cliques of undirected graph
#   Derived from Graphs.jl: https://github.com/julialang/Graphs.jl
#
##################################################################

"""
    maximal_cliques(g)

Return a vector of vectors representing the node indices in each of the maximal
cliques found in the undirected graph `g`.

```jldoctest
julia> using Graphs

julia> g = SimpleGraph(3)
{3, 0} undirected simple Int64 graph

julia> add_edge!(g, 1, 2)
true

julia> add_edge!(g, 2, 3)
true

julia> maximal_cliques(g)
2-element Vector{Vector{Int64}}:
 [2, 3]
 [2, 1]
```
"""
function maximal_cliques end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function maximal_cliques(g::AG::(!IsDirected)) where {T,AG<:AbstractGraph{T}}
    # Cache nbrs and find first pivot (highest degree)
    maxconn = -1
    # uncomment this when https://github.com/JuliaLang/julia/issues/23618 is fixed
    # nnbrs = [Set{T}() for n in vertices(g)]
    nnbrs = Vector{Set{T}}()
    for n in vertices(g)
        push!(nnbrs, Set{T}())
    end
    pivotnbrs = Set{T}() # handle empty graph
    pivotdonenbrs = Set{T}()  # initialize

    for n in vertices(g)
        nbrs = Set{T}()
        union!(nbrs, outneighbors(g, n))
        delete!(nbrs, n) # ignore edges between n and itself
        conn = length(nbrs)
        if conn > maxconn
            pivotnbrs = nbrs
            nnbrs[n] = pivotnbrs
            maxconn = conn
        else
            nnbrs[n] = nbrs
        end
    end

    # Initial setup
    cand = Set{T}(vertices(g))
    # union!(cand, keys(nnbrs))
    smallcand = setdiff(cand, pivotnbrs)
    done = Set{T}()
    stack = Vector{Tuple{Set{T},Set{T},Set{T}}}()
    clique_so_far = Vector{T}()
    cliques = Vector{Vector{T}}()

    # Start main loop
    while !isempty(smallcand) || !isempty(stack)
        if !isempty(smallcand) # Any vertices left to check?
            n = pop!(smallcand)
        else
            # back out clique_so_far
            cand, done, smallcand = pop!(stack)
            pop!(clique_so_far)
            continue
        end
        # Add next node to clique
        push!(clique_so_far, n)
        delete!(cand, n)
        push!(done, n)
        nn = nnbrs[n]
        new_cand = intersect(cand, nn)
        new_done = intersect(done, nn)
        # check if we have more to search
        if isempty(new_cand)
            if isempty(new_done)
                # Found a clique!
                push!(cliques, collect(clique_so_far))
            end
            pop!(clique_so_far)
            continue
        end
        # Shortcut--only one node left!
        if isempty(new_done) && length(new_cand) == 1
            push!(cliques, vcat(clique_so_far, collect(new_cand)))
            pop!(clique_so_far)
            continue
        end
        # find pivot node (max connected in cand)
        # look in done vertices first
        numb_cand = length(new_cand)
        maxconndone = -1
        for n in new_done
            cn = intersect(new_cand, nnbrs[n])
            conn = length(cn)
            if conn > maxconndone
                pivotdonenbrs = cn
                maxconndone = conn
                if maxconndone == numb_cand
                    break
                end
            end
        end
        # Shortcut--this part of tree already searched
        if maxconndone == numb_cand
            pop!(clique_so_far)
            continue
        end
        # still finding pivot node
        # look in cand vertices second
        maxconn = -1
        for n in new_cand
            cn = intersect(new_cand, nnbrs[n])
            conn = length(cn)
            if conn > maxconn
                pivotnbrs = cn
                maxconn = conn
                if maxconn == numb_cand - 1
                    break
                end
            end
        end
        # pivot node is max connected in cand from done or cand
        if maxconndone > maxconn
            pivotnbrs = pivotdonenbrs
        end
        # save search status for later backout
        push!(stack, (cand, done, smallcand))
        cand = new_cand
        done = new_done
        smallcand = setdiff(cand, pivotnbrs)
    end
    return cliques
end

"""
    maximum_clique(g)

Return a vector representing the node indices of a maximum clique
of the undirected graph `g`.

```jldoctest
julia> using Graphs

julia> maximum_clique(blockdiag(complete_graph(3), complete_graph(4)))
4-element Vector{Int64}:
 4
 5
 6
 7
```
"""
function maximum_clique end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function maximum_clique(g::AG::(!IsDirected)) where {T,AG<:AbstractGraph{T}}
    return sort(argmax(length, maximal_cliques(g)))
end

"""
    clique_number(g)

Returns the size of the largest clique of the undirected graph `g`.

```jldoctest
julia> using Graphs

julia> clique_number(blockdiag(complete_graph(3), complete_graph(4)))
4
```
"""
function clique_number end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function clique_number(g::AG::(!IsDirected)) where {T,AG<:AbstractGraph{T}}
    return maximum(length, maximal_cliques(g))
end

"""
    maximal_independent_sets(g)

Return a vector of vectors representing the node indices in each of the maximal
independent sets found in the undirected graph `g`.

```jldoctest
julia> using Graphs

julia> maximal_independent_sets(cycle_graph(5))
5-element Vector{Vector{Int64}}:
 [5, 2]
 [5, 3]
 [2, 4]
 [1, 4]
 [1, 3]
```
"""
function maximal_independent_sets end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function maximal_independent_sets(
    g::AG::(!IsDirected)
) where {T,AG<:AbstractGraph{T}}
    # Convert to SimpleGraph first because `complement` doesn't accept AbstractGraph.
    return maximal_cliques(complement(SimpleGraph(g)))
end

"""
    maximum_independent_set(g)

Return a vector representing the node indices of a maximum independent set
of the undirected graph `g`.

### See also
[`independent_set`](@ref)

## Examples
```jldoctest
julia> using Graphs

julia> maximum_independent_set(cycle_graph(7))
3-element Vector{Int64}:
 2
 5
 7
```
"""
function maximum_independent_set end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function maximum_independent_set(
    g::AG::(!IsDirected)
) where {T,AG<:AbstractGraph{T}}
    # Convert to SimpleGraph first because `complement` doesn't accept AbstractGraph.
    return maximum_clique(complement(SimpleGraph(g)))
end

"""
    independence_number(g)

Returns the size of the largest independent set of the undirected graph `g`.

```jldoctest
julia> using Graphs

julia> independence_number(cycle_graph(7))
3
```
"""
function independence_number end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function independence_number(g::AG::(!IsDirected)) where {T,AG<:AbstractGraph{T}}
    # Convert to SimpleGraph first because `complement` doesn't accept AbstractGraph.
    return clique_number(complement(SimpleGraph(g)))
end
