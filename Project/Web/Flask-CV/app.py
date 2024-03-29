from flask import Flask,render_template

# Créez une instance de l'application Flask
app = Flask(__name__)

# Définissez une route et la fonction associée
@app.route('/')
def accueil():
    return render_template ("index.html")

if __name__ == '__main__':
    app.run(host:='0.0.0.0')
