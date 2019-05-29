from flask import *

from werkzeug.utils import secure_filename
from fastai.vision import *

NO_FILE_STR = "No file uploaded."

app = Flask(__name__)

allowed_extensions = ['jpg', 'png', 'jpeg']
UPLOAD_FOLDER = "uploads"
MODEL_PATH = "python_model.pth"


def get_model():
    return load_learner('export.pkl')


model = get_model()

def predict_dog(path):
    category, class_idx, probs = model.predict(open_image(path))

    enum = [i for i in enumerate(probs)]
    sort = sorted(enum, key=lambda i: i[1]) # take a pair of (index,value) and sort it by value (at the first index)
    ret = [(LABELS[i[0]],i[1].item()) for i in sort]
    ret = ret[-3:] # get top three
    ret = ret[::-1] # reverse them, so the biggest is the first
    ret = str(ret)
    ret = ret[1:-1] # remove the [] from the string
    ret = ret.replace("'","").replace(", ",",").replace("(","").replace(")","") # remove other unwanted characters
    # the final output format:
    # label1,probability1,label2,probability2
    return ret


def file_allowed(file):
    return '.' in file and file.split('.')[-1].lower() in allowed_extensions


@app.route('/')
def homepage():
    return render_template("home.html")


def clean_category(cat):
    ret = cat
    sl = cat.split("-")
    if len(sl) >= 2:
        ret = sl[-1]
        ret = ret.replace("_", " ")

    return ret


LABELS = [clean_category(i) for i in model.data.classes]

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
        probs = str(predict_dog(filepath))
        os.remove(filepath)

        resp = make_response(render_template("probs.html"))
        print(probs)
        resp.set_cookie('probs', probs)
        return resp
    else:
        print("file not permitted")
        return "File extension is not permitted."


if __name__ == '__main__':
    print("hey")
    app.run(host='0.0.0.0', port=80)
