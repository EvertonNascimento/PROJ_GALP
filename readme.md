
All environment variables have to be setup before running

To run:

Set environment variable LOCATION to where the folder proj is located
ex: C:\Users\example-user\Desktop\AWS\GALP\proj

To deploy environment:
make -f makefile apply

environment will be setup and terraform will run the deploy


To destroy environment:
make -f makefile destroy
