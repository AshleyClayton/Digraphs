#############################################################################
##
#W  oper.gi
#Y  Copyright (C) 2014                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# graph algorithms

#

InstallMethod(DigraphEdgeUnion, "for digraphs",
[IsDigraph, IsDigraph],
function(graph1, graph2)
  local m, n, outm, outn, out, i;

  if DigraphNrVertices(graph1) > DigraphNrVertices(graph2) then 
    m := DigraphNrVertices(graph2); # smaller graph
    n := DigraphNrVertices(graph1);        
    outm := OutNeighbours(graph2);  # out neighbours of smaller graph
    outn := OutNeighbours(graph1);
  else
    m := DigraphNrVertices(graph1);
    n := DigraphNrVertices(graph2);
    outm := OutNeighbours(graph1);
    outn := OutNeighbours(graph2);
  fi;

  out := EmptyPlist(n);

  for i in [ 1 .. m ] do 
    out[i] := Concatenation(outm[i], outn[i]);
  od;

  for i in [ m + 1 .. n ] do 
    out[i] := ShallowCopy(outn[i]);
  od;

  return DigraphNC(out);
end);

#

InstallMethod(DigraphFloydWarshall, "for a digraph",
[IsDigraph, IsFunction, IsObject, IsObject],
function(graph, func, nopath, edge)
  local vertices, n, mat, out, i, j, k;

  vertices := DigraphVertices(graph);
  n := DigraphNrVertices(graph);
  mat := EmptyPlist(n);

  for i in vertices do
    mat[i] := EmptyPlist(n);
    for j in vertices do 
      mat[i][j] := nopath;
    od;
  od;
  
  out := OutNeighbours(graph);
  for i in vertices do 
    for j in out[i] do 
      mat[i][j] := edge;
    od;
  od;
  
  for k in vertices do
    for i in vertices do
      for j in vertices do
        func(mat, i, j, k);
      od;
    od;
  od;

  return mat;
end);

#

InstallMethod(DigraphReverse, "for a digraph",
[IsDigraph],
function(graph)
  local old, new, i, j;

  old := OutNeighbours(graph);
  new := List(DigraphVertices(graph), x -> [ ]);

  for i in DigraphVertices(graph) do 
    for j in old[i] do 
      Add(new[j], i);
    od;
  od;

  return DigraphNC(new);
end);

#

InstallMethod(DigraphReverseEdges, "for a digraph and an edge",
[IsDigraph, IsRectangularTable],
function(digraph, edges)
  local current, nredges, out, new, i;

  if IsMultiDigraph(digraph) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the first argument <digraph> must not be a multigraph,");
    return;
  fi;

  if not IsPosInt(edges[1][1]) or 
    not ForAll(edges, x -> IsDigraphEdge(digraph, x)) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the second argument <edges> must be a list of edges of <digraph>,");
    return;
  fi;
 
  Sort(edges);
  current := 1;


  nredges := Length(edges); 
  out := OutNeighbours(digraph);
  new := [];
  for i in [ 1 .. Length(DigraphVertices(digraph)) ] do
    new[i] := ShallowCopy(out[i]);
    while current <= nredges and  edges[current][1]  = i do
      Remove(new[i], Position(new[i], edges[current][2]));
      current := current + 1;
    od;
  od;

  for i in [ 1 .. nredges ]  do
    Add(new[edges[i][2]], edges[i][1]);
  od;

  return DigraphNC(new);
end);

#

# can we use IsListOf... jj
InstallMethod(DigraphReverseEdges, "for a digraph and an edge",
[IsDigraph, IsList],
function(digraph, edges)
  local nredges, current, out, new, pos_l, pos_h, toadd, pos, temp, i, edge;

  if IsMultiDigraph(digraph) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the first argument <digraph> must not be a multigraph,");
    return;
  fi;

  if Length(edges) = 0 then
    return DigraphCopy(digraph);
  fi;
  
  nredges := DigraphNrEdges(digraph);
  if not IsPosInt(edges[1]) or 
    not IsHomogeneousList(edges) or
    not ForAll(edges, x -> x <= nredges) then 
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the second argument <edge> must be a list of edges of <digraph>,");
    return;
  fi;

  Sort(edges); 
  current := edges[1];
  out := OutNeighbours(digraph);  
  new := [];
  pos_l := 0; 
  pos_h := 0;

  toadd := [];
  pos := 1;
  for i in [ 1 .. Length(DigraphVertices(digraph)) ] do
    pos_h := pos_h + Length(out[i]);
    new[i] := ShallowCopy(out[i]);
    while pos_l < current and current <= pos_h do
      temp := current - pos_l;
      toadd[pos] := [ i, new[i][temp]];
      pos := pos + 1;
      Unbind(new[i][temp]); 
      if IsBound(edges[pos]) then
        current := edges[pos];
      else
        break;
      fi;
    od;
    new[i] := Flat(new[i]);
    pos_l := pos_l + Length(out[i]);
  od;

  for edge in toadd do
    Add(new[edge[2]], edge[1]);
  od;

  return DigraphNC(new); 
end);

#

InstallMethod(DigraphReverseEdge, "for a digraph and an edge",
[IsDigraph, IsList],
function(digraph, edge)
  return DigraphReverseEdges(digraph, [edge]);
end);

#

InstallMethod(DigraphReverseEdge, "for a digraph and an edge",
[IsDigraph, IsPosInt],
function(digraph, edge)
  return DigraphReverseEdges(digraph, [edge]);
end);

#

InstallMethod(DigraphRemoveLoops, "for a digraph",
[IsDigraph],
function(digraph)
  local old, new, nr, out, i, j, tot;
  
  old := OutNeighbours(digraph);
  new := [];
  tot := 0;

  for i in DigraphVertices(digraph) do 
    new[i] := []; 
    nr := 0;
    for j in old[i] do 
      if i <> j then 
        nr := nr + 1;
        new[i][nr] := j;
      fi;
    od;
    tot := tot + nr;
  od;

  out := DigraphNC(new);
  SetDigraphHasLoops(out, false);
  SetDigraphNrEdges(out, tot);
  return out;
end);

#

InstallMethod(DigraphRemoveEdge, "for a digraph and a list of two pos ints",
[IsDigraph, IsHomogeneousList],
function(digraph, edge)
  local verts;

  if IsMultiDigraph(digraph) then
      Error("Digraphs: DigraphRemoveEdge: usage,\n",
      "the first argument <digraph> must not have multiple edges\n",
      "when the second argument <edges> is a pair of vertices,");
      return;
  fi;
  verts := DigraphVertices(digraph);
  if Length(edge) <> 2
   or not IsPosInt(edge[1])
   or not edge[1] in verts
   or not edge[2] in verts then
    Error("Digraphs: DigraphRemoveEdge: usage,\n",
    "the second argument <edge> must be a pair of vertices of <digraph>,");
    return;
  fi;
  return DigraphRemoveEdges(digraph, [ edge ]);
end);

InstallMethod(DigraphRemoveEdge, "for a digraph and a pos int",
[IsDigraph, IsPosInt],
function(digraph, edge)
  local m;

  m := DigraphNrEdges(digraph);
  if edge > m then
    Error("Digraphs, DigraphRemoveEdge, usage,\n",
    "the second argument <edge> must be the index of an edge in <digraph>,");
    return;
  fi;
  return DigraphRemoveEdgesNC(digraph, [ edge ]);
end);

InstallMethod(DigraphRemoveEdges, "for a digraph and a list",
[IsDigraph, IsHomogeneousList],
function(digraph, edges)
  local m, verts, remove, n, old_adj, count, offsets, pos, i, x;

  if IsEmpty(edges) then
    return DigraphCopy(digraph);
  fi;

  m := DigraphNrEdges(digraph);
  verts := DigraphVertices(digraph);

  if IsPosInt(edges[1]) and ForAll(edges, x -> 0 < x and x <= m) then
    # Remove edges by index
    remove := edges;
  elif IsRectangularTable(edges) and Length(edges[1]) = 2
   and IsPosInt(edges[1][1])
   and ForAll(edges, x -> x[1] in verts and x[2] in verts) then
    # Remove edges by [ source, range ]
    if IsMultiDigraph(digraph) then
      Error("Digraphs: DigraphRemoveEdges: usage,\n",
      "the first argument <digraph> must not have multiple edges\n",
      "when the second argument <edges> is a list of edges,");
      return;
    fi;
    n := DigraphNrVertices(digraph);
    old_adj := OutNeighbours(digraph);
    count := 0;
    remove := [  ];
    offsets := EmptyPlist(n);
    offsets[1] := 0;
    for i in [ 2 .. n ] do
      offsets[ i ] := offsets[ i - 1 ] + Length( old_adj[ i - 1 ] );
    od;
    for x in edges do
      pos := Position( old_adj[ x[1] ], x[2] );
      if pos <> fail then
        count := count + 1;
        remove[ count ] :=  offsets[x[1]] + pos;
      fi;
    od;
  else
    Error("Digraphs: DigraphRemoveEdges: usage,\n",
    "the second argument <edges> must be a list of indices of edges\n",
    "or a list of edges of the first argument <digraph>,");
    return;
  fi;
  return DigraphRemoveEdgesNC(digraph, remove);
end);

# DigraphRemoveEdgesNC assumes you are removing edges by index

InstallMethod(DigraphRemoveEdgesNC, "for a digraph and a list",
[IsDigraph, IsHomogeneousList],
function(digraph, edges)
  local m, n, old_adj, new_adj, old_edge_count, new_edge_count, degree_count, 
  old_labs, new_labs, gr, i, j;

  if IsEmpty(edges) then
    return DigraphCopy(digraph);
  fi;
  
  m := DigraphNrEdges(digraph);
  n := DigraphNrVertices(digraph);
  old_adj := OutNeighbours(digraph);
  new_adj := EmptyPlist(n);
  edges := BlistList( [ 1 .. m ], edges );
  old_edge_count := 0;
  new_edge_count := 0;
  degree_count := 0;
  old_labs := DigraphEdgeLabels(digraph);
  new_labs := [  ];
  for i in DigraphVertices(digraph) do # Loop over each vertex
    new_adj[i] := [  ];
    degree_count := 0;
    for j in old_adj[i] do
      old_edge_count := old_edge_count + 1;
      if not edges[ old_edge_count ] then # Keep this edge
        new_edge_count := new_edge_count + 1;
        degree_count := degree_count + 1;
        new_adj[ i ][ degree_count ] := j;
        new_labs[ new_edge_count ] := old_labs[ old_edge_count ];
      fi;
    od;
  od;
  gr := DigraphNC(new_adj);
  SetDigraphVertexLabels( gr, DigraphVertexLabels(digraph) );
  SetDigraphEdgeLabels( gr, new_labs );
  return gr;

end);

#

InstallMethod(DigraphAddEdge, "for a digraph and an edge",
[IsDigraph, IsList],
function(digraph, edge)
  local verts;

  verts := DigraphVertices(digraph);
  if Length(edge) <> 2
    or not IsPosInt(edge[1])
    or not IsPosInt(edge[2])
    or not edge[1] in verts
    or not edge[2] in verts then
    Error("Digraphs: DigraphAddEdge: usage,\n",
          "the second argument <edge> must be a pair of vertices of ",
          "<digraph>,");
    return;
  fi;

  return DigraphAddEdgesNC(digraph, [ edge ]);
end);

InstallMethod(DigraphAddEdges, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, edges)
  local vertices, newsource, newrange, m, edge;

  if not IsEmpty(edges) and
   (not IsList(edges[1])
    or not Length(edges[1]) = 2 
    or not IsPosInt(edges[1][1]) 
    or not IsRectangularTable(edges)) then
    Error("Digraphs: DigraphAddEdges: usage,\n",
          "the second argument <edges> must be a list of pairs of vertices\n",
          "of the first argument <digraph>,");
    return;
  fi;

  vertices := DigraphVertices(digraph);
  for edge in edges do
    if not (edge[1] in vertices and edge[2] in vertices) then
      Error("Digraphs: DigraphAddEdges: usage,\n",
          "the second argument <edges> must be a list of pairs of vertices\n",
          "of the first argument <digraph>,");
      return;
    fi;
  od;

  return DigraphAddEdgesNC(digraph, edges);
end);

InstallMethod(DigraphAddEdgesNC, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, edges)
  local out, new, verts, edge;

  out := OutNeighbours(digraph);
  new := List( out, ShallowCopy );
  verts := DigraphVertices( digraph );
  for edge in edges do
    Add( new[ edge[1] ], edge[2] );
  od;
  return DigraphNC( new );
end);
#

InstallMethod(DigraphAddVertex, "for a digraph",
[IsDigraph],
function(digraph)
  return DigraphAddVerticesNC(digraph, 1, [ ]); 
end);

InstallMethod(DigraphAddVertex, "for a digraph and an object",
[IsDigraph, IsObject],
function(digraph, name)
  return DigraphAddVerticesNC(digraph, 1, [ name ]); 
end);

#

InstallMethod(DigraphAddVertices, "for a digraph and a pos int",
[IsDigraph, IsInt],
function(digraph, m)
  if m < 0 then
    Error("Digraphs: DigraphAddVertices: usage,\n",
    "the second arg <m> (the number of vertices to add) must be non-negative,");
    return;
  fi;
  return DigraphAddVerticesNC(digraph, m, [ ]);
end);

InstallMethod(DigraphAddVertices, "for a digraph, a pos int and a list",
[IsDigraph, IsInt, IsList],
function(digraph, m, names)
  if m < 0 then
    Error("Digraphs: DigraphAddVertices: usage,\n",
    "the second arg <m> (the number of vertices to add) must be non-negative,");
    return;
  elif Length(names) <> m then
    Error("Digraphs: DigraphAddVertices: usage,\n",
      "the number of new vertex names (the length of the third arg <names>)\n",
      "must match the number of new vertices (the value of the second arg <m>),"
    );
    return;
  fi;
  return DigraphAddVerticesNC(digraph, m, names);
end);

#

InstallMethod(DigraphAddVerticesNC, "for a digraph, a pos int and a list",
[IsDigraph, IsInt, IsList],
function(digraph, m, names)
  local out, new, n, newverts, nam, i;
  
  out := OutNeighbours(digraph);
  n := DigraphNrVertices(digraph);
  new := EmptyPlist(n);
  for i in DigraphVertices(digraph) do
    new[i] := ShallowCopy(out[i]);
  od;
  newverts := [ (n + 1) .. (n + m) ];
  for i in newverts do
    new[i] := [ ];
  od;
  out := DigraphNC(new);
  # Transfer known data
  if IsEmpty(names) then
    names := newverts;
  fi;
  nam := Concatenation(DigraphVertexLabels(digraph), names);
  SetDigraphVertexLabels(out, nam);
  SetDigraphEdgeLabels(out, DigraphEdgeLabels(digraph));
  return out;
end);

#

InstallMethod(DigraphRemoveVertex, "for a digraph and a pos int",
[IsDigraph, IsPosInt],
function(digraph, m)
  if m > DigraphNrVertices(digraph) then
    Error("Digraphs: DigraphRemoveVertex: usage,\n",
    "the second arg <m> is not a vertex of the first arg <digraph>,");
    return;
  fi;
  return DigraphRemoveVerticesNC(digraph, [ m ]);
end);

#

InstallMethod(DigraphRemoveVertices, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, verts)
  local n;
  
  n := DigraphNrVertices(digraph);
  if not IsEmpty(verts) and 
   (not IsPosInt(verts[1]) or
    not IsHomogeneousList(verts) or
    not IsDuplicateFreeList(verts) or
    ForAny(verts, x -> x < 1 or n < x)) then
    Error("Digraphs: DigraphRemoveVertices: usage,\n",
    "the second arg <verts> should be a duplicate free list of vertices of\n",
    "the first arg <digraph>,");
    return;
  fi;
  return DigraphRemoveVerticesNC(digraph, verts );
end);

#

InstallMethod(DigraphRemoveVerticesNC, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, verts)
  local n, len, new_nrverts, m, log, diff, j, lookup, old_edge_count, old_labels, new_edge_count, new_labels, new_vertex_count, old_nbs, new_nbs, gr, i, x;
  
  if IsEmpty(verts) then
    return DigraphCopy(digraph);
  else
    n := DigraphNrVertices(digraph);
    len := Length(verts);
    new_nrverts := n - len;
    if new_nrverts = 0 then
      return EmptyDigraph(0);
    fi;
    m     := DigraphNrEdges(digraph);
    log   := LogInt(len, 2);
    if (2 * m * log) + (len * log) < (2 * m * len) then # Sort verts if sensible
      Sort(verts);
    fi;
    diff := Difference(DigraphVertices(digraph), verts);

    j := 0;
    lookup := EmptyPlist(n);
    for i in diff do
      j := j + 1;
      lookup[ i ] := j;
    od;

    old_edge_count   := 0;
    old_labels       := DigraphEdgeLabels(digraph);
    new_edge_count   := 0;
    new_labels       := [ ];
    new_vertex_count := 0;

    old_nbs := OutNeighbours(digraph);
    new_nbs := EmptyPlist(new_nrverts);
    for i in DigraphVertices(digraph) do
      if IsBound(lookup[i]) then
        new_vertex_count := new_vertex_count + 1;
        new_nbs[new_vertex_count] := [  ];
        j := 0;
        for x in old_nbs[ i ] do
          old_edge_count := old_edge_count + 1;
          if not x in verts then # Can search through diff if |diff| < |verts|
            j := j + 1;
            new_nbs[ new_vertex_count ][j] := lookup[x];
            new_edge_count := new_edge_count + 1;
            new_labels[ new_edge_count ] := old_labels[ old_edge_count ];
          fi;
        od;
      else
        old_edge_count := old_edge_count + Length(old_nbs[i]);
      fi;
    od;
  fi;
  gr := DigraphNC(new_nbs);
  SetDigraphVertexLabels(gr, DigraphVertexLabels(digraph){diff});
  SetDigraphEdgeLabels(gr, new_labels);
  return gr;
end);

#

InstallMethod(OnDigraphs, "for a digraph and a perm",
[IsDigraph, IsPerm],
function(graph, perm)
  local adj, out;

  if ForAny(DigraphVertices(graph), i-> i^perm > DigraphNrVertices(graph)) then
    Error("Digraphs: OnDigraphs: usage,\n",
    "the 2nd argument <perm> must permute the vertices ",
    "of the 1st argument <graph>,");
    return;
  fi;
 
  adj := List( OutNeighbours(graph), ShallowCopy );
  adj := Permuted(adj, perm);
  Apply(adj, x-> OnTuples(x, perm));

  out := DigraphNC(adj);
  SetDigraphVertexLabels(out, Permuted(DigraphVertexLabels(graph), perm));
  return out;
end);

#

InstallMethod(OnMultiDigraphs, "for a digraph, perm and perm",
[IsDigraph, IsPerm, IsPerm],
function(graph, perm1, perm2)
  return OnMultiDigraphs(graph, [perm1, perm2]);
end);

InstallMethod(OnMultiDigraphs, "for a digraph and perm coll",
[IsDigraph, IsPermCollection],
function(graph, perms)
  local source, range, out;

  if Length(perms) <> 2 then 
    Error("Digraphs: OnMultiDigraphs: usage,\n",
    "the 2nd argument must be a pair of permutations,");
    return;
  fi;

  if ForAny([ 1 .. DigraphNrEdges(graph) ], i-> 
    i^perms[2] > DigraphNrEdges(graph)) then
    Error("Digraphs: OnDigraphs: usage,\n",
    "the argument <perms[2]> must permute the edges ",
    "of the 1st argument <graph>,");
    return;
  fi;
 
  out := OnDigraphs(graph, perms[1]);
  SetDigraphEdgeLabels(out, Permuted(DigraphEdgeLabels(graph), perms[2]));
  return out;
end);

#

InstallMethod(DigraphSymmetricClosure, "for a digraph",
[IsDigraph],
function(digraph)
  local n, verts, mat, out, new, x, gr, i, j, k;
  
  n := DigraphNrVertices(digraph);
  if not (HasIsSymmetricDigraph(digraph) and IsSymmetricDigraph(digraph))
   and n > 1 then
    verts := ShallowCopy(DigraphVertices(digraph));
    mat := List( verts, x -> verts * 0 );
    out := OutNeighbours(digraph);
    for i in verts do
      for j in out[i] do
        if j < i then
          mat[j][i] := mat[j][i] - 1;
        else
          mat[i][j] := mat[i][j] + 1;
        fi;
      od;
    od;
    new := List( out, ShallowCopy );
    for i in verts do
      for j in [ i + 1 .. n ] do
        x := mat[i][j];
        if x > 0 then
          for k in [ 1 .. x ] do
            Add(new[j], i);
          od;
        elif x < 0 then
          for k in [ 1 .. -x ] do
            Add(new[i], j);
          od;
        fi;
      od;
    od;
    gr := DigraphNC( new );
  else
    gr := DigraphCopy(digraph);
  fi;
  SetIsSymmetricDigraph(gr, true);
  return gr;
end);

#

InstallMethod(DigraphTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)
  if IsMultiDigraph(graph) then
    Error("Digraphs: DigraphTransitiveClosure: usage,\n",
    "the argument <graph> cannot have multiple edges,");
    return;
  fi;
  return DigraphTransitiveClosure(graph, false);
end);

#

InstallMethod(DigraphReflexiveTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)
  if IsMultiDigraph(graph) then
    Error("Digraphs: DigraphReflexiveTransitiveClosure: usage,\n",
    "the argument <graph> cannot have multiple edges,");
    return;
  fi;
  return DigraphTransitiveClosure(graph, true); 
end);

#

InstallMethod(DigraphTransitiveClosure, "for a digraph and a boolean", 
[IsDigraph, IsBool],
function(graph, reflexive)
  local adj, m, n, verts, sorted, out, trans, reflex, mat, v, u;

  # <graph> is a digraph without multiple edges
  # <reflexive> is a boolean: true if we want the reflexive transitive closure
 
  adj   := OutNeighbours(graph);
  m     := DigraphNrEdges(graph);
  n     := DigraphNrVertices(graph);
  verts := DigraphVertices(graph);
  
  # Try correct method vis-a-vis complexity
  if m + n + ( m * n ) < ( n * n * n ) then
    sorted := DigraphTopologicalSort(graph);
    if sorted <> fail then # Method for big acyclic digraphs (loops allowed)
      out   := EmptyPlist(n);
      trans := EmptyPlist(n);
      for v in sorted do
        trans[v] := BlistList( verts, [v]);
        reflex   := false;
        for u in adj[v] do
          trans[v] := UnionBlist(trans[v], trans[u]);
          if u = v then
            reflex := true;
          fi;
        od;
        if (not reflexive) and (not reflex) then
          trans[v][v] := false;
        fi;
        out[v] := ListBlist(verts, trans[v]);
        trans[v][v] := true;
      od;
      out := DigraphNC(out);
    fi;
  fi;

  # Method for small or non-acyclic digraphs
  if not IsBound(out) then
    if reflexive then
      mat := DIGRAPH_REFLEX_TRANS_CLOSURE(graph);
    else
      mat := DIGRAPH_TRANS_CLOSURE(graph);
    fi;
    out := DigraphByAdjacencyMatrixNC(mat);
  fi;

  SetIsMultiDigraph(out, false);
  SetIsTransitiveDigraph(out, true);
  return out;
end);

#

InstallMethod(InducedSubdigraph, 
"for a digraph and a homogeneous list",
[IsDigraph, IsHomogeneousList],
function( digraph, subverts )
  local n, old, nr, lookup, adj, j, l, i, k, new;

  if IsEmpty(subverts) then
    return DigraphNC( [ ] );
  fi;

  n := DigraphNrVertices(digraph);
  if (IsRange(subverts) and not (IsPosInt(subverts[1]) and subverts[1] <= n and
    subverts[Length(subverts)] <= n))
    or not IsDuplicateFree(subverts)
    or not ForAll( subverts, x -> IsPosInt(x) and x < (n + 1)) then
    Error("Digraphs: InducedSubdigraph: usage,\n",
    "the second argument <subverts> must be a duplicate-free subset\n",
    "of the vertices of the first argument <digraph>,");
    return;
  fi;
  
  nr := Length(subverts);
  old := OutNeighbours(digraph);
  new := EmptyPlist(nr);
  lookup := [ 1 .. n ] * 0;
  lookup{subverts} := [ 1 .. nr ];

  for i in [ 1 .. nr ] do 
    adj := [ ];
    j := 0;
    for k in old[ subverts[i] ] do
      l := lookup[k];
      if l <> 0 then
        j := j + 1;
        adj[j] := l;
      fi;
    od;
    new[i] := adj;
  od;
  
  new := DigraphNC(new);
  SetDigraphVertexLabels(new, DigraphVertexLabels(digraph){subverts});
  #JDM need to set this correctly!
  #SetDigraphEdgeLabels(new, DigraphEdgeLabels(digraph){subverts});
  return new;
end);

#

InstallMethod(InNeighborsOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  return InNeighboursOfVertex(digraph, v);
end);

InstallMethod(InNeighboursOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: InNeighboursOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
  return InNeighboursOfVertexNC(digraph, v);
end);

InstallMethod(InNeighboursOfVertexNC, "for a digraph with in-neighbours and a vertex",
[IsDigraph and HasInNeighbours, IsPosInt],
function(digraph, v)
  return InNeighbours(digraph)[v];
end);

InstallMethod(InNeighboursOfVertexNC, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  local inn, pos, out, i, j;

  inn := [];
  pos := 1;
  out := OutNeighbours(digraph);
  for i in [ 1 .. Length(out) ] do
    for j in [ 1 .. Length(out[i]) ] do
      if out[i][j] = v then
        inn[pos] := i;
        pos := pos + 1;
      fi;
    od;
  od;
  return inn;
end);

#

InstallMethod(OutNeighborsOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  return OutNeighboursOfVertex(digraph, v);
end);

InstallMethod(OutNeighboursOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: OutNeighboursOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
  return OutNeighboursOfVertexNC(digraph, v);
end);

InstallMethod(OutNeighboursOfVertexNC, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  return OutNeighbours(digraph)[v];
end);

#

InstallMethod(InDegreeOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: InDegreeOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
  return InDegreeOfVertexNC(digraph, v);
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph with in-degrees and a vertex",
[IsDigraph and HasInDegrees, IsPosInt], 4,
function(digraph, v)
  return InDegrees(digraph)[v];
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph with in-neighbours and a vertex",
[IsDigraph and HasInNeighbours, IsPosInt],
function(digraph, v)
  return Length(InNeighbours(digraph)[v]);
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  local count, out, x, i;

  count := 0;
  out := OutNeighbours(digraph);
  for x in out do
    for i in x do
      if i = v then
        count := count + 1;
      fi;
    od;
  od;
  return count;
end);

#

InstallMethod(OutDegreeOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: OutDegreeOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
   return OutDegreeOfVertexNC(digraph, v);
end);

InstallMethod(OutDegreeOfVertexNC, "for a digraph with out-degrees and a vertex",
[IsDigraph and HasOutDegrees, IsPosInt],
function(digraph, v)
  return OutDegrees(digraph)[v];
end);

InstallMethod(OutDegreeOfVertexNC, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  return Length(OutNeighbours(digraph)[v]);
end);

#

InstallMethod(QuotientDigraph, "for a digraph and a homogeneous list",
[IsDigraph, IsHomogeneousList],
function(digraph, partition)
  local n, nr, check, lookup, out, new, x, i, j;

  n := DigraphNrVertices(digraph);
  if n = 0 and IsEmpty(partition) then
    return EmptyDigraph(0);
  elif n = 0 then
    Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> is not a valid partition of the\n",
          "vertices of the null digraph <digraph>. The only valid partition\n",
          "of <digraph> is the empty list,");
    return;
  fi;
  nr := Length(partition);
  if n = 0 or
   nr = 0 or
   not IsList(partition[1]) or
   IsEmpty(partition[1]) or
   not IsPosInt(partition[1][1]) then
    Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> is not a valid partition\n",
          "of the vertices of <digraph>, [ 1 .. ", n, " ],");
    return;
  fi;

  check := BlistList( DigraphVertices(digraph), [  ] );
  lookup := EmptyPlist(n);
  
  for x in [ 1 .. Length(partition) ] do
    for i in partition[x] do
      if i < 1 or i > n or check[i]  then
        Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> is not a valid partition\n",
          "of the vertices of <digraph>, [ 1 .. ", n, " ],");
        return;
      fi;
      check[i] := true;
      lookup[i] := x;
    od;
  od;
  
  if ForAny( check, x -> not x ) then
    Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> does not partition\n",
          "every vertex of the first argument, <digraph>,");
    return;
  fi;

  out := OutNeighbours(digraph);
  new := List( [ 1 .. nr ], x -> [ ] );
  for i in DigraphVertices(digraph) do
    for j in out[i] do
      Add(new[lookup[i]], lookup[j]);
    od;
  od;
  return DigraphNC(new);
  # Pass on information about <digraph> which might be relevant to gr?
end);

#

InstallMethod(DigraphOutEdges, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: DigraphOutEdges: usage,\n",
          v, " is not a vertex of the digraph,");
    return;
  fi;

  return List(OutNeighboursOfVertex(digraph, v), x -> [v, x]);
end);

#

InstallMethod(DigraphInEdges, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: DigraphInEdges: usage,\n",
          v, " is not a vertex of the digraph,");
    return;
  fi;

  return List(InNeighboursOfVertex(digraph, v), x -> [x, v]);
end);

#

InstallMethod(DigraphStronglyConnectedComponent, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  local scc;

  if not v in DigraphVertices(digraph) then
    Error("Digraphs: DigraphStronglyConnectedComponent: usage,\n",
          v, " is not a vertex of the digraph,");
    return;
  fi;

  scc := DigraphStronglyConnectedComponents(digraph);
  return scc.comps[scc.id[v]];
end);

#

InstallMethod(IsDigraphEdge, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, edge)
  local n;

  n := DigraphNrVertices(digraph);
  if Length(edge) <> 2 or
   not IsPosInt(edge[1]) or
   not IsPosInt(edge[2]) or
   n < edge[1] or
   n < edge[2] then
    return false;
  fi;
  if HasAdjacencyMatrix(digraph) then
    return AdjacencyMatrix(digraph)[edge[1]][edge[2]] <> 0;
  fi;
  if edge[2] in OutNeighboursOfVertex(digraph, edge[1]) then
    return true;
  fi;
  return false;
end);

#

InstallMethod(AsBinaryRelation, "for a digraph",
[IsDigraph],
function(digraph)
  local rel;
  
  if DigraphNrVertices(digraph) = 0 then
    Error("Digraphs: AsBinaryRelation: usage,\n",
          "the argument <digraph> must have at least one vertex,");
    return;
  elif IsMultiDigraph(digraph) then
    Error("Digraphs: AsBinaryRelation: usage,\n",
          "this function does not apply to digraphs with multiple edges,");
    return;
  fi;
  # Can translate known attributes of <digraph> to the relation, e.g. symmetry
  rel := BinaryRelationOnPointsNC(OutNeighbours(digraph));
  if HasIsReflexiveDigraph(digraph) then
    SetIsReflexiveBinaryRelation(rel, IsReflexiveDigraph(digraph));
  fi;
  if HasIsSymmetricDigraph(digraph) then
    SetIsSymmetricBinaryRelation(rel, IsSymmetricDigraph(digraph));
  fi;
  if HasIsTransitiveDigraph(digraph) then
    SetIsTransitiveBinaryRelation(rel, IsTransitiveDigraph(digraph));
  fi;
  if HasIsAntisymmetricDigraph(digraph) then
    SetIsAntisymmetricBinaryRelation(rel, IsAntisymmetricDigraph(digraph));
  fi;
  return rel;
end);

#

InstallMethod(DigraphDisjointUnion, "for two digraphs",
[IsDigraph, IsDigraph],
function(digraph1, digraph2)
  local nrvertices1, out2;

  nrvertices1 := DigraphNrVertices(digraph1);
  out2 := List(OutNeighbours(digraph2), x -> x + nrvertices1);

  return DigraphNC(Concatenation(OutNeighbours(digraph1), out2));
end);

#

InstallMethod(DigraphJoin, "for two digraphs",
[IsDigraph, IsDigraph],
function(digraph1, digraph2)
  local out1, out2, n, m, new, i;

  out1 := OutNeighbours(digraph1);
  out2 := OutNeighbours(digraph2);
  n := DigraphNrVertices(digraph1);
  m := DigraphNrVertices(digraph2);
  new := EmptyPlist(n + m);

  for i in DigraphVertices(digraph1) do
    new[i] := Concatenation(out1[i], [n + 1 .. n + m]); 
  od;
  for i in [ n + 1 .. n +  m ] do
    new[i] := Concatenation([ 1 .. n ], out2[i - n] + n);
  od;

  return DigraphNC(new);
end);

#

InstallMethod(IsReachable, "for a digraph and two pos ints",
[IsDigraph, IsPosInt, IsPosInt],
function(digraph, u, v)
  local verts, wcc, scc;

  verts := DigraphVertices(digraph);
  if not (u in verts and v in verts) then
    Error("Digraphs: IsReachable: usage,\n",
    "the second and third arguments <u> and <v> must be vertices\n",
    "of the first argument <digraph>,");
    return;
  fi;

  # If it's a known transitive digraph, just check whether the edge exists
  if HasIsTransitiveDigraph(digraph) and IsTransitiveDigraph(digraph) then
    return IsDigraphEdge(digraph, [ u, v ]);
  fi;
  
  # Glean information from WCC if we have it
  if HasDigraphConnectedComponents(digraph) then
    wcc := DigraphConnectedComponents(digraph);
    if wcc.id[u] <> wcc.id[v] then
      return false;
    fi;
  fi;

  # Glean information from SCC if we have it
  if HasDigraphStronglyConnectedComponents(digraph) then
    scc := DigraphStronglyConnectedComponents(digraph);
    if u <> v then
      if scc.id[u] = scc.id[v] then
        return true;
      fi;
    else
      if Length(scc.comps[scc.id[u]]) > 1 then
        return true;
      else
        return IsDigraphEdge(digraph, [u, u]);
      fi;
    fi;
  fi;

  # Glean information from adjacency matrix if we have it
  if HasAdjacencyMatrix(digraph) then
    if AdjacencyMatrix(digraph)[u][v] <> 0 then
      return true;
    fi;
  fi;

  Error("Digraphs: IsReachable: not yet implemented,");
  # return DIGRAPHS_IS_REACHABLE(digraph, u, v);
end);

#

InstallMethod(DigraphRemoveAllMultipleEdges, "for a digraph",
[IsDigraph],
function(digraph)
  local n, verts, nseen, old_adj, new_adj, tot, seen, count, gr, i, j;

  n := DigraphNrVertices(digraph);
  verts := DigraphVertices(digraph);
  old_adj := OutNeighbours(digraph);
  new_adj := EmptyPlist(n);
  tot := 0;
  for i in verts do
    seen := BlistList(verts, [  ]);
    count := 0;
    new_adj[i] := [  ];
    for j in old_adj[i] do
      if not seen[j] then
        seen[j] := true;
        count := count + 1;
        tot := tot + 1;
        new_adj[i][count] := j;
      fi;
    od;
  od;
  gr := DigraphNC(new_adj, tot);
  SetDigraphVertexLabels(gr, DigraphVertexLabels(digraph));
  return gr;
end);

#EOF
