# Boldify and unboldify words to create and read a dimension out of an ascii code. 

bf_gap_uc = Int('𝐀') - Int('A')
bf_gap_lc = Int('𝐚') - Int('a')

boldify(s::AbstractString) = 
    map(c -> Char(Int(c) + ('a' ≤ c ≤ 'z') * bf_gap_lc + 
        ('A' ≤ c ≤ 'Z') * bf_gap_uc), s)

deboldify(s::AbstractString) = 
    map(c -> Char(Int(c) - ('𝐚' ≤ c ≤ '𝐳') * bf_gap_lc - 
    ('𝐀' ≤ c ≤ '𝐙') * bf_gap_uc), s)
