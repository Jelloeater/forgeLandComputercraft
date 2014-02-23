
os.loadAPI("/bb/api/json")
str = http.get("http://json-time.appspot.com/time.json").readAll()
obj = json.decode(str)
print(obj.firstline)
