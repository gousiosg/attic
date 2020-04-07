#!/usr/bin/env python3

from typing import List
import math

def quicksort(input: List, low, high) -> List:

    if low < high:
        j = partition(input, low, high)
        quicksort(input, low, j - 1)
        quicksort(input, j + 1, high)

    return input

def quicksort_nonrecurcive(input, low, high) -> List:
    stack = []
    stack.append([low, high])

    while stack:
        l, h = stack.pop()
        pivot = partition(input, l, h)

        if pivot - 1 > l:
            stack.append([l, pivot - 1])

        if pivot + 1 < h:
            stack.append([pivot + 1, h])
    
    return input

def partition(arr: List, low: int, high: int) -> int:
    pivot = arr[high]
    i = (low - 1)

    for j in range(low, high):
        if arr[j] <= pivot:
            i = i + 1
            arr[i], arr[j] = arr[j], arr[i]
    
    arr[i+1],arr[high] = arr[high],arr[i+1]
    return i + 1


def mergesort(input: List) -> List:
    if len(input) == 1:
        return input

    mid = math.floor(len(input) / 2)
    print(f"split: {input[0:mid]} {input[mid:]}")
    
    return merge(mergesort(input[0:mid]), mergesort(input[mid:]))

def mergesort_nonrecursive(input: List) -> List:
    merge_len_stride = 1
    merge_len = pow(2, merge_len_stride)

    while merge_len < 2 * len(input):
        output = []
        for i in range(0, len(input), merge_len):
            to_merge = input[i : i + merge_len]
            middle = len(to_merge) // 2
            left = to_merge[0:middle]
            right = to_merge[middle:]
            print(f"split: {left} {right}")
            output.extend(merge(left, right))

        print(f"output: {output}")
        input = output
        merge_len_stride += 1
        merge_len = pow(2, merge_len_stride)

    return input

def merge(a: List, b: List) -> List:
    
    result = []
    a_index, b_index = 0, 0

    while a_index < len(a) and b_index < len(b):
        if a[a_index] < b[b_index]:
            result.append(a[a_index])
            a_index += 1
        elif b[b_index] < a[a_index]:
            result.append(b[b_index])
            b_index += 1
        else:
            result.append(b[b_index])
            result.append(a[a_index])
            a_index += 1
            b_index += 1

    if a_index < len(a):
        result.extend(a[a_index: ])

    if b_index < len(b):
        result.extend(b[b_index: ])
    print(f"merge: {a} {b} -> {result} ")
    return result

#print(merge([1], [1, 2]))
#print(merge([4], [5, -2]))


a = [9, 3, 7, 5, 6, 4, 8]
print(quicksort(a, 0, len(a) - 1))
print(quicksort_nonrecurcive(a, 0, len(a) - 1))
#print(mergesort_nonrecursive(a))
#print(mergesort(a))
#assert(mergesort(a) == [1,2,3,4,5,6])
#assert(quicksort(a) == [1,2,3,4,5,6])

#b = [-1,2,0,1,3]
#print(mergesort_nonrecursive(b))
#assert(mergesort(b) == [-1,0,1,2,3])
# assert(quicksort(a) == [-1,0,1,2,3])