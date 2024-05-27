import os
import markdown
from markdown.extensions.codehilite import CodeHiliteExtension
import json
from datetime import datetime
from urllib import request
from urllib.parse import urlencode
import os
import requests
from dotenv import load_dotenv
from flask import Flask, request, redirect, session, Response, jsonify
import pygments
from flask import Flask, send_from_directory, render_template
from dotenv import load_dotenv
import random

load_dotenv()  # Load environment variables from .env file

app = Flask(__name__)
app.secret_key = os.getenv('FLASK_KEY')
CLIENT_ID = os.getenv('SPOTIFY_CLIENT_ID')
CLIENT_SECRET = os.getenv('SPOTIFY_SECRET_ID')
ENVIRONMENT = os.getenv('ENVIRONMENT')
REDIRECT_URI_LOCAL = 'http://127.0.0.1:5000/callback'
REDIRECT_URI_REMOTE = 'http://18.156.114.112/callback'
REDIRECT_URI = REDIRECT_URI_REMOTE if ENVIRONMENT == 'production' else REDIRECT_URI_LOCAL
SCOPE = ('user-read-private user-read-email user-library-read user-top-read playlist-modify-public '
         'playlist-modify-private')

STATE_KEY = 'spotify_auth_state'
AUTH_URL = 'https://accounts.spotify.com/authorize'
TOKEN_URL = 'https://accounts.spotify.com/api/token'
API_BASE_URL = 'https://api.spotify.com/v1/'


@app.route("/")
def index():
    return render_template('welcome.html')


@app.route("/logout")
def logout():
    return redirect('/')


@app.route("/home")
def home():
    timestamp = session.get('expires_at')
    if not timestamp:
        return redirect('/login')
    return render_template('home.html')


@app.route("/login")
def login():
    query_params = {
        'client_id': CLIENT_ID,
        'response_type': 'code',
        'scope': SCOPE,
        'redirect_uri': REDIRECT_URI,
        'show_dialog': 'true'
    }
    auth_url = f"{AUTH_URL}?{urlencode(query_params)}"
    return redirect(auth_url)


@app.route("/callback")
def callback():
    # Check for errors in the query parameters
    if 'error' in request.args:
        return request.args['error']

    # Proceed if we have the authorization code from Spotify
    if 'code' in request.args:
        req_body = {
            'code': request.args['code'],
            'grant_type': 'authorization_code',
            'redirect_uri': REDIRECT_URI,
            'client_id': CLIENT_ID,
            'client_secret': CLIENT_SECRET
        }
        print("Callback request body: ", req_body)
        response = requests.post(TOKEN_URL, data=req_body)

        # Check if the request was successful
        if response.status_code != 200:
            return f"Failed to retrieve access token, error: {response.text}", response.status_code

        token_info = response.json()

        # Store the tokens and expiration in the session
        session['access_token'] = token_info.get('access_token')
        session['refresh_token'] = token_info.get('refresh_token')
        session['expires_at'] = datetime.now().timestamp() + token_info.get('expires_in', 3600)  # Default to 1 hour
        # if not specified

        return redirect('/home')

    return "No code provided, please try logging in again."


@app.route("/refresh_token")
def refresh_token():
    if 'refresh_token' not in session:
        return redirect('/login')

    if datetime.now().timestamp() > session['expires_at']:
        req_body = {
            'grant_type': 'refresh_token',
            'refresh_token': session['refresh_token'],
            'client_id': CLIENT_ID,
            'client_secret': CLIENT_SECRET
        }

        response = requests.post(TOKEN_URL, data=req_body)
        new_token_info = response.json()

        session['access_token'] = new_token_info['access_token']
        session['expires_at'] = datetime.now().timestamp() + new_token_info['expires_in']

        return redirect('/home')


@app.route("/playlists")
def get_playlists():
    if 'access_token' not in session:
        return redirect('/login')

    if datetime.now().timestamp() > session['expires_at']:
        return redirect('/refresh_token')

    headers = {
        'Authorization': f'Bearer {session["access_token"]}'

    }
    response = requests.get(f"{API_BASE_URL}me/playlists", headers=headers)

    return response.json()


@app.route("/liked_songs")
def get_liked_songs():
    if 'access_token' not in session:
        return redirect('/login')

    access_token = session['access_token']
    headers = {
        'Authorization': f'Bearer {access_token}'
    }

    all_tracks = []
    url = f"{API_BASE_URL}me/tracks?limit=20"

    while url:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            app.logger.error(f"Failed to fetch data: {response.text}")
            return f"Failed to fetch data: {response.text}", response.status_code

        data = response.json()
        all_tracks.extend(data.get('items'))
        url = data.get('next')

    return all_tracks


@app.route("/top_tracks")
def get_top_tracks():
    if 'access_token' not in session:
        return redirect('/login')
    if datetime.now().timestamp() > session.get('expires_at', 0):
        return redirect('/refresh_token')

    headers = {
        'Authorization': f'Bearer {session["access_token"]}'
    }

    response = requests.get(f"{API_BASE_URL}me/top/tracks?time_range=long_term&limit=20", headers=headers)
    if response.status_code == 200:
        return Response(response.content, mimetype='application/json')
    else:
        return Response(json.dumps({'error': 'Failed to fetch top tracks', 'status': response.status_code}),
                        status=response.status_code, mimetype='application/json')


API_BASE_URL = 'https://api.spotify.com/v1/'


@app.route("/recommendations", methods=['GET'])
def get_recommendations():
    if 'access_token' not in session:
        return redirect('/login')
    if datetime.now().timestamp() > session.get('expires_at', 0):
        return redirect('/refresh_token')

    headers = {
        'Authorization': f'Bearer {session["access_token"]}'
    }

    # Retrieve top tracks to use as seeds
    top_tracks_response = requests.get(f"{API_BASE_URL}me/top/tracks?limit=5&time_range=short_term", headers=headers)

    if top_tracks_response.status_code != 200:
        return Response(top_tracks_response.content, status=top_tracks_response.status_code,
                        mimetype='application/json')

    top_tracks_data = top_tracks_response.json()
    seed_tracks = ','.join([track['id'] for track in top_tracks_data['items']])

    # Get parameters from the request in webpage form
    min_energy = request.args.get('min_energy', 0.4)
    max_energy = request.args.get('max_energy', 0.8)
    target_popularity = request.args.get('target_popularity', random.randint(1, 100))
    target_acousticness = request.args.get('target_acousticness', 0.5)
    target_instrumentalness = request.args.get('target_instrumentalness', 0.5)
    target_tempo = request.args.get('target_tempo', 120)

    # Define additional parameters for recommendations, if necessary
    params = {
        'seed_tracks': seed_tracks,
        'limit': 20,
        'market': 'US',
        'min_energy': min_energy,
        'max_energy': max_energy,
        'target_popularity': target_popularity,
        'target_acousticness': target_acousticness,
        'target_instrumentalness': target_instrumentalness,
        'target_tempo': target_tempo
    }

    # Remove empty parameters
    params = {k: v for k, v in params.items() if v}

    # Debugging logs
    print(f"Parameters received: {params}")

    # Construct the request URL
    url = f"{API_BASE_URL}recommendations"
    print(f"Request URL: {url}")
    print(f"Request Params: {params}")

    # Fetch recommendations based on the seeds
    recommendations_response = requests.get(
        url,
        headers={'Authorization': f'Bearer {session["access_token"]}'},
        params=params
    )

    if recommendations_response.status_code == 200:
        return Response(recommendations_response.content, mimetype='application/json')
    else:
        print(f"Error from Spotify API: {recommendations_response.content}")
        return Response(recommendations_response.content, status=recommendations_response.status_code,
                        mimetype='application/json')


@app.route("/create_playlist", methods=['POST'])
def create_playlist():
    if 'access_token' not in session:
        return redirect('/login')
    if datetime.now().timestamp() > session.get('expires_at', 0):
        return redirect('/refresh_token')

    # Get the current user's profile to retrieve the user ID
    user_profile_response = requests.get(
        f"{API_BASE_URL}me",
        headers={'Authorization': f'Bearer {session["access_token"]}'}
    )

    if user_profile_response.status_code != 200:
        return Response(user_profile_response.content, status=user_profile_response.status_code,
                        mimetype='application/json')

    user_profile_data = user_profile_response.json()
    user_id = user_profile_data['id']

    # Create a new playlist
    playlist_name = f"SongScope generated playlist #{random.randint(1000, 9999)}"
    create_playlist_response = requests.post(
        f"{API_BASE_URL}users/{user_id}/playlists",
        headers={
            'Authorization': f'Bearer {session["access_token"]}',
            'Content-Type': 'application/json'
        },
        json={
            'name': playlist_name,
            'description': 'A playlist generated by SongScope',
            'public': False
        }
    )

    if create_playlist_response.status_code != 201:
        return Response(create_playlist_response.content, status=create_playlist_response.status_code,
                        mimetype='application/json')

    playlist_data = create_playlist_response.json()
    playlist_id = playlist_data['id']

    # Add tracks to the new playlist
    tracks = request.json.get('tracks', [])
    track_uris = [track['uri'] for track in tracks]

    add_tracks_response = requests.post(
        f"{API_BASE_URL}playlists/{playlist_id}/tracks",
        headers={
            'Authorization': f'Bearer {session["access_token"]}',
            'Content-Type': 'application/json'
        },
        json={'uris': track_uris}
    )

    if add_tracks_response.status_code != 201:
        return Response(add_tracks_response.content, status=add_tracks_response.status_code,
                        mimetype='application/json')

    return jsonify({'message': 'Playlist created successfully', 'playlist_id': playlist_id})


@app.route('/docs')
def doc():
    with open('../Iac_Terraform_AWS/README.md', 'r', encoding='utf-8') as file:
        content = file.read()
    # Using CodeHilite with Pygments style
    codehilite = CodeHiliteExtension(configs=[('pygments_style', 'monokai')])
    html_content = markdown.markdown(content, extensions=['fenced_code', codehilite])
    return render_template('wiki.html', content=html_content)


@app.route('/diagram')
def svg_display():
    # Assuming the SVG file is stored in a directory accessible by Flask
    svg_path = os.path.join(app.root_path, 'static', 'Untitled Diagram(2).drawio.svg')
    with open(svg_path, 'r') as svg_file:
        svg_content = svg_file.read()
    return render_template('display_svg.html', svg_data=svg_content)


if __name__ == '__main__':
    app.run(debug=True)
