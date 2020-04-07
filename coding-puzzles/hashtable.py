#!/usr/bin/env python3

class HashTable:
    def __init__(self, init_buckets = 10, hash_func = hash):
        self.buckets = [None] * init_buckets
        self.num_buckets = init_buckets
        self.hash_func = hash_func

    def _get_bucket(self, key):
        hash_code = self.hash_func(key)
        return hash_code % self.num_buckets


    def put(self, key, data):
        bucket = self._get_bucket(key)

        if self.buckets[bucket] == None:
            self.buckets[bucket] = []

        for item in self.buckets[bucket]:
            if item[0] == key:
                item[1] = data
                return

        self.buckets[bucket].append([key, data])

    def get(self, key):
        bucket = self._get_bucket(key)

        if self.buckets[bucket] == None:
            return None
        
        for item in self.buckets[bucket]:
            if item[0] == key:
                return item

        return None

    def remove(self, key):
        bucket = self._get_bucket(key)

        new_bucket_content = [None] * (len(self.buckets[bucket]) - 1)
        idx = 0
        for item in self.buckets[bucket]:
            if not item[0] == key:
                new_bucket_content[idx]= item
                idx += 1

        self.buckets[bucket] =  new_bucket_content   

    def print(self):
        # print(self.buckets)
        for bucket_idx in range(0, len(self.buckets)):
            print(f"{bucket_idx} -> {self.buckets[bucket_idx]}")


h = HashTable(10)

h.put(12, "twelve")
h.put(12, "ten")
h.put(22, "twenty two")
h.put(1, "one")
h.put(9, "nine")
#print(h.get(12))
#print(h.get(24))

h.print()
