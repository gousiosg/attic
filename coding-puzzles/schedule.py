#!/usr/bin/env python3

from typing import List

def num_rooms(schedule: List[List[float]]) -> int:

    sorted_timestamps = sorted(list(set([time for times in schedule for time in times])))
    required_rooms = [0 for i in range(0, len(sorted_timestamps))]

    for timeslot in schedule:
        for i in range(0, len(sorted_timestamps) - 1):
            if sorted_timestamps[i] >= timeslot[0] and sorted_timestamps[i] < timeslot[1]:
                required_rooms[i] += 1

    return max(required_rooms)


schedule = [
    [1, 2],
    [2, 3],
    [2, 5],
    [1, 4],
    [5, 6]
]
assert(num_rooms(schedule) == 3)

schedule = [
    [1, 2],
    [2.15, 2.30],
    [2.20, 2.30],
    [2, 3],
    [2, 5],
    [1, 4],
    [5, 6]
]
assert(num_rooms(schedule) == 5)
