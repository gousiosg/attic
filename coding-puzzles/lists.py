#!/usr/bin/env python

class ListNode:
    def __init__(self, x):
        self.val = x
        self.next = None


# Given a singly linked list, determine if it is a palindrome.
def is_palindrome(head: ListNode) -> bool:
        stack = []
        
        cur = head
        while cur is not None:
            stack.append(cur.val)
            cur = cur.next

        cur = head
        while cur is not None:
            if cur.val != stack.pop():
                return False
            cur = cur.next
            
        return True

# Partition a list given a value
def partition(head: ListNode, x: int) -> ListNode:

    before = before_head = ListNode(0)
    after = after_head = ListNode(0)

    while head:
        if head.val < x:
            before.next = head
            before = before.next
        else:
            after.next = head
            after = after.next

        head = head.next

    after.next = None
    before.next = after

    return before

l1, l2, l3, l4 = ListNode(1), ListNode(2), ListNode(2), ListNode(1)

l1.next = l2
l2.next = l3
l3.next = l4

assert(is_palindrome(l1) == True)
