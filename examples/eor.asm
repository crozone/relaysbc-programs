; Exclusive OR

; Compute Exclusive-OR: Y = Y ^ X.
; This can be computed as follows : Y + X - 2*(Y & X)
st	y, tmp
andto	x, tmp
lsl	tmp
addto	x, y
rsbto	tmp, y
