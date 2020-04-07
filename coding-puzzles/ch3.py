#!/usr/bin/env python3
import random

class Stack_3_2():
    def __init__(self, init_size = 10):
        self.stack_size = init_size
        self.back_arr = [None] * init_size
        self.head = 0

    def push(self, num):
        if self.head == 0:
            minimum = num
        else:
            minimum = min(self.back_arr[self.head - 1][1], num)

        self.back_arr[self.head] = [num, minimum]
        self.head += 1

        if self.head >= self.stack_size - 1:
            self.stack_size *= 2
            new_arr = [None] * self.stack_size
            for i in range(0, len(self.back_arr)):
                new_arr[i] = self.back_arr[i]

            self.back_arr = new_arr

    def pop(self):
        head = self.back_arr[self.head]
        self.back_arr[self.head] = None
        self.head -= 1
        return head

    def minimum(self):
        return self.back_arr[self.head - 1][1]

# s = Stack_3_2()
# s.push(12)
# s.push(11)
# s.push(5)
# print(s.back_arr)
# s.push(3)
# print(s.back_arr)
# s.pop()
# s.push(2)
# s.push(5)
# s.push(11)
# print(s.back_arr)
# print(s.minimum())


# class Queue_3_4():
#     def __init__(self, init_size = 10):
#         self.

#     def enqueue(self, num):
        

#     def dequeue(self):
        