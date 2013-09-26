ngx = {}

-- mock implementation of decode base64
function ngx.decode_base64(string)
  if string == "nokeyvalue" then
    return "usernamepassword"
  elseif string == "invalidusernamepwd" then
    return "username:password2"
  else
    return "username:password"
  end
end
