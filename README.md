# Whats' That Doggie?
A deep learning based app, that can calssify a breed of a dog inside a picture. <br>
The model can predict a dogs breed from 120 different dog breeds.
The repo is seperated into three parts:
* The notebook - model creation
* The server
* The flutter app <br>

## The notebook
In order to create the model, I used the [fastai](https://github.com/fastai/fastai) library and google colab.<br>
You can run the notebook as it is - but you have to change you kaggle api username and password.<br>
After the model exported, I moved the exported file (export.pkl) to the server directory.<br>

## The server
The server side python script, implemented with flask.<br>
The server will be visible to everyone on the network on port 80.<br>
The server contains a web app on the default route that enables the user to upload an image and see it's prediction.
When doing a post request to the server (that includes a multi-part image), it will do all the needed work to predict it - save it, load it, transform it, predict, and reformat the category to a nicer form.

## The app
The app is a cross platform, made with [flutter](https://github.com/flutter/flutter) and dart.<br>
It will not work properly on emulators. <br>
The device running the app must be on the same network as the server in order for it to connect to it. <br>
The server adress must be changed inside the app at /lib/main.dart at the SERVER_URL constant.

## To do
* Do more refactoring
* Add more comments
* Improve the ui of the web app, maybe redesign with a react
