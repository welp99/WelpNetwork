import pytest
from flask import template_rendered
from contextlib import contextmanager

from app import app as flask_app  # Assurez-vous d'importer votre application Flask correctement

@pytest.fixture
def app():
    yield flask_app

@pytest.fixture
def client(app):
    return app.test_client()

@contextmanager
def captured_templates(app):
    recorded = []
    def record(sender, template, context, **extra):
        recorded.append((template, context))
    template_rendered.connect(record, app)
    try:
        yield recorded
    finally:
        template_rendered.disconnect(record, app)

def test_home_page(client):
    with captured_templates(flask_app) as templates:
        response = client.get('/')
        assert response.status_code == 200
        assert len(templates) == 1
        template, context = templates[0]
        assert template.name == 'index.html'
        # Testez la présence de certains éléments dans le HTML
        assert b'Joan LARCHER' in response.data
        assert b'Production IT Engineer' in response.data
        assert b'href="https://www.linkedin.com/in/joan-larcher-nine-nine"' in response.data
