local matrix = {}
return function (m)
  if type(m) == "table" then return m end

  for i=1, 16 do
    matrix[i]=m[i]
  end

  return matrix
end