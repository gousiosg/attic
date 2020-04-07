from typing import List

# The function first discards as many whitespace characters as
#  necessary until the first non-whitespace character is found.
# Then, starting from this character, takes an optional initial
# plus or minus sign followed by as many numerical digits as possible,
# and interprets them as a numerical value.


def atoi(str: str) -> int:

    in_number: bool = False
    numbers = {
        '1': 1,
        '2': 2,
        '3': 3,
        '4': 4,
        '5': 5,
        '6': 6,
        '7': 7,
        '8': 8,
        '9': 9,
        '0': 0
    }
    result = []
    multiplier = 1
    prev = ''

    for c in str:
        if c not in numbers.keys():
            if in_number:
                break
            in_number = False
            prev = c
        else:
            in_number = True
            if prev == '-':
                multiplier = -1

            prev = c
            result.append(c)

    num_result = numbers[result.pop()]
    for c in range(1, len(result) + 1):
        num_result += 10**c * numbers[result.pop()]

    return num_result * multiplier


assert(atoi("42") == 42)
assert(atoi('  -42') == -42)
assert(atoi("My name 123 is") == 123)
assert(atoi("4193 with words") == 4193)


def reverse_string(s: List[str]) -> None:
    i = 0
    j = len(s) - 1
    while i < j:
        tmp = s[i]
        s[i] = s[j]
        s[j] = tmp

        i += 1
        j -= 1
    return s


assert(reverse_string(["H", "a", "n", "n", "a", "h"])
       == ["h", "a", "n", "n", "a", "H"])


# reverse integer: 123 -> 321, -123 -> -321
def reverse_int(x: int) -> int:
    if x >= 0:
        s = list(str(x))
        multiplier = 1
    else:
        s = list(str(-x))
        multiplier = -1

    i = 0
    j = len(s) - 1

    while i < j:
        tmp = s[i]
        s[i] = s[j]
        s[j] = tmp

        i += 1
        j -= 1

    result = 0
    for x in range(len(s)):
        result += 10 ** (len(s) - x - 1) * int(s[x])
        if result >= 2**31:
            return 0

    return result * multiplier


assert(reverse_int(123) == 321)
assert(reverse_int(-123) == -321)


def first_uniq_char(s: str) -> int:
    chars = list(s)
    found = False

    for i in range(len(chars)):
        found = False
        for j in range(i + 1, len(chars[i:])):
            if chars[i] == chars[j]:
                found = True
                break

        if found == False:
            return i


assert(first_uniq_char("leetcode") == 0)
assert(first_uniq_char("loveleetcode") == 2)


# Given two strings s and t , write a function to determine if t is an anagram of s.
def is_anagram(s: str, t: str) -> bool:
    sorted_s = sorted(list(s))
    sorted_t = sorted(list(t))

    return sorted_s == sorted_t


assert(is_anagram("anagram", "nagaram") == True)
assert(is_anagram("rat", "car") == False)


def is_palindrome(s: str) -> bool:
    chars = list(s)

    def is_alnum(c) -> bool:
        if 'a' <= c and c <='z':
            return True

        if 'A' <= c and c <= 'Z':
            return True

        if '0' <= c and c <= '9':
            return True

        return False

    i = 0
    j = len(chars) - 1

    while i < j:
        print(f"i:{i}, c: {chars[i]}, j:{j}, c: {chars[j]}")       

        while not is_alnum(chars[i]) and i < j:
            i += 1

        while not is_alnum(chars[j]) and j < i:
            j -= 1

        print(f"i:{i}, c: {chars[i]}, j:{j}, c: {chars[j]}")       
        #print(f"i:{i}, c: {chars[i]}, j:{j}, c: {chars[j]}")       

        if not str(chars[i]).lower() == str(chars[j]).lower():
            return False

        i += 1
        j -= 1

    return True

# assert(is_palindrome("ab  ba") == True)
# assert(is_palindrome("A man, a plan, a canal: Panama") == True)
#assert(is_palindrome("race a car") == False)
# assert(is_palindrome(".,") == False)

#Write a function to find the longest common prefix string amongst an array of strings.
#If there is no common prefix, return an empty string "".
def longestCommonPrefix(strs: List[str]) -> str:
    if not strs: return ""
    if len(strs) == 1: return strs[0]
    
    prefix=[]
    num = len(strs)
    for x in zip(*strs):
        print(x)
        if len(set(x)) == 1:
            prefix.append(x[0])
        else:
            break
    return "".join(prefix)

longestCommonPrefix(["flower","flow","flight"])

# Longest common subsequence
def lcs(xstr: str, ystr: str) -> str:
    print(f"{xstr} {ystr}")
    if not xstr or not ystr:
        return ""
    x, xs, y, ys = xstr[0], xstr[1:], ystr[0], ystr[1:]
    if x == y:
        return x + lcs(xs, ys)
    else:
        return max(lcs(xstr, ys), lcs(xs, ystr), key=len)

print(lcs("foobar", "f00bar"))


# Given a sequence of words written in the alien language, 
# and the order of the alphabet, return true if and only if 
# the given words are sorted lexicographicaly in this alien language.
def isAlienSorted(self, words: List[str], order: str) -> bool:
    
    word_order = {c: i for i, c in enumerate(order)}

    for w in zip(list(words), list(words)[1:]):
        for c in zip(list(w[0]), list(w[1])):
            
            if c[1] != c[0]:
                print(f"{c[0]}, {c[1]}")
                if word_order[c[1]] < word_order[c[0]]:
                    return False
                else:
                    break

        if len(w[0]) > len(w[1]):
            return False
    return True

