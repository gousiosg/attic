#!/usr/bin/env python3

import queue as q
from typing import List

class Node():
    def __init__(self, value):
        self.visited = False
        self.neighbours: List[Node] = []
        self.value = value

    def __repr__(self):
        return str(self.value)

class Graph():
    def __init__(self, nodes):
        self.nodes: List[Node] = nodes

    def reset(self):
        for n in self.nodes:
            n.visited = False

    def bfs(self, n_start: Node) -> List[Node]:
        result = []
        work_queue = q.Queue()
        work_queue.put(n_start)

        result.append(n_start)
        n_start.visited = True
        while not work_queue.empty():
            cur = work_queue.get()

            for n in cur.neighbours:
                if not n.visited:
                    work_queue.put(n)
                    n.visited = True
                    result.append(n)

        return result

    def dfs(self, n_start: Node) -> List[Node]:
        result = []
        result.append(n_start)
        n_start.visited = True

        for n in n_start.neighbours:
            if not n.visited:
                for r in self.dfs(n):
                    result.append(r)

        return result

    def topo_visit(self, node, stack = [], visited : set = set()) -> List[Node]:
        if node not in visited:
            visited.add(node)
            for neighbour in node.neighbours:
                self.topo_visit(neighbour, stack, visited)

            stack.append(node)

    def topo(self):
        stack = []
        visited = set()

        for node in self.nodes:
            self.topo_visit(node, stack, visited)

        return stack

a, b, c, d, e, f =  Node("A"), Node("B"), Node("C"), Node("D"), Node("E"), Node("F")
h = Node("H")
a.neighbours = [b, c, e]
b.neighbours = [d, a]
c.neighbours = [a, d, h]
d.neighbours = [b, c, f]
e.neighbours = [a]
f.neighbours = [d]
h.neighbours = [c, f]

#g = Graph([a, b, c, d, e, f, h])

#assert(g.bfs(a) == ['A', 'B', 'C', 'E', 'D', 'H', 'F'])
#assert(g.bfs(h) == ['H', 'C', 'F', 'A', 'D', 'B', 'E'])
#print(f"BFS from A:{g.bfs(a)}")
#print(f"BFS from A:{g.dfs(a)}")

a.neighbours = [b, c, e]
b.neighbours = [d]
c.neighbours = [h, d]
d.neighbours = [f]
e.neighbours = []
f.neighbours = []
h.neighbours = [f]

g = Graph([a, b, c, d, e, f, h])
print(f"Topological sort:{g.topo()}")
