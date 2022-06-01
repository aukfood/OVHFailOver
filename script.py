import json
import ovh  

client = ovh.Client()

idProject = "36ed74da46894d3c86a7f54e19650856"

instance = client.get('/cloud/project/'+idProject+'/instance')
idInstance1 = instance[0]["id"]
idInstance2 = instance[1]["id"]

result = client.get('/cloud/project/'+idProject+'/ip/failover')
idIp = result[0]["id"]
routedToInstance = result[0]["routedTo"]

if(routedToInstance==idInstance1):
    client.post('/cloud/project/'+idProject+'/ip/failover/'+idIp+'/attach', InstanceId=idInstance2)

elif(routedToInstance==idInstance2):
    client.post('/cloud/project/'+idProject+'/ip/failover/'+idIp+'/attach', InstanceId=idInstance1)
else : 
    print("fail ip routedTo")
