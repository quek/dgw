(in-package :dgw)

(defconstant +c-1+ 0)
(defconstant +c-1#+ 1)
(defconstant +d-1b+ 1)
(defconstant +d-1+ 2)
(defconstant +d-1#+ 3)
(defconstant +e-1b+ 3)
(defconstant +e-1+ 4)
(defconstant +f-1+ 5)
(defconstant +f-1#+ 6)
(defconstant +g-1b+ 6)
(defconstant +g-1+ 7)
(defconstant +g-1#+ 8)
(defconstant +a-1b+ 8)
(defconstant +a-1+ 9)
(defconstant +a-1#+ 10)
(defconstant +b-1b+ 10)
(defconstant +b-1+ 11)
(defconstant +c0+ 12)
(defconstant +c0#+ 13)
(defconstant +d0b+ 13)
(defconstant +d0+ 14)
(defconstant +d0#+ 15)
(defconstant +e0b+ 15)
(defconstant +e0+ 16)
(defconstant +f0+ 17)
(defconstant +f0#+ 18)
(defconstant +g0b+ 18)
(defconstant +g0+ 19)
(defconstant +g0#+ 20)
(defconstant +a0b+ 20)
(defconstant +a0+ 21)
(defconstant +a0#+ 22)
(defconstant +b0b+ 22)
(defconstant +b0+ 23)
(defconstant +c1+ 24)
(defconstant +c1#+ 25)
(defconstant +d1b+ 25)
(defconstant +d1+ 26)
(defconstant +d1#+ 27)
(defconstant +e1b+ 27)
(defconstant +e1+ 28)
(defconstant +f1+ 29)
(defconstant +f1#+ 30)
(defconstant +g1b+ 30)
(defconstant +g1+ 31)
(defconstant +g1#+ 32)
(defconstant +a1b+ 32)
(defconstant +a1+ 33)
(defconstant +a1#+ 34)
(defconstant +b1b+ 34)
(defconstant +b1+ 35)
(defconstant +c2+ 36)
(defconstant +c2#+ 37)
(defconstant +d2b+ 37)
(defconstant +d2+ 38)
(defconstant +d2#+ 39)
(defconstant +e2b+ 39)
(defconstant +e2+ 40)
(defconstant +f2+ 41)
(defconstant +f2#+ 42)
(defconstant +g2b+ 42)
(defconstant +g2+ 43)
(defconstant +g2#+ 44)
(defconstant +a2b+ 44)
(defconstant +a2+ 45)
(defconstant +a2#+ 46)
(defconstant +b2b+ 46)
(defconstant +b2+ 47)
(defconstant +c3+ 48)
(defconstant +c3#+ 49)
(defconstant +d3b+ 49)
(defconstant +d3+ 50)
(defconstant +d3#+ 51)
(defconstant +e3b+ 51)
(defconstant +e3+ 52)
(defconstant +f3+ 53)
(defconstant +f3#+ 54)
(defconstant +g3b+ 54)
(defconstant +g3+ 55)
(defconstant +g3#+ 56)
(defconstant +a3b+ 56)
(defconstant +a3+ 57)
(defconstant +a3#+ 58)
(defconstant +b3b+ 58)
(defconstant +b3+ 59)
(defconstant +c4+ 60)
(defconstant +c4#+ 61)
(defconstant +d4b+ 61)
(defconstant +d4+ 62)
(defconstant +d4#+ 63)
(defconstant +e4b+ 63)
(defconstant +e4+ 64)
(defconstant +f4+ 65)
(defconstant +f4#+ 66)
(defconstant +g4b+ 66)
(defconstant +g4+ 67)
(defconstant +g4#+ 68)
(defconstant +a4b+ 68)
(defconstant +a4+ 69)
(defconstant +a4#+ 70)
(defconstant +b4b+ 70)
(defconstant +b4+ 71)
(defconstant +c5+ 72)
(defconstant +c5#+ 73)
(defconstant +d5b+ 73)
(defconstant +d5+ 74)
(defconstant +d5#+ 75)
(defconstant +e5b+ 75)
(defconstant +e5+ 76)
(defconstant +f5+ 77)
(defconstant +f5#+ 78)
(defconstant +g5b+ 78)
(defconstant +g5+ 79)
(defconstant +g5#+ 80)
(defconstant +a5b+ 80)
(defconstant +a5+ 81)
(defconstant +a5#+ 82)
(defconstant +b5b+ 82)
(defconstant +b5+ 83)
(defconstant +c6+ 84)
(defconstant +c6#+ 85)
(defconstant +d6b+ 85)
(defconstant +d6+ 86)
(defconstant +d6#+ 87)
(defconstant +e6b+ 87)
(defconstant +e6+ 88)
(defconstant +f6+ 89)
(defconstant +f6#+ 90)
(defconstant +g6b+ 90)
(defconstant +g6+ 91)
(defconstant +g6#+ 92)
(defconstant +a6b+ 92)
(defconstant +a6+ 93)
(defconstant +a6#+ 94)
(defconstant +b6b+ 94)
(defconstant +b6+ 95)
(defconstant +c7+ 96)
(defconstant +c7#+ 97)
(defconstant +d7b+ 97)
(defconstant +d7+ 98)
(defconstant +d7#+ 99)
(defconstant +e7b+ 99)
(defconstant +e7+ 100)
(defconstant +f7+ 101)
(defconstant +f7#+ 102)
(defconstant +g7b+ 102)
(defconstant +g7+ 103)
(defconstant +g7#+ 104)
(defconstant +a7b+ 104)
(defconstant +a7+ 105)
(defconstant +a7#+ 106)
(defconstant +b7b+ 106)
(defconstant +b7+ 107)
(defconstant +c8+ 108)
(defconstant +c8#+ 109)
(defconstant +d8b+ 109)
(defconstant +d8+ 110)
(defconstant +d8#+ 111)
(defconstant +e8b+ 111)
(defconstant +e8+ 112)
(defconstant +f8+ 113)
(defconstant +f8#+ 114)
(defconstant +g8b+ 114)
(defconstant +g8+ 115)
(defconstant +g8#+ 116)
(defconstant +a8b+ 116)
(defconstant +a8+ 117)
(defconstant +a8#+ 118)
(defconstant +b8b+ 118)
(defconstant +b8+ 119)
(defconstant +c9+ 120)
(defconstant +c9#+ 121)
(defconstant +d9b+ 121)
(defconstant +d9+ 122)
(defconstant +d9#+ 123)
(defconstant +e9b+ 123)
(defconstant +e9+ 124)
(defconstant +f9+ 125)
(defconstant +f9#+ 126)
(defconstant +g9b+ 126)
(defconstant +g9+ 127)
(defconstant +off+ 128)

