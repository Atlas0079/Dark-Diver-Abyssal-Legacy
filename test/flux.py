import http.client
import json

conn = http.client.HTTPSConnection("api2.aigcbest.top")
payload = json.dumps({
   "model": "flux.1.1-pro",
   "prompt": "A mature female character in anime style standing and slightly sideways, gazing at the audience. She has short black hair with red tips and deep purple eyes. She was wearing a black witch hat, paired with a cape style scarf, and a loose skirt with lantern pants style, with a simple design and complete sleeves. The overall clothing style is loose and simple. The background is white.",
   "size": "1024x1536"
})
headers = {
   'Authorization': 'Bearer sk-a04PXgGnnluQ4SSB13C9Ae46771f4230B0Fc1a547eA938D0',
   'Accept': 'application/json',
   'Content-Type': 'application/json'
}
conn.request("POST", "/v1/images/generations", payload, headers)
res = conn.getresponse()
data = res.read()
print(data.decode("utf-8"))