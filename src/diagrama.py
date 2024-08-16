# diagram.py
#meu__app.png
from diagrams import Diagram, Cluster
from diagrams.aws.compute import EC2, Lambda
from diagrams.aws.database import RDS
from diagrams.aws.network import ELB, APIGateway
from diagrams.aws.integration import SQS, Eventbridge
from diagrams.aws.general import Client, MobileClient
from diagrams.aws.storage import S3
# from diagrams.programming.framework import React

with Diagram("Meu App", show=True):

    #Declaração dos componentes (fora dos clusters)
    api = APIGateway("API Gateway")
    evento = Eventbridge("EventBridge")

    #Declaração dos componentes (dentro do cluster front end)
    with Cluster ("Front end"):
      source1 = Client("Cliente web")
      source2 = MobileClient("Celular")

    with Cluster("Fluxo"):
      #Declaração dos componentes (dentro do cluster fluxo)
      lb = ELB("Load Balancer")
      services = Lambda("Serviços")
      db = RDS("DB")
      bucket = S3("Bucket")


    #Ordem
    [source1, source2] >> api >> evento >> lb >> services >> [db, bucket]
    db >> api >> evento >> [source1, source2]