# Whats' That Doggie?
![The Flutter app](https://github.com/LoliamShely/Whats-That-Doggie/blob/master/simulator_detector.gif)<br><br>
![The Web app](https://github.com/LoliamShely/Whats-That-Doggie/blob/master/webapp_demo.gif)<br><br>
A web and mobile app that uses a deep learning model that can calssify a breed of a dog in a picture. <br>
The model can predict a dogs breed from 120 different dog breeds.
The repo is seperated into three parts:
* The notebook - model training & evaluation
* The server (flask & web app)
* The flutter app <br>

<b>Each part is separate, so when expirimenting with them - make sure to isolate them in different folders.<b>

## The notebook
In order to create the model, I used the [fastai](https://github.com/fastai/fastai) library and google colab.<br>
You can run the notebook as is - but you have to change you kaggle api username and password in the appropriate field.<br>
After the model was exported, I moved the exported file (export.pkl) to the <i>server<i> directory.<br>

## The server
The server side python script, implemented with flask and the web app.<br>
The server will be visible to everyone on the network on port 80.<br>
Contains a web app on the default route that enables the user to upload an image and see it's prediction in a nice graph.
When doing a post request to the server (that includes a multi-part image), it will do all the needed work to predict it - save it, load it, transform it, predict, and reformat the category to a nicer form.

## The app
The app is a cross platform, made with [flutter](https://github.com/flutter/flutter) and dart.<br>
It will not work properly on emulators, but it will on a phisical device. <br>
The device running the app must be on the same network as the server in order for it to connect. <br>
The server adress must be changed inside the app at /lib/main.dart at the <i>SERVER_URL<i> constant.
