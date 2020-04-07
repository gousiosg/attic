from typing import List


## Davide
# Given a string of parenthesis, return the indexes of the parenthesis 
# you should remove from the string to make it valid.
# Examples:
# (())) -> 2 or 3 or 4
# (()()() -> 0 or 1 or 3 or 5
# ()()(( -> 4 and 5
def isParenthesis(c): 
    return ((c == '(') or (c == ')'))  
  
# method returns true if contains valid  
# parenthesis  
def isValidString(str): 
    cnt = 0
    for i in range(len(str)): 
        if (str[i] == '('): 
            cnt += 1
        elif (str[i] == ')'): 
            cnt -= 1
        if (cnt < 0): 
            return False
    return (cnt == 0) 
      
def balanced_parentheses(str): 
    if (len(str) == 0): 
        return
          
    # visit set to ignore already visited  
    visit = set() 
      
    # queue to maintain BFS 
    q = [] 
    temp = 0
    level = 0
      
    # pushing given as starting node into queu 
    q.append(str) 
    visit.add(str) 
    while(len(q)): 
        str = q[0] 
        q.pop() 
        if (isValidString(str)): 
            print(str) 
              
            # If answer is found, make level true  
            # so that valid of only that level  
            # are processed.  
            level = True
        if (level): 
            continue
        for i in range(len(str)): 
            if (not isParenthesis(str[i])): 
                continue
                  
            # Removing parenthesis from str and  
            # pushing into queue,if not visited already  
            temp = str[0:i] + str[i + 1:]  
            if temp not in visit: 
                q.append(temp) 
                visit.add(temp)

    return list(filter(lambda x: isParenthesis(x), visit))

print(balanced_parentheses("()())()"))

# assert(parentheses("(()))"), [2,3,4])
# assert(parentheses("(()()()"), [0, 1, 2, 3])
# assert(parentheses("()()(("), [4, 5])

def longest_valid_parentheses(s: str) -> int:
        stack = [-1]
        maxlen = 0
        
        for i in range(len(s)):
            
            if s[i] == '(':
                stack.append(i)
            else:
                stack.pop()
                if len(stack) == 0:
                    stack.append(i)
                curlen = i - stack[-1]
                #print(curlen)
                if curlen > maxlen:
                    maxlen = curlen
            #print(f"{i}, {s[i]}, {stack}")
        return maxlen

assert(longest_valid_parentheses("(()") == 2)
assert(longest_valid_parentheses("(())(()") == 4)


# Given a string containing just the characters '(', ')', '{', '}', 
#  '[' and ']', determine if the input string is valid.

# An input string is valid if:

# Open brackets must be closed by the same type of brackets.
# Open brackets must be closed in the correct order.
# Note that an empty string is also considered valid.
def is_balanced_paren(s: str) -> bool:
    stack = []
    open_symbols = set(['[', '{', '('])

    for i in range(len(s)):
        if s[i] in open_symbols:
            stack.append(s[i])
        else:
            if len(stack) == 0:
                return False

            c = stack.pop()
            if c == '[' and s[i] != ']':
                return False
            elif c == '{' and s[i] != '}':
                return False
            elif c == '(' and s[i] != ')':
                return False
            else:
                pass

    if len(stack) > 0:
        return False
    return True

assert(is_balanced_paren("([])") == True)
assert(is_balanced_paren("([{])") == False)


def minAddToMakeValid(s: str):
        stack = []
        unbalanced = 0
        for symbol in list(s):
            if symbol == "(":
                stack.append(symbol)
            else:
                if len(stack) == 0:
                    unbalanced += 1
                else:
                    stack.pop()
        return unbalanced + stack.size()


def minRemoveToMakeValid(s: str):
    left = []
    right = []
    
    for i in range(len(s)):
        if s[i] == '(':
            left.append(i)
        if s[i] == ')':
            if len(left) == 0:
                right.append(i)
            else:
                left.pop()
    
    res = []
    invalid_set = set(left + right)
    
    for i in range(len(s)):
        if i not in invalid_set:
            res.append(s[i])
    
    return ''.join(res)