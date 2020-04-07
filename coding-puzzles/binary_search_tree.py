#!/usr/bin/env python3

from typing import List


class Node:
    def __init__(self, left: 'Node', right: 'Node', val):
        self.left = left
        self.right = right
        self.val = val

    def insert(self, val):
        if val > self.val:
            if self.right is None:
                print(f"add {val} as new right node of {self.val}")
                self.right = Node(None, None, val)
            else:
                print(f"add {val} on the right of {self.val}")
                self.right.insert(val)
        else:
            if self.left is None:
                print(f"add {val} as new left node of {self.val}")
                self.left = Node(None, None, val)
            else:
                print(f"add {val} on the left of {self.val}")
                self.left.insert(val)

    def dfs(self, acc: List = []) -> List:
        if self.right is not None:
            self.right.dfs(acc)

        acc.append(self.val)

        if self.left is not None:
            self.left.dfs(acc)

        return acc

    def bfs(self) -> List:
        acc = []
        queue = []
        queue.append(self)
        acc.append(self.val)

        # while (len(queue) > 0):

        # return acc

    def is_valid(self, root) -> bool:
        return self.validate_tree(root, float('-inf'), float('inf'))

    def validate_tree(self, root, left_bound, right_bound):
        if root is None:
            return True

        return left_bound < root.val < right_bound \
            and self.validate_tree(root.left, left_bound, root.val) \
            and self.validate_tree(root.right, root.val, right_bound)

    def isBalanced(self, root, h=1) -> bool:
        if not root:
            return h
        l = self.isBalanced(root.left, h+1)
        if not l:
            return
        r = self.isBalanced(root.right, h+1)
        if not r:
            return
        return abs(l-r) <= 1 and max(l, r)

    def balance(self, root):
        v = []

        def dfs(node):
            if node:
                dfs(node.left)
                v.append(node.val)
                dfs(node.right)

        dfs(root)

        def bst(v):
            if not v:
                return None
            mid = len(v) // 2
            root = Node(None, None, v[mid])
            root.left = bst(v[:mid])
            root.right = bst(v[mid + 1:])
            return root

        return bst(v)


t = Node(None, None, 1)
# t.insert(4)
# t.insert(3)
# t.insert(13)
# t.insert(15)
# t.insert(14)
# t.insert(8)

# print(t.dfs())
# print(t.bfs())
t.insert(2)
t.insert(3)
t.insert(4)
print(t.balance(t))
