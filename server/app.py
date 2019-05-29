from flask import *
from werkzeug.utils import secure_filename
from fastai.vision import *
import string

NO_FILE_STR = "No file uploaded."

app = Flask(__name__)

allowed_extensions = ['jpg', 'png', 'jpeg']
UPLOAD_FOLDER = "uploads"
MODEL_PATH = "python_model.pth"


def get_model():
    return load_learner('export.pkl')


model = get_model()


def predict_dog(path):
    category = model.predict(open_image(path))[0]
    return str(category)


def file_allowed(file):
    return '.' in file and file.split('.')[-1].lower() in allowed_extensions


@app.route('/')
def homepage():
    return render_template("home.html")


def clean_category(cat):
    ret = cat
    sl = cat.split("-")
    if len(sl) == 2:
        ret = sl[1]
        ret = ret.replace("_", " ")

    return ret
@app.route('/', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        print("request does not contain a file.")
        return NO_FILE_STR
    file = request.files['file']
    if file.filename == '':
        print("filename==nothing")
        return NO_FILE_STR
    if file_allowed(file.filename):
        print("file allowed")
        filename = secure_filename(file.filename)
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        print(filename + " uploaded successfully.")
        filepath = UPLOAD_FOLDER + "/" + filename
        prediction = predict_dog(filepath)
        prediction = clean_category(prediction)
        os.remove(filepath)
        return prediction
    else:
        print("file not permitted")
        return "File extension is not permitted."


if __name__ == '__main__':
    print("hey")
    app.run(host='0.0.0.0', port=80)
