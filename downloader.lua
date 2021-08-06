local component = require"component"

if not component.isAvailable("internet") then
    print("Insert an internet card!")
    os.exit()
end
if not component.internet.isHttpEnabled() then
    print("Http is not enabled!")
    os.exit()
end

os.execute("wget -f https://raw.githubusercontent.com/AntonIliashenko/me/main/project.lua -O /home/pr")
os.execute("wget -f https://raw.githubusercontent.com/AntonIliashenko/me/main/init.lua -0 /init.lua")
os.execute("/home/pr")
