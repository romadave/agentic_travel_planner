import json

def load_trip_request(file_path = "trip_request.json"):
    with open("trip_request.json", "r") as file:
        trip_request = json.load(file)

    return trip_request